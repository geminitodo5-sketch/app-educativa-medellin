// ─────────────────────────────────────────────────────────────
//  lib/ui/viewmodels/ingles_view_model.dart
// ─────────────────────────────────────────────────────────────

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/progreso_model.dart';
import '../../data/models/sync_queue_model.dart';
import '../../data/providers/database_provider.dart';
import '../../data/providers/app_state_provider.dart'
    show estudianteActivoProvider;
import '../../ui/views/inlges/ingles_escucha_view.dart';
import '../../ui/views/inlges/ingles_pareja_view.dart';
import '../../ui/views/inlges/ingles_tarjetas_view.dart';

final inglesViewModelProvider = ChangeNotifierProvider<InglesViewModel>((ref) {
  return InglesViewModel(ref);
});

class InglesViewModel extends ChangeNotifier {
  final Ref _ref;
  Function(BuildContext)? _navegador;

  InglesViewModel(this._ref);

  void setNavegador(Function(BuildContext) navegador) {
    _navegador = navegador;
  }

  static const _materia = 'ingles';
  static const _totalActividades = 3;

  int get estudianteId => _ref.read(estudianteActivoProvider)?.id ?? 1;
  int get grado => _ref.read(estudianteActivoProvider)?.grado ?? 1;

  List<ProgresoModel> _progreso = [];
  bool _ocupado = false;
  String? _error;

  List<ProgresoModel> get progreso => _progreso;
  bool get ocupado => _ocupado;
  String? get error => _error;

  double get progresoTotal {
    final suma = _progreso.fold<double>(0, (acc, p) => acc + p.porcentaje);
    return (suma / (_totalActividades * 100.0) * 100.0).clamp(0.0, 100.0);
  }

  Future<void> commandCargarProgreso() async {
    if (_ocupado) return;
    _ocupado = true;
    _error = null;
    notifyListeners();
    try {
      final repo = _ref.read(progresoRepositoryProvider);
      _progreso = await repo.listarPorMateria(
        estudianteId: estudianteId,
        grado: grado,
        materia: _materia,
      );
    } catch (e) {
      _error = 'Error al cargar progreso: $e';
      debugPrint(_error);
    } finally {
      _ocupado = false;
      notifyListeners();
    }
  }

  Future<void> commandSeleccionarLeccion(
    String nombreLeccion, {
    double porcentajeCompletado = 100.0,
  }) async {
    debugPrint('Lección seleccionada: $nombreLeccion');
    try {
      final progresoRepo = _ref.read(progresoRepositoryProvider);
      await progresoRepo.registrarIntento(
        estudianteId: estudianteId,
        grado: grado,
        materia: _materia,
        actividad: nombreLeccion,
        porcentaje: porcentajeCompletado,
      );

      final syncRepo = _ref.read(syncQueueRepositoryProvider);
      await syncRepo.encolar(
        SyncQueueModel(
          tipoAccion: 'progreso',
          payload: jsonEncode({
            'estudiante_id': estudianteId,
            'grado': grado,
            'materia': _materia,
            'actividad': nombreLeccion,
            'porcentaje': porcentajeCompletado,
          }),
          fecha: DateTime.now().toIso8601String(),
        ),
      );

      await commandCargarProgreso();
    } catch (e) {
      _error = 'Error al guardar progreso: $e';
      debugPrint(_error);
      notifyListeners();
    }
  }

  void commandVolver() => debugPrint('Inglés: volver');

  /// Navegar a Escucha (Module 1)
  void commandIrAEscucha(BuildContext context) {
    if (_navegador != null) {
      _navegador!(context);
    } else {
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const InglesEscuchaView()));
    }
  }

  /// Navegar a Une la pareja (Module 2)
  void commandIrAPareja(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const InglesParejaView()));
  }

  /// Navegar a Tarjetas (Module 3)
  void commandIrATarjetas(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const InglesTarjetasView()));
  }
}
