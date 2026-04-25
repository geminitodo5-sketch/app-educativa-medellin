import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/sync_queue_model.dart';
import '../../data/providers/app_state_provider.dart'
    show estudianteActivoProvider;
import '../../data/providers/database_provider.dart';

// ── Modelo de datos ──────────────────────────────────────────────────────────

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

// ── Estado ───────────────────────────────────────────────────────────────────

class ArmaLaPalabraState {
  final int palabraIndex;
  final List<String?> silabasColocadas;
  final List<bool> opcionesDisponibles;
  final bool completado;
  final bool error;
  final bool actividadCompletada;

  const ArmaLaPalabraState({
    required this.palabraIndex,
    required this.silabasColocadas,
    required this.opcionesDisponibles,
    required this.completado,
    required this.error,
    this.actividadCompletada = false,
  });

  ArmaLaPalabraState copyWith({
    int? palabraIndex,
    List<String?>? silabasColocadas,
    List<bool>? opcionesDisponibles,
    bool? completado,
    bool? error,
    bool? actividadCompletada,
  }) {
    return ArmaLaPalabraState(
      palabraIndex: palabraIndex ?? this.palabraIndex,
      silabasColocadas: silabasColocadas ?? this.silabasColocadas,
      opcionesDisponibles: opcionesDisponibles ?? this.opcionesDisponibles,
      completado: completado ?? this.completado,
      error: error ?? this.error,
      actividadCompletada: actividadCompletada ?? this.actividadCompletada,
    );
  }
}

// ── ViewModel ────────────────────────────────────────────────────────────────

class ArmaLaPalabraViewModel extends StateNotifier<ArmaLaPalabraState> {
  final Ref _ref;
  final List<PalabraData> _palabras;

  ArmaLaPalabraViewModel._(this._ref, this._palabras, ArmaLaPalabraState initialState)
      : super(initialState);

  factory ArmaLaPalabraViewModel(Ref ref) {
    final palabras = _crearListaAleatoria();
    return ArmaLaPalabraViewModel._(
      ref,
      palabras,
      ArmaLaPalabraState(
        palabraIndex: 0,
        silabasColocadas: List.filled(palabras[0].silabas.length, null),
        opcionesDisponibles: List.filled(palabras[0].opcionesMezcladas.length, true),
        completado: false,
        error: false,
      ),
    );
  }

  static const List<PalabraData> _todasLasPalabras = [
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
    PalabraData(
      imagenAsset: 'assets/images/actividades/espanol/carro.png',
      palabra: 'Carro',
      silabas: ['Ca', 'rro'],
      opcionesMezcladas: ['Ca', 'rro', 'Mi', 'Sa', 'lo', 'Pe'],
    ),
    PalabraData(
      imagenAsset: 'assets/images/actividades/espanol/gato_comiendo.png',
      palabra: 'Gato',
      silabas: ['Ga', 'to'],
      opcionesMezcladas: ['Ga', 'to', 'Mi', 'Pa', 'lo', 'Sa'],
    ),
    PalabraData(
      imagenAsset: 'assets/images/actividades/espanol/manzana.png',
      palabra: 'Manzana',
      silabas: ['Man', 'za', 'na'],
      opcionesMezcladas: ['Man', 'za', 'na', 'Pe', 'li', 'To'],
    ),
    PalabraData(
      imagenAsset: 'assets/images/actividades/espanol/pinguinos.png',
      palabra: 'Pingüino',
      silabas: ['Pin', 'güi', 'no'],
      opcionesMezcladas: ['Pin', 'güi', 'no', 'Ca', 'li', 'Me'],
    ),
    PalabraData(
      imagenAsset: 'assets/images/actividades/espanol/nino_balon.png',
      palabra: 'Niño',
      silabas: ['Ni', 'ño'],
      opcionesMezcladas: ['Ni', 'ño', 'Ca', 'Pe', 'la', 'Mi'],
    ),
  ];

  static List<PalabraData> _crearListaAleatoria() {
    final lista = List<PalabraData>.from(_todasLasPalabras);
    lista.shuffle(Random());
    return lista.take(4).toList();
  }

  PalabraData get palabraActual => _palabras[state.palabraIndex];

  void commandColocarSilaba(int opcionIndex, int recuadroIndex) {
    if (state.completado || state.error) return;

    final silabaElegida = palabraActual.opcionesMezcladas[opcionIndex];
    final nuevasSilabas = List<String?>.from(state.silabasColocadas);
    final nuevasDisponibles = List<bool>.from(state.opcionesDisponibles);

    final silabaPrev = nuevasSilabas[recuadroIndex];
    if (silabaPrev != null) {
      for (int i = 0; i < palabraActual.opcionesMezcladas.length; i++) {
        if (!nuevasDisponibles[i] &&
            palabraActual.opcionesMezcladas[i] == silabaPrev) {
          nuevasDisponibles[i] = true;
          break;
        }
      }
    }

    nuevasSilabas[recuadroIndex] = silabaElegida;
    nuevasDisponibles[opcionIndex] = false;

    state = state.copyWith(
      silabasColocadas: nuevasSilabas,
      opcionesDisponibles: nuevasDisponibles,
    );

    _verificar();
  }

  void commandQuitarSilaba(int recuadroIndex) {
    if (state.completado || state.error) return;

    final silaba = state.silabasColocadas[recuadroIndex];
    if (silaba == null) return;

    final nuevasSilabas = List<String?>.from(state.silabasColocadas);
    final nuevasDisponibles = List<bool>.from(state.opcionesDisponibles);

    nuevasSilabas[recuadroIndex] = null;
    for (int i = 0; i < palabraActual.opcionesMezcladas.length; i++) {
      if (!nuevasDisponibles[i] &&
          palabraActual.opcionesMezcladas[i] == silaba) {
        nuevasDisponibles[i] = true;
        break;
      }
    }

    state = state.copyWith(
      silabasColocadas: nuevasSilabas,
      opcionesDisponibles: nuevasDisponibles,
      error: false,
    );
  }

  void commandLimpiarError() {
    if (!state.error) return;
    state = state.copyWith(error: false);
  }

  void commandLimpiarRespuestas() {
    state = state.copyWith(
      silabasColocadas: List.filled(palabraActual.silabas.length, null),
      opcionesDisponibles:
          List.filled(palabraActual.opcionesMezcladas.length, true),
      completado: false,
      error: false,
    );
  }

  void commandSiguientePalabra() {
    final esUltima = state.palabraIndex == _palabras.length - 1;
    if (esUltima) {
      _guardarProgreso();
      state = state.copyWith(actividadCompletada: true);
    } else {
      final nextIndex = state.palabraIndex + 1;
      final nextPalabra = _palabras[nextIndex];
      state = ArmaLaPalabraState(
        palabraIndex: nextIndex,
        silabasColocadas: List.filled(nextPalabra.silabas.length, null),
        opcionesDisponibles:
            List.filled(nextPalabra.opcionesMezcladas.length, true),
        completado: false,
        error: false,
      );
    }
  }

  void _verificar() {
    final silabas = state.silabasColocadas;
    if (silabas.any((s) => s == null)) return;

    bool correcto = true;
    for (int i = 0; i < palabraActual.silabas.length; i++) {
      if (silabas[i] != palabraActual.silabas[i]) {
        correcto = false;
        break;
      }
    }

    if (correcto) {
      state = state.copyWith(completado: true, error: false);
    } else {
      state = state.copyWith(error: true, completado: false);
    }
  }

  Future<void> _guardarProgreso() async {
    try {
      final estudiante = _ref.read(estudianteActivoProvider);
      final estudianteId = estudiante?.id ?? 1;
      final grado = estudiante?.grado ?? 1;

      await _ref.read(progresoRepositoryProvider).registrarIntento(
            estudianteId: estudianteId,
            grado: grado,
            materia: 'español',
            actividad: 'Arma la palabra',
            porcentaje: 100.0,
          );

      await _ref.read(syncQueueRepositoryProvider).encolar(SyncQueueModel(
            tipoAccion: 'progreso',
            payload: jsonEncode({
              'estudiante_id': estudianteId,
              'grado': grado,
              'materia': 'español',
              'actividad': 'Arma la palabra',
              'porcentaje': 100.0,
            }),
            fecha: DateTime.now().toIso8601String(),
          ));
    } catch (e) {
      debugPrint('Error guardando progreso Arma la palabra: $e');
    }
  }
}

// ── Provider ─────────────────────────────────────────────────────────────────

final armaLaPalabraViewModelProvider = StateNotifierProvider.autoDispose<
    ArmaLaPalabraViewModel, ArmaLaPalabraState>(
  (ref) => ArmaLaPalabraViewModel(ref),
);