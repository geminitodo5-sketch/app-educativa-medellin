// ─────────────────────────────────────────────────────────────
//  lib/ui/views/ciencias_view.dart
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/providers/app_state_provider.dart';
import '../viewmodels/ciencias_view_model (1).dart';
import 'ciencias/vivo_no_vivo_screen.dart';
import 'ciencias/cuerpo_humano_screen.dart';
import 'ciencias/animales/animales_flow_screen.dart';
import 'ciencias/las_plantas_screen.dart';

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
    final syncState = ref.watch(syncListenerProvider);

    return Scaffold(
      // ── FIX 1: color de fondo que hace match con la imagen ──
      backgroundColor: const Color(0xFFAEE6F0),
      extendBodyBehindAppBar: true,
      extendBody: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.black, size: 28),
          onPressed: () {
            vm.commandVolver();
            Navigator.of(context).maybePop();
          },
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: syncState.when(
              data: (count) => Icon(
                count > 0 ? Icons.sync_rounded : Icons.cloud_done_rounded,
                color: Colors.black45,
                size: 24,
              ),
              error: (_, __) => const Icon(
                Icons.cloud_off_rounded,
                color: Colors.redAccent,
                size: 24,
              ),
              loading: () => const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
        ],
      ),

      // ── FIX 2: SizedBox.expand para que el Stack ocupe toda la pantalla ──
      body: SizedBox.expand(
        child: Stack(
          children: [
            // Fondo - cubre toda la pantalla incluyendo zonas del sistema
            Positioned.fill(
              child: Image.asset(
                'assets/images/bienvenida/fondos (1).png',
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
                errorBuilder: (ctx, e, _) =>
                    Container(color: const Color(0xFFAEE6F0)),
              ),
            ),

            // Pollito esquina inferior izquierda
            Positioned(
              bottom: -20,
              left: 30,
              child: Image.asset(
                'assets/images/avatares/pollo feliz 2 (2).png',
                width: 85,
                errorBuilder: (ctx, e, _) => const SizedBox(),
              ),
            ),

            // Contenido principal
            SafeArea(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 10),

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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 40, vertical: 10),
                      child: _BarraProgreso(
                        porcentaje: vm.progresoTotal,
                        color: const Color(0xFF3DCC52),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Tarjetas de actividades
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      child: Column(
                        children: [
                          _ActividadCard(
                            imagen: 'assets/images/areas/ciencias_naturales/Group 42 (1).png',
                            texto: '¿Vivo o no\nVivo?',
                            completado: _completado(vm, '¿Vivo o no Vivo?'),
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const VivoNoVivoScreen(),
                                ),
                              );
                              if (mounted) {
                                ref
                                    .read(cienciasViewModelProvider)
                                    .commandCargarProgreso();
                              }
                            },
                          ),
                          const SizedBox(height: 14),
                          _ActividadCard(
                            imagen: 'assets/images/areas/ciencias_naturales/h1 2 (1).png',
                            texto: 'Cuerpo\nhumano',
                            completado: _completado(vm, 'Cuerpo humano'),
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const CuerpoHumanoScreen(),
                                ),
                              );
                              if (mounted) {
                                ref
                                    .read(cienciasViewModelProvider)
                                    .commandCargarProgreso();
                              }
                            },
                          ),
                          const SizedBox(height: 14),
                          _ActividadCard(
                            imagen: 'assets/images/areas/ciencias_naturales/Group 43 (1).png',
                            texto: 'Animales',
                            completado: _completado(vm, 'Animales'),
                            rellenar: true,
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const AnimalesFlowScreen(),
                                ),
                              );
                              if (mounted) {
                                ref
                                    .read(cienciasViewModelProvider)
                                    .commandCargarProgreso();
                              }
                            },
                          ),
                          const SizedBox(height: 14),
                          _ActividadCard(
                            imagen: 'assets/images/areas/ciencias_naturales/Group 44 (1).png',
                            texto: 'Las\nplantas',
                            completado: _completado(vm, 'Las plantas'),
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const LasPlantasScreen(),
                                ),
                              );
                              if (mounted) {
                                ref
                                    .read(cienciasViewModelProvider)
                                    .commandCargarProgreso();
                              }
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _completado(CienciasViewModel vm, String actividad) =>
      vm.progreso.any((p) => p.actividad == actividad && p.porcentaje >= 100);
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
            const Text(
              'Progreso',
              style: TextStyle(fontFamily: 'Poppins', fontSize: 12),
            ),
            Text(
              '${porcentaje.toInt()}%',
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
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

// ─── Tarjeta de actividad ──────────────────────────────────────
class _ActividadCard extends StatefulWidget {
  final String imagen;
  final String texto;
  final bool completado;
  final VoidCallback onTap;
  final bool rellenar;

  const _ActividadCard({
    required this.imagen,
    required this.texto,
    required this.completado,
    required this.onTap,
    this.rellenar = false,
  });

  @override
  State<_ActividadCard> createState() => _ActividadCardState();
}

class _ActividadCardState extends State<_ActividadCard>
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
          width: double.infinity,
          height: 70,
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
                      ? Image.asset(
                          widget.imagen,
                          fit: BoxFit.cover,
                          errorBuilder: (ctx, e, _) => const Icon(
                            Icons.science_rounded,
                            color: Color(0xFF3DCC52),
                          ),
                        )
                      : Padding(
                          padding: const EdgeInsets.all(8),
                          child: Image.asset(
                            widget.imagen,
                            fit: BoxFit.contain,
                            errorBuilder: (ctx, e, _) => const Icon(
                              Icons.science_rounded,
                              color: Color(0xFF3DCC52),
                            ),
                          ),
                        ),
                ),
              ),
              // Texto
              Expanded(
                child: Text(
                  widget.texto,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Hiruko',
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1.2,
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