// ─────────────────────────────────────────────────────────────
//  lib/data/providers/database_provider.dart
//  Capa: Datos — Responsabilidad: Ingeniería
//  Expone SqliteService y repositorios como singletons Riverpod
// ─────────────────────────────────────────────────────────────

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/sqlite_service.dart';
import '../repositories/estudiante_repository.dart';
import '../repositories/progreso_repository.dart';

/// Servicio SQLite singleton.
final sqliteServiceProvider = Provider<SqliteService>((ref) {
  return SqliteService();
});

/// Repositorio de estudiantes.
final estudianteRepositoryProvider = Provider<EstudianteRepository>((ref) {
  return EstudianteRepository(ref.read(sqliteServiceProvider));
});

/// Repositorio de progreso.
final progresoRepositoryProvider = Provider<ProgresoRepository>((ref) {
  return ProgresoRepository(ref.read(sqliteServiceProvider));
});
