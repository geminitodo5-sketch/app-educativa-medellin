// ─────────────────────────────────────────────────────────────
//  lib/data/services/local_llm_service.dart
//  LLM local offline con flutter_gemma 0.13.x + MediaPipe.
//  Modelo: Gemma 3n E2B (Edge 2B, instruction-tuned, INT4).
//
//  Distribución del modelo via Firebase Storage:
//    1. Descarga gemma-3n-e2b-it-int4.bin desde ai.google.dev/gemma.
//    2. Súbelo a Firebase Storage → carpeta /models/.
//    3. Copia la URL de descarga y pégala en _urlModelo abajo.
//    4. Reglas de Storage mínimas (Storage → Rules):
//         rules_version = '2';
//         service firebase.storage {
//           match /b/{bucket}/o {
//             match /models/{file} {
//               allow read: if true;
//             }
//           }
//         }
//
//  Flujo en la app (transparente al usuario):
//    1. Al arrancar → inicializarSiExiste() detecta si ya está descargado.
//    2. Si no está → descarga automática en background desde Firebase.
//    3. Mientras descarga → el asistente usa RAG local como fallback.
//    4. Al completar → isReady = true; las preguntas se responden
//       con Gemma local offline, sin internet.
// ─────────────────────────────────────────────────────────────

import 'package:flutter_gemma/flutter_gemma.dart';

class LocalLlmService {
  // ── URL Firebase Storage ──────────────────────────────────────
  // Reemplaza con la URL real de tu archivo Gemma 3n E2B en Firebase.
  static const _urlModelo =
      'https://huggingface.co/NUMI12123/NUMI-gemma/resolve/main/gemma-2b-it-cpu-int8.bin';

  static const _nombreArchivo = 'gemma-2b-it-cpu-int8.bin';

  // ── Estado público ─────────────────────────────────────────────
  bool _isReady = false;
  bool _isDownloading = false;
  double _downloadProgress = 0.0;

  bool get isReady => _isReady;
  bool get isDownloading => _isDownloading;
  double get downloadProgress => _downloadProgress;

  // ──────────────────────────────────────────────────────────────
  //  Inicialización al arrancar la app.
  //  Si el modelo ya fue descargado en una sesión anterior,
  //  lo activa sin volver a descargarlo.
  // ──────────────────────────────────────────────────────────────
  Future<void> inicializarSiExiste() async {
    try {
      await FlutterGemma.initialize();
      final instalado = await FlutterGemma.isModelInstalled(_nombreArchivo);
      if (!instalado) return;

      // El archivo ya existe localmente; install() lo reutiliza sin red.
      await FlutterGemma.installModel(
        modelType: ModelType.gemmaIt,
        fileType: ModelFileType.binary,
      ).fromNetwork(_urlModelo).install();

      _isReady = true;
    } catch (_) {
      _isReady = false;
    }
  }

  // ──────────────────────────────────────────────────────────────
  //  Descarga el modelo Gemma 3n E2B desde Firebase y lo activa.
  //  Se llama automáticamente al abrir la app por primera vez.
  // ──────────────────────────────────────────────────────────────
  Future<void> descargarModelo({
    required void Function(double) onProgress,
  }) async {
    if (_isDownloading || _isReady) return;
    _isDownloading = true;
    _downloadProgress = 0.0;
    onProgress(0.0);

    try {
      await FlutterGemma.initialize();

      await FlutterGemma.installModel(
        modelType: ModelType.gemmaIt,
        fileType: ModelFileType.binary,
      )
          .fromNetwork(_urlModelo)
          .withProgress((int pct) {
            _downloadProgress = pct / 100.0;
            onProgress(_downloadProgress);
          })
          .install();

      _isDownloading = false;
      _isReady = true;
      onProgress(1.0);
    } catch (e) {
      _isDownloading = false;
      _downloadProgress = 0.0;
      rethrow;
    }
  }

  // ──────────────────────────────────────────────────────────────
  //  Generación de respuesta — streaming token a token.
  //  Incluye system prompt adaptado por materia y grado.
  // ──────────────────────────────────────────────────────────────
  Stream<String> generarRespuesta({
    required String contexto,
    required String pregunta,
    int grado = 3,
    String materia = 'matematicas',
  }) async* {
    if (!_isReady) throw StateError('Modelo Gemma no inicializado');

    final model = await FlutterGemma.getActiveModel(maxTokens: 512);
    try {
      final chat = await model.createChat(
        temperature: 0.7,
        topK: 40,
        randomSeed: 1,
      );

      final prompt = _construirPrompt(
        contexto: contexto,
        pregunta: pregunta,
        grado: grado,
        materia: materia,
      );

      await chat.addQueryChunk(Message(text: prompt, isUser: true));

      await for (final response in chat.generateChatResponseAsync()) {
        if (response is TextResponse && response.token.isNotEmpty) {
          yield response.token;
        }
      }
    } finally {
      await model.close();
    }
  }

  // ──────────────────────────────────────────────────────────────
  //  Prompt adaptado por materia y grado — formato Gemma IT
  // ──────────────────────────────────────────────────────────────
  String _construirPrompt({
    required String contexto,
    required String pregunta,
    required int grado,
    required String materia,
  }) {
    final nivelLenguaje = switch (grado) {
      <= 3 => 'muy sencillas, como si hablaras con un niño de 8 años',
      4    => 'claras y con ejemplos del diario, para un niño de 9-10 años',
      _    => 'un poco más detalladas, para un estudiante de 10-11 años',
    };

    return '<start_of_turn>user\n'
        '${_rolPorMateria(materia, grado)}\n'
        'Usa palabras $nivelLenguaje.\n'
        'Responde SIEMPRE en español. Máximo 4 oraciones cortas. '
        'Termina con una frase de aliento motivadora.\n\n'
        'Información del currículo escolar:\n'
        '$contexto\n\n'
        'Pregunta del estudiante: $pregunta\n'
        '<end_of_turn>\n'
        '<start_of_turn>model\n';
  }

  // ── System prompt por materia ─────────────────────────────────
  String _rolPorMateria(String materia, int grado) {
    const roles = <String, String>{
      'matematicas':
          'Eres Sabi, un asistente educativo experto en Matemáticas para niños '
          'colombianos de primaria. Explica operaciones, geometría y problemas '
          'paso a paso con ejemplos concretos. Muestra siempre el procedimiento, '
          'nunca solo la respuesta final.',
      'ciencias':
          'Eres Sabi, un asistente educativo experto en Ciencias Naturales para '
          'niños colombianos de primaria. Explica el cuerpo humano, ecosistemas, '
          'energía y fenómenos naturales usando analogías simples y ejemplos de '
          'la vida cotidiana colombiana.',
      'espanol':
          'Eres Sabi, un asistente educativo experto en Lengua Española para '
          'niños colombianos de primaria. Ayuda con gramática, ortografía, '
          'comprensión lectora y escritura. Usa ejemplos de palabras y oraciones '
          'sencillas del español colombiano.',
      'ingles':
          'You are Sabi, a friendly English teacher for Colombian primary school '
          'children. Explain English concepts clearly. Mix Spanish with English '
          'explanations when needed to help understanding. Always use simple '
          'vocabulary and give real-life examples.',
      'sociales':
          'Eres Sabi, un asistente educativo experto en Ciencias Sociales '
          'colombianas para niños de primaria. Explica historia, geografía, '
          'cultura y civismo de Colombia con ejemplos locales, lugares conocidos '
          'y situaciones reales del país.',
    };
    return roles[materia] ??
        'Eres Sabi, un asistente educativo amigable para niños colombianos '
        'de $grado° grado de primaria.';
  }
}
