// ─────────────────────────────────────────────────────────────
//  lib/ui/views/inicio_view.dart
//  Pantalla de introducción: reproduce intro.mp4 y luego navega.
//  Si existe un estudiante registrado → va al Menú.
//  Si no existe → va a Bienvenida (registro).
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import '../../data/models/estudiante_model.dart';
import '../../data/providers/database_provider.dart';
import '../../data/providers/app_state_provider.dart';
import 'registro_view.dart';
import 'menu_1_y_2_view.dart';
import 'menu_3_a_5_view.dart';

class InicioView extends ConsumerStatefulWidget {
  const InicioView({super.key});

  @override
  ConsumerState<InicioView> createState() => _InicioViewState();
}

class _InicioViewState extends ConsumerState<InicioView> {
  late final Player _player;
  late final VideoController _controller;
  bool _navegando = false;
  bool _inicializado = false;

  @override
  void initState() {
    super.initState();
    _player = Player();
    _controller = VideoController(_player);
    _inicializarVideo();
  }

  Future<void> _inicializarVideo() async {
    try {
      await _player.open(Media('asset:///assets/videos/intro.mp4'));
      _player.stream.completed.listen((completado) {
        if (completado) _navegarSiguiente();
      });
      if (mounted) setState(() => _inicializado = true);
      await _player.play();
    } catch (_) {
      await Future.delayed(const Duration(seconds: 2));
      _navegarSiguiente();
    }
  }

  Future<void> _navegarSiguiente() async {
    if (_navegando || !mounted) return;
    _navegando = true;

    final repo = ref.read(estudianteRepositoryProvider);
    final todos = await repo.listarTodos();

    if (!mounted) return;

    if (todos.isNotEmpty) {
      final estudiante = todos.first;
      await repo.actualizarUltimaSesion(estudiante.id!);
      ref.read(estudianteActivoProvider.notifier).state = estudiante;
      _irAMenuDirecto(estudiante);
    } else {
      _irABienvenida();
    }
  }

  void _irABienvenida() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (ctx, a, _) => const RegistroView(),
        transitionsBuilder: (ctx, anim, _, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  void _irAMenuDirecto(EstudianteModel estudiante) {
    final Widget destino = estudiante.grado <= 2
        ? Menu1Y2Screen(
            nombre: estudiante.nombre,
            avatar: estudiante.personaje,
            nivel: estudiante.grado,
          )
        : const Menu3A5Screen();

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (ctx, a, _) => destino,
        transitionsBuilder: (ctx, anim, _, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _navegarSiguiente,
        child: SizedBox.expand(
          child: _inicializado
              ? Video(
                  controller: _controller,
                  controls: NoVideoControls,
                  fit: BoxFit.cover,
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
