// ─────────────────────────────────────────────────────────────
//  lib/ui/views/ciencias_sociales_view.dart
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/providers/app_state_provider.dart';
import '../../data/models/estudiante_model.dart';
import '../../data/models/progreso_model.dart';
import '../viewmodels/sociales_view_model.dart';
import 'sociales/heroes_ciudad_screen.dart';
import 'sociales/detective_objetos_screen.dart';
import 'sociales/pasado_presente_screen.dart';

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
    final syncState = ref.watch(syncListenerProvider);
    final EstudianteModel? estudiante = ref.watch(estudianteActivoProvider);

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
            // Fondo paisaje (mismo que matemáticas)
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

            // Mono abajo derecha (mismo que matemáticas)
            Positioned(
              bottom: 0,
              right: 0,
              child: Image.asset(
                'assets/images/avatares/avatar_mono1.jpg',
                width: 160,
                errorBuilder: (ctx, e, _) => const SizedBox(),
              ),
            ),

            SafeArea(
              bottom: false,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final screen = MediaQuery.of(context);
                  final sw = screen.size.width;
                  final sh = screen.size.height;
                  final isTablet = sw >= 600;
                  final headerHPadding = isTablet ? 40.0 : 16.0;
                  final barraHPadding = isTablet ? 80.0 : 40.0;

                  return CustomScrollView(
                    slivers: [
                      // ── Encabezado ─────────────────────────────────────
                      SliverToBoxAdapter(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const SizedBox(height: 10),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: headerHPadding),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      vm.commandVolver();
                                      Navigator.of(context).maybePop();
                                    },
                                    child: Icon(
                                      Icons.arrow_back_rounded,
                                      size: isTablet ? 44 : 36,
                                      color: Colors.black,
                                    ),
                                  ),
                                  syncState.when(
                                    data: (count) => Icon(
                                      count > 0
                                          ? Icons.sync_rounded
                                          : Icons.cloud_done_rounded,
                                      color: Colors.black45,
                                      size: isTablet ? 30 : 24,
                                    ),
                                    error: (_, __) => const Icon(
                                      Icons.cloud_off_rounded,
                                      color: Colors.redAccent,
                                    ),
                                    loading: () => const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 6),

                            Text(
                              'Ciencias\nSociales',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Hiruko',
                                fontSize: isTablet ? 52 : 38,
                                fontWeight: FontWeight.w900,
                                color: Colors.black,
                                height: 1.15,
                              ),
                            ),
                            if (estudiante != null)
                              Text(
                                'Hola, ${estudiante.nombre}',
                                style: TextStyle(
                                  fontFamily: 'Hiruko',
                                  fontSize: isTablet ? 28 : 22,
                                  color: Colors.black87,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),

                            Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: barraHPadding,
                                vertical: 4,
                              ),
                              child: _BarraProgreso(
                                porcentaje: vm.progresoTotal,
                                color: const Color(0xFFF5A623),
                              ),
                            ),
                            SizedBox(height: sh * 0.10),
                          ],
                        ),
                      ),

                      // ── Contenido scrolleable ──────────────────────────
                      SliverPadding(
                        padding: EdgeInsets.symmetric(horizontal: isTablet ? 60.0 : 20.0),
                        sliver: SliverToBoxAdapter(
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Column(
                                children: [
                                  const SizedBox(height: 4),

                                  _BotonSociales(
                                    imagePath: 'assets/images/areas/sociales/heroes_ciudad.png.png',
                                    fallbackEmoji: '👧',
                                    texto: 'Héroes de\nla\nCiudad',
                                    completado: _completado(vm, 'Héroes de la Ciudad'),
                                    botonHeight: sh * 0.10,
                                    onTap: () async {
                                      await Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => HeroesCiudadScreen(
                                            onCompleted: () => vm.commandSeleccionarTema(
                                                'Héroes de la Ciudad',
                                                porcentaje: 100.0),
                                          ),
                                        ),
                                      );
                                      ref.read(socialesViewModelProvider).commandCargarProgreso();
                                    },
                                  ),

                                  SizedBox(height: sh * 0.018),
                                  _BotonSociales(
                                    imagePath: 'assets/images/areas/sociales/detective_objetos.png.png',
                                    fallbackEmoji: '🐻',
                                    texto: 'Detective de\nObjetos',
                                    completado: _completado(vm, 'Detective de Objetos'),
                                    botonHeight: sh * 0.10,
                                    onTap: () async {
                                      await Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => DetectiveObjetosScreen(
                                            onCompleted: () => vm.commandSeleccionarTema(
                                                'Detective de Objetos',
                                                porcentaje: 100.0),
                                          ),
                                        ),
                                      );
                                      ref.read(socialesViewModelProvider).commandCargarProgreso();
                                    },
                                  ),

                                  SizedBox(height: sh * 0.018),
                                  _BotonSociales(
                                    imagePath: 'assets/images/areas/sociales/pasado_presente.png.png',
                                    fallbackEmoji: '💡',
                                    texto: 'Pasado y\nPresente',
                                    completado: _completado(vm, 'Pasado y Presente'),
                                    botonHeight: sh * 0.10,
                                    onTap: () async {
                                      await Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => PasadoPresenteScreen(
                                            onCompleted: () => vm.commandSeleccionarTema(
                                                'Pasado y Presente',
                                                porcentaje: 100.0),
                                          ),
                                        ),
                                      );
                                      ref.read(socialesViewModelProvider).commandCargarProgreso();
                                    },
                                  ),

                                  const SizedBox(height: 200),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _completado(SocialesViewModel vm, String tema) =>
      vm.progreso.any((ProgresoModel p) => p.actividad == tema && p.porcentaje >= 100);
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
              style: TextStyle(
                fontFamily: 'Hiruko',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            Text(
              '${porcentaje.toInt()}%',
              style: const TextStyle(
                fontFamily: 'Hiruko',
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: Colors.black87,
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
            backgroundColor: Colors.white.withOpacity(0.5),
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
  final double botonHeight;

  const _BotonSociales({
    required this.imagePath,
    required this.fallbackEmoji,
    required this.texto,
    required this.completado,
    required this.onTap,
    this.botonHeight = 84,
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
          height: widget.botonHeight,
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
                margin: const EdgeInsets.all(8),
                width: widget.botonHeight * 0.78,
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
                    child: Text(
                      widget.fallbackEmoji,
                      style: TextStyle(fontSize: widget.botonHeight * 0.36),
                    ),
                  ),
                ),
              ),
              // Texto
              Expanded(
                child: Center(
                  child: Text(
                    widget.texto,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Hiruko',
                      fontSize: (widget.botonHeight * 0.25).clamp(16.0, 26.0),
                      fontWeight: FontWeight.w700,
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
                    ? Icon(
                        Icons.check_circle_rounded,
                        color: Colors.white,
                        size: widget.botonHeight * 0.33,
                      )
                    : Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: Colors.white,
                        size: widget.botonHeight * 0.26,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}