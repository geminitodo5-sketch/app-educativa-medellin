import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Modelo de datos para la actividad
class PalabraData {
  final String imagenAsset;
  final String palabra;
  final List<String> silabas;
  final List<String> opcionesMezcladas;

  const PalabraData({
    required this.imagenAsset,
    required this.palabra,
    required this.silabas,
    required this.opcionesMezcladas,
  });
}

/// Estado inmutable de la vista
class ArmaLaPalabraEstado {
  final int palabraActualIndex;
  final List<String?> silabasColocadas;
  final List<bool> opcionesDisponibles;
  final bool completado;

  const ArmaLaPalabraEstado({
    required this.palabraActualIndex,
    required this.silabasColocadas,
    required this.opcionesDisponibles,
    required this.completado,
  });

  ArmaLaPalabraEstado copyWith({
    int? palabraActualIndex,
    List<String?>? silabasColocadas,
    List<bool>? opcionesDisponibles,
    bool? completado,
  }) {
    return ArmaLaPalabraEstado(
      palabraActualIndex: palabraActualIndex ?? this.palabraActualIndex,
      silabasColocadas: silabasColocadas ?? this.silabasColocadas,
      opcionesDisponibles: opcionesDisponibles ?? this.opcionesDisponibles,
      completado: completado ?? this.completado,
    );
  }
}

class ArmaLaPalabraViewModel extends StateNotifier<ArmaLaPalabraEstado> {
  ArmaLaPalabraViewModel() : super(_initialState());

  static const List<PalabraData> _palabras = [
    PalabraData(
      imagenAsset: 'assets/images/actividades/espanol/perro.png',
      palabra: 'Perro',
      silabas: ['Pe', 'rro'],
      opcionesMezcladas: ['Te', 'rro', 'di', 'Ti', 'co', 'Pe'],
    ),
    PalabraData(
      imagenAsset: 'assets/images/actividades/espanol/mono.png',
      palabra: 'Mono',
      silabas: ['Mo', 'no'],
      opcionesMezcladas: ['Mo', 'la', 'di', 'no', 'Pe', 'Ti'],
    ),
    PalabraData(
      imagenAsset: 'assets/images/actividades/espanol/banano.png',
      palabra: 'Banano',
      silabas: ['Ba', 'na', 'no'],
      opcionesMezcladas: ['Ba', 'na', 'di', 'no', 'Te', 'Ti'],
    ),
  ];

  static ArmaLaPalabraEstado _initialState() {
    final p = _palabras[0];
    return ArmaLaPalabraEstado(
      palabraActualIndex: 0,
      silabasColocadas: List.filled(p.silabas.length, null),
      opcionesDisponibles: List.filled(p.opcionesMezcladas.length, true),
      completado: false,
    );
  }

  PalabraData get palabraActual => _palabras[state.palabraActualIndex];

  void commandColocarSilaba(int opcionIndex, int recuadroIndex) {
    if (state.completado) return;

    final silabaElegida = palabraActual.opcionesMezcladas[opcionIndex];
    final nuevasColocadas = [...state.silabasColocadas];
    final nuevasDisponibles = [...state.opcionesDisponibles];

    // Si el recuadro ya tenía algo, devolver la anterior al pool
    if (nuevasColocadas[recuadroIndex] != null) {
      final silabaPrev = nuevasColocadas[recuadroIndex]!;
      for (int i = 0; i < palabraActual.opcionesMezcladas.length; i++) {
        if (!nuevasDisponibles[i] &&
            palabraActual.opcionesMezcladas[i] == silabaPrev) {
          nuevasDisponibles[i] = true;
          break;
        }
      }
    }

    nuevasColocadas[recuadroIndex] = silabaElegida;
    nuevasDisponibles[opcionIndex] = false;

    // Verificar si está correcto
    bool esCorrecto = true;
    for (int i = 0; i < palabraActual.silabas.length; i++) {
      if (nuevasColocadas[i] != palabraActual.silabas[i]) {
        esCorrecto = false;
        break;
      }
    }

    state = state.copyWith(
      silabasColocadas: nuevasColocadas,
      opcionesDisponibles: nuevasDisponibles,
      completado: esCorrecto,
    );
  }

  void commandSiguientePalabra() {
    final nextIndex = (state.palabraActualIndex + 1) % _palabras.length;
    final p = _palabras[nextIndex];
    state = ArmaLaPalabraEstado(
      palabraActualIndex: nextIndex,
      silabasColocadas: List.filled(p.silabas.length, null),
      opcionesDisponibles: List.filled(p.opcionesMezcladas.length, true),
      completado: false,
    );
  }

  void commandReproducirInstruccion() {
    debugPrint('Reproduciendo audio: Arma la palabra');
  }
}

final armaLaPalabraViewModelProvider =
    StateNotifierProvider.autoDispose<
      ArmaLaPalabraViewModel,
      ArmaLaPalabraEstado
    >((ref) => ArmaLaPalabraViewModel());
