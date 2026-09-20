import '../services/sqlite_service.dart';
import '../models/estudiante_model.dart';

class EstudianteRepository {
  final SqliteService _db;

  EstudianteRepository(this._db);

  static const _tabla = 'estudiantes';

  /// Crea un estudiante y devuelve su id generado.
  Future<int> crear(EstudianteModel estudiante) async {
    return await _db.insertar(_tabla, estudiante.toMap());
  }

  /// Devuelve el primer estudiante que coincida con [id].
  Future<EstudianteModel?> obtenerPorId(int id) async {
    final filas = await _db.consultar(
      _tabla,
      where:     'id = ?',
      whereArgs: [id],
      limit:     1,
    );
    if (filas.isEmpty) return null;
    return EstudianteModel.fromMap(filas.first);
  }

  /// Devuelve todos los estudiantes registrados.
  Future<List<EstudianteModel>> listarTodos() async {
    final filas = await _db.consultar(_tabla, orderBy: 'nombre ASC');
    return filas.map(EstudianteModel.fromMap).toList();
  }

  /// Actualiza los datos del estudiante (debe tener [id]).
  Future<int> actualizar(EstudianteModel estudiante) async {
    assert(estudiante.id != null, 'El estudiante debe tener id para actualizarse');
    return await _db.actualizar(
      _tabla,
      estudiante.toMap(),
      where:     'id = ?',
      whereArgs: [estudiante.id],
    );
  }

  /// Registra la última sesión del estudiante con la fecha actual.
  Future<void> actualizarUltimaSesion(int estudianteId) async {
    await _db.actualizar(
      _tabla,
      {'ultima_sesion': DateTime.now().toIso8601String()},
      where:     'id = ?',
      whereArgs: [estudianteId],
    );
  }

  /// Elimina un estudiante (su progreso y logros se eliminan en cascada).
  Future<int> eliminar(int id) async {
    return await _db.eliminar(
      _tabla,
      where:     'id = ?',
      whereArgs: [id],
    );
  }

  /// Busca un estudiante por email y contraseña (login local legacy).
  Future<EstudianteModel?> buscarPorEmailYContrasena(
      String email, String contrasena) async {
    final filas = await _db.consultar(
      _tabla,
      where:     'email = ? AND contrasena = ?',
      whereArgs: [email, contrasena],
      limit:     1,
    );
    if (filas.isEmpty) return null;
    return EstudianteModel.fromMap(filas.first);
  }

  /// Busca un estudiante por su UID de Firebase Auth.
  Future<EstudianteModel?> buscarPorFirebaseUid(String uid) async {
    final filas = await _db.consultar(
      _tabla,
      where:     'firebase_uid = ?',
      whereArgs: [uid],
      limit:     1,
    );
    if (filas.isEmpty) return null;
    return EstudianteModel.fromMap(filas.first);
  }

  /// Busca un estudiante por email (para migración de cuentas legacy).
  Future<EstudianteModel?> buscarPorEmail(String email) async {
    final filas = await _db.consultar(
      _tabla,
      where:     'email = ?',
      whereArgs: [email],
      limit:     1,
    );
    if (filas.isEmpty) return null;
    return EstudianteModel.fromMap(filas.first);
  }

  /// Asocia un firebase_uid a un estudiante existente (migración legacy).
  Future<void> vincularFirebaseUid(int estudianteId, String uid) async {
    await _db.actualizar(
      _tabla,
      {'firebase_uid': uid},
      where:     'id = ?',
      whereArgs: [estudianteId],
    );
  }

  /// Crea el estudiante por defecto si no existe ninguno.
  /// Devuelve el estudiante (existente o recién creado).
  Future<EstudianteModel> obtenerOCrearPorDefecto() async {
    final todos = await listarTodos();
    if (todos.isNotEmpty) return todos.first;

    final nuevo = EstudianteModel(
      nombre:        'Estudiante',
      grado:         1,
      personaje:     'pollito',
      fechaRegistro: DateTime.now().toIso8601String(),
    );
    final id = await crear(nuevo);
    return nuevo.copyWith(id: id);
  }
}
