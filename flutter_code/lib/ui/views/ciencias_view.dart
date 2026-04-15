// ─────────────────────────────────────────────────────────────
//  lib/ui/views/ciencias_view.dart
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../viewmodels/ciencias_view_model (1).dart';

class CienciasView extends ConsumerStatefulWidget {
  const CienciasView({super.key});

  @override
  ConsumerState<CienciasView> createState() => _CienciasViewState();
}

class _CienciasViewState extends ConsumerState<CienciasView> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(cienciasViewModelProvider).commandCargarProgreso(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = ref.watch(cienciasViewModelProvider);

    return Scaffold(
      body: Stack(
        children: [
          // Fondo
          Positioned.fill(
            child: Image.asset(
              'assets/images/bienvenida/fondos (1).png',
              fit: BoxFit.cover,
              errorBuilder: (ctx, e, _) => Container(color: const Color(0xFFE0F7FA)),
            ),
          ),

          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 10),

                // Flecha volver
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 16),
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
                  'Ciencias\nnaturales',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Hiruko',
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),

                // Barra de progreso
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 40, vertical: 6),
                  child: _BarraProgreso(
                      porcentaje: vm.progresoTotal,
                      color: const Color(0xFF3DCC52)),
                ),

                const SizedBox(height: 16),

                // Tarjetas de temas
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(
                    children: [
                      _BotonTema(
                        imagen: 'assets/images/areas/ciencias_naturales/Group 42 (1).png',
                        texto: '¿Vivo o no\nVivo?',
                        completado: _completado(vm, '¿Vivo o no Vivo?'),
                        onTap: () => vm.commandSeleccionarTema(
                            '¿Vivo o no Vivo?',
                            porcentajeCompletado: 100.0),
                      ),
                      const SizedBox(height: 14),
                      _BotonTema(
                        imagen: 'assets/images/areas/ciencias_naturales/h1 2 (1).png',
                        texto: 'Cuerpo\nhumano',
                        completado: _completado(vm, 'Cuerpo humano'),
                        onTap: () => vm.commandSeleccionarTema(
                            'Cuerpo humano',
                            porcentajeCompletado: 100.0),
                      ),
                      const SizedBox(height: 14),
                      _BotonTema(
                        imagen: 'assets/images/areas/ciencias_naturales/Group 43 (1).png',
                        texto: 'Animales',
                        completado: _completado(vm, 'Animales'),
                        rellenar: true,
                        onTap: () => vm.commandSeleccionarTema(
                            'Animales',
                            porcentajeCompletado: 100.0),
                      ),
                      const SizedBox(height: 14),
                      _BotonTema(
                        imagen: 'assets/images/areas/ciencias_naturales/Group 44 (1).png',
                        texto: 'Las\nplantas',
                        completado: _completado(vm, 'Las plantas'),
                        onTap: () => vm.commandSeleccionarTema(
                            'Las plantas',
                            porcentajeCompletado: 100.0),
                      ),
                    ],
                  ),
                ),

                const Spacer(),
              ],
            ),
          ),

          // Pollito esquina inferior derecha
          Positioned(
            bottom: -20,
            left: 30,
            child: Image.asset(
              'assets/images/avatares/pollo feliz 2 (2).png',
              width: 85,
              errorBuilder: (ctx, e, _) => const SizedBox(),
            ),
          ),
        ],
      ),
    );
  }

  bool _completado(CienciasViewModel vm, String tema) =>
      vm.progreso.any((p) => p.actividad == tema && p.porcentaje >= 100);
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

// ─── Botón de tema ─────────────────────────────────────────────
class _BotonTema extends StatefulWidget {
  final String imagen;
  final String texto;
  final bool completado;
  final VoidCallback onTap;
  final bool rellenar;

  const _BotonTema({
    required this.imagen,
    required this.texto,
    required this.completado,
    required this.onTap,
    this.rellenar = false,
  });

  @override
  State<_BotonTema> createState() => _BotonTemaState();
}

class _BotonTemaState extends State<_BotonTema>
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
          height: 60,
          decoration: BoxDecoration(
            color: const Color(0xFF3DCC52),
            borderRadius: BorderRadius.circular(15),
            boxShadow: const [
              BoxShadow(
                color: Color(0xFF22A45D),
                blurRadius: 0,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // Imagen
              Container(
                margin: const EdgeInsets.all(5),
                width: 80,
                height: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F7FA),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: widget.rellenar
                      ? Image.asset(widget.imagen,
                          fit: BoxFit.cover,
                          errorBuilder: (ctx, e, _) => const Icon(
                              Icons.science_rounded,
                              color: Color(0xFF3DCC52)))
                      : Padding(
                          padding: const EdgeInsets.all(8),
                          child: Image.asset(widget.imagen,
                              fit: BoxFit.contain,
                              errorBuilder: (ctx, e, _) => const Icon(
                                  Icons.science_rounded,
                                  color: Color(0xFF3DCC52))),
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
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              // Indicador
              Padding(
                padding: const EdgeInsets.only(right: 14),
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
