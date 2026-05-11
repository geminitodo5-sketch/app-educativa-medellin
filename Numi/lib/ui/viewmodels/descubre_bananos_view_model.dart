import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Estados posibles del feedback después de seleccionar una opción
enum FeedbackEstadoBananos { esperando, correcto, incorrecto }

/// Estado inmutable de la actividad de bananos
class DescubreBananosEstado {
  final int numeroObjetivo;           // Cantidad real de bananos (aleatorio 3–8)
  final List<int> opciones;           // Las 3 opciones de respuesta (A, B, C)
  final int? opcionSeleccionada;      // Cuál eligió el niño (null si no ha elegido)
  final FeedbackEstadoBananos feedback;

  const DescubreBananosEstado({
    required this.numeroObjetivo,
    required this.opciones,
    required this.opcionSeleccionada,
    required this.feedback,
  });

  bool get esCorrecto => opcionSeleccionada == numeroObjetivo;
  bool get yaRespondio => opcionSeleccionada != null;

  DescubreBananosEstado copyWith({
    int? numeroObjetivo,
    List<int>? opciones,
    int? opcionSeleccionada,
    FeedbackEstadoBananos? feedback,
    bool limpiarOpcion = false,
  }) {
    return DescubreBananosEstado(
      numeroObjetivo: numeroObjetivo ?? this.numeroObjetivo,
      opciones: opciones ?? this.opciones,
      opcionSeleccionada: limpiarOpcion ? null : (opcionSeleccionada ?? this.opcionSeleccionada),
      feedback: feedback ?? this.feedback,
    );
  }
}

class DescubreBananosViewModel extends StateNotifier<DescubreBananosEstado> {
  final Random _random = Random();

  DescubreBananosViewModel() : super(_generarEstadoInicial(Random()));

  // ── Getters de conveniencia para la Vista ──────────────────────────────
  int get numeroObjetivo => state.numeroObjetivo;
  List<int> get opciones => state.opciones;
  int? get opcionSeleccionada => state.opcionSeleccionada;
  FeedbackEstadoBananos get feedback => state.feedback;
  bool get yaRespondio => state.yaRespondio;
  bool get esCorrecto => state.esCorrecto;

  // ── Generador de estado inicial ────────────────────────────────────────
  static DescubreBananosEstado _generarEstadoInicial(Random random) {
    return _crearRonda(random, anterior: -1);
  }

  static DescubreBananosEstado _crearRonda(Random random, {required int anterior}) {
    // Número aleatorio entre 3 y 8, diferente al anterior
    int objetivo;
    do {
      objetivo = random.nextInt(6) + 3; // 3, 4, 5, 6, 7 u 8
    } while (objetivo == anterior);

    // Generar 2 distractores únicos, distintos al objetivo y entre sí
    final Set<int> usados = {objetivo};
    final List<int> distractores = [];

    while (distractores.length < 2) {
      int candidato = random.nextInt(6) + 3;
      if (!usados.contains(candidato)) {
        usados.add(candidato);
        distractores.add(candidato);
      }
    }

    // Mezclar las 3 opciones aleatoriamente
    final List<int> opciones = [objetivo, ...distractores]..shuffle(random);

    return DescubreBananosEstado(
      numeroObjetivo: objetivo,
      opciones: opciones,
      opcionSeleccionada: null,
      feedback: FeedbackEstadoBananos.esperando,
    );
  }

  // ── Comandos ───────────────────────────────────────────────────────────

  /// El niño selecciona una opción (A, B o C)
  /// Retorna true si es correcto (para compatibilidad con el código anterior)
  bool commandValidarRespuesta(int valorElegido) {
    if (state.yaRespondio) return state.esCorrecto;

    final esCorrecto = valorElegido == state.numeroObjetivo;

    state = state.copyWith(
      opcionSeleccionada: valorElegido,
      feedback: esCorrecto
          ? FeedbackEstadoBananos.correcto
          : FeedbackEstadoBananos.incorrecto,
    );

    return esCorrecto;
  }

  /// Genera un nuevo reto con número aleatorio distinto al actual
  void commandNuevoReto() {
    final anterior = state.numeroObjetivo;
    state = _crearRonda(_random, anterior: anterior);
  }

  /// Limpia la selección para intentar de nuevo (mismo número)
  void commandIntentarDeNuevo() {
    state = state.copyWith(
      feedback: FeedbackEstadoBananos.esperando,
      limpiarOpcion: true,
    );
  }

  /// Reproduce instrucción por voz
  /// TODO: conectar con tu servicio TTS
  void commandReproducirInstruccion() {
    // ttsService.speak('¿Cuántos bananos tiene Muni?');
  }
}

final descubreBananosViewModelProvider = StateNotifierProvider.autoDispose<
    DescubreBananosViewModel, DescubreBananosEstado>(
  (ref) => DescubreBananosViewModel(),
);