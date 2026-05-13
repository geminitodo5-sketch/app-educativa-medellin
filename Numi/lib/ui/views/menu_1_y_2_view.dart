// ─────────────────────────────────────────────────────────────
//  lib/ui/views/menu_1_y_2_view.dart
//  Menú principal para grados 1 y 2.
//  Muestra las 5 materias con barra de progreso real desde la BD.
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/providers/app_state_provider.dart';
import '../../data/providers/musica_provider.dart';
import '../../data/providers/racha_provider.dart';
import '../../main.dart' show routeObserver;
import 'racha_view.dart';
import 'matematicas_view.dart';
import 'ciencias_view.dart';
import 'ingles_view.dart';
import 'espanol_view.dart';
import 'ciencias_sociales_view.dart';
import 'configuracion_view.dart';

class Menu1Y2Screen extends ConsumerStatefulWidget {
  final String nombre;
  final String avatar;
  final int nivel;

  const Menu1Y2Screen({
    super.key,
    this.nombre = 'Estudiante',
    this.avatar = 'pollito',
    this.nivel = 1,
  });

  @override
  ConsumerState<Menu1Y2Screen> createState() => _Menu1Y2ScreenState();
}

class _Menu1Y2ScreenState extends ConsumerState<Menu1Y2Screen> with RouteAware {
  bool _salidoPorPush = false;

  @override
  void initState() {
    super.initState();
    ref.read(musicaServiceProvider).entrar();
  }

  Future<void> _abrirRacha() async {
    final estudiante = ref.read(estudianteActivoProvider);
    if (estudiante?.id == null || !mounted) return;
    final svc = ref.read(rachaServiceProvider);
    final info = await svc.obtenerRacha(estudiante!.id!);
    if (mounted) {
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => RachaView(info: info)),
      );
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void didPushNext() {
    _salidoPorPush = true;
    ref.read(musicaServiceProvider).salir();
  }

  @override
  void didPopNext() {
    _salidoPorPush = false;
    ref.read(musicaServiceProvider).entrar();
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    if (!_salidoPorPush) ref.read(musicaServiceProvider).salir();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Lee el progreso de todas las materias desde la BD
    final progresoAsync = ref.watch(menuProgresoProvider);
    final estudiante = ref.watch(estudianteActivoProvider);

    final nombre = estudiante?.nombre ?? widget.nombre;
    final avatar = estudiante?.personaje ?? widget.avatar;
    final nivel = estudiante?.grado ?? widget.nivel;

    // ── Escala responsiva ────────────────────────────────────
    final screen = MediaQuery.of(context).size;
    // Factor de escala dinámico: referencia 800px de alto (celular típico)
    // Se adapta automáticamente a cualquier pantalla — celular pequeño, grande o tablet
    final double s = (screen.height / 800.0).clamp(0.85, 1.8);

    return Scaffold(
      body: Stack(
        children: [
          // ── Fondo ────────────────────────────────────────────
          Container(
            decoration: const BoxDecoration(
              color: Color(0xFF7BD0E8),
              image: DecorationImage(
                image: AssetImage('assets/images/bienvenida/fondos (1).png'),
                fit: BoxFit.cover,
                alignment: Alignment.bottomCenter,
              ),
            ),
          ),

          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Saludo ──────────────────────────────────────
                Padding(
                  padding: EdgeInsets.only(
                    left: 24 * s,
                    right: 24 * s,
                    top: 14 * s,
                    bottom: 4 * s,
                  ),
                  child: Text(
                    '¡Hola!',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 20 * s,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                ),

                // ── Barra de perfil ─────────────────────────────
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24 * s),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8 * s,
                      vertical: 6 * s,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B74FF),
                      borderRadius: BorderRadius.circular(40 * s),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        // Avatar
                        Container(
                          width: 50 * s,
                          height: 50 * s,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                          ),
                          padding: EdgeInsets.all(4 * s),
                          child: ClipOval(
                            child: Image.asset(
                              avatar == 'pollito'
                                  ? 'assets/images/bienvenida/pollo feliz 2 (2).png'
                                  : 'assets/images/bienvenida/mono.png',
                              fit: BoxFit.contain,
                              errorBuilder: (ctx, e, _) => const Icon(
                                Icons.person,
                                color: Color(0xFF3B74FF),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 12 * s),
                        // Nombre
                        Expanded(
                          child: Text(
                            nombre,
                            style: TextStyle(
                              fontFamily: 'Hiruko',
                              fontSize: 22 * s,
                              fontWeight: FontWeight.w800,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        // Grado
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 14 * s,
                            vertical: 6 * s,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20 * s),
                          ),
                          child: Text(
                            '$nivel° Grado',
                            style: TextStyle(
                              fontFamily: 'Hiruko',
                              fontSize: 16 * s,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        SizedBox(width: 6 * s),
                        // Botón de racha
                        GestureDetector(
                          onTap: _abrirRacha,
                          child: Container(
                            width: 38 * s,
                            height: 38 * s,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF8C00),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFCC5500),
                                  blurRadius: 0,
                                  offset: Offset(0, 3 * s),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.local_fire_department_rounded,
                              color: Colors.white,
                              size: 22 * s,
                            ),
                          ),
                        ),
                        SizedBox(width: 8 * s),
                      ],
                    ),
                  ),
                ),

                // ── Tarjeta de materias (centrada automáticamente) ─
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final navBarHeight = 70 * s + 20 * s;
                      final availableHeight =
                          constraints.maxHeight - navBarHeight;

                      return SingleChildScrollView(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: availableHeight,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(height: 62 * s),
                              Stack(
                                alignment: Alignment.topCenter,
                                clipBehavior: Clip.none,
                                children: [
                                  // Pollito asomándose
                                  Positioned(
                                    top: -62 * s,
                                    left: 32 * s,
                                    child: Image.asset(
                                      'assets/images/bienvenida/pollo feliz 2 (2).png',
                                      width: 80 * s,
                                      height: 80 * s,
                                      errorBuilder: (ctx, e, _) =>
                                          const SizedBox(),
                                    ),
                                  ),

                                  // Tarjeta blanca
                                  Container(
                                    margin: EdgeInsets.symmetric(
                                        horizontal: 20 * s),
                                    padding: EdgeInsets.fromLTRB(
                                        16 * s, 20 * s, 16 * s, 16 * s),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF6F6F6),
                                      borderRadius:
                                          BorderRadius.circular(28 * s),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black
                                              .withValues(alpha: 0.07),
                                          blurRadius: 20,
                                          offset: const Offset(0, 6),
                                        ),
                                      ],
                                    ),
                                    child: progresoAsync.when(
                                      loading: () => Padding(
                                        padding: EdgeInsets.symmetric(
                                            vertical: 40 * s),
                                        child: const Center(
                                          child: CircularProgressIndicator(
                                            color: Color(0xFF3475F7),
                                          ),
                                        ),
                                      ),
                                      error: (e, _) =>
                                          _buildMaterias(context, {}, s),
                                      data: (progreso) =>
                                          _buildMaterias(context, progreso, s),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // ── Barra de navegación inferior ────────────────────
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              margin: EdgeInsets.only(
                  left: 20 * s, right: 20 * s, bottom: 20 * s),
              height: 70 * s,
              decoration: BoxDecoration(
                color: const Color(0xFF6ED0E8),
                borderRadius: BorderRadius.circular(40 * s),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Inicio (ya estamos aquí — no hace nada)
                  IconButton(
                    onPressed: () {},
                    icon: Icon(
                      Icons.home_rounded,
                      color: Colors.white,
                      size: 34 * s,
                    ),
                    tooltip: 'Inicio',
                  ),
                  // Numi decorativo
                  Text(
                    'numi',
                    style: GoogleFonts.fredoka(
                      fontSize: 26 * s,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  // Configuración
                  IconButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const ConfiguracionView(),
                      ),
                    ),
                    icon: Icon(
                      Icons.settings_rounded,
                      color: Colors.white,
                      size: 34 * s,
                    ),
                    tooltip: 'Configuración',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMaterias(
      BuildContext context, Map<String, double> progreso, double s) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _MateriaRow(
          color: const Color(0xFF3E7DFE),
          shadowColor: const Color(0xFF2C60D2),
          icono: 'assets/images/menu_materias/123_12.png',
          nombre: 'Matemáticas',
          porcentaje: progreso['matematicas'] ?? 0.0,
          scale: s,
          onTap: () => _irA(context, const MatematicasView()),
        ),
        SizedBox(height: 12 * s),
        _MateriaRow(
          color: const Color(0xFF3DCC52),
          shadowColor: const Color(0xFF22A45D),
          icono: 'assets/images/menu_materias/planta_12.png',
          nombre: 'Ciencias',
          porcentaje: progreso['ciencias'] ?? 0.0,
          scale: s,
          onTap: () => _irA(context, const CienciasView()),
        ),
        SizedBox(height: 12 * s),
        _MateriaRow(
          color: const Color(0xFFB83232),
          shadowColor: const Color(0xFF8B1A1A),
          icono: 'assets/images/menu_materias/alfabeto_1.png',
          nombre: 'Español',
          porcentaje: progreso['español'] ?? 0.0,
          scale: s,
          onTap: () => _irA(context, const EspanolView()),
        ),
        SizedBox(height: 12 * s),
        _MateriaRow(
          color: const Color(0xFFF5A623),
          shadowColor: const Color(0xFFB8710A),
          icono: 'assets/images/menu_materias/globo_1.png',
          nombre: 'Sociales',
          porcentaje: progreso['sociales'] ?? 0.0,
          scale: s,
          onTap: () => _irA(context, const CienciasSocialesView()),
        ),
        SizedBox(height: 12 * s),
        _MateriaRow(
          color: const Color(0xFF8B5CF6),
          shadowColor: const Color(0xFF6A3592),
          icono: 'assets/images/menu_materias/libros_1.png',
          nombre: 'Inglés',
          porcentaje: progreso['ingles'] ?? 0.0,
          scale: s,
          onTap: () => _irA(context, const InglesView()),
        ),
      ],
    );
  }

  void _irA(BuildContext context, Widget vista) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => vista)).then((_) {
      ref.invalidate(menuProgresoProvider);
      _mostrarRachaPendiente();
    });
  }

  void _mostrarRachaPendiente() {
    if (!mounted) return;
    final info = ref.read(rachaPendienteProvider);
    if (info == null) return;
    ref.read(rachaPendienteProvider.notifier).state = null;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => RachaView(info: info)),
    );
  }
}

// ─── Fila de materia con icono, nombre y barra de progreso ─────
class _MateriaRow extends StatefulWidget {
  final Color color;
  final Color shadowColor;
  final String icono;
  final String nombre;
  final double porcentaje; // 0..100
  final double scale;
  final VoidCallback onTap;

  const _MateriaRow({
    required this.color,
    required this.shadowColor,
    required this.icono,
    required this.nombre,
    required this.porcentaje,
    required this.scale,
    required this.onTap,
  });

  @override
  State<_MateriaRow> createState() => _MateriaRowState();
}

class _MateriaRowState extends State<_MateriaRow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 80),
  );
  late final Animation<double> _scale = Tween<double>(
    begin: 1.0,
    end: 0.97,
  ).animate(_ctrl);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pct = widget.porcentaje.clamp(0.0, 100.0);
    final s = widget.scale;

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
          decoration: BoxDecoration(
            color: widget.color,
            borderRadius: BorderRadius.circular(18 * s),
            boxShadow: [
              BoxShadow(
                color: widget.shadowColor,
                blurRadius: 0,
                offset: Offset(0, 5 * s),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(10 * s),
            child: Row(
              children: [
                // Icono en cuadro blanco
                Container(
                  width: 56 * s,
                  height: 56 * s,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14 * s),
                  ),
                  padding: EdgeInsets.all(8 * s),
                  child: Image.asset(
                    widget.icono,
                    fit: BoxFit.contain,
                    errorBuilder: (ctx, e, _) => Icon(
                      Icons.school_rounded,
                      color: widget.color,
                      size: 28 * s,
                    ),
                  ),
                ),

                SizedBox(width: 12 * s),

                // Nombre + barra de progreso
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            widget.nombre,
                            style: TextStyle(
                              fontFamily: 'Hiruko',
                              fontSize: 18 * s,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            '${pct.toInt()}%',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 13 * s,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 6 * s),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6 * s),
                        child: LinearProgressIndicator(
                          value: pct / 100.0,
                          minHeight: 8 * s,
                          backgroundColor:
                              Colors.white.withValues(alpha: 0.3),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(width: 10 * s),

                // Flecha
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.white,
                  size: 18 * s,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}