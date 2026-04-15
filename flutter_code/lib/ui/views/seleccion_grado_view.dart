// ─────────────────────────────────────────────────────────────
//  lib/ui/views/seleccion_grado_view.dart
//  Selección de grado: solo 1° y 2° están activos.
//  Actualiza el grado del estudiante en la BD y navega al menú.
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/providers/database_provider.dart';
import '../../data/providers/app_state_provider.dart';
import 'menu_1_y_2_view.dart';

class SeleccionGradoView extends ConsumerStatefulWidget {
  const SeleccionGradoView({super.key});

  @override
  ConsumerState<SeleccionGradoView> createState() => _SeleccionGradoViewState();
}

class _SeleccionGradoViewState extends ConsumerState<SeleccionGradoView> {
  bool _cargando = false;

  Future<void> _onGradeSelected(int grade) async {
    // Grados 3, 4 y 5 aún no disponibles
    if (grade > 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '¡El $grade° grado estará disponible muy pronto! 🚀',
            style: const TextStyle(fontFamily: 'Hiruko', fontSize: 16),
          ),
          backgroundColor: const Color(0xFF1E293B),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() => _cargando = true);

    try {
      final estudiante = ref.read(estudianteActivoProvider);
      if (estudiante == null) return;

      // Actualiza el grado del estudiante en la BD
      final repo = ref.read(estudianteRepositoryProvider);
      final actualizado = estudiante.copyWith(grado: grade);
      await repo.actualizar(actualizado);
      ref.read(estudianteActivoProvider.notifier).state = actualizado;

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (ctx, a, _) => Menu1Y2Screen(
            nombre: actualizado.nombre,
            avatar: actualizado.personaje,
            nivel: actualizado.grado,
          ),
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
          // Personaje: Pollito (inferior izquierda, cortado)
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

          // Personaje: Monito (inferior derecha, cortado)
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

                // Título
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.0),
                  child: Text(
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
                ),

                SizedBox(height: screenSize.height * 0.05),

                // Cuadrícula de botones
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Column(
                        children: [
                          // Fila 1 y 2 (activos)
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

                          // Fila 3 y 4 (próximamente)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              GradeButton(
                                text: '3°',
                                color: const Color(0xFF59E347),
                                activo: false,
                                onTap: () => _onGradeSelected(3),
                              ),
                              const SizedBox(width: 24),
                              GradeButton(
                                text: '4°',
                                color: const Color(0xFFB41EFF),
                                activo: false,
                                onTap: () => _onGradeSelected(4),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Grado 5 (próximamente)
                          GradeButton(
                            text: '5°',
                            color: const Color(0xFFF65757),
                            activo: false,
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

// ─── Botón de grado ────────────────────────────────────────────
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
