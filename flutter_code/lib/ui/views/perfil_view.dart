import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../viewmodels/perfil_view_model.dart';

// Definición del provider para este ViewModel
final perfilViewModelProvider = ChangeNotifierProvider<PerfilViewModel>((ref) {
  return PerfilViewModel();
});

class PerfilView extends ConsumerWidget {
  const PerfilView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Escuchamos cambios en el ViewModel
    final viewModel = ref.watch(perfilViewModelProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil del Estudiante'),
      ),
      body: Center(
        child: viewModel.ocupado
            ? const CircularProgressIndicator()
            : ElevatedButton(
                onPressed: () => ref.read(perfilViewModelProvider).commandCargarDatos(),
                child: const Text('Simular Carga de Datos'),
              ),
      ),
    );
  }
}