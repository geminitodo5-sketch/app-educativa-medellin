import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/database_provider.dart';
import '../services/embedding_service.dart';
import '../services/local_llm_service.dart';
import '../services/rag_service.dart';

// Re-exporta los tipos de datos para que los ViewModels no necesiten
// importar rag_service.dart directamente.
export '../services/rag_service.dart' show RagRespuesta, PreguntaQuiz;

class RagRepository {
  final RagService _rag;
  final LocalLlmService _localLlm;

  RagRepository(this._rag, this._localLlm);

  bool get isModelReady => _localLlm.isReady;
  bool get isModelDownloading => _localLlm.isDownloading;

  Future<void> inicializarModeloSiExiste() =>
      _localLlm.inicializarSiExiste();

  Future<void> descargarModelo({
    required void Function(double) onProgress,
  }) =>
      _localLlm.descargarModelo(onProgress: onProgress);

  Future<RagRespuesta> responder({
    required String pregunta,
    required String materia,
    required int grado,
  }) =>
      _rag.responder(pregunta: pregunta, materia: materia, grado: grado);

  Future<List<String>> preguntasSugeridas({
    required String materia,
    required int grado,
    int cantidad = 4,
  }) =>
      _rag.preguntasSugeridas(
          materia: materia, grado: grado, cantidad: cantidad);

  Future<void> guardarHistorial({
    required int estudianteId,
    required String pregunta,
    required String respuesta,
    required String materia,
    required int grado,
  }) =>
      _rag.guardarHistorial(
        estudianteId: estudianteId,
        pregunta: pregunta,
        respuesta: respuesta,
        materia: materia,
        grado: grado,
      );

  Future<List<Map<String, dynamic>>> obtenerHistorial({
    required int estudianteId,
    required String materia,
    int limite = 60,
  }) =>
      _rag.obtenerHistorial(
          estudianteId: estudianteId, materia: materia, limite: limite);

  Future<List<PreguntaQuiz>> generarPreguntasMCQ({
    required String materia,
    required int grado,
    int cantidad = 10,
  }) =>
      _rag.generarPreguntasMCQ(
          materia: materia, grado: grado, cantidad: cantidad);

  Future<String?> obtenerUltimaMateria(int estudianteId) =>
      _rag.obtenerUltimaMateria(estudianteId);
}

final embeddingServiceProvider = Provider<EmbeddingService>((ref) {
  final svc = EmbeddingService();
  svc.initialize();
  return svc;
});

final localLlmServiceProvider = Provider<LocalLlmService>((ref) {
  return LocalLlmService();
});

final ragServiceProvider = Provider<RagService>((ref) {
  return RagService(
    ref.read(sqliteServiceProvider),
    embeddings: ref.read(embeddingServiceProvider),
    localLlm: ref.read(localLlmServiceProvider),
  );
});

final ragRepositoryProvider = Provider<RagRepository>((ref) {
  return RagRepository(
    ref.read(ragServiceProvider),
    ref.read(localLlmServiceProvider),
  );
});
