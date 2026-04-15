// ─────────────────────────────────────────────────────────────
//  lib/ui/views/matematicas_view.dart
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../viewmodels/matematicas_view_model.dart';

class MatematicasView extends ConsumerStatefulWidget {
  const MatematicasView({super.key});

  @override
  ConsumerState<MatematicasView> createState() => _MatematicasViewState();
}

class _MatematicasViewState extends ConsumerState<MatematicasView> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(matematicasViewModelProvider).commandCargarProgreso(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = ref.watch(matematicasViewModelProvider);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1EB9D8), Color(0xFF59E347)],
          ),
        ),
        child: Stack(
          children: [
            // Fondo paisaje
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Image.asset(
                'assets/images/interfaz/fondos/fondo.jpg',
                fit: BoxFit.cover,
                errorBuilder: (ctx, e, _) => const SizedBox(),
              ),
            ),

            // Mono abajo derecha
            Positioned(
              bottom: 0,
              right: 0,
              child: Image.asset(
                'assets/images/avatares/avatar_mono1.jpg',
                width: 140,
                errorBuilder: (ctx, e, _) => const SizedBox(),
              ),
            ),

            SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 10),

                  // Flecha volver
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: GestureDetector(
                        onTap: () {
                          vm.commandVolver();
                          Navigator.of(context).maybePop();
                        },
                        child: const Icon(Icons.arrow_back_rounded,
                            size: 36, color: Colors.black),
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Título
                  const Text(
                    'Matemáticas',
                    style: TextStyle(
                      fontFamily: 'Hiruko',
                      fontSize: 38,
                      fontWeight: FontWeight.w900,
                      color: Colors.black,
                    ),
                  ),

                  // Barra de progreso real (actividades completadas / total)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 40, vertical: 4),
                    child: _BarraProgreso(
                      porcentaje: vm.progresoTotal,
                      color: const Color(0xFF3475F7),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Botones + Pollo
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // Pollo detrás
                        Positioned(
                          top: -18,
                          left: 10,
                          child: Image.asset(
                            'assets/images/avatares/pollo feliz 2 (2).png',
                            width: 80,
                            errorBuilder: (ctx, e, _) => const SizedBox(),
                          ),
                        ),

                        Column(
                          children: [
                            const SizedBox(height: 55),
                            _BotonMateria(
                              rutaIcono: 'assets/images/areas/matematicas/Group 40 (1) (1).png',
                              texto: 'Los números',
                              completado: _estaCompletado(vm, 'Los números'),
                              onTap: () => vm.commandSeleccionarLeccion(
                                  'Los números',
                                  porcentajeCompletado: 100.0),
                            ),
                            
                            const SizedBox(height: 14),
                            _BotonMateria(
                              rutaIcono: 'assets/images/areas/matematicas/_ (1) (1).png',
                              texto: 'Quien tiene más',
                              completado: _estaCompletado(vm, 'Quien tiene más'),
                              onTap: () => vm.commandSeleccionarLeccion(
                                  'Quien tiene más',
                                  porcentajeCompletado: 100.0),
                            ),
                            const SizedBox(height: 14),
                            _BotonMateria(
                              rutaIcono: 'assets/images/areas/matematicas/Group 41 (1) (2).png',
                              texto: 'Sumar',
                              completado: _estaCompletado(vm, 'Sumar'),
                              onTap: () => vm.commandSeleccionarLeccion(
                                  'Sumar',
                                  porcentajeCompletado: 100.0),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _estaCompletado(MatematicasViewModel vm, String actividad) {
    return vm.progreso.any(
        (p) => p.actividad == actividad && p.porcentaje >= 100);
  }
}

// ─── Barra de progreso ─────────────────────────────────────────
class _BarraProgreso extends StatelessWidget {
  final double porcentaje;
  final Color color;

  const _BarraProgreso({required this.porcentaje, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Progreso',
                style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    color: Colors.black54)),
            Text('${porcentaje.toInt()}%',
                style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87)),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: (porcentaje / 100).clamp(0.0, 1.0),
            minHeight: 10,
            backgroundColor: Colors.white.withValues(alpha: 0.5),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}

// ─── Botón de lección ──────────────────────────────────────────
class _BotonMateria extends StatefulWidget {
  final String rutaIcono;
  final String texto;
  final bool completado;
  final VoidCallback onTap;

  const _BotonMateria({
    required this.rutaIcono,
    required this.texto,
    required this.completado,
    required this.onTap,
  });

  @override
  State<_BotonMateria> createState() => _BotonMateriaState();
}

class _BotonMateriaState extends State<_BotonMateria>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 80),
  );
  late final Animation<double> _scale =
      Tween<double>(begin: 1.0, end: 0.96).animate(_ctrl);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onTap();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          height: 84,
          decoration: BoxDecoration(
            color: const Color(0xFF3475F7),
            borderRadius: BorderRadius.circular(18),
            boxShadow: const [
              BoxShadow(
                color: Color(0xFF1A4BBF),
                blurRadius: 0,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              // Icono
              Container(
                margin: const EdgeInsets.all(8),
                width: 68,
                height: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(8),
                child: Image.asset(
                  widget.rutaIcono,
                  fit: BoxFit.contain,
                  errorBuilder: (ctx, e, _) => const Icon(
                    Icons.calculate_rounded,
                    color: Color(0xFF3475F7),
                    size: 32,
                  ),
                ),
              ),
              // Texto
              Expanded(
                child: Center(
                  child: Text(
                    widget.texto,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'Hiruko',
                      fontSize: 21,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              // Indicador completado o flecha
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: widget.completado
                    ? const Icon(Icons.check_circle_rounded,
                        color: Colors.white, size: 28)
                    : const Icon(Icons.arrow_forward_ios_rounded,
                        color: Colors.white, size: 22),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
