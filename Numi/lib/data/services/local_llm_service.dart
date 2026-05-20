import 'dart:async';

import 'package:flutter_gemma/flutter_gemma.dart';

class LocalLlmService {
  static const _urlModelo =
      'https://huggingface.co/NUMI12123/NUMI-gemma/resolve/main/gemma-2b-it-cpu-int8.bin';

  static const _nombreArchivo = 'gemma-2b-it-cpu-int8.bin';

  bool _isReady = false;
  bool _isDownloading = false;
  double _downloadProgress = 0.0;

  bool get isReady => _isReady;
  bool get isDownloading => _isDownloading;
  double get downloadProgress => _downloadProgress;

  Future<void> inicializarSiExiste() async {
    try {
      await FlutterGemma.initialize();
      final instalado = await FlutterGemma.isModelInstalled(_nombreArchivo);
      if (!instalado) return;

      // install() sobre un archivo ya descargado lo activa sin red
      await FlutterGemma.installModel(
        modelType: ModelType.gemmaIt,
        fileType: ModelFileType.binary,
      ).fromNetwork(_urlModelo).install();

      _isReady = true;
    } catch (_) {
      _isReady = false;
    }
  }

  // SmartDownloader (flutter_gemma) activa foreground service para archivos >500 MB
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

      var hayTokens = false;
      await for (final response in chat.generateChatResponseAsync()
          .timeout(
            const Duration(seconds: 30),
            onTimeout: (sink) => sink.close(),
          )) {
        if (response is TextResponse && response.token.isNotEmpty) {
          hayTokens = true;
          yield response.token;
        }
      }
      // Sin tokens en 30 s → rag_service.dart cae al formateador de respaldo
      if (!hayTokens) {
        throw TimeoutException('Gemma no respondió en 30 s', const Duration(seconds: 30));
      }
    } finally {
      await model.close();
    }
  }

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

    // Sin contexto del RAG, Gemma responde desde conocimiento general en vez de bloquearse
    final seccionContexto = contexto.trim().isNotEmpty
        ? 'Información del currículo escolar:\n$contexto\n\n'
        : '';

    final instruccionContexto = contexto.trim().isNotEmpty
        ? 'Usa la información del currículo como base principal. '
          'Si la pregunta va más allá del currículo, '
          'complementa con tu conocimiento general.'
        : 'El currículo no tiene información específica sobre este tema. '
          'Responde usando tu conocimiento general de forma educativa, '
          'clara y apropiada para un niño colombiano de $grado° grado.';

    return '<start_of_turn>user\n'
        '${_rolPorMateria(materia, grado)}\n'
        'Usa palabras $nivelLenguaje.\n'
        'Responde SIEMPRE en español. Máximo 4 oraciones cortas. '
        '$instruccionContexto '
        'Termina con una frase de aliento motivadora.\n\n'
        '$seccionContexto'
        'Pregunta del estudiante: $pregunta\n'
        '<end_of_turn>\n'
        '<start_of_turn>model\n';
  }

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
