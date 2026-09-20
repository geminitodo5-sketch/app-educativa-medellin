import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:path_provider/path_provider.dart';

import 'descarga_primer_plano.dart';
import 'descarga_reanudable.dart';

class LocalLlmService {
  static const _urlModelo =
      'https://huggingface.co/NUMI12123/NUMI-gemma/resolve/main/gemma-2b-it-cpu-int8.bin';

  static const _nombreArchivo = 'gemma-2b-it-cpu-int8.bin';

  final DescargaReanudable _descarga = DescargaReanudable();

  bool _isReady = false;
  bool _isDownloading = false;
  double _downloadProgress = 0.0;

  bool get isReady => _isReady;
  bool get isDownloading => _isDownloading;
  double get downloadProgress => _downloadProgress;

  /// Archivo definitivo del modelo. Vive en el almacenamiento privado de la app
  /// y flutter_gemma lo usa desde ahí (fromFile), sin copiarlo.
  Future<File> _archivoModelo() async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/modelos/$_nombreArchivo');
  }

  /// Fracción 0.0–1.0 ya descargada de una descarga interrumpida (0 si no hay).
  /// Permite mostrar el progreso real al reabrir la app.
  Future<double> progresoGuardado() async =>
      _descarga.progresoGuardado(await _archivoModelo());

  Future<void> inicializarSiExiste() async {
    try {
      await FlutterGemma.initialize();

      // Descarga propia ya completa: registrarla (sin red, sin copiar).
      final propio = await _archivoModelo();
      if (await propio.exists()) {
        await _registrar(propio);
        _isReady = true;
        return;
      }

      // Instalación anterior vía red (flutter_gemma): activarla sin red.
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

  Future<void> _registrar(File archivo) async {
    await FlutterGemma.installModel(
      modelType: ModelType.gemmaIt,
      fileType: ModelFileType.binary,
    ).fromFile(archivo.path).install();
  }

  /// Descarga el modelo de forma REANUDABLE: si se corta la conexión, la app se
  /// minimiza o se cierra, la siguiente llamada continúa desde el último byte.
  /// Mientras descarga mantiene un servicio en primer plano (notificación) para
  /// que Android no congele el proceso al minimizar la app.
  Future<void> descargarModelo({
    required void Function(double) onProgress,
  }) async {
    if (_isDownloading || _isReady) return;
    _isDownloading = true;
    _downloadProgress = await progresoGuardado();
    onProgress(_downloadProgress);

    try {
      await FlutterGemma.initialize();
      final destino = await _archivoModelo();

      if (!await destino.exists()) {
        await DescargaPrimerPlano.iniciar();
        var ultimoPct = -1;
        await _descarga.descargarEnSegundoPlano(
          url: _urlModelo,
          destino: destino,
          onProgress: (recibidos, total) {
            if (total <= 0) return;
            // Nunca retroceder: evita saltos visuales entre reintentos.
            final p = (recibidos / total).clamp(0.0, 1.0);
            if (p < _downloadProgress) return;
            _downloadProgress = p;
            onProgress(p);
            final pct = (p * 100).floor();
            if (pct != ultimoPct) {
              ultimoPct = pct;
              DescargaPrimerPlano.actualizar('$pct % completado');
            }
          },
        );
      }

      await _registrar(destino);
      _isDownloading = false;
      _isReady = true;
      onProgress(1.0);
    } catch (e) {
      debugPrint('LocalLlmService.descargarModelo: $e');
      _isDownloading = false;
      // Se conserva el progreso: el .part sigue en disco y se reanudará.
      rethrow;
    } finally {
      await DescargaPrimerPlano.detener();
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
