import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/progreso_model.dart';
import '../../data/models/sync_queue_model.dart';
import '../../data/providers/database_provider.dart';
import '../../data/providers/app_state_provider.dart'
    show estudianteActivoProvider, menuProgresoProvider;

final espanolViewModelProvider =
    ChangeNotifierProvider<EspanolViewModel>((ref) {
  return EspanolViewModel(ref);
});

class EspanolViewModel extends ChangeNotifier {
  final Ref _ref;

  EspanolViewModel(this._ref);

  static const _materia = 'español';

  /// Palabra loca, Arma la palabra, Oraciones
  static const _totalActividades = 3;

  int get estudianteId => _ref.read(estudianteActivoProvider)?.id ?? 1;
  int get grado => _ref.read(estudianteActivoProvider)?.grado ?? 1;

  List<ProgresoModel> _progreso = [];
  bool _ocupado = false;
  String? _error;

  List<ProgresoModel> get progreso => _progreso;
  bool get ocupado => _ocupado;
  String? get error => _error;

  /// Porcentaje real: suma / (total × 100) × 100
  double get progresoTotal {
    final suma =
        _progreso.fold<double>(0, (acc, p) => acc + p.porcentaje);
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

  Future<void> commandSeleccionarActividad(String nombre,
      {double porcentaje = 100.0}) async {
    try {
      final progresoRepo = _ref.read(progresoRepositoryProvider);
      await progresoRepo.registrarIntento(
        estudianteId: estudianteId,
        grado: grado,
        materia: _materia,
        actividad: nombre,
        porcentaje: porcentaje,
      );

      final syncRepo = _ref.read(syncQueueRepositoryProvider);
      await syncRepo.encolar(SyncQueueModel(
        tipoAccion: 'progreso',
        payload: jsonEncode({
          'estudiante_id': estudianteId,
          'grado': grado,
          'materia': _materia,
          'actividad': nombre,
          'porcentaje': porcentaje,
        }),
        fecha: DateTime.now().toIso8601String(),
      ));

      // Sync inmediata a Firestore para reflejar el progreso en otros dispositivos
      _ref.read(sincronizarUseCaseProvider).ejecutar(estudianteId).ignore();
      _ref.invalidate(menuProgresoProvider);
      await commandCargarProgreso();
    } catch (e) {
      _error = 'Error al guardar progreso: $e';
      debugPrint(_error);
      notifyListeners();
    }
  }

  void commandVolver() => debugPrint('Español: volver');
}
