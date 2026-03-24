import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'ui/views/perfil_view.dart';

void main() {
  // Inicializamos Riverpod con ProviderScope
  runApp(const ProviderScope(child: AppEducativa()));
}

class AppEducativa extends StatelessWidget {
  const AppEducativa({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'App Educativa Medellín',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      // Punto de entrada temporal según la lista de vistas disponibles
      home: const PerfilView(),
    );
  }
}
