import '../services/sqlite_service.dart';
import '../models/sync_queue_model.dart';

class SyncQueueRepository {
  final SqliteService _db;

  SyncQueueRepository(this._db);

  static const _tabla = 'sync_queue';

  /// Encola un nuevo registro para sincronizar después.
  Future<int> encolar(SyncQueueModel item) async {
    final datos = item.copyWith(
      fecha: DateTime.now().toIso8601String(),
    ).toMap();
    return await _db.insertar(_tabla, datos);
  }

  /// Retorna todos los registros que aún no han sido enviados,
  /// ordenados del más antiguo al más reciente.
  Future<List<SyncQueueModel>> pendientes() async {
    final filas = await _db.consultar(
      _tabla,
      where:   'enviado = 0',
      orderBy: 'fecha ASC',
    );
    return filas.map(SyncQueueModel.fromMap).toList();
  }

  /// Marca un registro como enviado exitosamente.
  Future<void> marcarEnviado(int id) async {
    await _db.actualizar(
      _tabla,
      {'enviado': 1},
      where:     'id = ?',
      whereArgs: [id],
    );
  }

  /// Incrementa el contador de intentos fallidos de un registro.
  Future<void> registrarFallo(int id) async {
    await _db.rawQuery(
      'UPDATE $_tabla SET intentos_sync = intentos_sync + 1 WHERE id = ?',
      [id],
    );
  }

  /// Elimina todos los registros ya enviados (limpieza periódica).
  Future<int> limpiarEnviados() async {
    return await _db.eliminar(
      _tabla,
      where:     'enviado = 1',
      whereArgs: [],
    );
  }

  /// Cantidad de registros pendientes (útil para mostrar badge en UI).
  Future<int> cantidadPendientes() async {
    final filas = await _db.rawQuery(
      'SELECT COUNT(*) AS total FROM $_tabla WHERE enviado = 0',
    );
    return (filas.first['total'] as int?) ?? 0;
  }
}
