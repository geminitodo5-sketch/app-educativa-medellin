import '../services/sqlite_service.dart';
import '../models/progreso_model.dart';

class ProgresoRepository {
  final SqliteService _db;

  ProgresoRepository(this._db);

  static const _tabla = 'progreso';

  /// Guarda o actualiza el progreso de una actividad.
  /// Usa REPLACE para respetar el índice único
  /// (estudiante_id, grado, materia, actividad).
  Future<int> guardar(ProgresoModel progreso) async {
    final datos = progreso.copyWith(
      // Preserva ultimaVez si ya viene informado (ej: restaurado desde Firestore).
      // Solo asigna la hora actual cuando el registro es nuevo/local.
      ultimaVez: progreso.ultimaVez ?? DateTime.now().toIso8601String(),
    ).toMap();
    return await _db.insertar(_tabla, datos);
  }

  /// Obtiene el progreso de una actividad específica.
  Future<ProgresoModel?> obtenerActividad({
    required int    estudianteId,
    required int    grado,
    required String materia,
    required String actividad,
  }) async {
    final filas = await _db.consultar(
      _tabla,
      where:     'estudiante_id = ? AND grado = ? AND materia = ? AND actividad = ?',
      whereArgs: [estudianteId, grado, materia, actividad],
      limit:     1,
    );
    if (filas.isEmpty) return null;
    return ProgresoModel.fromMap(filas.first);
  }

  /// Lista todo el progreso de un estudiante en una materia y grado.
  Future<List<ProgresoModel>> listarPorMateria({
    required int    estudianteId,
    required int    grado,
    required String materia,
  }) async {
    final filas = await _db.consultar(
      _tabla,
      where:     'estudiante_id = ? AND grado = ? AND materia = ?',
      whereArgs: [estudianteId, grado, materia],
      orderBy:   'actividad ASC',
    );
    return filas.map(ProgresoModel.fromMap).toList();
  }

  /// Porcentaje promedio del estudiante en una materia y grado.
  Future<double> promedioMateria({
    required int    estudianteId,
    required int    grado,
    required String materia,
  }) async {
    final filas = await _db.rawQuery(
      '''SELECT AVG(porcentaje) AS promedio FROM $_tabla
         WHERE estudiante_id = ? AND grado = ? AND materia = ?''',
      [estudianteId, grado, materia],
    );
    return (filas.first['promedio'] as num?)?.toDouble() ?? 0.0;
  }

  /// Porcentaje de avance de la materia calculado como:
  ///   SUM(porcentaje_de_cada_actividad) / (actividadesTotales × 100) × 100
  ///
  /// Ejemplo: 2 de 3 actividades al 100% → (200)/(300) × 100 = 66.7 %
  /// [actividadesTotales] debe reflejar el número real de actividades
  /// de la materia (Matemáticas=3, Ciencias=4, Español=3, Sociales=3, Inglés=3).
  Future<double> porcentajeMateria({
    required int    estudianteId,
    required int    grado,
    required String materia,
    int actividadesTotales = 3,
  }) async {
    final filas = await _db.rawQuery(
      '''SELECT COALESCE(SUM(porcentaje), 0) AS suma FROM $_tabla
         WHERE estudiante_id = ? AND grado = ? AND materia = ?''',
      [estudianteId, grado, materia],
    );
    final suma = (filas.first['suma'] as num?)?.toDouble() ?? 0.0;
    final total = (actividadesTotales * 100.0);
    if (total <= 0) return 0.0;
    return (suma / total * 100.0).clamp(0.0, 100.0);
  }

  /// Incrementa los intentos y actualiza el porcentaje de una actividad.
  Future<void> registrarIntento({
    required int    estudianteId,
    required int    grado,
    required String materia,
    required String actividad,
    required double porcentaje,
  }) async {
    final existente = await obtenerActividad(
      estudianteId: estudianteId,
      grado:        grado,
      materia:      materia,
      actividad:    actividad,
    );

    final nuevo = ProgresoModel(
      id:           existente?.id,
      estudianteId: estudianteId,
      grado:        grado,
      materia:      materia,
      actividad:    actividad,
      porcentaje:   porcentaje,
      intentos:     (existente?.intentos ?? 0) + 1,
      sincronizado: false,
    );

    await guardar(nuevo);
  }
}
