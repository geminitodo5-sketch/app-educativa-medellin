import 'dart:convert';
import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'sqlite_service.dart';

class DescargaPaqueteService {
  // ── Cambia esta URL cuando despliegues el backend ────────────
  static const String _apiBase =
      'https://app-educativa-medellin-production.up.railway.app'; // producción
  // Para pruebas locales usa: 'http://10.0.2.2:8000' (Android emulador)
  // o 'http://localhost:8000' (Windows/desktop)

  final SqliteService _db;
  final Dio _dio;

  DescargaPaqueteService(this._db)
      : _dio = Dio(
          BaseOptions(
            connectTimeout: const Duration(seconds: 15),
            receiveTimeout: const Duration(seconds: 60),
          ),
        );

  // ── Consultas ─────────────────────────────────────────────────

  /// Devuelve true si la materia ya tiene contenido descargado en la BD.
  Future<bool> estaDescargado(String materia) async {
    final rows = await _db.consultar(
      'base_conocimiento',
      where: 'materia = ?',
      whereArgs: [materia],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  /// Devuelve la versión del paquete instalado, o null si no hay ninguno.
  Future<String?> versionInstalada(String materia) async {
    final rows = await _db.rawQuery(
      'SELECT version_paquete FROM base_conocimiento WHERE materia = ? LIMIT 1',
      [materia],
    );
    if (rows.isEmpty) return null;
    return rows.first['version_paquete'] as String?;
  }

  /// Descarga e instala el paquete de una materia.
  /// [onProgress] recibe valores de 0.0 a 1.0.
  Future<void> descargarPaquete(
    String materia, {
    void Function(double progreso)? onProgress,
  }) async {
    final tempDir = await getTemporaryDirectory();
    final zipPath = '${tempDir.path}/rag_$materia.zip';

    // 1. Descargar ZIP
    await _dio.download(
      '$_apiBase/api/paquetes/$materia',
      zipPath,
      onReceiveProgress: (recibido, total) {
        if (total > 0 && onProgress != null) {
          onProgress((recibido / total) * 0.8); // 80 % = descarga
        }
      },
    );

    // 2. Extraer JSON del ZIP
    final extractDir = '${tempDir.path}/rag_$materia/';
    extractFileToDisk(zipPath, extractDir);

    final jsonFile = File('$extractDir$materia.json');
    if (!await jsonFile.exists()) {
      throw Exception('JSON no encontrado en el paquete descargado.');
    }

    onProgress?.call(0.85);

    // 3. Importar a SQLite
    await _importarJson(jsonFile, materia);

    onProgress?.call(1.0);

    // 4. Limpiar temporales
    try {
      await File(zipPath).delete();
      await Directory(extractDir).delete(recursive: true);
    } catch (_) {}
  }

  // ── Privado ───────────────────────────────────────────────────

  Future<void> _importarJson(File jsonFile, String materia) async {
    final raw = await jsonFile.readAsString();
    final data = json.decode(raw) as Map<String, dynamic>;
    final version = data['version'] as String? ?? '1.0.0';
    final contenido = data['contenido'] as List<dynamic>;

    final db = await _db.database;

    await db.transaction((txn) async {
      // Borra entradas antiguas de esa materia
      await txn.delete(
        'base_conocimiento',
        where: 'materia = ?',
        whereArgs: [materia],
      );

      // Inserta todas las entradas nuevas
      for (final entry in contenido) {
        // Salta entradas malformadas (arrays anidados en lugar de maps)
        if (entry is! Map) continue;
        final e = Map<String, dynamic>.from(entry);

        // palabras_clave puede venir como List (JSON) o String (legacy)
        final kw = e['palabras_clave'];
        final palabras = kw is List
            ? kw.map((w) => w.toString()).join(',')
            : (kw?.toString() ?? '');

        await txn.insert('base_conocimiento', {
          'materia': materia,
          'grado': (e['grado'] as num?)?.toInt() ?? 0,
          'tema': (e['tema'] as String?) ?? '',
          'pregunta': (e['pregunta'] as String?) ?? '',
          'respuesta': (e['respuesta'] as String?) ?? '',
          'palabras_clave': palabras,
          'version_paquete': version,
        });
      }
    });
  }

  /// Elimina el contenido de una materia de la BD local.
  Future<void> eliminarPaquete(String materia) async {
    await _db.eliminar(
      'base_conocimiento',
      where: 'materia = ?',
      whereArgs: [materia],
    );
  }

  /// Consulta la API para obtener la lista de paquetes disponibles.
  Future<List<Map<String, dynamic>>> listarPaquetesApi() async {
    try {
      final resp = await _dio.get('$_apiBase/api/paquetes');
      final lista = resp.data['paquetes'] as List<dynamic>;
      return lista.cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }
}
