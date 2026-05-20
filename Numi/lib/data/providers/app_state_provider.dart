// ─────────────────────────────────────────────────────────────
//  lib/data/providers/app_state_provider.dart
//  Estado global de la sesión activa + progreso del menú
// ─────────────────────────────────────────────────────────────

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/estudiante_model.dart';
import 'database_provider.dart';
// ignore: unused_import — usado por progresoRealtimeProvider
import '../services/sqlite_service.dart';

/// Estudiante que tiene la sesión activa.
/// Se establece en bienvenida.dart y seleccion_grado_view.dart.
final estudianteActivoProvider = StateProvider<EstudianteModel?>((ref) => null);

/// Número de actividades por materia (para calcular el porcentaje real).
const Map<String, int> actividadesPorMateria = {
  'matematicas': 3, // Los números, Quien tiene más, Sumar
  'ciencias': 4,    // ¿Vivo o no Vivo?, Cuerpo humano, Animales, Las plantas
  'español': 3,     // Palabra loca, Arma la palabra, Oraciones
  'sociales': 3,    // Héroes de la Ciudad, Detective de Objetos, Pasado y Presente
  'ingles': 3,      // Module 1, Module 2, Module 3
};

/// Progreso de todas las materias del estudiante activo.
/// Se recalcula cuando cambia el estudiante o se invalida manualmente.
final menuProgresoProvider = FutureProvider<Map<String, double>>((ref) async {
  final estudiante = ref.watch(estudianteActivoProvider);
  if (estudiante == null || estudiante.id == null) return {};

  final repo = ref.read(progresoRepositoryProvider);
  final result = <String, double>{};

  for (final entry in actividadesPorMateria.entries) {
    result[entry.key] = await repo.porcentajeMateria(
      estudianteId: estudiante.id!,
      grado: estudiante.grado,
      materia: entry.key,
      actividadesTotales: entry.value,
    );
  }
  return result;
});

/// Stream que escucha la conectividad y drena la sync_queue legacy.
/// Se watch-ea desde la raíz de la app para mantenerse vivo.
final syncListenerProvider = StreamProvider<int>((ref) {
  final syncService = ref.watch(syncServiceProvider);
  return syncService.escucharYSincronizar();
});

/// Stream que escucha la conectividad y ejecuta la sincronización
/// bidireccional con Firestore (progreso de las 5 áreas + perfil).
/// Se activa solo cuando hay un estudiante con sesión activa.
final firestoreSyncListenerProvider = StreamProvider<int>((ref) async* {
  final connectivity = Connectivity();
  await for (final result in connectivity.onConnectivityChanged) {
    final esOnline = result == ConnectivityResult.mobile  ||
                     result == ConnectivityResult.wifi    ||
                     result == ConnectivityResult.ethernet;
    if (esOnline) {
      final estudiante = ref.read(estudianteActivoProvider);
      if (estudiante?.id != null) {
        final r = await ref
            .read(sincronizarUseCaseProvider)
            .ejecutar(estudiante!.id!);
        yield r.subidos + r.descargados;
        continue;
      }
    }
    yield 0;
  }
});

/// Listener en tiempo real de Firestore para sincronización multi-dispositivo.
///
/// Cuando otro dispositivo (con la misma cuenta) sube progreso a Firestore,
/// este provider lo recibe al instante, aplica el merge max(porcentaje)
/// en SQLite e invalida [menuProgresoProvider] para que la UI se refresque.
///
/// Filtro de auto-escrituras: solo se procesan cambios cuyo origen está
/// confirmado por el servidor y NO son pendientes de este dispositivo
/// ([hasPendingWrites] == false). Esto evita el bucle dispositivo→Firestore
/// →dispositivo al subir el propio progreso.
final progresoRealtimeProvider = StreamProvider<int>((ref) async* {
  final estudiante = ref.watch(estudianteActivoProvider);

  // Sin sesión activa o sin UID de Firebase: sin listener
  if (estudiante == null ||
      estudiante.firebaseUid == null ||
      estudiante.id == null) {
    yield 0;
    return;
  }

  final uid          = estudiante.firebaseUid!;
  final estudianteId = estudiante.id!;
  final repo         = ref.read(progresoRepositoryProvider);
  final db           = ref.read(sqliteServiceProvider);
  final fss          = ref.read(firestoreSyncServiceProvider);

  try {
    await for (final cambios in fss.escucharProgreso(uid)) {
      if (cambios.isEmpty) {
        yield 0;
        continue;
      }

      int actualizados = 0;

      for (final doc in cambios) {
        try {
          final cloudGrado  = (doc['grado']      as num).toInt();
          final materia     =  doc['materia']    as String;
          final actividad   =  doc['actividad']  as String;
          final cloudPct    = (doc['porcentaje'] as num).toDouble();
          final cloudInt    = (doc['intentos']   as num?)?.toInt() ?? 0;
          final cloudTime   =  doc['ultima_vez'] as String?;

          final local = await repo.obtenerActividad(
            estudianteId: estudianteId,
            grado:        cloudGrado,
            materia:      materia,
            actividad:    actividad,
          );

          if (local == null) {
            // El registro solo existe en Firestore → insertar localmente
            await db.insertar('progreso', {
              'estudiante_id': estudianteId,
              'grado':         cloudGrado,
              'materia':       materia,
              'actividad':     actividad,
              'porcentaje':    cloudPct,
              'intentos':      cloudInt,
              'ultima_vez':    cloudTime ?? DateTime.now().toIso8601String(),
              'sincronizado':  1,
            });
            actualizados++;
          } else if (cloudPct > local.porcentaje) {
            // Firestore tiene mayor avance (otro dispositivo) → actualizar local
            await db.actualizar(
              'progreso',
              {
                'porcentaje':   cloudPct,
                'intentos':     cloudInt > local.intentos
                    ? cloudInt
                    : local.intentos,
                'ultima_vez':   cloudTime ?? DateTime.now().toIso8601String(),
                'sincronizado': 1,
              },
              where:     'id = ?',
              whereArgs: [local.id],
            );
            actualizados++;
          }
        } catch (_) {
          // Documento malformado: continúa con los demás
        }
      }

      // Refrescar la UI solo si algo cambió
      if (actualizados > 0) {
        ref.invalidate(menuProgresoProvider);
      }
      yield actualizados;
    }
  } catch (_) {
    // Firestore no disponible temporalmente: el provider emite 0 sin morir
    yield 0;
  }
});
