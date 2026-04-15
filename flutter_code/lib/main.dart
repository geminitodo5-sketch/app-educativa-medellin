import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:media_kit/media_kit.dart';
import 'data/providers/database_provider.dart';
import 'data/providers/app_state_provider.dart';
import 'ui/views/inicio_view.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();

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

/// Widget raíz. Usa ConsumerWidget para:
///   1. Activar el listener de sync offline→backend (vive toda la sesión).
///   2. Acceder al tema/estado global si hace falta en el futuro.
class AppEducativa extends ConsumerWidget {
  const AppEducativa({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Activa el stream que escucha conectividad y drena sync_queue
    // cuando el dispositivo recupera internet.
    ref.watch(syncListenerProvider);

    return MaterialApp(
      title: 'Numi - App Educativa',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF3475F7)),
        useMaterial3: true,
        fontFamily: 'Hiruko',
      ),
      home: const InicioView(),
    );
  }
}
