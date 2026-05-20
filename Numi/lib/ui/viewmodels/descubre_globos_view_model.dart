import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/progreso_model.dart';
import '../../data/providers/database_provider.dart';
import '../../data/providers/app_state_provider.dart';

/// Estados del feedback tras tocar un globo
enum FeedbackEstadoGlobos { esperando, correcto, incorrecto }

/// Estado inmutable de la actividad de globos
class DescubreGlobosEstado {
  final int
  numeroObjetivo; // El número que el niño debe encontrar (aleatorio 1–9)
  final List<int> numerosEnGlobos; // Los 3 números que aparecen en los globos
  final FeedbackEstadoGlobos feedback;
  final int? ultimoTocado; // Último número que tocó el niño

  const DescubreGlobosEstado({
    required this.numeroObjetivo,
    required this.numerosEnGlobos,
    required this.feedback,
    required this.ultimoTocado,
  });

  bool get yaRespondioCorrectamente =>
      feedback == FeedbackEstadoGlobos.correcto;

  DescubreGlobosEstado copyWith({
    int? numeroObjetivo,
    List<int>? numerosEnGlobos,
    FeedbackEstadoGlobos? feedback,
    int? ultimoTocado,
    bool limpiarTocado = false,
  }) {
    return DescubreGlobosEstado(
      numeroObjetivo: numeroObjetivo ?? this.numeroObjetivo,
      numerosEnGlobos: numerosEnGlobos ?? this.numerosEnGlobos,
      feedback: feedback ?? this.feedback,
      ultimoTocado: limpiarTocado ? null : (ultimoTocado ?? this.ultimoTocado),
    );
  }
}

class DescubreGlobosViewModel extends StateNotifier<DescubreGlobosEstado> {
  final Ref _ref;
  final Random _random = Random();

  DescubreGlobosViewModel(this._ref) : super(_generarEstadoInicial(Random()));

  // ── Getters de conveniencia ────────────────────────────────────────────
  int get numeroObjetivo => state.numeroObjetivo;
  List<int> get numerosEnGlobos => state.numerosEnGlobos;
  FeedbackEstadoGlobos get feedback => state.feedback;
  int? get ultimoTocado => state.ultimoTocado;
  bool get yaRespondioCorrectamente => state.yaRespondioCorrectamente;

  // ── Generador de estado inicial ────────────────────────────────────────
  static DescubreGlobosEstado _generarEstadoInicial(Random random) {
    return _crearRonda(random, anterior: -1);
  }

  static DescubreGlobosEstado _crearRonda(
    Random random, {
    required int anterior,
  }) {
    // Objetivo aleatorio 1–9, distinto al anterior
    int objetivo;
    do {
      objetivo = random.nextInt(9) + 1;
    } while (objetivo == anterior);

    // 2 distractores únicos, distintos al objetivo
    final Set<int> usados = {objetivo};
    final List<int> distractores = [];
    while (distractores.length < 2) {
      final candidato = random.nextInt(9) + 1;
      if (!usados.contains(candidato)) {
        usados.add(candidato);
        distractores.add(candidato);
      }
    }

    // Mezclar los 3 números aleatoriamente
    final numeros = [objetivo, ...distractores]..shuffle(random);

    return DescubreGlobosEstado(
      numeroObjetivo: objetivo,
      numerosEnGlobos: numeros,
      feedback: FeedbackEstadoGlobos.esperando,
      ultimoTocado: null,
    );
  }

  // ── Comandos ───────────────────────────────────────────────────────────

  /// El niño toca un globo — retorna true si es el correcto
  bool commandValidarRespuesta(int numerotocado) {
    if (state.yaRespondioCorrectamente) return true;

    final esCorrecto = numerotocado == state.numeroObjetivo;

    state = state.copyWith(
      ultimoTocado: numerotocado,
      feedback: esCorrecto
          ? FeedbackEstadoGlobos.correcto
          : FeedbackEstadoGlobos.incorrecto,
    );

    if (esCorrecto) {
      _guardarProgresoFinal();
    }

    return esCorrecto;
  }

  /// Registra en la base de datos que la actividad se completó al 100%
  Future<void> _guardarProgresoFinal() async {
    final estudiante = _ref.read(estudianteActivoProvider);
    if (estudiante == null) return;

    // Ingeniería: Guardamos el progreso al 100% en SQLite
    await _ref
        .read(progresoRepositoryProvider)
        .registrarIntento(
          estudianteId: estudiante.id!,
          grado: estudiante.grado,
          materia: 'matematicas',
          actividad: 'Los números',
          porcentaje: 100,
        );

    // Sync inmediata a Firestore para reflejar el progreso en otros dispositivos
    _ref.read(sincronizarUseCaseProvider).ejecutar(estudiante.id!).ignore();
    _ref.invalidate(menuProgresoProvider);
  }

  /// Nuevo reto: número objetivo diferente, nuevos globos
  void commandNuevoReto() {
    final anterior = state.numeroObjetivo;
    state = _crearRonda(_random, anterior: anterior);
  }

  /// Intenta de nuevo con el mismo número objetivo
  void commandIntentarDeNuevo() {
    state = state.copyWith(
      feedback: FeedbackEstadoGlobos.esperando,
      limpiarTocado: true,
    );
  }

  /// Reproduce instrucción por voz
  /// TODO: conectar con tu servicio TTS
  void commandReproducirInstruccion() {
    // ttsService.speak('Presiona el globo cuando salga el ${state.numeroObjetivo}');
  }
}

final descubreGlobosViewModelProvider =
    StateNotifierProvider.autoDispose<
      DescubreGlobosViewModel,
      DescubreGlobosEstado
    >((ref) => DescubreGlobosViewModel(ref));
