import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/providers/app_state_provider.dart';
import '../../data/providers/racha_provider.dart';

class ActividadTerminadaScreen extends ConsumerStatefulWidget {
  final VoidCallback? onVolver;

  const ActividadTerminadaScreen({super.key, this.onVolver});

  @override
  ConsumerState<ActividadTerminadaScreen> createState() =>
      _ActividadTerminadaScreenState();
}

class _ActividadTerminadaScreenState
    extends ConsumerState<ActividadTerminadaScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _fadeAnim = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
    );

    _slideAnim = Tween<Offset>(
      begin: const Offset(0, -0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
    ));

    _scaleAnim = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 1.0, curve: Curves.elasticOut),
      ),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _verificarRacha();
      }
    });

    _controller.forward();
  }

  Future<void> _verificarRacha() async {
    final estudiante = ref.read(estudianteActivoProvider);
    // Solo aplica para grados 1 y 2
    if (estudiante?.id == null || estudiante!.grado > 2 || !mounted) return;
    final svc = ref.read(rachaServiceProvider);
    final info = await svc.verificarRacha(estudiante.id!);
    // Guarda la racha pendiente; el menú la mostrará al volver
    if (info != null && mounted) {
      ref.read(rachaPendienteProvider.notifier).state = info;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── 1. FONDO completo ──────────────────────────────────
          Image.asset(
            'assets/images/actividad_terminada/fondo.png',
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF4DD8EE),
                    Color(0xFF1EB9D8),
                    Color(0xFF52C234),
                  ],
                  stops: [0.0, 0.6, 1.0],
                ),
              ),
            ),
          ),

          // ── 2. CONTENIDO ──────────────────────────────────────
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Barra superior ──
                _buildTopBar(),

                // ── Texto ¡Felicitaciones! ──
                const Spacer(flex: 2),
                _buildTitulo(),
                const Spacer(flex: 3),

                // ── Personajes ──
                _buildPersonajes(context),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: widget.onVolver ?? () => Navigator.of(context).pop(),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.25),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Completaste \nlas actividades',
              style: TextStyle(
                fontFamily: 'Hiruko',
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black,
                shadows: [
                  Shadow(
                    color: Colors.black26,
                    offset: Offset(0, 1),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitulo() {
    return SlideTransition(
      position: _slideAnim,
      child: FadeTransition(
        opacity: _fadeAnim,
        child: const Center(
          child: Text(
            '¡Felicitaciones!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Hiruko',
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: Colors.black,
              shadows: [
                Shadow(
                  color: Colors.black26,
                  offset: Offset(0, 2),
                  blurRadius: 6,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPersonajes(BuildContext context) {
    final double w = MediaQuery.of(context).size.width;
    final double h = MediaQuery.of(context).size.height;

    return ScaleTransition(
      scale: _scaleAnim,
      child: SizedBox(
        height: h * 0.38,
        width: double.infinity,
        child: Stack(
          alignment: Alignment.bottomCenter,
          clipBehavior: Clip.none,
          children: [
            // Mono (derecha, más grande)
            Positioned(
              left: w * 0.25,
              bottom: h * -0.01,
              child: Image.asset(
                'assets/images/areas/ingles/mono gano.png',
                width: w * 0.8,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const SizedBox(),
              ),
            ),

            // Pollo (izquierda, ligeramente más pequeño)
            Positioned(
              right: w * 0.7,
              bottom: h * 0.22,
              child: Transform.rotate(
                angle: 0.4,
                child: Image.asset(
                  'assets/images/areas/ingles/pollo gano.png',
                  width: w * 0.38,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const SizedBox(),
                ),
              ),
            ),

            // Corazones decorativos flotantes
            const Positioned(
              left: 80,
              bottom: 180,
              child: _CorazonFlotante(size: 18, color: Color(0xFFFF4D6D)),
            ),
            const Positioned(
              right: 90,
              bottom: 220,
              child: _CorazonFlotante(size: 14, color: Color(0xFFFF4D6D)),
            ),
            const Positioned(
              right: 55,
              bottom: 170,
              child: _CorazonFlotante(size: 10, color: Color(0xFFFF4D6D)),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Widget auxiliar: corazón decorativo ────────────────────────

class _CorazonFlotante extends StatelessWidget {
  final double size;
  final Color color;

  const _CorazonFlotante({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Icon(Icons.favorite, size: size, color: color);
  }
}
