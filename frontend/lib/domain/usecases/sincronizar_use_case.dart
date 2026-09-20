import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../data/models/estudiante_model.dart';
import '../../data/models/progreso_model.dart';
import '../../data/repositories/estudiante_repository.dart';
import '../../data/repositories/progreso_repository.dart';
import '../../data/services/api_sync_service.dart';
import '../../data/services/sqlite_service.dart';

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

/// Resultado de intentar restaurar una cuenta al iniciar sesión.
///  - [estudiante] != null → perfil restaurado.
///  - [sinConexion] → no se pudo consultar el servidor (NO es una cuenta nueva).
///  - ambos vacíos → el servidor respondió y la cuenta no tiene datos (cuenta nueva).
class RestauracionLogin {
  final EstudianteModel? estudiante;
  final bool sinConexion;

  const RestauracionLogin({this.estudiante, this.sinConexion = false});

  static const nuevo = RestauracionLogin();
}

class SincronizarUseCase {
  final EstudianteRepository  _estudiantes;
  final ProgresoRepository    _progreso;
  final ApiSyncService        _remoto;
  final SqliteService         _db;
  final Connectivity          _connectivity;

  SincronizarUseCase({
    required EstudianteRepository  estudiantes,
    required ProgresoRepository    progreso,
    required ApiSyncService        remoto,
    required SqliteService         db,
    Connectivity?                  connectivity,
  })  : _estudiantes = estudiantes,
        _progreso    = progreso,
        _remoto      = remoto,
        _db          = db,
        _connectivity = connectivity ?? Connectivity();

  /// Texto de diagnóstico: para errores HTTP incluye método, URL, código y cuerpo.
  static String _detalle(Object e) {
    if (e is DioException) {
      final r = e.response;
      return '${e.requestOptions.method} ${e.requestOptions.uri} → '
          '${r?.statusCode ?? e.type.name} ${r?.data ?? e.message ?? ''}';
    }
    return e.toString();
  }

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

  /// Sincronización completa para un estudiante ya existente en este
  /// dispositivo. Seguro llamar en background — captura todos los errores.
  Future<SyncResultado> ejecutar(int estudianteId) async {
    try {
      if (!await _hayInternet()) return SyncResultado.vacio;

      final estudiante = await _estudiantes.obtenerPorId(estudianteId);
      if (estudiante?.firebaseUid == null) return SyncResultado.vacio;

      // 1. Subir perfil (nombre, grado, personaje, etc.)
      await _remoto.subirPerfil(estudiante!);

      // 2. Descargar progreso del backend y hacer merge (max gana)
      final cloudDocs   = await _remoto.descargarProgreso();
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
          // Solo existe en el servidor → insertar localmente (ya sincronizado)
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

      // 3. Subir TODO el progreso local. El servidor fusiona (gana el mayor
      //    avance), así que es idempotente y además migra al backend los
      //    registros que antes quedaron marcados como sincronizados en Firestore.
      final pendientes = await _todosPara(estudianteId);
      await _remoto.subirProgreso(pendientes);

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
      debugPrint('SincronizarUseCase.ejecutar falló: ${_detalle(e)}');
      return SyncResultado(
        subidos: 0, descargados: 0, exito: false, error: e.toString(),
      );
    }
  }

  /// Llama al iniciar sesión cuando el usuario NO tiene perfil local.
  /// Busca el perfil en el backend y reconstruye todo el historial de progreso.
  ///
  /// Distingue tres casos (ver [RestauracionLogin]): restaurado, cuenta nueva
  /// y servidor no disponible. Un fallo de red NUNCA se interpreta como cuenta nueva.
  Future<RestauracionLogin> sincronizarAlLogin(String uid) async {
    try {
      if (!await _hayInternet()) {
        return const RestauracionLogin(sinConexion: true);
      }

      final perfil = await _remoto.descargarPerfil();
      if (perfil == null) return RestauracionLogin.nuevo; // El servidor respondió: cuenta nueva

      // Crear estudiante local con los datos del backend
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

      // Descargar y guardar todo el progreso desde el backend
      final cloudDocs = await _remoto.descargarProgreso();
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

      return RestauracionLogin(estudiante: estudianteLocal);
    } catch (e) {
      debugPrint('SincronizarUseCase.sincronizarAlLogin falló: ${_detalle(e)}');
      return const RestauracionLogin(sinConexion: true);
    }
  }

  Future<List<ProgresoModel>> _todosPara(int estudianteId) async {
    final filas = await _db.consultar(
      'progreso',
      where:     'estudiante_id = ?',
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

  /// Inserta un registro descargado del backend, preservando la fecha exacta.
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

  /// Actualiza un registro local con datos del backend, preservando la fecha.
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
