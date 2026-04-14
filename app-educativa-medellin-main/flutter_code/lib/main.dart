import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'data/providers/database_provider.dart';
import 'ui/views/menu_principal.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // sqflite necesita FFI en Windows y Linux (no en Android/iOS)
  if (Platform.isWindows || Platform.isLinux) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // Inicializa la BD (crea las 7 tablas si es la primera vez)
  final container = ProviderContainer();
  await container.read(sqliteServiceProvider).database;
  container.dispose();

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
