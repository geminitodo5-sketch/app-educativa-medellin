import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Definición del provider para este ViewModel - Responsabilidad de Ingeniería
final perfilViewModelProvider = ChangeNotifierProvider<PerfilViewModel>((ref) {
  return PerfilViewModel();
});

class PerfilViewModel extends ChangeNotifier {
  // Estado del ViewModel
  bool _ocupado = false;
  bool get ocupado => _ocupado;

  // Comandos que responden a eventos de la vista
  void commandCargarDatos() async {
    if (_ocupado) return; // Evita ejecuciones duplicadas

    _ocupado = true;
    notifyListeners();

    // Aquí iría la llamada a un UseCase (Dominio)
    await Future.delayed(const Duration(seconds: 1)); // Simulación

    _ocupado = false;
    notifyListeners();
  }
}