import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/providers/app_state_provider.dart';
import '../../data/models/estudiante_model.dart';
import '../../data/models/progreso_model.dart';
import '../viewmodels/matematicas_view_model.dart';
import 'matematicas/los_numeros/descubre_numeros_view.dart';
import 'matematicas/quien_tiene_mas/quien_tiene_mas.dart';
import 'matematicas/sumar/sumar.dart';

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
                                  'Matemáticas',
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
                                    color: const Color(0xFF3475F7),
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
                              // Pollo detrás
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
                                  _BotonMateria(
                                    rutaIcono:
                                        'assets/images/areas/matematicas/Group 40 (1) (1).png',
                                    texto: 'Los números',
                                    completado: _estaCompletado(vm, 'Los números'),
                                    botonHeight: sh * 0.10,
                                    onTap: () async {
                                      await Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => const DescubreNumerosView(),
                                        ),
                                      );
                                      ref
                                          .read(matematicasViewModelProvider)
                                          .commandCargarProgreso();
                                    },
                                  ),

                                  SizedBox(height: sh * 0.018),
                                  _BotonMateria(
                                    rutaIcono:
                                        'assets/images/areas/matematicas/_ (1) (1).png',
                                    texto: 'Quien tiene más',
                                    completado: _estaCompletado(
                                      vm,
                                      'Quien tiene más',
                                    ),
                                    botonHeight: sh * 0.10,
                                    onTap: () async {
                                      await Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => const ComparacionCantidadesView(),
                                        ),
                                      );
                                      ref.read(matematicasViewModelProvider).commandCargarProgreso();
                                    },
                                  ),
                                  SizedBox(height: sh * 0.018),
                                  _BotonMateria(
                                    rutaIcono:
                                        'assets/images/areas/matematicas/Group 41 (1) (2).png',
                                    texto: 'Sumar',
                                    completado: _estaCompletado(vm, 'Sumar'),
                                    botonHeight: sh * 0.10,
                                    onTap: () async {
                                      await Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => const SumarPatronview(),
                                        ),
                                      );
                                      ref.read(matematicasViewModelProvider).commandCargarProgreso();
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

  bool _estaCompletado(MatematicasViewModel vm, String actividad) {
    return vm.progreso.any(
      (ProgresoModel p) => p.actividad == actividad && p.porcentaje >= 100,
    );
  }
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

class _BotonMateria extends StatefulWidget {
  final String rutaIcono;
  final String texto;
  final bool completado;
  final VoidCallback onTap;
  final double botonHeight;

  const _BotonMateria({
    required this.rutaIcono,
    required this.texto,
    required this.completado,
    required this.onTap,
    this.botonHeight = 84,
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
          height: widget.botonHeight,
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
                width: widget.botonHeight * 0.78,
                height: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(8),
                child: Image.asset(
                  widget.rutaIcono,
                  fit: BoxFit.contain,
                  errorBuilder: (ctx, e, _) => Icon(
                    Icons.calculate_rounded,
                    color: const Color(0xFF3475F7),
                    size: widget.botonHeight * 0.38,
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