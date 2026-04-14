// ─────────────────────────────────────────────────────────────
//  lib/ui/viewmodels/matematicas_view_model.dart
//  Capa: UI — Responsabilidad: Diseño + Ingeniería
// ─────────────────────────────────────────────────────────────

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/progreso_model.dart';
import '../../data/providers/database_provider.dart';

final matematicasViewModelProvider =
    ChangeNotifierProvider<MatematicasViewModel>((ref) {
  return MatematicasViewModel(ref);
});

class MatematicasViewModel extends ChangeNotifier {
  final Ref _ref;

  MatematicasViewModel(this._ref);

  // ── Estado ──────────────────────────────────────────────────
  static const _materia = 'matematicas';

  /// estudianteId activo (se debe asignar desde PerfilViewModel
  /// o desde la pantalla antes de usar este ViewModel).
  int estudianteId = 1;
  int grado        = 1;

  List<ProgresoModel> _progreso = [];
  bool                _ocupado  = false;
  String?             _error;

  List<ProgresoModel> get progreso => _progreso;
  bool                get ocupado  => _ocupado;
  String?             get error    => _error;

  /// Porcentaje promedio calculado a partir del progreso cargado.
  double get promedioGeneral {
    if (_progreso.isEmpty) return 0.0;
    final suma = _progreso.fold<double>(0, (acc, p) => acc + p.porcentaje);
    return suma / _progreso.length;
  }

  // ── Comandos ────────────────────────────────────────────────

  /// Carga el progreso del estudiante en matemáticas desde la BD.
  Future<void> commandCargarProgreso() async {
    if (_ocupado) return;

    _ocupado = true;
    _error   = null;
    notifyListeners();

    try {
      final repo = _ref.read(progresoRepositoryProvider);
      _progreso = await repo.listarPorMateria(
        estudianteId: estudianteId,
        grado:        grado,
        materia:      _materia,
      );
    } catch (e) {
      _error = 'Error al cargar progreso: $e';
      debugPrint(_error);
    } finally {
      _ocupado = false;
      notifyListeners();
    }
  }

  /// Registra que el estudiante completó una lección con un porcentaje dado.
  Future<void> commandSeleccionarLeccion(String nombreLeccion,
      {double porcentajeCompletado = 0.0}) async {
    debugPrint('Lección seleccionada: $nombreLeccion');
    try {
      final repo = _ref.read(progresoRepositoryProvider);
      await repo.registrarIntento(
        estudianteId: estudianteId,
        grado:        grado,
        materia:      _materia,
        actividad:    nombreLeccion,
        porcentaje:   porcentajeCompletado,
      );
      // Refresca la lista local
      await commandCargarProgreso();
    } catch (e) {
      _error = 'Error al guardar progreso: $e';
      debugPrint(_error);
      notifyListeners();
    }
  }

  /// Maneja la acción de regresar.
  void commandVolver() {
    debugPrint('Comando volver ejecutado');
  }
}
