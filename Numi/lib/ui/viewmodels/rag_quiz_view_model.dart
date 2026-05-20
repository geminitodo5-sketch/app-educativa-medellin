import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/rag_repository.dart';
import '../../data/services/banco_preguntas_service.dart';
import '../../data/services/feedback_sounds.dart';
import '../../data/providers/app_state_provider.dart';
import '../../data/providers/database_provider.dart';
import '../../data/providers/racha_provider.dart';

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

class RagQuizViewModel extends StateNotifier<RagQuizEstado> {
  final RagRepository _ragRepo;
  final BancoPreguntasService _banco;
  final Ref _ref;

  RagQuizViewModel(this._ragRepo, this._banco, this._ref)
      : super(const RagQuizEstado());

  static const _actividadesQuiz = {
    'matematicas': 3,
    'ciencias':    4,
    'espanol':     3,
    'ingles':      3,
    'sociales':    3,
  };

  static const _materiaDB = {
    'espanol': 'español',
  };

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
        preguntas = await _ragRepo.generarPreguntasMCQ(
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

  // Registra la opción seleccionada y reproduce el sonido de feedback.
  void responder(int opcion) {
    final pregunta = state.preguntaActual;
    if (pregunta == null || state.ultimaRespuestaCorrecta != null) return;

    final esCorrecto = opcion == pregunta.indiceCorrecto;
    final nuevasCorrectas = esCorrecto ? state.correctas + 1 : state.correctas;

    FeedbackSounds.instance.reproducir(esCorrecto);

    state = state.copyWith(
      ultimaRespuestaCorrecta: esCorrecto,
      ultimaOpcionSeleccionada: opcion,
      correctas: nuevasCorrectas,
      quizCompletado: nuevasCorrectas >= RagQuizEstado.metaCorrectas,
    );
  }

  // Registra progreso al 100% y verifica la racha al completar el quiz.
  Future<void> registrarProgresoYRacha(String materia, int grado) async {
    final estudiante = _ref.read(estudianteActivoProvider);
    if (estudiante == null || estudiante.id == null) return;

    final repo      = _ref.read(progresoRepositoryProvider);
    final total     = _actividadesQuiz[materia] ?? 3;
    final materiaDB = _materiaDB[materia] ?? materia;
    final gradoEst  = estudiante.grado;

    for (int i = 1; i <= total; i++) {
      await repo.registrarIntento(
        estudianteId: estudiante.id!,
        grado:        gradoEst,
        materia:      materiaDB,
        actividad:    'quiz_rag_$i',
        porcentaje:   100.0,
      );
    }

    // Sync inmediata a Firestore para reflejar el progreso en otros dispositivos
    _ref.read(sincronizarUseCaseProvider).ejecutar(estudiante.id!).ignore();
    _ref.invalidate(menuProgresoProvider);

    if (!mounted) return;
    final svc  = _ref.read(rachaServiceProvider);
    final info = await svc.verificarRacha(estudiante.id!);
    if (info != null && mounted) {
      _ref.read(rachaPendienteProvider.notifier).state = info;
    }
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

final ragQuizViewModelProvider =
    StateNotifierProvider.autoDispose<RagQuizViewModel, RagQuizEstado>((ref) {
  return RagQuizViewModel(
    ref.read(ragRepositoryProvider),
    ref.read(bancoPreguntasServiceProvider),
    ref,
  );
});
