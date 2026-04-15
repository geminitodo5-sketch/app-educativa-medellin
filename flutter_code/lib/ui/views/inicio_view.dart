// ─────────────────────────────────────────────────────────────
//  lib/ui/views/inicio_view.dart
//  Pantalla de introducción: reproduce inicio.mp4 y luego navega.
//  Si existe un estudiante registrado → va al Menú.
//  Si no existe → va a Bienvenida (registro).
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import '../../data/models/estudiante_model.dart';
import '../../data/providers/database_provider.dart';
import '../../data/providers/app_state_provider.dart';
import 'bienvenida.dart';
import 'menu_1_y_2_view.dart';

class InicioView extends ConsumerStatefulWidget {
  const InicioView({super.key});

  @override
  ConsumerState<InicioView> createState() => _InicioViewState();
}

class _InicioViewState extends ConsumerState<InicioView> {
  VideoPlayerController? _controller;
  bool _navegando = false;

  @override
  void initState() {
    super.initState();
    _inicializarVideo();
  }

  Future<void> _inicializarVideo() async {
    try {
      final ctrl = VideoPlayerController.asset('assets/videos/intro.mp4');
      await ctrl.initialize();
      if (!mounted) return;
      setState(() => _controller = ctrl);
      ctrl.addListener(_escucharVideo);
      ctrl.play();
    } catch (_) {
      // Si el video falla, navega directamente después de un breve delay
      await Future.delayed(const Duration(seconds: 2));
      _navegarSiguiente();
    }
  }

  void _escucharVideo() {
    final ctrl = _controller;
    if (ctrl == null) return;
    final pos = ctrl.value.position;
    final dur = ctrl.value.duration;
    if (dur.inMilliseconds > 0 && pos >= dur - const Duration(milliseconds: 200)) {
      _navegarSiguiente();
    }
  }

  Future<void> _navegarSiguiente() async {
    if (_navegando || !mounted) return;
    _navegando = true;

    // Verifica si hay un estudiante registrado
    final repo = ref.read(estudianteRepositoryProvider);
    final todos = await repo.listarTodos();

    if (!mounted) return;

    if (todos.isNotEmpty) {
      // Ya existe un estudiante → cargar sesión y ir al menú
      final estudiante = todos.first;
      await repo.actualizarUltimaSesion(estudiante.id!);
      ref.read(estudianteActivoProvider.notifier).state = estudiante;
      _irAMenuDirecto(estudiante);
    } else {
      // Primera vez → registro
      _irABienvenida();
    }
  }

  void _irABienvenida() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (ctx, a, _) => const WelcomeScreen(),
        transitionsBuilder: (ctx, anim, _, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  void _irAMenuDirecto(EstudianteModel estudiante) {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (ctx, a, _) => Menu1Y2Screen(
          nombre: estudiante.nombre,
          avatar: estudiante.personaje,
          nivel: estudiante.grado,
        ),
        transitionsBuilder: (ctx, anim, _, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  void dispose() {
    _controller?.removeListener(_escucharVideo);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = _controller;

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _navegarSiguiente,
        child: SizedBox.expand(
          child: ctrl != null && ctrl.value.isInitialized
              ? FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: ctrl.value.size.width,
                    height: ctrl.value.size.height,
                    child: VideoPlayer(ctrl),
                  ),
                )
              : const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'numi',
                        style: TextStyle(
                          fontFamily: 'Hiruko',
                          fontSize: 64,
                          color: Colors.white,
                          letterSpacing: 4,
                        ),
                      ),
                      SizedBox(height: 24),
                      CircularProgressIndicator(color: Colors.white),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
