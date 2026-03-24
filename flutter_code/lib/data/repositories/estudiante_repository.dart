import 'package:flutter_code/data/services/sqlite_service.dart';
import 'package:flutter_code/domain/models/estudiante.dart';

/// Repositorio encargado de la gestión de datos de los estudiantes.
/// Pertenece a la capa de DATOS.
///
/// Responsabilidades:
/// - CRUD de estudiantes en base de datos local (SQLite).
/// - Abstracción de la fuente de datos para el dominio.
class EstudianteRepository {
  final SqliteService _sqliteService;

  // Nombre de la tabla en SQLite
  static const String _tableName = 'estudiantes';

  EstudianteRepository(this._sqliteService);

  /// Obtiene la lista completa de estudiantes registrados en el dispositivo.
  Future<List<Estudiante>> obtenerEstudiantes() async {
    final List<Map<String, dynamic>> maps = await _sqliteService.query(_tableName);
    return maps.map((map) => Estudiante.fromMap(map)).toList();
  }

  /// Busca un estudiante por su identificador único.
  Future<Estudiante?> obtenerEstudiantePorId(int id) async {
    final List<Map<String, dynamic>> maps = await _sqliteService.query(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Estudiante.fromMap(maps.first);
    }
    return null;
  }

  /// Guarda un nuevo estudiante en la base de datos.
  ///
  /// IMPORTANTE: El campo 'pin' del objeto [estudiante] debe venir ya hasheado
  /// (SHA-256) desde el UseCase antes de llamar a este método.
  Future<int> guardarEstudiante(Estudiante estudiante) async {
    return await _sqliteService.insert(
      _tableName,
      estudiante.toMap(),
    );
  }

  /// Actualiza los datos de un estudiante existente (ej. progreso, grado).
  Future<int> actualizarEstudiante(Estudiante estudiante) async {
    return await _sqliteService.update(
      _tableName,
      estudiante.toMap(),
      where: 'id = ?',
      whereArgs: [estudiante.id],
    );
  }
}
