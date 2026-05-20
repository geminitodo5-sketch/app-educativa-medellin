import 'sqlite_service.dart';

class RachaInfo {
  final int dias;
  final Set<int> diasActivosSemana; // 1=Lunes … 7=Domingo

  const RachaInfo({required this.dias, required this.diasActivosSemana});
}

class RachaService {
  final SqliteService _db;

  RachaService(this._db);

  /// Comprueba si hoy ya fue registrado.
  /// Si no, incrementa (o reinicia) la racha y retorna la info actualizada.
  /// Retorna null si ya se verificó hoy → no volver a mostrar la pantalla.
  Future<RachaInfo?> verificarRacha(int estudianteId) async {
    final hoy = _hoy();
    final rows = await _db.consultar(
      'estudiantes', where: 'id = ?', whereArgs: [estudianteId]);
    if (rows.isEmpty) return null;

    final ultimaRacha = rows.first['ultima_racha'] as String?;
    if (ultimaRacha == hoy) return null;

    int rachaDias = (rows.first['racha_dias'] as int?) ?? 0;
    rachaDias = (ultimaRacha == _ayer()) ? rachaDias + 1 : 1;

    await _db.actualizar(
      'estudiantes',
      {'racha_dias': rachaDias, 'ultima_racha': hoy},
      where: 'id = ?',
      whereArgs: [estudianteId],
    );

    // Registra la sesión del día (ignora duplicados).
    try {
      await _db.insertar(
        'sesiones_diarias', {'estudiante_id': estudianteId, 'fecha': hoy});
    } catch (_) {}

    return RachaInfo(
      dias: rachaDias,
      diasActivosSemana: await _diasActivos(estudianteId),
    );
  }

  /// Obtiene la racha actual sin modificarla (para consulta manual).
  Future<RachaInfo> obtenerRacha(int estudianteId) async {
    final rows = await _db.consultar(
      'estudiantes', where: 'id = ?', whereArgs: [estudianteId]);
    final dias = rows.isEmpty ? 0 : ((rows.first['racha_dias'] as int?) ?? 0);
    return RachaInfo(
      dias: dias,
      diasActivosSemana: await _diasActivos(estudianteId),
    );
  }

  /// Retorna los weekdays activos en la semana actual (lunes=1, domingo=7).
  Future<Set<int>> _diasActivos(int estudianteId) async {
    final hoy = DateTime.now();
    final lunes = hoy.subtract(Duration(days: hoy.weekday - 1));
    final domingo = lunes.add(const Duration(days: 6));
    final rows = await _db.rawQuery(
      'SELECT fecha FROM sesiones_diarias '
      'WHERE estudiante_id = ? AND fecha >= ? AND fecha <= ?',
      [estudianteId, _fmt(lunes), _fmt(domingo)],
    );
    return rows
        .map((r) => DateTime.parse(r['fecha'] as String).weekday)
        .toSet();
  }

  String _hoy() => _fmt(DateTime.now());
  String _ayer() => _fmt(DateTime.now().subtract(const Duration(days: 1)));
  String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}
