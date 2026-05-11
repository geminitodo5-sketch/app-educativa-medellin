// ─────────────────────────────────────────────────────────────
//  lib/data/providers/app_state_provider.dart
//  Estado global de la sesión activa + progreso del menú
// ─────────────────────────────────────────────────────────────

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/estudiante_model.dart';
import 'database_provider.dart';

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

/// Stream que escucha la conectividad y sincroniza automáticamente.
/// Se watch-ea desde la raíz de la app para mantenerse vivo.
final syncListenerProvider = StreamProvider<int>((ref) {
  final syncService = ref.watch(syncServiceProvider);
  return syncService.escucharYSincronizar();
});
