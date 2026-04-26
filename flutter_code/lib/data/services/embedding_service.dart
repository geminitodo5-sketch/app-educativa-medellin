// ─────────────────────────────────────────────────────────────
//  lib/data/services/embedding_service.dart
//  Búsqueda semántica para el RAG:
//    • Online  → delega a /api/buscar_semantico (FAISS + sentence-transformers)
//    • Offline → usa TFLite si el modelo está en assets/models/
//    • Siempre → similitud coseno para vectores precalculados
// ─────────────────────────────────────────────────────────────

import 'dart:math';
import 'package:dio/dio.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

class EmbeddingService {
  // Coloca el modelo TFLite en este path de assets para activar búsqueda offline.
  // Modelo recomendado: paraphrase-multilingual-MiniLM-L12-v2 (exportado a TFLite)
  static const String _modelAssetPath = 'assets/models/embedding_model.tflite';
  static const int _embeddingDim = 384;
  static const int _maxSeqLen = 128;

  Interpreter? _interpreter;
  bool _initialized = false;

  bool get modelAvailable => _interpreter != null;

  /// Inicializa el servicio. Falla silenciosamente si el modelo no está disponible.
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    try {
      final options = InterpreterOptions()..threads = 2;
      _interpreter = await Interpreter.fromAsset(
        _modelAssetPath,
        options: options,
      );
    } catch (_) {
      _interpreter = null; // BM25 se usará como fallback
    }
  }

  // ─── Embedding local (TFLite) ─────────────────────────────

  /// Genera un embedding para [text] usando el modelo TFLite.
  /// Devuelve null si el modelo no está disponible.
  Future<List<double>?> encodeLocal(String text) async {
    if (_interpreter == null) return null;
    try {
      final tokens = _tokenize(text);
      final input = [tokens]; // shape [1, _maxSeqLen]
      final output = List.generate(1, (_) => List.filled(_embeddingDim, 0.0));
      _interpreter!.run(input, output);
      return _normalize(List<double>.from(output[0] as List));
    } catch (_) {
      return null;
    }
  }

  // ─── Búsqueda semántica online (FAISS backend) ────────────

  /// Llama a /api/buscar_semantico en el backend Python.
  /// Devuelve null si hay error de red o el servidor no está disponible.
  Future<List<Map<String, dynamic>>?> buscarSemantico({
    required Dio dio,
    required String baseUrl,
    required String pregunta,
    required String materia,
    int? grado,
    int topK = 5,
  }) async {
    try {
      final response = await dio.post(
        '$baseUrl/api/buscar_semantico',
        data: {
          'pregunta': pregunta,
          'materia': materia,
          if (grado != null) 'grado': grado,
          'top_k': topK,
        },
        options: Options(
          sendTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 10),
        ),
      );
      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(
          (response.data as Map)['resultados'] ?? [],
        );
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  // ─── Similitud coseno ─────────────────────────────────────

  /// Similitud coseno entre dos vectores de igual dimensión. Rango: [-1, 1].
  static double cosineSimilarity(List<double> a, List<double> b) {
    assert(a.length == b.length, 'Los vectores deben tener la misma dimensión');
    double dot = 0, normA = 0, normB = 0;
    for (int i = 0; i < a.length; i++) {
      dot += a[i] * b[i];
      normA += a[i] * a[i];
      normB += b[i] * b[i];
    }
    final denom = sqrt(normA) * sqrt(normB);
    return denom == 0 ? 0.0 : dot / denom;
  }

  /// Ordena [corpus] por similitud coseno descendente con [queryEmbedding].
  static List<(Map<String, dynamic>, double)> rankBySimilarity({
    required List<double> queryEmbedding,
    required List<(Map<String, dynamic>, List<double>)> corpus,
    int topK = 5,
  }) {
    final scored = corpus
        .map((item) => (item.$1, cosineSimilarity(queryEmbedding, item.$2)))
        .toList()
      ..sort((a, b) => b.$2.compareTo(a.$2));
    return scored.take(topK).toList();
  }

  // ─── Helpers internos ─────────────────────────────────────

  List<double> _normalize(List<double> v) {
    final norm = sqrt(v.fold(0.0, (s, x) => s + x * x));
    if (norm == 0) return v;
    return v.map((x) => x / norm).toList();
  }

  // Tokenizador de placeholder — reemplazar con el tokenizador del modelo real.
  // Los modelos MiniLM usan WordPiece; exportar el tokenizador junto al .tflite.
  List<int> _tokenize(String text, {int maxLen = _maxSeqLen}) {
    final units = text.toLowerCase().codeUnits.take(maxLen).toList();
    while (units.length < maxLen) {
      units.add(0); // padding
    }
    return units;
  }

  void dispose() {
    _interpreter?.close();
    _interpreter = null;
    _initialized = false;
  }
}
