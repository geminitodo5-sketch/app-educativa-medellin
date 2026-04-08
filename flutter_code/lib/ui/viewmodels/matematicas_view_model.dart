import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider para el ViewModel de Matemáticas
final matematicasViewModelProvider = ChangeNotifierProvider<MatematicasViewModel>((ref) {
  return MatematicasViewModel();
});

class MatematicasViewModel extends ChangeNotifier {
  /// Maneja la selección de una lección específica
  void commandSeleccionarLeccion(String nombreLeccion) {
    // Aquí Ingeniería integrará la navegación al UseCase correspondiente
    debugPrint('Navegando a la lección: $nombreLeccion');
  }

  /// Maneja la acción de regresar
  void commandVolver() {
    debugPrint('Comando volver ejecutado');
  }
}