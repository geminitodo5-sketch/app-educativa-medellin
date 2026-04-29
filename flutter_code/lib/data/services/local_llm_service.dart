// ─────────────────────────────────────────────────────────────
//  lib/data/services/local_llm_service.dart
//  LLM local offline con flutter_gemma 0.13.x + MediaPipe.
//
//  Distribución del modelo via Firebase Storage:
//    1. Sube el archivo .bin a Firebase Storage (acceso público de lectura).
//    2. Copia la URL de descarga y pégala en _urlModelo abajo.
//       Formato:
//         https://firebasestorage.googleapis.com/v0/b/TU_PROYECTO.appspot.com/
//         o/models%2Fgemma-2b-it-gpu-int4.bin?alt=media
//    3. Reglas de Storage mínimas (Storage → Rules):
//         rules_version = '2';
//         service firebase.storage {
//           match /b/{bucket}/o {
//             match /models/{file} {
//               allow read: if true;   // solo lectura pública en /models/
//             }
//           }
//         }
//
//  Flujo en la app (transparente al usuario):
//    1. Al abrir el asistente → inicializarSiExiste() detecta si ya está descargado.
//    2. Si no está → la descarga arranca en background automáticamente.
//    3. Mientras descarga → el asistente usa Gemini cloud como fallback.
//    4. Al completar → el servicio marca isReady=true y las siguientes preguntas
//       se responden con Gemma local (sin internet).
// ─────────────────────────────────────────────────────────────

import 'package:flutter_gemma/flutter_gemma.dart';

class LocalLlmService {
  // ── URL Firebase Storage ───────────────────────────────────
  // Reemplaza esta URL con la de tu archivo en Firebase Storage.
  // Ejemplo: https://firebasestorage.googleapis.com/v0/b/numi-app.appspot.com/
  //          o/models%2Fgemma-2b-it-gpu-int4.bin?alt=media
  static const _urlModelo =
      'https://firebasestorage.googleapis.com/v0/b/TU_PROYECTO.appspot.com'
      '/o/models%2Fgemma-2b-it-gpu-int4.bin?alt=media';

  static const _nombreArchivo = 'gemma-2b-it-gpu-int4.bin';

  // ── Estado público ────────────────────────────────────────
  bool _isReady = false;
  bool _isDownloading = false;
  double _downloadProgress = 0.0;

  bool get isReady => _isReady;
  bool get isDownloading => _isDownloading;
  double get downloadProgress => _downloadProgress;

  // ─────────────────────────────────────────────────────────
  //  Inicialización al arrancar la app.
  //  Si el modelo ya fue descargado en una sesión anterior,
  //  lo activa sin descargar nada.
  // ─────────────────────────────────────────────────────────
  Future<void> inicializarSiExiste() async {
    try {
      await FlutterGemma.initialize();
      final instalado = await FlutterGemma.isModelInstalled(_nombreArchivo);
      if (!instalado) return;

      // El modelo ya existe en el almacenamiento interno de flutter_gemma.
      // Llamar a installModel con el mismo archivo es idempotente:
      // reutiliza el archivo local sin volver a descargarlo.
      await FlutterGemma.installModel(
        modelType: ModelType.gemmaIt,
        fileType: ModelFileType.binary,
      ).fromNetwork(_urlModelo).install();

      _isReady = true;
    } catch (_) {
      _isReady = false;
    }
  }

  // ─────────────────────────────────────────────────────────
  //  Descarga el modelo desde Firebase Storage y lo activa.
  //  La descarga es automática (iniciada por el ViewModel)
  //  y muestra progreso en la UI via [onProgress] (0.0–1.0).
  // ─────────────────────────────────────────────────────────
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

  // ─────────────────────────────────────────────────────────
  //  Generación de respuesta — streaming token a token
  // ─────────────────────────────────────────────────────────
  Stream<String> generarRespuesta({
    required String contexto,
    required String pregunta,
    int grado = 3,
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

  // ─────────────────────────────────────────────────────────
  //  Prompt en español adaptado por grado — formato Gemma IT
  // ─────────────────────────────────────────────────────────
  String _construirPrompt({
    required String contexto,
    required String pregunta,
    required int grado,
  }) {
    final nivel = switch (grado) {
      <= 3 => 'muy sencillas, como si hablaras con un niño de 8 años',
      4    => 'claras y con ejemplos del diario, para un niño de 9-10 años',
      _    => 'un poco más detalladas, para un estudiante de 10-11 años',
    };

    return '<start_of_turn>user\n'
        'Eres Sabi, un asistente educativo amigable para niños colombianos '
        'de $grado° grado de primaria.\n'
        'Usa palabras $nivel.\n'
        'Responde SIEMPRE en español. Máximo 4 oraciones cortas. '
        'Termina con una frase de aliento motivadora.\n\n'
        'Información del currículo escolar:\n'
        '$contexto\n\n'
        'Pregunta del estudiante: $pregunta\n'
        '<end_of_turn>\n'
        '<start_of_turn>model\n';
  }
}
