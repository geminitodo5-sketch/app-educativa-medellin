import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Estados posibles del feedback después de verificar
enum FeedbackEstado { esperando, correcto, incorrecto }

/// Estado inmutable de la actividad
class DescubreNumerosEstado {
  final int numeroObjetivo;       // Número aleatorio entre 1 y 8
  final List<Key> fresasEnCuadro; // Fresas arrastradas al recuadro
  final int totalFresasDisponibles; // Fresas que se muestran en la grilla
  final FeedbackEstado feedback;  // Estado del panel inferior
  final bool verificado;          // Si ya presionó "Verificar"

  const DescubreNumerosEstado({
    required this.numeroObjetivo,
    required this.fresasEnCuadro,
    required this.totalFresasDisponibles,
    required this.feedback,
    required this.verificado,
  });

  int get fresasRestantes => totalFresasDisponibles - fresasEnCuadro.length;

  bool get esCorrecto => fresasEnCuadro.length == numeroObjetivo;

  /// Cuántas fresas faltan o sobran para el mensaje de feedback
  int get diferencia => fresasEnCuadro.length - numeroObjetivo;

  DescubreNumerosEstado copyWith({
    int? numeroObjetivo,
    List<Key>? fresasEnCuadro,
    int? totalFresasDisponibles,
    FeedbackEstado? feedback,
    bool? verificado,
  }) {
    return DescubreNumerosEstado(
      numeroObjetivo: numeroObjetivo ?? this.numeroObjetivo,
      fresasEnCuadro: fresasEnCuadro ?? this.fresasEnCuadro,
      totalFresasDisponibles: totalFresasDisponibles ?? this.totalFresasDisponibles,
      feedback: feedback ?? this.feedback,
      verificado: verificado ?? this.verificado,
    );
  }
}

class DescubreNumerosViewModel extends StateNotifier<DescubreNumerosEstado> {
  final Random _random = Random();

  DescubreNumerosViewModel() : super(_crearEstadoInicial(Random()));

  static DescubreNumerosEstado _crearEstadoInicial(Random random) {
    final objetivo = random.nextInt(8) + 1; // 1 a 8
    // Siempre hay al menos 2 fresas más que el objetivo (para que sea un reto real)
    final total = min(objetivo + 2 + random.nextInt(3), 8);
    return DescubreNumerosEstado(
      numeroObjetivo: objetivo,
      fresasEnCuadro: [],
      totalFresasDisponibles: total,
      feedback: FeedbackEstado.esperando,
      verificado: false,
    );
  }

  // -- Getters de conveniencia para la Vista --
  int get numeroObjetivo => state.numeroObjetivo;
  int get fresasRestantes => state.fresasRestantes;
  List<Key> get fresasEnCuadro => state.fresasEnCuadro;
  FeedbackEstado get feedback => state.feedback;
  bool get verificado => state.verificado;
  int get diferencia => state.diferencia;
  bool get esCorrecto => state.esCorrecto;
  int get totalFresasDisponibles => state.totalFresasDisponibles;

  /// Agrega una fresa al recuadro (se llama desde el DragTarget)
  void commandAgregarFresa() {
    if (state.verificado) return; // No se puede modificar si ya verificó
    if (state.fresasEnCuadro.length >= state.totalFresasDisponibles) return;

    final nuevasFresas = [...state.fresasEnCuadro, UniqueKey()];
    state = state.copyWith(
      fresasEnCuadro: nuevasFresas,
      feedback: FeedbackEstado.esperando,
      verificado: false,
    );
  }

  /// Quita la última fresa del recuadro
  void commandQuitarFresa() {
    if (state.verificado) return;
    if (state.fresasEnCuadro.isEmpty) return;

    final nuevasFresas = [...state.fresasEnCuadro]..removeLast();
    state = state.copyWith(
      fresasEnCuadro: nuevasFresas,
      feedback: FeedbackEstado.esperando,
    );
  }

  /// Verifica si la cantidad de fresas en el recuadro es la correcta
  void commandVerificar() {
    if (state.fresasEnCuadro.isEmpty) return;

    state = state.copyWith(
      feedback: state.esCorrecto
          ? FeedbackEstado.correcto
          : FeedbackEstado.incorrecto,
      verificado: true,
    );
  }

  /// Genera un nuevo reto con número aleatorio diferente al actual
  void commandNuevoReto() {
    int nuevoObjetivo;
    do {
      nuevoObjetivo = _random.nextInt(8) + 1;
    } while (nuevoObjetivo == state.numeroObjetivo); // Evita repetir el mismo número

    final total = min(nuevoObjetivo + 2 + _random.nextInt(3), 8);
    state = DescubreNumerosEstado(
      numeroObjetivo: nuevoObjetivo,
      fresasEnCuadro: [],
      totalFresasDisponibles: total,
      feedback: FeedbackEstado.esperando,
      verificado: false,
    );
  }

  /// Limpia el recuadro para intentar de nuevo
  void commandIntentarDeNuevo() {
    state = state.copyWith(
      fresasEnCuadro: [],
      feedback: FeedbackEstado.esperando,
      verificado: false,
    );
  }

  /// Reproduce la instrucción por voz (aquí conectas tu servicio TTS)
  void commandReproducirInstruccion() {
    // TODO: conectar con tu servicio de Text-to-Speech
    // Ejemplo: ttsService.speak('Coloca $numeroObjetivo fresas en el cuadro');
  }
}

final descubreNumerosViewModelProvider =
    StateNotifierProvider.autoDispose<DescubreNumerosViewModel, DescubreNumerosEstado>(
  (ref) => DescubreNumerosViewModel(),
);