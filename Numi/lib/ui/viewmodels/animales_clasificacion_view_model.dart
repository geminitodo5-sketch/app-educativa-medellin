import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// ViewModel para la clasificación de animales (Domésticos/Salvajes)
/// Capa: UI (Ingeniería/Lógica de estado)
final animalesClasificacionViewModelProvider = ChangeNotifierProvider.autoDispose(
  (ref) => AnimalesClasificacionViewModel(),
);

class AnimalesClasificacionViewModel extends ChangeNotifier {
  bool _respondido = false;
  bool get respondido => _respondido;

  /// Valida si el animal seleccionado pertenece a la categoría correcta
  bool validarRespuesta(String seleccion) {
    final correcto = seleccion == 'domestico';
    if (correcto) {
      _respondido = true;
      notifyListeners();
    }
    return correcto;
  }

  void commandReproducirInstruccion() {
    debugPrint(
      'Reproduciendo: Decide si estos animales son domésticos o salvajes',
    );
  }
}
