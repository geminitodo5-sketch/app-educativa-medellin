// ─────────────────────────────────────────────────────────────
//  lib/data/services/embedding_service.dart
//  Servicio de embeddings semánticos para reranking RAG offline.
//
//  Modos de operación:
//    1. TFLite (preferido) — carga assets/models/embedding_model.tflite
//       Requiere declarar el asset en pubspec.yaml:
//         - assets/models/
//    2. Hash-bag (fallback automático) — siempre disponible, sin modelo.
//       Produce vectores comparables vía similitud coseno.
//
//  La calidad del reranking mejora con un modelo TFLite real, pero el
//  sistema funciona correctamente con el fallback hash-bag.
// ─────────────────────────────────────────────────────────────

import 'dart:math';
import 'dart:typed_data';
import 'package:tflite_flutter/tflite_flutter.dart';

class EmbeddingService {
  Interpreter? _interpreter;
  int _embDim = 64;
  bool _initialized = false;

  // true después de initialize() — siempre disponemos de algún embedding.
  bool get modelAvailable => _initialized;
  bool get usesTFLite => _interpreter != null;

  Future<void> initialize() async {
    if (_initialized) return;
    try {
      final options = InterpreterOptions()..threads = 2;
      _interpreter = await Interpreter.fromAsset(
        'assets/models/embedding_model.tflite',
        options: options,
      );
      // Detectar dimensión de salida desde la forma del tensor de output
      final outShape = _interpreter!.getOutputTensor(0).shape;
      _embDim = outShape.last;
    } catch (_) {
      // Modelo no encontrado — se usará hash-bag como fallback.
      _interpreter = null;
      _embDim = 64;
    } finally {
      _initialized = true;
    }
  }

  /// Devuelve un vector de embedding para [text].
  /// Usa TFLite si el modelo está cargado; de lo contrario hash-bag.
  Future<List<double>?> encodeLocal(String text) async {
    if (!_initialized) return null;

    final interp = _interpreter;
    if (interp != null) {
      try {
        return _runTFLite(interp, text);
      } catch (_) {
        // Fallo de inferencia — caemos al hash-bag
      }
    }
    return _hashBag(text, _embDim);
  }

  // ─── TFLite inference ────────────────────────────────────────

  List<double> _runTFLite(Interpreter interp, String text) {
    final inShape  = interp.getInputTensor(0).shape;
    final outShape = interp.getOutputTensor(0).shape;
    final inDim    = inShape.last;
    final outDim   = outShape.last;

    // Construir input como bag-of-hashes normalizado
    final inputVec = _hashBag(text, inDim);
    final inputFloat = Float32List.fromList(inputVec);

    // Preparar buffer de salida
    final outputFloat = Float32List(outDim);

    // Reformar como listas anidadas [1, dim] para tflite_flutter
    final input2d  = [inputFloat.toList()];
    final output2d = [outputFloat.toList()];

    interp.run(input2d, output2d);

    return _l2Normalize(output2d[0]);
  }

  // ─── Hash bag-of-words + bigramas de caracteres ──────────────

  List<double> _hashBag(String text, int dim) {
    final vec = List<double>.filled(dim, 0.0);
    final words = text
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-záéíóúñü0-9\s]'), ' ')
        .trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.length >= 2);

    for (final word in words) {
      // unigrama
      vec[word.hashCode.abs() % dim] += 1.0;
      // bigramas de caracteres
      for (int i = 0; i < word.length - 1; i++) {
        final bg = word.substring(i, i + 2);
        vec[(bg.hashCode.abs() ^ 0x5F3759DF) % dim] += 0.5;
      }
    }
    return _l2Normalize(vec);
  }

  List<double> _l2Normalize(List<double> v) {
    final norm = sqrt(v.fold(0.0, (s, x) => s + x * x));
    if (norm < 1e-9) return List<double>.filled(v.length, 0.0);
    return v.map((x) => x / norm).toList();
  }

  // ─── Utilidades estáticas ─────────────────────────────────────

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

  void dispose() => _interpreter?.close();
}
