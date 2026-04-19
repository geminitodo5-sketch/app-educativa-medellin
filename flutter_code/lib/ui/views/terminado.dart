import 'package:flutter/material.dart';

class ActividadTerminadaScreen extends StatefulWidget {
  final VoidCallback? onVolver;

  const ActividadTerminadaScreen({super.key, this.onVolver});

  @override
  State<ActividadTerminadaScreen> createState() =>
      _ActividadTerminadaScreenState();
}

class _ActividadTerminadaScreenState extends State<ActividadTerminadaScreen>
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

    _controller.forward();
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
                _buildPersonajes(),

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
              'Completaste las actividades',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
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
              color: Colors.white,
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

  Widget _buildPersonajes() {
    return ScaleTransition(
      scale: _scaleAnim,
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.38,
        width: double.infinity,
        child: Stack(
          alignment: Alignment.bottomCenter,
          clipBehavior: Clip.none,
          children: [
            // Mono (derecha, más grande)
            Positioned(
              right: 16,
              bottom: 0,
              child: Image.asset(
                'assets/images/actividad_terminada/mono_gano.png',
                height: MediaQuery.of(context).size.height * 0.34,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const SizedBox(
                  height: 200,
                  width: 140,
                  child: Icon(Icons.emoji_emotions, size: 80, color: Colors.white),
                ),
              ),
            ),

            // Pollo (izquierda, ligeramente más pequeño)
            Positioned(
              left: 0,
              bottom: 10,
              child: Image.asset(
                'assets/images/actividad_terminada/pollo_gano.png',
                height: MediaQuery.of(context).size.height * 0.26,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const SizedBox(
                  height: 160,
                  width: 120,
                  child: Icon(Icons.emoji_nature, size: 70, color: Colors.white),
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