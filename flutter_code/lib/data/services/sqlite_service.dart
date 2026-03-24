import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

/// Servicio encargado de la conexión y operaciones directas con SQLite.
/// Pertenece a la capa de DATOS.
///
/// No contiene lógica de negocio, solo CRUD genérico.
class SqliteService {
  static Database? _database;

  /// Obtiene la instancia de la base de datos, inicializándola si es necesario.
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Inicializa la base de datos y crea las tablas necesarias.
  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'app_educativa.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  /// Crea la estructura de tablas al instalar la app por primera vez.
  Future<void> _onCreate(Database db, int version) async {
    // Tabla de Estudiantes
    await db.execute('''
      CREATE TABLE estudiantes(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL,
        grado INTEGER NOT NULL,
        pin TEXT NOT NULL,
        avatar TEXT NOT NULL,
        monedas INTEGER DEFAULT 0
      )
    ''');

    // Aquí se agregarían tablas futuras como 'progreso', 'logros', etc.
    // Ejemplo placeholder:
    // await db.execute('CREATE TABLE progreso(...)');
  }

  /// Realiza una consulta genérica a la base de datos.
  Future<List<Map<String, dynamic>>> query(
    String table, {
    String? where,
    List<Object?>? whereArgs,
  }) async {
    final db = await database;
    return await db.query(table, where: where, whereArgs: whereArgs);
  }

  /// Inserta un registro en la tabla especificada.
  /// Retorna el ID del registro insertado.
  Future<int> insert(String table, Map<String, dynamic> data) async {
    final db = await database;
    return await db.insert(
      table,
      data,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Actualiza registros en la tabla especificada.
  /// Retorna la cantidad de filas afectadas.
  Future<int> update(
    String table,
    Map<String, dynamic> data, {
    String? where,
    List<Object?>? whereArgs,
  }) async {
    final db = await database;
    return await db.update(table, data, where: where, whereArgs: whereArgs);
  }

  // Nota: Delete no solicitado explícitamente pero se agregaría aquí si fuese necesario.
}
