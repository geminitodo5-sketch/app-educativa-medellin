// ─────────────────────────────────────────────────────────────
//  lib/ui/views/ciencias_sociales_view.dart
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../viewmodels/sociales_view_model.dart';

class CienciasSocialesView extends ConsumerStatefulWidget {
  const CienciasSocialesView({super.key});

  @override
  ConsumerState<CienciasSocialesView> createState() =>
      _CienciasSocialesViewState();
}

class _CienciasSocialesViewState extends ConsumerState<CienciasSocialesView> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(socialesViewModelProvider).commandCargarProgreso(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = ref.watch(socialesViewModelProvider);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF64D8EB), Color(0xFFB4E6A5)],
          ),
        ),
        child: Stack(
          clipBehavior: Clip.none,
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

            SafeArea(
              child: Column(
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
                            size: 40, color: Colors.black),
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Título
                  const Text(
                    'Ciencias\nSociales',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Hiruko',
                      fontSize: 44,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF3D2B1F),
                      height: 1.15,
                    ),
                  ),

                  // Barra de progreso
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 40, vertical: 6),
                    child: _BarraProgreso(
                        porcentaje: vm.progresoTotal,
                        color: const Color(0xFFF5A623)),
                  ),

                  const SizedBox(height: 20),

                  // Botones
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Column(
                      children: [
                        _BotonSociales(
                          imagePath: 'assets/images/areas/sociales/heroes_ciudad.png.png',
                          fallbackEmoji: '👧',
                          texto: 'Héroes de\nla\nCiudad',
                          completado: _completado(vm, 'Héroes de la Ciudad'),
                          onTap: () => vm.commandSeleccionarTema(
                              'Héroes de la Ciudad',
                              porcentaje: 100.0),
                        ),
                        const SizedBox(height: 18),
                        _BotonSociales(
                          imagePath: 'assets/images/areas/sociales/detective_objetos.png.png',
                          fallbackEmoji: '🐻',
                          texto: 'Detective de\nObjetos',
                          completado: _completado(vm, 'Detective de Objetos'),
                          onTap: () => vm.commandSeleccionarTema(
                              'Detective de Objetos',
                              porcentaje: 100.0),
                        ),
                        const SizedBox(height: 18),
                        _BotonSociales(
                          imagePath: 'assets/images/areas/sociales/pasado_presente.png.png',
                          fallbackEmoji: '💡',
                          texto: 'Pasado y\nPresente',
                          completado: _completado(vm, 'Pasado y Presente'),
                          onTap: () => vm.commandSeleccionarTema(
                              'Pasado y Presente',
                              porcentaje: 100.0),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(flex: 3),
                ],
              ),
            ),

            // Mono esquina inferior derecha
            Positioned(
              bottom: 0,
              right: 0,
              child: Image.asset(
                'assets/images/avatares/avatar_mono1.jpg',
                width: 130,
                errorBuilder: (ctx, e, _) => const SizedBox(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _completado(SocialesViewModel vm, String tema) =>
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

// ─── Botón naranja de sociales ─────────────────────────────────
class _BotonSociales extends StatefulWidget {
  final String imagePath;
  final String fallbackEmoji;
  final String texto;
  final bool completado;
  final VoidCallback onTap;

  const _BotonSociales({
    required this.imagePath,
    required this.fallbackEmoji,
    required this.texto,
    required this.completado,
    required this.onTap,
  });

  @override
  State<_BotonSociales> createState() => _BotonSocialesState();
}

class _BotonSocialesState extends State<_BotonSociales>
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
          height: 75,
          decoration: BoxDecoration(
            color: const Color(0xFFF5A623),
            borderRadius: BorderRadius.circular(18),
            boxShadow: const [
              BoxShadow(
                color: Color(0xFFB8710A),
                blurRadius: 0,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              // Imagen
              Container(
                margin: const EdgeInsets.all(6),
                width: 78,
                height: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                clipBehavior: Clip.antiAlias,
                child: Image.asset(
                  widget.imagePath,
                  fit: BoxFit.contain,
                  errorBuilder: (ctx, e, _) => Center(
                    child: Text(widget.fallbackEmoji,
                        style: const TextStyle(fontSize: 36)),
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
                      height: 1.2,
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
