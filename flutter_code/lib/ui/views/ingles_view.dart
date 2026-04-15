// ─────────────────────────────────────────────────────────────
//  lib/ui/views/ingles_view.dart
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../viewmodels/ingles_view_model.dart';

class InglesView extends ConsumerStatefulWidget {
  const InglesView({super.key});

  @override
  ConsumerState<InglesView> createState() => _InglesViewState();
}

class _InglesViewState extends ConsumerState<InglesView> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(inglesViewModelProvider).commandCargarProgreso(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = ref.watch(inglesViewModelProvider);

    return Scaffold(
      body: Stack(
        children: [
          // Fondo
          Positioned.fill(
            child: Image.asset(
              'assets/images/bienvenida/fondos (1).png',
              fit: BoxFit.cover,
              errorBuilder: (ctx, e, _) =>
                  Container(color: const Color(0xFF7BD0E8)),
            ),
          ),

          // Pollito esquina inferior izquierda
          Positioned(
            bottom: 370,
            left: 40,
            child: Image.asset(
              'assets/images/bienvenida/pollo feliz 2 (2).png',
              width: 60,
              fit: BoxFit.contain,
              errorBuilder: (ctx, e, _) => const SizedBox(),
            ),
          ),

          // Mono esquina inferior derecha
          Positioned(
            bottom: -20,
            right: 0,
            child: Image.asset(
              'assets/images/bienvenida/mono.png',
              width: 150,
              fit: BoxFit.contain,
              errorBuilder: (ctx, e, _) => const SizedBox(),
            ),
          ),

          // Contenido principal
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 10),

                // Flecha volver
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 12),
                    child: GestureDetector(
                      onTap: () {
                        vm.commandVolver();
                        Navigator.of(context).maybePop();
                      },
                      child: const Icon(Icons.arrow_back_rounded,
                          size: 35, color: Colors.black87),
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // Título
                const Text(
                  'Inglés',
                  style: TextStyle(
                    fontFamily: 'Hiruko',
                    fontSize: 44,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),

                // Barra de progreso
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 40, vertical: 6),
                  child: _BarraProgreso(
                      porcentaje: vm.progresoTotal,
                      color: const Color(0xFF8B5CF6)),
                ),

                const Spacer(flex: 2),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 35),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _BotonMateria(
                        imagen: 'assets/images/areas/ingles/ingles1.png',
                        texto: 'Escucha',
                        completado: _completado(vm, 'Module 1'),
                        onTap: () => vm.commandSeleccionarLeccion(
                            'Module 1',
                            porcentajeCompletado: 100.0),
                      ),
                      const SizedBox(height: 20),
                      _BotonMateria(
                        imagen: 'assets/images/areas/ingles/ingles2.png',
                        texto: 'Une\nla pareja',
                        completado: _completado(vm, 'Module 2'),
                        onTap: () => vm.commandSeleccionarLeccion(
                            'Module 2',
                            porcentajeCompletado: 100.0),
                      ),
                      const SizedBox(height: 20),
                      _BotonMateria(
                        imagen: 'assets/images/areas/ingles/ingles3.png',
                        texto: 'Tarjetas',
                        completado: _completado(vm, 'Module 3'),
                        onTap: () => vm.commandSeleccionarLeccion(
                            'Module 3',
                            porcentajeCompletado: 100.0),
                      ),
                    ],
                  ),
                ),

                const Spacer(flex: 3),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _completado(InglesViewModel vm, String modulo) =>
      vm.progreso.any((p) => p.actividad == modulo && p.porcentaje >= 100);
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
                style: TextStyle(fontFamily: 'Poppins', fontSize: 12)),
            Text('${porcentaje.toInt()}%',
                style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: (porcentaje / 100).clamp(0.0, 1.0),
            minHeight: 10,
            backgroundColor: Colors.black12,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}

// ─── Botón de módulo ───────────────────────────────────────────
class _BotonMateria extends StatefulWidget {
  final String imagen;
  final String texto;
  final bool completado;
  final VoidCallback onTap;

  const _BotonMateria({
    required this.imagen,
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
    duration: const Duration(milliseconds: 100),
  );
  late final Animation<double> _scale =
      Tween<double>(begin: 1.0, end: 0.95).animate(
          CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));

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
          height: 80,
          decoration: BoxDecoration(
            color: const Color(0xFF8B5CF6),
            borderRadius: BorderRadius.circular(18),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 12,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              // Imagen
              Container(
                margin: const EdgeInsets.all(12),
                width: 65,
                height: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.asset(
                    widget.imagen,
                    fit: BoxFit.contain,
                    errorBuilder: (ctx, e, _) => const Icon(
                        Icons.headphones_rounded,
                        color: Color(0xFF8B5CF6),
                        size: 36),
                  ),
                ),
              ),
              // Texto
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Center(
                    child: Text(
                      widget.texto,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'Hiruko',
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        height: 1.1,
                      ),
                    ),
                  ),
                ),
              ),
              // Indicador
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
