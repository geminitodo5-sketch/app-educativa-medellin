// lib/ui/views/ingles_congratulations_view.dart
// Úsala desde cualquier módulo:
//   Navigator.pushReplacement(context,
//     MaterialPageRoute(builder: (_) => const InglesCongratulationsView()));

import 'package:flutter/material.dart';

class InglesCongratulationsView extends StatelessWidget {
  const InglesCongratulationsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final h = constraints.maxHeight;
          final w = constraints.maxWidth;

          return Stack(
            children: [
              // ── Fondo completo ──────────────────────────────────────────
              Positioned.fill(
                child: Image.asset(
                  'assets/images/bienvenida/fondos (1).png',
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) =>
                      Container(color: const Color(0xFF87CEEB)),
                ),
              ),

              // ── Contenido ───────────────────────────────────────────────
              SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Barra superior
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 24, 16, 14),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.maybePop(context),
                            child: const Icon(
                              Icons.arrow_back_rounded,
                              size: 40,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(width: 25),
                          const Text(
                            'Completaste  las\nactividades',
                            style: TextStyle(
                              fontFamily: 'Hiruko',
                              fontSize: 25,
                              fontWeight: FontWeight.w900,
                              color: Colors.black87,
                              height: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Texto congratulations
                    Padding(
                      padding: EdgeInsets.only(top: h * 0.30, left: w * 0.15),
                      child: const Text(
                        '¡Congratulations!',
                        style: TextStyle(
                          fontFamily: 'Hiruko',
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),

                    const Spacer(),
                  ],
                ),
              ),

              // ── Pollo — arriba izquierda, inclinado ─────────────────────
              Positioned(
                right: w * 0.7,
                bottom: h * 0.22,
                child: Transform.rotate(
                  angle: 0.4,
                  child: Image.asset(
                    'assets/images/areas/ingles/pollo gano.png',
                    width: w * 0.38,
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => const SizedBox(),
                  ),
                ),
              ),

              // ── Mono — centro-derecha abajo, grande ─────────────────────
              Positioned(
                left: w * 0.25,
                bottom: h * -0.01,
                child: Image.asset(
                  'assets/images/areas/ingles/mono gano.png',
                  width: w * 0.8,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => const SizedBox(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
