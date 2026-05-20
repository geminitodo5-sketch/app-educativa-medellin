// ─────────────────────────────────────────────────────────────
//  lib/data/providers/database_provider.dart
//  Capa: Datos — Responsabilidad: Ingeniería
//  Expone SqliteService y repositorios como singletons Riverpod
// ─────────────────────────────────────────────────────────────

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/sqlite_service.dart';
import '../services/sync_service.dart';
import '../services/banco_preguntas_service.dart';
import '../services/firebase_auth_service.dart';
import '../services/firestore_sync_service.dart';
import '../repositories/estudiante_repository.dart';
import '../repositories/progreso_repository.dart';
import '../repositories/sync_queue_repository.dart';
import '../../domain/usecases/sincronizar_use_case.dart';

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

/// Repositorio de cola de sincronización.
final syncQueueRepositoryProvider = Provider<SyncQueueRepository>((ref) {
  return SyncQueueRepository(ref.read(sqliteServiceProvider));
});

/// Servicio de sincronización offline→backend.
final syncServiceProvider = Provider<SyncService>((ref) {
  return SyncService(ref.read(syncQueueRepositoryProvider));
});

/// Banco estático de preguntas MCQ con distractores de calidad.
final bancoPreguntasServiceProvider = Provider<BancoPreguntasService>((ref) {
  return BancoPreguntasService(ref.read(sqliteServiceProvider));
});

/// Servicio de autenticación Firebase (email/contraseña + Google).
final firebaseAuthServiceProvider = Provider<FirebaseAuthService>((ref) {
  return FirebaseAuthService();
});

/// Servicio de sincronización con Firestore (push/pull).
final firestoreSyncServiceProvider = Provider<FirestoreSyncService>((ref) {
  return FirestoreSyncService();
});

/// UseCase que orquesta la sincronización offline-first bidireccional.
final sincronizarUseCaseProvider = Provider<SincronizarUseCase>((ref) {
  return SincronizarUseCase(
    estudiantes: ref.read(estudianteRepositoryProvider),
    progreso:    ref.read(progresoRepositoryProvider),
    firestore:   ref.read(firestoreSyncServiceProvider),
    db:          ref.read(sqliteServiceProvider),
  );
});

/// Resetea la base de datos completa (solo para desarrollo/debug).
final resetDbProvider = Provider<Future<void> Function()>((ref) {
  return () => ref.read(sqliteServiceProvider).resetearBaseDatos();
});
