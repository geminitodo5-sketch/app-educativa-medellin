import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/providers/app_state_provider.dart';
import '../../data/models/estudiante_model.dart';
import '../../data/models/progreso_model.dart';
import '../viewmodels/ingles_view_model.dart';
import 'inlges/ingles_escucha_view.dart';
import 'inlges/ingles_pareja_view.dart';
import 'inlges/ingles_tarjetas_view.dart';
import 'inlges/ingles_congratulations_view.dart';

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
                width: 160,
                errorBuilder: (ctx, e, _) => const SizedBox(),
              ),
            ),

            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final screen = MediaQuery.of(context);
                  final sw = screen.size.width;
                  final sh = screen.size.height;
                  final isTablet = sw >= 600;
                  final headerHPadding = isTablet ? 40.0 : 16.0;
                  final barraHPadding = isTablet ? 80.0 : 40.0;

                  // Altura dinámica: adapta a cualquier pantalla
                  final headerMin = sh * 0.20;
                  final headerMax = sh * 0.26;

                  return CustomScrollView(
                    slivers: [
                      // ── Encabezado sticky ──────────────────────────────
                      SliverPersistentHeader(
                        pinned: true,
                        delegate: _HeaderDelegate(
                          minHeight: headerMin,
                          maxHeight: headerMax,
                          child: Container(
                            color: Colors.transparent,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const SizedBox(height: 10),
                                // Fila Superior: Volver + Sync Status
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

                                // Título
                                Text(
                                  'Inglés',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontFamily: 'Hiruko',
                                    fontSize: isTablet ? 52 : 38,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.black,
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

                                // Barra de progreso
                                Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: barraHPadding,
                                    vertical: 4,
                                  ),
                                  child: _BarraProgreso(
                                    porcentaje: vm.progresoTotal,
                                    color: const Color(0xFF8B5CF6),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // ── Contenido scrolleable ──────────────────────────
                      SliverToBoxAdapter(
                        child: SizedBox(height: sh * 0.005),
                      ),
                      SliverPadding(
                        padding: EdgeInsets.symmetric(horizontal: isTablet ? 60.0 : 20.0),
                        sliver: SliverToBoxAdapter(
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              // Pollito detrás
                              Positioned(
                                top: -(sh * 0.03),
                                left: 10,
                                child: Image.asset(
                                  'assets/images/avatares/pollo feliz 2 (2).png',
                                  width: sh * 0.09,
                                  errorBuilder: (ctx, e, _) => const SizedBox(),
                                ),
                              ),

                              Column(
                                children: [
                                  SizedBox(height: sh * 0.06),

                                  _ActividadCard(
                                    texto: 'Escucha',
                                    imagenLeft: 'assets/images/areas/ingles/ingles1.png',
                                    completado: _completado(vm, 'Module 1'),
                                    cardHeight: sh * 0.10,
                                    onTap: () async {
                                      await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => InglesEscuchaView(
                                            onCompleted: () => vm.commandSeleccionarLeccion(
                                                'Module 1',
                                                porcentajeCompletado: 100.0),
                                          ),
                                        ),
                                      );
                                      if (mounted) {
                                        ref.read(inglesViewModelProvider).commandCargarProgreso();
                                      }
                                    },
                                  ),

                                  SizedBox(height: sh * 0.018),
                                  _ActividadCard(
                                    texto: 'Une\nla pareja',
                                    imagenLeft: 'assets/images/areas/ingles/ingles2.png',
                                    completado: _completado(vm, 'Module 2'),
                                    cardHeight: sh * 0.10,
                                    onTap: () async {
                                      await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => InglesParejaView(
                                            onCompleted: () => vm.commandSeleccionarLeccion(
                                                'Module 2',
                                                porcentajeCompletado: 100.0),
                                          ),
                                        ),
                                      );
                                      if (mounted) {
                                        ref.read(inglesViewModelProvider).commandCargarProgreso();
                                      }
                                    },
                                  ),

                                  SizedBox(height: sh * 0.018),
                                  _ActividadCard(
                                    texto: 'Tarjetas',
                                    imagenLeft: 'assets/images/areas/ingles/ingles3.png',
                                    completado: _completado(vm, 'Module 3'),
                                    cardHeight: sh * 0.10,
                                    onTap: () async {
                                      bool completado = false;
                                      final nav = Navigator.of(context);
                                      await nav.push(
                                        MaterialPageRoute(
                                          builder: (_) => InglesTarjetasView(
                                            onCompleted: () {
                                              completado = true;
                                              vm.commandSeleccionarLeccion('Module 3',
                                                  porcentajeCompletado: 100.0);
                                            },
                                          ),
                                        ),
                                      );
                                      await ref
                                          .read(inglesViewModelProvider)
                                          .commandCargarProgreso();
                                      if (completado && mounted) {
                                        nav.push(
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                const InglesCongratulationsView(),
                                          ),
                                        );
                                      }
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

  bool _completado(InglesViewModel vm, String modulo) =>
      vm.progreso.any((ProgresoModel p) => p.actividad == modulo && p.porcentaje >= 100);
}

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

class _HeaderDelegate extends SliverPersistentHeaderDelegate {
  final double minHeight;
  final double maxHeight;
  final Widget child;

  const _HeaderDelegate({
    required this.minHeight,
    required this.maxHeight,
    required this.child,
  });

  @override
  double get minExtent => minHeight;

  @override
  double get maxExtent => maxHeight;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return SizedBox.expand(child: child);
  }

  @override
  bool shouldRebuild(_HeaderDelegate oldDelegate) =>
      maxHeight != oldDelegate.maxHeight ||
      minHeight != oldDelegate.minHeight ||
      child != oldDelegate.child;
}

class _ActividadCard extends StatefulWidget {
  final String texto;
  final String imagenLeft;
  final bool completado;
  final VoidCallback onTap;
  final double cardHeight;

  const _ActividadCard({
    required this.texto,
    required this.imagenLeft,
    required this.completado,
    required this.onTap,
    this.cardHeight = 84,
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
  late final Animation<double> _scale = Tween<double>(
    begin: 1.0,
    end: 0.96,
  ).animate(_ctrl);

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
          height: widget.cardHeight,
          decoration: BoxDecoration(
            color: const Color(0xFF8B5CF6),
            borderRadius: BorderRadius.circular(18),
            boxShadow: const [
              BoxShadow(
                color: Color(0xFF5B3BA6),
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
                width: widget.cardHeight * 0.78,
                height: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Image.asset(
                      widget.imagenLeft,
                      fit: BoxFit.contain,
                      errorBuilder: (ctx, e, _) => Icon(
                        Icons.headphones_rounded,
                        color: const Color(0xFF8B5CF6),
                        size: widget.cardHeight * 0.38,
                      ),
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
                      fontSize: (widget.cardHeight * 0.25).clamp(16.0, 26.0),
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
                        size: widget.cardHeight * 0.33,
                      )
                    : Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: Colors.white,
                        size: widget.cardHeight * 0.26,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}