import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/providers/app_state_provider.dart';
import '../../data/models/estudiante_model.dart';
import '../../data/models/progreso_model.dart';
import '../viewmodels/ciencias_view_model.dart';
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
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final screen = MediaQuery.of(context);
                  final sw = screen.size.width;
                  final sh = screen.size.height;
                  final isTablet = sw >= 600;
                  final headerHPadding = isTablet ? 40.0 : 16.0;
                  final barraHPadding = isTablet ? 80.0 : 40.0;

                  // Altura dinámica segura: nunca menor al contenido real.
                  // En celulares pequeños (sh < 650) el header necesita más %.
                  final double headerFraction = sh < 650 ? 0.30 : (sh < 750 ? 0.27 : 0.25);
                  final headerMin = sh * headerFraction;
                  final headerMax = sh * headerFraction;

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
                                SizedBox(height: sh * 0.008),
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
                                          size: isTablet ? 44 : 32,
                                          color: Colors.black,
                                        ),
                                      ),
                                      syncState.when(
                                        data: (count) => Icon(
                                          count > 0
                                              ? Icons.sync_rounded
                                              : Icons.cloud_done_rounded,
                                          color: Colors.black45,
                                          size: isTablet ? 30 : 22,
                                        ),
                                        error: (_, __) => const Icon(
                                          Icons.cloud_off_rounded,
                                          color: Colors.redAccent,
                                        ),
                                        loading: () => const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(strokeWidth: 2),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                SizedBox(height: sh * 0.004),

                                // Título — tamaño adaptativo para pantallas pequeñas
                                Text(
                                  'Ciencias\nnaturales',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontFamily: 'Hiruko',
                                    fontSize: isTablet ? 52 : (sh < 650 ? 28.0 : 34.0),
                                    fontWeight: FontWeight.w900,
                                    color: Colors.black,
                                    height: 1.1,
                                  ),
                                ),
                                if (estudiante != null)
                                  Text(
                                    'Hola, ${estudiante.nombre}',
                                    style: TextStyle(
                                      fontFamily: 'Hiruko',
                                      fontSize: isTablet ? 28 : (sh < 650 ? 16.0 : 19.0),
                                      color: Colors.black87,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),

                                // Barra de progreso
                                Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: barraHPadding,
                                    vertical: sh * 0.004,
                                  ),
                                  child: _BarraProgreso(
                                    porcentaje: vm.progresoTotal,
                                    color: const Color(0xFF3DCC52),
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
                              Column(
                                children: [
                                  SizedBox(height: sh * 0.06),

                                  _ActividadCard(
                                    imagen: 'assets/images/areas/ciencias_naturales/Group 42 (1).png',
                                    texto: '¿Vivo o no\nVivo?',
                                    completado: _completado(vm, '¿Vivo o no Vivo?'),
                                    cardHeight: sh * 0.10,
                                    onTap: () async {
                                      await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => const VivoNoVivoScreen(),
                                        ),
                                      );
                                      if (mounted) {
                                        ref.read(cienciasViewModelProvider).commandCargarProgreso();
                                      }
                                    },
                                  ),

                                  SizedBox(height: sh * 0.018),
                                  _ActividadCard(
                                    imagen: 'assets/images/areas/ciencias_naturales/h1 2 (1).png',
                                    texto: 'Cuerpo\nhumano',
                                    completado: _completado(vm, 'Cuerpo humano'),
                                    cardHeight: sh * 0.10,
                                    onTap: () async {
                                      await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => const CuerpoHumanoScreen(),
                                        ),
                                      );
                                      if (mounted) {
                                        ref.read(cienciasViewModelProvider).commandCargarProgreso();
                                      }
                                    },
                                  ),

                                  SizedBox(height: sh * 0.018),
                                  _ActividadCard(
                                    imagen: 'assets/images/areas/ciencias_naturales/Group 43 (1).png',
                                    texto: 'Animales',
                                    completado: _completado(vm, 'Animales'),
                                    cardHeight: sh * 0.10,
                                    rellenar: true,
                                    onTap: () async {
                                      await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => const AnimalesFlowScreen(),
                                        ),
                                      );
                                      if (mounted) {
                                        ref.read(cienciasViewModelProvider).commandCargarProgreso();
                                      }
                                    },
                                  ),

                                  SizedBox(height: sh * 0.018),
                                  _ActividadCard(
                                    imagen: 'assets/images/areas/ciencias_naturales/Group 44 (1).png',
                                    texto: 'Las\nplantas',
                                    completado: _completado(vm, 'Las plantas'),
                                    cardHeight: sh * 0.10,
                                    ajustarAncho: true,
                                    onTap: () async {
                                      await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => const LasPlantasScreen(),
                                        ),
                                      );
                                      if (mounted) {
                                        ref.read(cienciasViewModelProvider).commandCargarProgreso();
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

  bool _completado(CienciasViewModel vm, String actividad) =>
      vm.progreso.any((ProgresoModel p) => p.actividad == actividad && p.porcentaje >= 100);
}

class _BarraProgreso extends StatelessWidget {
  final double porcentaje;
  final Color color;

  const _BarraProgreso({required this.porcentaje, required this.color});

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;
    final sh = MediaQuery.of(context).size.height;
    final isTablet = sw >= 600;
    final fontSize = isTablet ? 22.0 : (sw * 0.042).clamp(14.0, 18.0);
    final barHeight = (sh * 0.013).clamp(8.0, 14.0);

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Progreso',
              style: TextStyle(
                fontFamily: 'Hiruko',
                fontSize: fontSize,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            Text(
              '${porcentaje.toInt()}%',
              style: TextStyle(
                fontFamily: 'Hiruko',
                fontSize: fontSize,
                fontWeight: FontWeight.w900,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        SizedBox(height: sh * 0.005),
        ClipRRect(
          borderRadius: BorderRadius.circular(barHeight),
          child: LinearProgressIndicator(
            value: (porcentaje / 100).clamp(0.0, 1.0),
            minHeight: barHeight,
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
    return ClipRect(child: SizedBox.expand(child: child));
  }

  @override
  bool shouldRebuild(_HeaderDelegate oldDelegate) =>
      maxHeight != oldDelegate.maxHeight ||
      minHeight != oldDelegate.minHeight ||
      child != oldDelegate.child;
}

class _ActividadCard extends StatefulWidget {
  final String imagen;
  final String texto;
  final bool completado;
  final VoidCallback onTap;
  final bool rellenar;
  final bool ajustarAncho;
  final double cardHeight;

  const _ActividadCard({
    required this.imagen,
    required this.texto,
    required this.completado,
    required this.onTap,
    this.rellenar = false,
    this.ajustarAncho = false,
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
          height: widget.cardHeight,
          decoration: BoxDecoration(
            color: const Color(0xFF3DCC52),
            borderRadius: BorderRadius.circular(18),
            boxShadow: const [
              BoxShadow(
                color: Color(0xFF22A45D),
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
                  color: const Color(0xFFE0F7FA),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: widget.rellenar
                      ? Image.asset(
                          widget.imagen,
                          fit: BoxFit.cover,
                          errorBuilder: (ctx, e, _) => Icon(
                            Icons.science_rounded,
                            color: const Color(0xFF3DCC52),
                            size: widget.cardHeight * 0.38,
                          ),
                        )
                      : widget.ajustarAncho
                          ? LayoutBuilder(
                              builder: (ctx, bc) => OverflowBox(
                                maxWidth: bc.maxWidth * 1.8,
                                maxHeight: bc.maxHeight * 1.8,
                                alignment: Alignment.bottomCenter,
                                child: Image.asset(
                                  widget.imagen,
                                  fit: BoxFit.fitWidth,
                                  errorBuilder: (ctx, e, _) => Icon(
                                    Icons.science_rounded,
                                    color: const Color(0xFF3DCC52),
                                    size: widget.cardHeight * 0.38,
                                  ),
                                ),
                              ),
                            )
                          : Padding(
                              padding: const EdgeInsets.all(8),
                              child: Image.asset(
                                widget.imagen,
                                fit: BoxFit.contain,
                                errorBuilder: (ctx, e, _) => Icon(
                                  Icons.science_rounded,
                                  color: const Color(0xFF3DCC52),
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
                      fontSize: (widget.cardHeight * 0.30).clamp(20.0, 32.0),
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      height: 1.2,
                    ),
                  ),
                ),
              ),
              // Indicador completado o flecha
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