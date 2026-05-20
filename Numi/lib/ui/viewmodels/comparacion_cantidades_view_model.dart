import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/sync_queue_model.dart';
import '../../data/providers/database_provider.dart';
import '../../data/providers/app_state_provider.dart';

/// Estado inmutable de la pantalla de comparación de cantidades
class ComparacionCantidadesState {
  final int manzanasJuan;
  final int manzanasSara;
  final bool?
  respuestaCorrecta; // null = sin responder, true = correcto, false = incorrecto
  final bool respondido;

  const ComparacionCantidadesState({
    required this.manzanasJuan,
    required this.manzanasSara,
    this.respuestaCorrecta,
    this.respondido = false,
  });

  /// Nombre del personaje que tiene más manzanas
  String get ganador {
    if (manzanasJuan > manzanasSara) return 'Juan';
    if (manzanasSara > manzanasJuan) return 'Sara';
    return 'Empate';
  }

  ComparacionCantidadesState copyWith({
    int? manzanasJuan,
    int? manzanasSara,
    bool? respuestaCorrecta,
    bool? respondido,
  }) {
    return ComparacionCantidadesState(
      manzanasJuan: manzanasJuan ?? this.manzanasJuan,
      manzanasSara: manzanasSara ?? this.manzanasSara,
      respuestaCorrecta: respuestaCorrecta ?? this.respuestaCorrecta,
      respondido: respondido ?? this.respondido,
    );
  }
}

/// ViewModel para la pantalla "¿Quién tiene más?"
///
/// Responsabilidades:
///  - Generar cantidades aleatorias distintas (máx. 12) para cada personaje
///  - Validar la selección del usuario
///  - Exponer comandos para reproducir instrucción de audio
///  - Permitir reiniciar el juego con nuevas cantidades
class ComparacionCantidadesViewModel
    extends StateNotifier<ComparacionCantidadesState> {
  final Ref _ref;
  final Random _random = Random();

  ComparacionCantidadesViewModel(this._ref)
    : super(_generarEstadoInicial(Random()));

  // ─── Generadores ────────────────────────────────────────────────────────────

  /// Genera un estado inicial con cantidades aleatorias distintas entre 1 y 12
  static ComparacionCantidadesState _generarEstadoInicial(Random rnd) {
    final cantidades = _cantidadesAleatorias(rnd);
    return ComparacionCantidadesState(
      manzanasJuan: cantidades[0],
      manzanasSara: cantidades[1],
    );
  }

  /// Devuelve dos enteros distintos en [1, 12]
  static List<int> _cantidadesAleatorias(Random rnd) {
    int a = rnd.nextInt(12) + 1; // 1..12
    int b;
    do {
      b = rnd.nextInt(12) + 1;
    } while (b == a); // garantiza que sean distintos
    return [a, b];
  }

  // ─── Accesors de conveniencia ────────────────────────────────────────────────

  int get manzanasJuan => state.manzanasJuan;
  int get manzanasSara => state.manzanasSara;
  bool? get respuestaCorrecta => state.respuestaCorrecta;
  bool get respondido => state.respondido;
  String get ganador => state.ganador;

  // ─── Comandos ────────────────────────────────────────────────────────────────

  /// Valida si el [nombre] seleccionado es el que tiene más manzanas.
  /// Retorna `true` si la respuesta es correcta.
  bool validarSeleccion(String nombre) {
    if (state.respondido) return state.respuestaCorrecta ?? false;

    final esGanador = nombre == state.ganador;
    state = state.copyWith(respuestaCorrecta: esGanador, respondido: true);
    return esGanador;
  }

  /// Genera una nueva ronda con cantidades aleatorias distintas
  void commandNuevaRonda() {
    final cantidades = _cantidadesAleatorias(_random);
    state = ComparacionCantidadesState(
      manzanasJuan: cantidades[0],
      manzanasSara: cantidades[1],
    );
  }

  /// Comando para reproducir la instrucción de audio
  /// Conecta con el servicio de TTS / audio de la app
  void commandReproducirInstruccion() {
    // TODO: integrar AudioService o flutter_tts
    // AudioService.play('quien_tiene_mas_manzanas');
  }

  /// Registra en SQLite que la actividad se completó al 100%
  /// y encola la sincronización para el servidor (Offline-first).
  Future<void> commandGuardarProgresoFinal(String actividad) async {
    final estudiante = _ref.read(estudianteActivoProvider);
    if (estudiante == null) return;

    try {
      // 1. Persistencia local en SQLite (Capa Datos)
      await _ref
          .read(progresoRepositoryProvider)
          .registrarIntento(
            estudianteId: estudiante.id!,
            grado: estudiante.grado,
            materia: 'matematicas',
            actividad: actividad,
            porcentaje: 100,
          );

      // 2. Encolar para sincronización (Offline-first)
      final syncRepo = _ref.read(syncQueueRepositoryProvider);
      await syncRepo.encolar(
        SyncQueueModel(
          tipoAccion: 'progreso',
          payload: jsonEncode({
            'estudiante_id': estudiante.id,
            'grado': estudiante.grado,
            'materia': 'matematicas',
            'actividad': actividad,
            'porcentaje': 100.0,
          }),
          fecha: DateTime.now().toIso8601String(),
        ),
      );

      // Sync inmediata a Firestore para reflejar el progreso en otros dispositivos
      _ref.read(sincronizarUseCaseProvider).ejecutar(estudiante.id!).ignore();
      _ref.invalidate(menuProgresoProvider);
    } catch (e) {
      debugPrint('Error al guardar progreso de comparación: $e');
    }
  }
}

// ─── Provider ────────────────────────────────────────────────────────────────

final comparacionCantidadesViewModelProvider =
    StateNotifierProvider<
      ComparacionCantidadesViewModel,
      ComparacionCantidadesState
    >((ref) => ComparacionCantidadesViewModel(ref));
