// ─────────────────────────────────────────────────────────────
//  lib/ui/viewmodels/rag_quiz_view_model.dart
//  ViewModel para el quiz MCQ generado por RAG (T3.10)
//  Grados 3-5: 5 respuestas correctas → animación de felicitaciones
// ─────────────────────────────────────────────────────────────

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/rag_service.dart';
import 'asistente_ia_view_model.dart';

// ── Estado ────────────────────────────────────────────────────

class RagQuizEstado {
  final List<PreguntaQuiz> preguntas;
  final int indiceActual;
  final int correctas;                  // 0..metaCorrectas
  final bool cargando;
  final bool quizCompletado;            // true al llegar a 5 correctas
  final bool sinContenido;              // true si no hay corpus descargado
  final bool? ultimaRespuestaCorrecta;  // null = sin responder aún

  const RagQuizEstado({
    this.preguntas = const [],
    this.indiceActual = 0,
    this.correctas = 0,
    this.cargando = true,
    this.quizCompletado = false,
    this.sinContenido = false,
    this.ultimaRespuestaCorrecta,
  });

  PreguntaQuiz? get preguntaActual =>
      indiceActual < preguntas.length ? preguntas[indiceActual] : null;

  double get progresoNormalizado => correctas / metaCorrectas;

  static const int metaCorrectas = 5;

  RagQuizEstado copyWith({
    List<PreguntaQuiz>? preguntas,
    int? indiceActual,
    int? correctas,
    bool? cargando,
    bool? quizCompletado,
    bool? sinContenido,
    Object? ultimaRespuestaCorrecta = _sentinel,
  }) =>
      RagQuizEstado(
        preguntas: preguntas ?? this.preguntas,
        indiceActual: indiceActual ?? this.indiceActual,
        correctas: correctas ?? this.correctas,
        cargando: cargando ?? this.cargando,
        quizCompletado: quizCompletado ?? this.quizCompletado,
        sinContenido: sinContenido ?? this.sinContenido,
        ultimaRespuestaCorrecta: ultimaRespuestaCorrecta == _sentinel
            ? this.ultimaRespuestaCorrecta
            : ultimaRespuestaCorrecta as bool?,
      );
}

const Object _sentinel = Object();

// ── ViewModel ─────────────────────────────────────────────────

class RagQuizViewModel extends StateNotifier<RagQuizEstado> {
  final RagService _rag;

  RagQuizViewModel(this._rag) : super(const RagQuizEstado());

  Future<void> inicializar(String materia, int grado) async {
    state = const RagQuizEstado(cargando: true);
    try {
      final preguntas = await _rag.generarPreguntasMCQ(
        materia: materia,
        grado: grado,
        cantidad: 15,
      );
      if (preguntas.isEmpty) {
        state = const RagQuizEstado(cargando: false, sinContenido: true);
      } else {
        state = RagQuizEstado(preguntas: preguntas, cargando: false);
      }
    } catch (_) {
      state = const RagQuizEstado(cargando: false, sinContenido: true);
    }
  }

  // Registra la opción seleccionada por el estudiante.
  void responder(int opcion) {
    final pregunta = state.preguntaActual;
    if (pregunta == null || state.ultimaRespuestaCorrecta != null) return;

    final esCorrecto = opcion == pregunta.indiceCorrecto;
    final nuevasCorrectas = esCorrecto ? state.correctas + 1 : state.correctas;

    state = state.copyWith(
      ultimaRespuestaCorrecta: esCorrecto,
      correctas: nuevasCorrectas,
      quizCompletado: nuevasCorrectas >= RagQuizEstado.metaCorrectas,
    );
  }

  // Avanza a la siguiente pregunta (luego de una respuesta correcta).
  void avanzar() {
    final total = state.preguntas.length;
    final siguiente = (state.indiceActual + 1) % total;
    state = state.copyWith(
      indiceActual: siguiente,
      ultimaRespuestaCorrecta: null,
    );
  }

  // Permite volver a responder la misma pregunta (luego de incorrecta).
  void reintentarActual() {
    state = state.copyWith(ultimaRespuestaCorrecta: null);
  }
}

// ── Provider ──────────────────────────────────────────────────

final ragQuizViewModelProvider =
    StateNotifierProvider.autoDispose<RagQuizViewModel, RagQuizEstado>((ref) {
  return RagQuizViewModel(ref.read(ragServiceProvider));
});
