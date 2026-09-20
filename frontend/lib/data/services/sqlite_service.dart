import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class SqliteService {
  static const String _dbName    = 'numi.db';
  static const int    _dbVersion = 6;

  static SqliteService? _instance;
  static Database?      _database;

  SqliteService._internal();
  factory SqliteService() {
    _instance ??= SqliteService._internal();
    return _instance!;
  }

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final path = join(await getDatabasesPath(), _dbName);
    return await openDatabase(
      path,
      version:    _dbVersion,
      onCreate:   _onCreate,
      onUpgrade:  _onUpgrade,
      onConfigure: (db) async =>
          await db.execute('PRAGMA foreign_keys = ON'),
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.transaction((txn) async {

      // 1. estudiantes
      await txn.execute('''
        CREATE TABLE estudiantes (
          id             INTEGER PRIMARY KEY AUTOINCREMENT,
          nombre         TEXT    NOT NULL,
          grado          INTEGER NOT NULL CHECK (grado BETWEEN 1 AND 5),
          personaje      TEXT    NOT NULL CHECK (personaje IN ('pollito','mono')),
          fecha_registro TEXT    NOT NULL,
          ultima_sesion  TEXT,
          email          TEXT,
          contrasena     TEXT,
          edad           INTEGER,
          genero         TEXT,
          racha_dias     INTEGER NOT NULL DEFAULT 0,
          ultima_racha   TEXT,
          firebase_uid   TEXT
        )
      ''');

      // 2. progreso
      await txn.execute('''
        CREATE TABLE progreso (
          id            INTEGER PRIMARY KEY AUTOINCREMENT,
          estudiante_id INTEGER NOT NULL REFERENCES estudiantes(id) ON DELETE CASCADE,
          grado         INTEGER NOT NULL CHECK (grado BETWEEN 1 AND 5),
          materia       TEXT    NOT NULL CHECK (materia IN (
                          'matematicas','ingles','español','ciencias','sociales')),
          actividad     TEXT    NOT NULL,
          porcentaje    REAL    NOT NULL DEFAULT 0.0
                          CHECK (porcentaje BETWEEN 0.0 AND 100.0),
          intentos      INTEGER NOT NULL DEFAULT 0,
          ultima_vez    TEXT,
          sincronizado  INTEGER NOT NULL DEFAULT 0 CHECK (sincronizado IN (0,1))
        )
      ''');
      await txn.execute(
        'CREATE INDEX idx_progreso_mat ON progreso (estudiante_id, grado, materia)');
      await txn.execute(
        'CREATE UNIQUE INDEX idx_progreso_unico ON progreso (estudiante_id, grado, materia, actividad)');

      // 3. sync_queue
      await txn.execute('''
        CREATE TABLE sync_queue (
          id            INTEGER PRIMARY KEY AUTOINCREMENT,
          tipo_accion   TEXT    NOT NULL,
          payload       TEXT    NOT NULL,
          fecha         TEXT    NOT NULL,
          enviado       INTEGER NOT NULL DEFAULT 0 CHECK (enviado IN (0,1)),
          intentos_sync INTEGER NOT NULL DEFAULT 0
        )
      ''');
      await txn.execute(
        'CREATE INDEX idx_sync_pend ON sync_queue (enviado, fecha)');

      // 4. paquetes_contenido
      await txn.execute('''
        CREATE TABLE paquetes_contenido (
          id             INTEGER PRIMARY KEY AUTOINCREMENT,
          grado          INTEGER NOT NULL CHECK (grado BETWEEN 1 AND 5),
          materia        TEXT    NOT NULL CHECK (materia IN (
                           'matematicas','ingles','español','ciencias','sociales')),
          version        TEXT    NOT NULL,
          ruta_local     TEXT    NOT NULL,
          fecha_descarga TEXT    NOT NULL,
          tamanio_bytes  INTEGER,
          activo         INTEGER NOT NULL DEFAULT 1 CHECK (activo IN (0,1))
        )
      ''');
      await txn.execute(
        'CREATE INDEX idx_paquetes ON paquetes_contenido (grado, materia, activo)');

      // 5. logros
      await txn.execute('''
        CREATE TABLE logros (
          id             INTEGER PRIMARY KEY AUTOINCREMENT,
          estudiante_id  INTEGER NOT NULL REFERENCES estudiantes(id) ON DELETE CASCADE,
          tipo_logro     TEXT    NOT NULL,
          materia        TEXT    CHECK (materia IN (
                           'matematicas','ingles','español','ciencias','sociales')),
          fecha_obtenido TEXT    NOT NULL,
          sincronizado   INTEGER NOT NULL DEFAULT 0 CHECK (sincronizado IN (0,1))
        )
      ''');
      await txn.execute(
        'CREATE INDEX idx_logros ON logros (estudiante_id, sincronizado)');

      // 6. historial_rag (solo grados 3-5)
      await txn.execute('''
        CREATE TABLE historial_rag (
          id            INTEGER PRIMARY KEY AUTOINCREMENT,
          estudiante_id INTEGER NOT NULL REFERENCES estudiantes(id) ON DELETE CASCADE,
          pregunta      TEXT    NOT NULL,
          respuesta     TEXT    NOT NULL,
          materia       TEXT    NOT NULL CHECK (materia IN (
                          'matematicas','ingles','español','ciencias','sociales')),
          grado         INTEGER NOT NULL CHECK (grado BETWEEN 3 AND 5),
          fecha         TEXT    NOT NULL,
          util          INTEGER CHECK (util IN (0,1))
        )
      ''');
      await txn.execute(
        'CREATE INDEX idx_rag ON historial_rag (estudiante_id, fecha)');

      // 7. base_conocimiento (RAG offline)
      await txn.execute('''
        CREATE TABLE base_conocimiento (
          id               INTEGER PRIMARY KEY AUTOINCREMENT,
          materia          TEXT    NOT NULL CHECK (materia IN (
                             'matematicas','ingles','espanol','ciencias','sociales')),
          grado            INTEGER NOT NULL CHECK (grado BETWEEN 1 AND 5),
          tema             TEXT    NOT NULL,
          pregunta         TEXT    NOT NULL,
          respuesta        TEXT    NOT NULL,
          palabras_clave   TEXT    NOT NULL,
          version_paquete  TEXT    NOT NULL DEFAULT '1.0.0'
        )
      ''');
      await txn.execute(
        'CREATE INDEX idx_rag_materia ON base_conocimiento (materia, grado)');

      // 8. sesiones_diarias (racha — 1 fila por estudiante por día)
      await txn.execute('''
        CREATE TABLE sesiones_diarias (
          id            INTEGER PRIMARY KEY AUTOINCREMENT,
          estudiante_id INTEGER NOT NULL REFERENCES estudiantes(id) ON DELETE CASCADE,
          fecha         TEXT    NOT NULL
        )
      ''');
      await txn.execute(
        'CREATE UNIQUE INDEX idx_sesiones_unico ON sesiones_diarias (estudiante_id, fecha)');

      // 9. configuracion (siempre 1 sola fila)
      await txn.execute('''
        CREATE TABLE configuracion (
          id                   INTEGER PRIMARY KEY CHECK (id = 1),
          sonido_activado      INTEGER NOT NULL DEFAULT 1 CHECK (sonido_activado IN (0,1)),
          idioma               TEXT    NOT NULL DEFAULT 'es' CHECK (idioma IN ('es','en')),
          modo_offline_forzado INTEGER NOT NULL DEFAULT 0
                                 CHECK (modo_offline_forzado IN (0,1)),
          ultima_actualizacion TEXT
        )
      ''');
      await txn.execute(
        "INSERT INTO configuracion (id, sonido_activado, idioma, modo_offline_forzado) VALUES (1, 1, 'es', 0)");

      // 10. preguntas_quiz — banco estático de preguntas MCQ con distractores de calidad
      await txn.execute('''
        CREATE TABLE preguntas_quiz (
          id          INTEGER PRIMARY KEY AUTOINCREMENT,
          materia     TEXT    NOT NULL,
          grado       INTEGER NOT NULL,
          tema        TEXT    NOT NULL,
          pregunta    TEXT    NOT NULL,
          opcion_a    TEXT    NOT NULL,
          opcion_b    TEXT    NOT NULL,
          opcion_c    TEXT    NOT NULL,
          opcion_d    TEXT    NOT NULL,
          correcta    TEXT    NOT NULL,
          explicacion TEXT,
          dificultad  INTEGER NOT NULL DEFAULT 1
        )
      ''');
      await txn.execute(
        'CREATE INDEX idx_preguntas_quiz ON preguntas_quiz (materia, grado)');
    });
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE estudiantes ADD COLUMN email      TEXT');
      await db.execute('ALTER TABLE estudiantes ADD COLUMN contrasena TEXT');
      await db.execute('ALTER TABLE estudiantes ADD COLUMN edad       INTEGER');
      await db.execute('ALTER TABLE estudiantes ADD COLUMN genero     TEXT');
    }
    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS base_conocimiento (
          id               INTEGER PRIMARY KEY AUTOINCREMENT,
          materia          TEXT    NOT NULL CHECK (materia IN (
                             'matematicas','ingles','espanol','ciencias','sociales')),
          grado            INTEGER NOT NULL CHECK (grado BETWEEN 1 AND 5),
          tema             TEXT    NOT NULL,
          pregunta         TEXT    NOT NULL,
          respuesta        TEXT    NOT NULL,
          palabras_clave   TEXT    NOT NULL,
          version_paquete  TEXT    NOT NULL DEFAULT '1.0.0'
        )
      ''');
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_rag_materia ON base_conocimiento (materia, grado)');
    }
    if (oldVersion < 4) {
      await db.execute(
        'ALTER TABLE estudiantes ADD COLUMN racha_dias INTEGER NOT NULL DEFAULT 0');
      await db.execute(
        'ALTER TABLE estudiantes ADD COLUMN ultima_racha TEXT');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS sesiones_diarias (
          id            INTEGER PRIMARY KEY AUTOINCREMENT,
          estudiante_id INTEGER NOT NULL REFERENCES estudiantes(id) ON DELETE CASCADE,
          fecha         TEXT    NOT NULL
        )
      ''');
      await db.execute(
        'CREATE UNIQUE INDEX IF NOT EXISTS idx_sesiones_unico ON sesiones_diarias (estudiante_id, fecha)');
    }
    if (oldVersion < 5) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS preguntas_quiz (
          id          INTEGER PRIMARY KEY AUTOINCREMENT,
          materia     TEXT    NOT NULL,
          grado       INTEGER NOT NULL,
          tema        TEXT    NOT NULL,
          pregunta    TEXT    NOT NULL,
          opcion_a    TEXT    NOT NULL,
          opcion_b    TEXT    NOT NULL,
          opcion_c    TEXT    NOT NULL,
          opcion_d    TEXT    NOT NULL,
          correcta    TEXT    NOT NULL,
          explicacion TEXT,
          dificultad  INTEGER NOT NULL DEFAULT 1
        )
      ''');
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_preguntas_quiz ON preguntas_quiz (materia, grado)');
    }
    if (oldVersion < 6) {
      await db.execute(
        'ALTER TABLE estudiantes ADD COLUMN firebase_uid TEXT');
    }
  }

  // ── Métodos genéricos ────────────────────────────────────────
  Future<int> insertar(String tabla, Map<String, dynamic> datos) async {
    final db = await database;
    return await db.insert(tabla, datos,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> consultar(
    String tabla, {
    String?        where,
    List<dynamic>? whereArgs,
    String?        orderBy,
    int?           limit,
  }) async {
    final db = await database;
    return await db.query(tabla,
        where: where, whereArgs: whereArgs,
        orderBy: orderBy, limit: limit);
  }

  Future<int> actualizar(
    String tabla,
    Map<String, dynamic> datos, {
    required String        where,
    required List<dynamic> whereArgs,
  }) async {
    final db = await database;
    return await db.update(tabla, datos,
        where: where, whereArgs: whereArgs);
  }

  Future<int> eliminar(
    String tabla, {
    required String        where,
    required List<dynamic> whereArgs,
  }) async {
    final db = await database;
    return await db.delete(tabla, where: where, whereArgs: whereArgs);
  }

  Future<List<Map<String, dynamic>>> rawQuery(
      String sql, [List<dynamic>? args]) async {
    final db = await database;
    return await db.rawQuery(sql, args);
  }

  Future<void> cerrar() async {
    final db = await database;
    await db.close();
    _database = null;
  }

  /// Borra el archivo numi.db y reinicia la instancia estática.
  /// Al llamar [database] de nuevo se recrean las 7 tablas desde cero.
  Future<void> resetearBaseDatos() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
    final path = join(await getDatabasesPath(), _dbName);
    final file = File(path);
    if (await file.exists()) await file.delete();
  }
}
