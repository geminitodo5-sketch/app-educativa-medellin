// ─────────────────────────────────────────────────────────────
//  lib/ui/views/espanol_view.dart
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../viewmodels/espanol_view_model.dart';

class EspanolView extends ConsumerStatefulWidget {
  const EspanolView({super.key});

  @override
  ConsumerState<EspanolView> createState() => _EspanolViewState();
}

class _EspanolViewState extends ConsumerState<EspanolView> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(espanolViewModelProvider).commandCargarProgreso(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = ref.watch(espanolViewModelProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded,
              color: Colors.black, size: 28),
          onPressed: () {
            vm.commandVolver();
            Navigator.of(context).maybePop();
          },
        ),
      ),
      body: Stack(
        children: [
          // Fondo cielo
          Container(
            width: double.infinity,
            height: double.infinity,
            color: const Color(0xFF7BD0E8),
          ),

          // Paisaje de fondo
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Image.asset(
              'assets/images/bienvenida/fondos (1).png',
              fit: BoxFit.fitWidth,
              alignment: Alignment.bottomCenter,
              errorBuilder: (ctx, e, _) => const SizedBox(),
            ),
          ),

          // Mono esquina inferior derecha
          Positioned(
            bottom: 0,
            right: 0,
            child: Image.asset(
              'assets/images/bienvenida/mono.png',
              width: 100,
              fit: BoxFit.contain,
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
                    'Español',
                    style: TextStyle(
                      fontFamily: 'Hiruko',
                      fontSize: 38,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  // Barra de progreso
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 40, vertical: 6),
                    child: _BarraProgreso(
                        porcentaje: vm.progresoTotal,
                        color: const Color(0xFFB83232)),
                  ),

                  const SizedBox(height: 14),

                  // Actividades
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // Pollito
                        Positioned(
                          top: -30,
                          left: 10,
                          child: Image.asset(
                            'assets/images/avatares/pollo feliz 2 (2).png',
                            width: 75,
                            fit: BoxFit.contain,
                            errorBuilder: (ctx, e, _) => const SizedBox(),
                          ),
                        ),

                        Column(
                          children: [
                            const SizedBox(height: 55),
                            _ActividadCard(
                              texto: 'Palabra\nloca',
                              imagenLeft: 'assets/images/areas/espanol/palabra_loca.png',
                              completado: _completado(vm, 'Palabra loca'),
                              onTap: () => vm.commandSeleccionarActividad(
                                  'Palabra loca',
                                  porcentaje: 100.0),
                            ),
                            const SizedBox(height: 14),
                            _ActividadCard(
                              texto: 'Arma\nla palabra',
                              imagenLeft: 'assets/images/areas/espanol/arma_palabra.png',
                              completado: _completado(vm, 'Arma la palabra'),
                              onTap: () => vm.commandSeleccionarActividad(
                                  'Arma la palabra',
                                  porcentaje: 100.0),
                            ),
                            const SizedBox(height: 14),
                            _ActividadCard(
                              texto: 'Oraciones',
                              imagenLeft: 'assets/images/areas/espanol/gato_con_comida.png',
                              completado: _completado(vm, 'Oraciones'),
                              onTap: () => vm.commandSeleccionarActividad(
                                  'Oraciones',
                                  porcentaje: 100.0),
                            ),
                          ],
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
    );
  }

  bool _completado(EspanolViewModel vm, String actividad) =>
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

// ─── Tarjeta de actividad ──────────────────────────────────────
class _ActividadCard extends StatefulWidget {
  final String texto;
  final String imagenLeft;
  final bool completado;
  final VoidCallback onTap;

  const _ActividadCard({
    required this.texto,
    required this.imagenLeft,
    required this.completado,
    required this.onTap,
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
          height: 90,
          decoration: BoxDecoration(
            color: const Color(0xFFB83232),
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Color(0xFF8B1A1A),
                blurRadius: 0,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // Imagen
              Container(
                margin: const EdgeInsets.all(10),
                width: 68,
                height: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.asset(
                    widget.imagenLeft,
                    fit: BoxFit.contain,
                    errorBuilder: (ctx, e, _) => const Icon(
                      Icons.menu_book_rounded,
                      color: Color(0xFFB83232),
                      size: 36,
                    ),
                  ),
                ),
              ),
              // Texto
              Expanded(
                child: Text(
                  widget.texto,
                  style: const TextStyle(
                    fontFamily: 'Hiruko',
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1.2,
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
