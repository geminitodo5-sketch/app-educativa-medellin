import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// ViewModel para la actividad de hábitats de animales
/// Responsabilidad: Ingeniería
final animalesViewModelProvider = ChangeNotifierProvider.autoDispose(
  (ref) => AnimalesViewModel(),
);

class AnimalesViewModel extends ChangeNotifier {
  // Estado de aciertos por animal
  final Map<String, bool> _aciertos = {'pinguino': false, 'cocodrilo': false};

  Map<String, bool> get aciertos => _aciertos;
  bool get completado => _aciertos.values.every((v) => v);

  /// Valida si el animal corresponde al hábitat
  bool commandValidarHabitat(String animalId, String habitatId) {
    bool esCorrecto = (animalId == habitatId);
    if (esCorrecto) {
      _aciertos[animalId] = true;
      notifyListeners();
    }
    return esCorrecto;
  }

  void commandReproducirInstruccion() {
    debugPrint('Reproduciendo audio: Devuelve a estos animales a su hogar');
  }
}
