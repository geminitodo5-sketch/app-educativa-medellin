import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../viewmodels/comparacion_cantidades_view_model.dart';
import 'quien_tiene_mas_2.dart';

/// Vista de comparación de cantidades — "¿Quién tiene más?"
/// Responsabilidad: Crosmedia
class ComparacionCantidadesView extends ConsumerWidget {
  const ComparacionCantidadesView({super.key});

  // ─── Feedback de respuesta ─────────────────────────────────────────────────

  void _verificarRespuesta(BuildContext context, WidgetRef ref, String nombre) {
    final notifier = ref.read(comparacionCantidadesViewModelProvider.notifier);
    final state = ref.read(comparacionCantidadesViewModelProvider);

    // Evita re-responder en la misma ronda
    if (state.respondido) return;

    final esCorrecto = notifier.validarSeleccion(nombre);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          esCorrecto
              ? '¡Muy bien! ${state.ganador} tiene más. 🎉'
              : '¡Casi! Cuenta bien las manzanas.',
        ),
        backgroundColor: esCorrecto ? Colors.green : Colors.orange,
        duration: const Duration(seconds: 2),
      ),
    );

    // Si es correcto, pasamos a la fase 2 tras un breve delay
    Future.delayed(const Duration(seconds: 2), () {
      if (context.mounted && esCorrecto) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MenosFrutasview()),
        );
      }
    });
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(comparacionCantidadesViewModelProvider);
    final notifier = ref.read(comparacionCantidadesViewModelProvider.notifier);

    return Scaffold(
      backgroundColor: const Color(0xFF3475F7),
      body: Stack(
        children: [
          // ── Título ──────────────────────────────────────────────────────────
          const Positioned(
            top: 60,
            left: 0,
            right: 0,
            child: Text(
              'Quién tiene más',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontFamily: 'Hiruko',
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // ── Panel blanco principal ──────────────────────────────────────────
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: MediaQuery.of(context).size.height * 0.82,
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(40),
                  topRight: Radius.circular(40),
                ),
              ),
              child: Column(
                children: [
                  // Espacio para que los personajes desborden hacia arriba
                  const SizedBox(height: 50),

                  // ── Tarjetas de personajes ──────────────────────────────────
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.42,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          _PersonCard(
                            color: const Color(0xFFA7F3FF),
                            imagePath:
                                'assets/images/actividades/matematicas/niño.png',
                            cantidadManzanas: state.manzanasJuan,
                          ),
                          const SizedBox(width: 2),
                          _PersonCard(
                            color: const Color(0xFFFFC1C1),
                            imagePath:
                                'assets/images/actividades/matematicas/niña.png',
                            cantidadManzanas: state.manzanasSara,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── Pregunta + Audio ────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 28,
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.volume_up_rounded, size: 50),
                          onPressed: notifier.commandReproducirInstruccion,
                          color: const Color(0xFF1E293B),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Text(
                            'Quién tiene más manzanas',
                            style: TextStyle(
                              fontSize: 19,
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── Botones de selección ────────────────────────────────────
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        _SelectionButton(
                          nombre: 'Juan',
                          imagePath:
                              'assets/images/actividades/matematicas/niño.png',
                          color: const Color(0xFFA7F3FF),
                          onTap: () =>
                              _verificarRespuesta(context, ref, 'Juan'),
                        ),
                        _SelectionButton(
                          nombre: 'Sara',
                          imagePath:
                              'assets/images/actividades/matematicas/niña.png',
                          color: const Color(0xFFFFC1C1),
                          onTap: () =>
                              _verificarRespuesta(context, ref, 'Sara'),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          // ── Personajes desbordando sobre el panel blanco ────────────────────
          // Se posicionan sobre la línea de separación azul/blanca
          Positioned(
            top: MediaQuery.of(context).size.height * 0.25,
            left: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: Center(
                      child: Image.asset(
                        'assets/images/actividades/matematicas/niño.png',
                        height: 130,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Center(
                      child: Image.asset(
                        'assets/images/actividades/matematicas/niña.png',
                        height: 130,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Botón cerrar — esquina superior derecha ─────────────────────────
          Positioned(
            top: 44,
            right: 16,
            child: SafeArea(
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Tarjeta de personaje ──────────────────────────────────────────────────

class _PersonCard extends StatelessWidget {
  const _PersonCard({
    required this.color,
    required this.imagePath,
    required this.cantidadManzanas,
  });

  final Color color;
  final String imagePath;
  final int cantidadManzanas;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(25),
        ),
        // El personaje flota encima (Stack en la vista padre),
        // aquí solo mostramos las manzanas con espacio reservado arriba
        child: Padding(
          padding: const EdgeInsets.only(
            top: 60,
            left: 8,
            right: 8,
            bottom: 10,
          ),
          child: Wrap(
            spacing: 4,
            runSpacing: 4,
            alignment: WrapAlignment.center,
            children: List.generate(
              cantidadManzanas,
              (_) => Image.asset(
                'assets/images/actividades/matematicas/manzana.png',
                width: 34,
                height: 34,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Botón de selección ────────────────────────────────────────────────────

class _SelectionButton extends StatelessWidget {
  const _SelectionButton({
    required this.nombre,
    required this.imagePath,
    required this.color,
    required this.onTap,
  });

  final String nombre;
  final String imagePath;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 130,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              nombre,
              style: const TextStyle(
                fontSize: 20,
                fontFamily: 'Hiruko',
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Image.asset(imagePath, height: 80),
          ],
        ),
      ),
    );
  }
}
