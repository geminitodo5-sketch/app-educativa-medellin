import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/sync_queue_model.dart';
import '../../data/providers/app_state_provider.dart'
    show estudianteActivoProvider, menuProgresoProvider;
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
  final List<OracionEjercicio> _ejercicios;

  OracionesViewModel._(this._ref, this._ejercicios, OracionesEstado initialState)
      : super(initialState);

  factory OracionesViewModel(Ref ref) {
    final ejercicios = _crearListaAleatoria();
    return OracionesViewModel._(ref, ejercicios, _estadoInicial(ejercicios, 0));
  }

  static const List<OracionEjercicio> _todosLosEjercicios = [
    OracionEjercicio(
      imagenAsset: 'assets/images/actividades/espanol/gato_comiendo.png',
      palabrasDesordenadas: ['come', 'gato', 'El'],
      respuestaCorrecta: ['El', 'gato', 'come'],
    ),
    OracionEjercicio(
      imagenAsset: 'assets/images/actividades/espanol/nino_balon.png',
      palabrasDesordenadas: ['juega', 'con', 'El', 'el', 'balón', 'niño'],
      respuestaCorrecta: ['El', 'niño', 'juega', 'con', 'el', 'balón'],
    ),
    OracionEjercicio(
      imagenAsset: 'assets/images/actividades/espanol/carro.png',
      palabrasDesordenadas: ['carro', 'es', 'El', 'rojo', 'color', 'de'],
      respuestaCorrecta: ['El', 'carro', 'es', 'de', 'color', 'rojo'],
    ),
    OracionEjercicio(
      imagenAsset: 'assets/images/actividades/espanol/perro.png',
      palabrasDesordenadas: ['ladra', 'El', 'fuerte', 'perro'],
      respuestaCorrecta: ['El', 'perro', 'ladra', 'fuerte'],
    ),
    OracionEjercicio(
      imagenAsset: 'assets/images/actividades/espanol/mono.png',
      palabrasDesordenadas: ['al', 'El', 'sube', 'mono', 'árbol'],
      respuestaCorrecta: ['El', 'mono', 'sube', 'al', 'árbol'],
    ),
    OracionEjercicio(
      imagenAsset: 'assets/images/actividades/espanol/banano.png',
      palabrasDesordenadas: ['es', 'El', 'amarillo', 'banano'],
      respuestaCorrecta: ['El', 'banano', 'es', 'amarillo'],
    ),
    OracionEjercicio(
      imagenAsset: 'assets/images/actividades/espanol/manzana.png',
      palabrasDesordenadas: ['es', 'La', 'roja', 'manzana'],
      respuestaCorrecta: ['La', 'manzana', 'es', 'roja'],
    ),
    OracionEjercicio(
      imagenAsset: 'assets/images/actividades/espanol/pinguinos.png',
      palabrasDesordenadas: ['son', 'pingüinos', 'Los', 'muy', 'lindos'],
      respuestaCorrecta: ['Los', 'pingüinos', 'son', 'muy', 'lindos'],
    ),
    OracionEjercicio(
      imagenAsset: 'assets/images/actividades/espanol/mono_corazon.png',
      palabrasDesordenadas: ['da', 'El', 'abrazo', 'un', 'mono'],
      respuestaCorrecta: ['El', 'mono', 'da', 'un', 'abrazo'],
    ),
  ];

  static List<OracionEjercicio> _crearListaAleatoria() {
    final lista = List<OracionEjercicio>.from(_todosLosEjercicios);
    lista.shuffle(Random());
    return lista.take(4).toList();
  }

  static OracionesEstado _estadoInicial(List<OracionEjercicio> ejercicios, int index) {
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

  OracionEjercicio get currentEjercicio => _ejercicios[state.ejercicioActual];

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
    if (state.ejercicioActual < _ejercicios.length - 1) {
      state = _estadoInicial(_ejercicios, state.ejercicioActual + 1);
    } else {
      _guardarProgreso();
      state = state.copyWith(juegoFinalizado: true);
    }
  }

  void commandReiniciar() {
    state = _estadoInicial(_ejercicios, state.ejercicioActual);
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

      // Sync inmediata a Firestore para reflejar el progreso en otros dispositivos
      _ref.read(sincronizarUseCaseProvider).ejecutar(estudianteId).ignore();
      _ref.invalidate(menuProgresoProvider);
    } catch (e) {
      debugPrint('Error guardando progreso Oraciones: $e');
    }
  }
}

final oracionesViewModelProvider =
    StateNotifierProvider.autoDispose<OracionesViewModel, OracionesEstado>(
  (ref) => OracionesViewModel(ref),
);