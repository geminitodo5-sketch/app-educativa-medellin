import 'package:flutter/foundation.dart';

class PerfilViewModel extends ChangeNotifier {
  // Estado del ViewModel
  bool _ocupado = false;
  bool get ocupado => _ocupado;

  // Comandos que responden a eventos de la vista
  void commandCargarDatos() async {
    _ocupado = true;
    notifyListeners();

    // Aquí iría la llamada a un UseCase (Dominio)
    await Future.delayed(const Duration(seconds: 1)); // Simulación

    _ocupado = false;
    notifyListeners();
  }
}