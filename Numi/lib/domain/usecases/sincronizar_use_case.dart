// ─────────────────────────────────────────────────────────────
//  lib/domain/usecases/sincronizar_use_case.dart
//  Capa: Dominio — Responsabilidad: Ingeniería
//
//  Orquesta la sincronización bidireccional offline-first:
//
//  SUBIR (local → Firestore):
//    1. Consulta progreso WHERE sincronizado = 0.
//    2. Sube a Firestore (batch write).
//    3. Marca como sincronizado = 1 localmente.
//
//  DESCARGAR (Firestore → local):
//    4. Descarga todos los docs de /usuarios/{uid}/progreso.
//    5. Por cada doc: si cloud.porcentaje > local → actualiza local.
//       Si no existe localmente → inserta.
//
//  Resolución de conflictos: max(porcentaje) gana.
//  Un niño nunca retrocede en su avance.
//
//  USO EN NUEVO DISPOSITIVO (sincronizarAlLogin):
//    — Si el usuario tiene perfil en Firestore, se restaura todo
//      (perfil + progreso de las 5 áreas) automáticamente.
// ─────────────────────────────────────────────────────────────

import 'package:connectivity_plus/connectivity_plus.dart';
import '../../data/models/estudiante_model.dart';
import '../../data/models/progreso_model.dart';
import '../../data/repositories/estudiante_repository.dart';
import '../../data/repositories/progreso_repository.dart';
import '../../data/services/firestore_sync_service.dart';
import '../../data/services/sqlite_service.dart';

// ── Resultado de sincronización ───────────────────────────────

class SyncResultado {
  final int  subidos;
  final int  descargados;
  final bool exito;
  final String? error;

  const SyncResultado({
    required this.subidos,
    required this.descargados,
    required this.exito,
    this.error,
  });

  static const vacio =
      SyncResultado(subidos: 0, descargados: 0, exito: true);
}

// ── UseCase ───────────────────────────────────────────────────

class SincronizarUseCase {
  final EstudianteRepository  _estudiantes;
  final ProgresoRepository    _progreso;
  final FirestoreSyncService  _firestore;
  final SqliteService         _db;
  final Connectivity          _connectivity;

  SincronizarUseCase({
    required EstudianteRepository  estudiantes,
    required ProgresoRepository    progreso,
    required FirestoreSyncService  firestore,
    required SqliteService         db,
    Connectivity?                  connectivity,
  })  : _estudiantes = estudiantes,
        _progreso    = progreso,
        _firestore   = firestore,
        _db          = db,
        _connectivity = connectivity ?? Connectivity();

  // ── Conectividad ──────────────────────────────────────────────

  Future<bool> _hayInternet() async {
    final result = await _connectivity.checkConnectivity();
    // connectivity_plus v5+ devuelve ConnectivityResult (v4) o
    // List<ConnectivityResult> (v5 Android). Soportamos ambos.
    if (result is List) {
      return (result as List).any(_esOnline);
    }
    return _esOnline(result);
  }

  bool _esOnline(dynamic r) =>
      r == ConnectivityResult.mobile  ||
      r == ConnectivityResult.wifi    ||
      r == ConnectivityResult.ethernet;

  // ── Sync principal ────────────────────────────────────────────

  /// Sincronización completa para un estudiante ya existente en este
  /// dispositivo. Seguro llamar en background — captura todos los errores.
  Future<SyncResultado> ejecutar(int estudianteId) async {
    try {
      if (!await _hayInternet()) return SyncResultado.vacio;

      final estudiante = await _estudiantes.obtenerPorId(estudianteId);
      if (estudiante?.firebaseUid == null) return SyncResultado.vacio;

      final uid = estudiante!.firebaseUid!;

      // 1. Subir perfil (nombre, grado, personaje, etc.)
      await _firestore.subirPerfil(estudiante);

      // 2. Descargar progreso de Firestore y hacer merge (max gana)
      final cloudDocs   = await _firestore.descargarProgreso(uid);
      int  descargados  = 0;

      for (final doc in cloudDocs) {
        final grado      = (doc['grado']      as num).toInt();
        final materia    =  doc['materia']    as String;
        final actividad  =  doc['actividad']  as String;
        final cloudPct   = (doc['porcentaje'] as num).toDouble();
        final cloudInt   = (doc['intentos']   as num?)?.toInt() ?? 0;
        final cloudTime  =  doc['ultima_vez'] as String?;

        final local = await _progreso.obtenerActividad(
          estudianteId: estudianteId,
          grado:        grado,
          materia:      materia,
          actividad:    actividad,
        );

        if (local == null) {
          // Solo existe en la nube → insertar localmente (ya sincronizado)
          await _insertarDesdeCloud(
            estudianteId: estudianteId,
            grado:        grado,
            materia:      materia,
            actividad:    actividad,
            porcentaje:   cloudPct,
            intentos:     cloudInt,
            ultimaVez:    cloudTime,
          );
          descargados++;
        } else if (cloudPct > local.porcentaje) {
          // La nube tiene mayor avance → actualizar local
          await _actualizarDesdeCloud(
            local:      local,
            porcentaje: cloudPct,
            intentos:   cloudInt > local.intentos ? cloudInt : local.intentos,
            ultimaVez:  cloudTime,
          );
          descargados++;
        }
        // Si local >= cloud: no cambiar local; se subirá en el paso siguiente.
      }

      // 3. Subir registros locales no sincronizados (porcentaje local es el mejor)
      final pendientes = await _pendientesPara(estudianteId);
      await _firestore.subirProgreso(uid, pendientes);

      // 4. Marcar todos como sincronizados
      if (pendientes.isNotEmpty) {
        await _marcarSincronizados(estudianteId);
      }

      return SyncResultado(
        subidos:      pendientes.length,
        descargados:  descargados,
        exito:        true,
      );
    } catch (e) {
      return SyncResultado(
        subidos: 0, descargados: 0, exito: false, error: e.toString(),
      );
    }
  }

  // ── Restaurar en nuevo dispositivo ────────────────────────────

  /// Llama al iniciar sesión cuando el usuario NO tiene perfil local.
  /// Busca el perfil en Firestore y reconstruye todo el historial de progreso.
  ///
  /// Retorna el EstudianteModel creado localmente, o null si:
  ///   - No hay internet
  ///   - El usuario no tiene datos en Firestore (primera vez absoluta)
  Future<EstudianteModel?> sincronizarAlLogin(String uid) async {
    try {
      if (!await _hayInternet()) return null;

      final perfil = await _firestore.descargarPerfil(uid);
      if (perfil == null) return null; // Usuario nuevo, sin datos en Firestore

      // Crear estudiante local con los datos de Firestore
      final nuevo = EstudianteModel(
        nombre:        perfil['nombre']        as String?  ?? 'Estudiante',
        grado:         (perfil['grado']        as num?)?.toInt() ?? 1,
        personaje:     perfil['personaje']     as String?  ?? 'pollito',
        fechaRegistro: perfil['fecha_registro'] as String? ??
                       DateTime.now().toIso8601String(),
        email:         perfil['email']         as String?,
        edad:          (perfil['edad']         as num?)?.toInt(),
        genero:        perfil['genero']        as String?,
        firebaseUid:   uid,
      );

      final id             = await _estudiantes.crear(nuevo);
      final estudianteLocal = nuevo.copyWith(id: id);

      // Descargar y guardar todo el progreso desde Firestore
      final cloudDocs = await _firestore.descargarProgreso(uid);
      for (final doc in cloudDocs) {
        await _insertarDesdeCloud(
          estudianteId: id,
          grado:        (doc['grado']      as num).toInt(),
          materia:       doc['materia']    as String,
          actividad:     doc['actividad']  as String,
          porcentaje:   (doc['porcentaje'] as num).toDouble(),
          intentos:     (doc['intentos']   as num?)?.toInt() ?? 0,
          ultimaVez:     doc['ultima_vez'] as String?,
        );
      }

      return estudianteLocal;
    } catch (_) {
      return null;
    }
  }

  // ── Helpers privados ─────────────────────────────────────────

  Future<List<ProgresoModel>> _pendientesPara(int estudianteId) async {
    final filas = await _db.consultar(
      'progreso',
      where:     'estudiante_id = ? AND sincronizado = 0',
      whereArgs: [estudianteId],
    );
    return filas.map(ProgresoModel.fromMap).toList();
  }

  Future<void> _marcarSincronizados(int estudianteId) async {
    await _db.actualizar(
      'progreso',
      {'sincronizado': 1},
      where:     'estudiante_id = ? AND sincronizado = 0',
      whereArgs: [estudianteId],
    );
  }

  /// Inserta un registro descargado de Firestore, preservando la fecha exacta.
  Future<void> _insertarDesdeCloud({
    required int    estudianteId,
    required int    grado,
    required String materia,
    required String actividad,
    required double porcentaje,
    required int    intentos,
    String?         ultimaVez,
  }) async {
    await _db.insertar('progreso', {
      'estudiante_id': estudianteId,
      'grado':         grado,
      'materia':       materia,
      'actividad':     actividad,
      'porcentaje':    porcentaje,
      'intentos':      intentos,
      'ultima_vez':    ultimaVez ?? DateTime.now().toIso8601String(),
      'sincronizado':  1,
    });
  }

  /// Actualiza un registro local con datos de Firestore, preservando la fecha.
  Future<void> _actualizarDesdeCloud({
    required ProgresoModel local,
    required double        porcentaje,
    required int           intentos,
    String?                ultimaVez,
  }) async {
    await _db.actualizar(
      'progreso',
      {
        'porcentaje':   porcentaje,
        'intentos':     intentos,
        'ultima_vez':   ultimaVez ?? DateTime.now().toIso8601String(),
        'sincronizado': 1,
      },
      where:     'id = ?',
      whereArgs: [local.id],
    );
  }
}
