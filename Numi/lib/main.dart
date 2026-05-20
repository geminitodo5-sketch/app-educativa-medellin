import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:media_kit/media_kit.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'data/providers/database_provider.dart';
import 'data/providers/app_state_provider.dart'
    show syncListenerProvider, firestoreSyncListenerProvider,
         progresoRealtimeProvider;
import 'ui/viewmodels/asistente_ia_view_model.dart' show gemmaStartupProvider;
import 'ui/views/inicio_view.dart';

/// Observer global que permite a Menu3A5Screen detectar cuándo se
/// pushea una pantalla encima y pausar la música de fondo.
final RouteObserver<ModalRoute<void>> routeObserver =
    RouteObserver<ModalRoute<void>>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();

  // Inicializa Firebase antes de cualquier otra cosa
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // sqflite necesita FFI en Windows y Linux (no en Android/iOS)
  if (Platform.isWindows || Platform.isLinux) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // Inicializa la BD (crea las tablas si es la primera vez)
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
    // Drena sync_queue legacy al recuperar internet.
    ref.watch(syncListenerProvider);
    // Sincronización bidireccional con Firestore (progreso entre dispositivos).
    ref.watch(firestoreSyncListenerProvider);
    // Listener en tiempo real: actualiza la UI al instante cuando otro
    // dispositivo (misma cuenta) sube progreso a Firestore.
    ref.watch(progresoRealtimeProvider);

    // Inicia verificación/descarga de Gemma 3n E2B en background al abrir la app.
    ref.watch(gemmaStartupProvider);

    return MaterialApp(
      title: 'Numi - App Educativa',
      debugShowCheckedModeBanner: false,
      navigatorObservers: [routeObserver],
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF3475F7)),
        useMaterial3: true,
        fontFamily: 'Hiruko',
      ),
      home: const InicioView(),
    );
  }
}
