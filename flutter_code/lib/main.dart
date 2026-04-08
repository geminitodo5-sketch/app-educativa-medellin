import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'ui/views/menu_principal.dart';

void main() {
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
      home: const MenuPrincipal(),
    );
  }
}