// ─────────────────────────────────────────────────────────────
//  lib/data/services/embedding_service.dart
//  Búsqueda semántica para el RAG:
//    • TFLite local → modelo en assets/models/embedding_model.tflite
//    • Similitud coseno para reranking de resultados BM25
//
//  Para activar el modo TFLite completo:
//    1. Exportar paraphrase-multilingual-MiniLM-L12-v2 a TFLite.
//    2. Copiar el .tflite a assets/models/embedding_model.tflite
//    3. Declararlo en pubspec.yaml bajo flutter > assets.
//    4. Instanciar EmbeddingService, llamar initialize() y pasarlo
//       a RagService(db, embeddings: embeddingService).
//
//  Sin modelo: el servicio falla silenciosamente y RagService
//  usa solo BM25 + expansión conceptual.
// ─────────────────────────────────────────────────────────────

import 'dart:math';
import 'package:tflite_flutter/tflite_flutter.dart';

class EmbeddingService {
  static const String _modelAssetPath = 'assets/models/embedding_model.tflite';
  static const int _embeddingDim = 384;
  static const int _maxSeqLen    = 128;

  // Tamaño del vocabulario para el tokenizer de hash.
  // Un valor primo grande minimiza colisiones.
  static const int _vocabSize = 30001;

  Interpreter? _interpreter;
  bool _initialized = false;

  bool get modelAvailable => _interpreter != null;

  // ─── Inicialización ───────────────────────────────────────

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
      _interpreter = null; // BM25 + expansión conceptual como fallback
    }
  }

  // ─── Embedding local (TFLite) ─────────────────────────────

  Future<List<double>?> encodeLocal(String text) async {
    if (_interpreter == null) return null;
    try {
      final tokens = _tokenize(text);
      final input  = [tokens]; // shape [1, _maxSeqLen]
      final output = List.generate(1, (_) => List.filled(_embeddingDim, 0.0));
      _interpreter!.run(input, output);
      return _normalize(List<double>.from(output[0] as List));
    } catch (_) {
      return null;
    }
  }

  // ─── Similitud coseno ─────────────────────────────────────

  static double cosineSimilarity(List<double> a, List<double> b) {
    assert(a.length == b.length);
    double dot = 0, normA = 0, normB = 0;
    for (int i = 0; i < a.length; i++) {
      dot   += a[i] * b[i];
      normA += a[i] * a[i];
      normB += b[i] * b[i];
    }
    final denom = sqrt(normA) * sqrt(normB);
    return denom == 0 ? 0.0 : dot / denom;
  }

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

  // Tokenizer de subword hash (character n-grams de largo 3-4).
  // No requiere archivo de vocabulario y es determinístico.
  // Produce IDs consistentes que el modelo puede usar como input_ids.
  // Para producción con MiniLM real, reemplazar por WordPiece tokenizer.
  List<int> _tokenize(String text, {int maxLen = _maxSeqLen}) {
    final normalized = _normalizeText(text);
    final tokens = <int>[1]; // [CLS] token = 1

    // Extraer character n-grams solapados (trigramas y cuatrigramas)
    for (int i = 0; i < normalized.length; i++) {
      if (tokens.length >= maxLen - 1) break;

      // Trigrama
      if (i + 3 <= normalized.length) {
        final gram3 = normalized.substring(i, i + 3);
        tokens.add(_hashGram(gram3));
      }
      // Cuatrigrama (cada 2 posiciones para no sobrecargar)
      if (i % 2 == 0 && i + 4 <= normalized.length) {
        final gram4 = normalized.substring(i, i + 4);
        if (tokens.length < maxLen - 1) tokens.add(_hashGram(gram4));
      }
    }

    tokens.add(2); // [SEP] token = 2

    // Pad con 0 hasta maxLen
    while (tokens.length < maxLen) { tokens.add(0); }
    return tokens.take(maxLen).toList();
  }

  // Hash de un n-gram a un índice de vocabulario [3, _vocabSize)
  int _hashGram(String gram) {
    int h = 5381;
    for (final c in gram.codeUnits) {
      h = ((h << 5) + h) ^ c; // djb2
    }
    return (h.abs() % (_vocabSize - 3)) + 3; // [3, vocabSize)
  }

  // Normalización de texto para tokenizar
  String _normalizeText(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[áàâä]'), 'a')
        .replaceAll(RegExp(r'[éèêë]'), 'e')
        .replaceAll(RegExp(r'[íìîï]'), 'i')
        .replaceAll(RegExp(r'[óòôö]'), 'o')
        .replaceAll(RegExp(r'[úùûü]'), 'u')
        .replaceAll('ñ', 'n')
        .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  void dispose() {
    _interpreter?.close();
    _interpreter = null;
    _initialized = false;
  }
}
