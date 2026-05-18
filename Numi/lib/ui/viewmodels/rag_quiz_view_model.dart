// ─────────────────────────────────────────────────────────────
//  lib/ui/viewmodels/rag_quiz_view_model.dart
//  ViewModel para el quiz MCQ generado por RAG (T3.10)
//  Grados 3-5: 5 respuestas correctas → animación de felicitaciones
// ─────────────────────────────────────────────────────────────

import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/rag_service.dart';
import '../../data/services/banco_preguntas_service.dart';
import '../../data/providers/database_provider.dart';
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
  final int? ultimaOpcionSeleccionada;  // índice de la última opción elegida
  final Set<int> vistas;               // índices ya mostrados

  const RagQuizEstado({
    this.preguntas = const [],
    this.indiceActual = 0,
    this.correctas = 0,
    this.cargando = true,
    this.quizCompletado = false,
    this.sinContenido = false,
    this.ultimaRespuestaCorrecta,
    this.ultimaOpcionSeleccionada,
    this.vistas = const {},
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
    Object? ultimaOpcionSeleccionada = _sentinel,
    Set<int>? vistas,
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
        ultimaOpcionSeleccionada: ultimaOpcionSeleccionada == _sentinel
            ? this.ultimaOpcionSeleccionada
            : ultimaOpcionSeleccionada as int?,
        vistas: vistas ?? this.vistas,
      );
}

const Object _sentinel = Object();

// ── ViewModel ─────────────────────────────────────────────────

class RagQuizViewModel extends StateNotifier<RagQuizEstado> {
  final RagService _rag;
  final BancoPreguntasService _banco;

  RagQuizViewModel(this._rag, this._banco) : super(const RagQuizEstado());

  Future<void> inicializar(String materia, int grado) async {
    state = const RagQuizEstado(cargando: true);
    try {
      // Asegurar que el banco estático esté sembrado.
      await _banco.inicializar();

      // 1) Intentar banco estático primero (siempre disponible offline).
      var preguntas = await _banco.obtenerPreguntas(
        materia: materia,
        grado: grado,
        cantidad: 15,
      );

      // 2) Si no hay preguntas estáticas, intentar generar desde RAG corpus.
      if (preguntas.isEmpty) {
        preguntas = await _rag.generarPreguntasMCQ(
          materia: materia,
          grado: grado,
          cantidad: 15,
        );
      }

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
      ultimaOpcionSeleccionada: opcion,
      correctas: nuevasCorrectas,
      quizCompletado: nuevasCorrectas >= RagQuizEstado.metaCorrectas,
    );
  }

  // Avanza a una pregunta aleatoria no mostrada aún.
  void avanzar() {
    final total = state.preguntas.length;
    final visitados = {...state.vistas, state.indiceActual};

    // Candidatos: índices que no se han visto todavía
    var disponibles = List.generate(total, (i) => i)
        .where((i) => !visitados.contains(i))
        .toList();

    // Si ya se vieron todas, reiniciar el ciclo
    if (disponibles.isEmpty) {
      disponibles = List.generate(total, (i) => i)
          .where((i) => i != state.indiceActual)
          .toList();
      visitados.clear();
    }

    disponibles.shuffle(Random());
    final siguiente = disponibles.first;

    state = state.copyWith(
      indiceActual: siguiente,
      vistas: {...visitados, siguiente},
      ultimaRespuestaCorrecta: null,
      ultimaOpcionSeleccionada: null,
    );
  }

  // Permite volver a responder la misma pregunta (luego de incorrecta).
  void reintentarActual() {
    state = state.copyWith(
      ultimaRespuestaCorrecta: null,
      ultimaOpcionSeleccionada: null,
    );
  }
}

// ── Provider ──────────────────────────────────────────────────

final ragQuizViewModelProvider =
    StateNotifierProvider.autoDispose<RagQuizViewModel, RagQuizEstado>((ref) {
  return RagQuizViewModel(
    ref.read(ragServiceProvider),
    ref.read(bancoPreguntasServiceProvider),
  );
});
