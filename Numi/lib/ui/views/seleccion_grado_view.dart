import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import '../../data/providers/database_provider.dart';
import '../../data/providers/app_state_provider.dart';
import '../../data/providers/musica_provider.dart';
import 'menu_1_y_2_view.dart';
import 'menu_3_a_5_view.dart';

class SeleccionGradoView extends ConsumerStatefulWidget {
  const SeleccionGradoView({super.key});

  @override
  ConsumerState<SeleccionGradoView> createState() => _SeleccionGradoViewState();
}

class _SeleccionGradoViewState extends ConsumerState<SeleccionGradoView> {
  bool _cargando = false;

  AudioPlayer? _player;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    Future.microtask(() => _reproducirAudio());
    ref.read(musicaServiceProvider).entrar();
  }

  Future<void> _reproducirAudio() async {
    try {
      await _player?.setAsset('assets/Audio/sociales/audio_generalsi_mezcla_fix.mp3');
      await _player?.play();
    } catch (e) {
      debugPrint('Error reproduciendo audio: $e');
    }
  }

  @override
  void dispose() {
    ref.read(musicaServiceProvider).salir();
    _player?.dispose();
    super.dispose();
  }

  Future<void> _onGradeSelected(int grade) async {
    setState(() => _cargando = true);

    try {
      final estudiante = ref.read(estudianteActivoProvider);
      if (estudiante == null) return;

      final repo = ref.read(estudianteRepositoryProvider);
      final actualizado = estudiante.copyWith(grado: grade);
      await repo.actualizar(actualizado);
      ref.read(estudianteActivoProvider.notifier).state = actualizado;

      if (!mounted) return;

      // Grados 1 y 2 → menú de actividades
      // Grados 3, 4 y 5 → menú del asistente RAG
      final destino = grade <= 2
          ? Menu1Y2Screen(
              nombre: actualizado.nombre,
              avatar: actualizado.personaje,
              nivel: actualizado.grado,
            )
          : const Menu3A5Screen();

      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (ctx, a, _) => destino,
          transitionsBuilder: (ctx, anim, _, child) =>
              FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 400),
        ),
      );
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final characterWidth = screenSize.width * 0.45;
    final characterHeight = characterWidth * 1.2;

    return Scaffold(
      backgroundColor: const Color(0xFFA1E7E6),
      body: Stack(
        children: [
          // Personaje: Pollito (inferior izquierda)
          Positioned(
            left: -20,
            bottom: -(characterHeight * 0.4),
            child: SizedBox(
              width: characterWidth,
              height: characterHeight,
              child: Image.asset(
                'assets/images/bienvenida/pollo1.png',
                fit: BoxFit.contain,
                errorBuilder: (ctx, e, _) => Image.asset(
                  'assets/images/bienvenida/pollo feliz 2 (2).png',
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),

          // Personaje: Monito (inferior derecha)
          Positioned(
            right: -20,
            bottom: -(characterHeight * 0.4),
            child: SizedBox(
              width: characterWidth,
              height: characterHeight,
              child: Image.asset(
                'assets/images/bienvenida/mono.png',
                fit: BoxFit.contain,
              ),
            ),
          ),

          // Indicador de carga global
          if (_cargando)
            const Positioned.fill(
              child: ColoredBox(
                color: Colors.black26,
                child: Center(
                  child: CircularProgressIndicator(color: Color(0xFF3475F7)),
                ),
              ),
            ),

          // Contenido principal
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: screenSize.height * 0.06),

                // ── Título + ícono altavoz pegado ───────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Enunciado
                      const Text(
                        '¿A qué grado perteneces?',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Hiruko',
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      GestureDetector(
                        onTap: _reproducirAudio,
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE3F2FD),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.volume_up_rounded,
                            color: Color(0xFF1E293B),
                            size: 22,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // ───────────────────────────────────────────────

                SizedBox(height: screenSize.height * 0.04),

                // Cuadrícula de botones
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Column(
                        children: [
                          // Fila 1° y 2° (activos)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              GradeButton(
                                text: '1°',
                                color: const Color(0xFF3475F7),
                                activo: true,
                                onTap: () => _onGradeSelected(1),
                              ),
                              const SizedBox(width: 24),
                              GradeButton(
                                text: '2°',
                                color: const Color(0xFFEFA825),
                                activo: true,
                                onTap: () => _onGradeSelected(2),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Fila 3° y 4°
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              GradeButton(
                                text: '3°',
                                color: const Color(0xFF59E347),
                                activo: true,
                                onTap: () => _onGradeSelected(3),
                              ),
                              const SizedBox(width: 24),
                              GradeButton(
                                text: '4°',
                                color: const Color(0xFFB41EFF),
                                activo: true,
                                onTap: () => _onGradeSelected(4),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Grado 5°
                          GradeButton(
                            text: '5°',
                            color: const Color(0xFFF65757),
                            activo: true,
                            onTap: () => _onGradeSelected(5),
                          ),

                          SizedBox(height: characterHeight * 0.6 + 40),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class GradeButton extends StatefulWidget {
  final String text;
  final Color color;
  final bool activo;
  final VoidCallback onTap;

  const GradeButton({
    super.key,
    required this.text,
    required this.color,
    required this.activo,
    required this.onTap,
  });

  @override
  State<GradeButton> createState() => _GradeButtonState();
}

class _GradeButtonState extends State<GradeButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final double maxSize = (MediaQuery.of(context).size.width - 40 - 24) / 2;
    final double size = maxSize > 140 ? 140 : maxSize;

    return GestureDetector(
      onTapDown: widget.activo ? (_) => setState(() => _isPressed = true) : null,
      onTapUp: widget.activo
          ? (_) {
              setState(() => _isPressed = false);
              Future.delayed(const Duration(milliseconds: 150), widget.onTap);
            }
          : null,
      onTapCancel: widget.activo ? () => setState(() => _isPressed = false) : null,
      onTap: !widget.activo ? widget.onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        width: size,
        height: size,
        transform: _isPressed
            ? (Matrix4.diagonal3Values(0.94, 0.94, 1.0))
            : Matrix4.identity(),
        transformAlignment: Alignment.center,
        decoration: BoxDecoration(
          color: widget.activo
              ? widget.color
              : widget.color.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(size * 0.22),
          boxShadow: _isPressed || !widget.activo
              ? []
              : [
                  const BoxShadow(
                    color: Colors.black26,
                    offset: Offset(0, 6),
                    blurRadius: 4,
                  ),
                ],
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              widget.text,
              style: TextStyle(
                fontSize: 52,
                fontWeight: FontWeight.w800,
                color: widget.activo
                    ? const Color(0xFF1C1C1C)
                    : const Color(0xFF1C1C1C).withValues(alpha: 0.4),
              ),
            ),
            if (!widget.activo)
              Text(
                'Pronto',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
          ],
        ),
      ),
    );
  }
}