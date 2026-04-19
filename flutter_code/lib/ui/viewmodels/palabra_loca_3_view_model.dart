import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/sync_queue_model.dart';
import '../../data/providers/app_state_provider.dart'
    show estudianteActivoProvider;
import '../../data/providers/database_provider.dart';

class OracionEjercicio {
  final String imagenAsset;
  final List<String> palabrasDesordenadas;
  final List<String> respuestaCorrecta;

  const OracionEjercicio({
    required this.imagenAsset,
    required this.palabrasDesordenadas,
    required this.respuestaCorrecta,
  });
}

class OracionesEstado {
  final int ejercicioActual;
  final List<String?> respuestaUsuario;
  final List<String?> palabrasDisponibles;
  final bool mostrandoResultado;
  final bool respuestaCorrecta;
  final bool juegoFinalizado;

  OracionesEstado({
    required this.ejercicioActual,
    required this.respuestaUsuario,
    required this.palabrasDisponibles,
    required this.mostrandoResultado,
    required this.respuestaCorrecta,
    required this.juegoFinalizado,
  });

  OracionesEstado copyWith({
    int? ejercicioActual,
    List<String?>? respuestaUsuario,
    List<String?>? palabrasDisponibles,
    bool? mostrandoResultado,
    bool? respuestaCorrecta,
    bool? juegoFinalizado,
  }) {
    return OracionesEstado(
      ejercicioActual: ejercicioActual ?? this.ejercicioActual,
      respuestaUsuario: respuestaUsuario ?? this.respuestaUsuario,
      palabrasDisponibles: palabrasDisponibles ?? this.palabrasDisponibles,
      mostrandoResultado: mostrandoResultado ?? this.mostrandoResultado,
      respuestaCorrecta: respuestaCorrecta ?? this.respuestaCorrecta,
      juegoFinalizado: juegoFinalizado ?? this.juegoFinalizado,
    );
  }
}

class OracionesViewModel extends StateNotifier<OracionesEstado> {
  final Ref _ref;

  OracionesViewModel(this._ref) : super(_initialState(0));

  static final List<OracionEjercicio> ejercicios = [
    const OracionEjercicio(
      imagenAsset: 'assets/images/actividades/espanol/gato_comiendo.png',
      palabrasDesordenadas: ['come', 'gato', 'El'],
      respuestaCorrecta: ['El', 'gato', 'come'],
    ),
    const OracionEjercicio(
      imagenAsset: 'assets/images/actividades/espanol/nino_balon.png',
      palabrasDesordenadas: ['juega', 'con', 'El', 'el', 'balón', 'niño'],
      respuestaCorrecta: ['El', 'niño', 'juega', 'con', 'el', 'balón'],
    ),
    const OracionEjercicio(
      imagenAsset: 'assets/images/actividades/espanol/carro.png',
      palabrasDesordenadas: ['carro', 'es', 'El', 'rojo', 'color', 'de'],
      respuestaCorrecta: ['El', 'carro', 'es', 'de', 'color', 'rojo'],
    ),
  ];

  static OracionesEstado _initialState(int index) {
    final ejercicio = ejercicios[index];
    return OracionesEstado(
      ejercicioActual: index,
      respuestaUsuario: List.filled(ejercicio.respuestaCorrecta.length, null),
      palabrasDisponibles: List<String?>.from(ejercicio.palabrasDesordenadas),
      mostrandoResultado: false,
      respuestaCorrecta: false,
      juegoFinalizado: false,
    );
  }

  OracionEjercicio get currentEjercicio => ejercicios[state.ejercicioActual];

  void commandSeleccionarPalabra(int index) {
    if (state.mostrandoResultado) return;
    final vacio = state.respuestaUsuario.indexWhere((p) => p == null);
    if (vacio == -1) return;

    final nuevasPalabrasDisponibles = [...state.palabrasDisponibles];
    final nuevaRespuestaUsuario = [...state.respuestaUsuario];
    nuevaRespuestaUsuario[vacio] = nuevasPalabrasDisponibles[index];
    nuevasPalabrasDisponibles[index] = null;
    state = state.copyWith(
      respuestaUsuario: nuevaRespuestaUsuario,
      palabrasDisponibles: nuevasPalabrasDisponibles,
    );
  }

  void commandDevolverPalabra(int index) {
    if (state.mostrandoResultado) return;
    final palabra = state.respuestaUsuario[index];
    if (palabra == null) return;
    final nuevasPalabrasDisponibles = [...state.palabrasDisponibles];
    final nuevaRespuestaUsuario = [...state.respuestaUsuario];
    int slot = -1;
    final originales = currentEjercicio.palabrasDesordenadas;
    for (int j = 0; j < originales.length; j++) {
      if (nuevasPalabrasDisponibles[j] == null && originales[j] == palabra) {
        slot = j;
        break;
      }
    }
    if (slot != -1) {
      nuevasPalabrasDisponibles[slot] = palabra;
      nuevaRespuestaUsuario[index] = null;
    }
    state = state.copyWith(
      respuestaUsuario: nuevaRespuestaUsuario,
      palabrasDisponibles: nuevasPalabrasDisponibles,
    );
  }

  void commandVerificar() {
    final ok = currentEjercicio.respuestaCorrecta.asMap().entries.every(
      (e) => state.respuestaUsuario[e.key] == e.value,
    );
    state = state.copyWith(mostrandoResultado: true, respuestaCorrecta: ok);
  }

  void commandSiguiente() {
    if (state.ejercicioActual < ejercicios.length - 1) {
      state = _initialState(state.ejercicioActual + 1);
    } else {
      _guardarProgreso();
      state = state.copyWith(juegoFinalizado: true);
    }
  }

  void commandReiniciar() {
    state = _initialState(0);
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
            actividad: 'Oraciones',
            porcentaje: 100.0,
          );

      await _ref.read(syncQueueRepositoryProvider).encolar(SyncQueueModel(
            tipoAccion: 'progreso',
            payload: jsonEncode({
              'estudiante_id': estudianteId,
              'grado': grado,
              'materia': 'español',
              'actividad': 'Oraciones',
              'porcentaje': 100.0,
            }),
            fecha: DateTime.now().toIso8601String(),
          ));
    } catch (e) {
      debugPrint('Error guardando progreso Oraciones: $e');
    }
  }
}

final oracionesViewModelProvider =
    StateNotifierProvider.autoDispose<OracionesViewModel, OracionesEstado>(
  (ref) => OracionesViewModel(ref),
);
