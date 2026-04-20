// ─────────────────────────────────────────────────────────────
//  lib/ui/views/menu_1_y_2_view.dart
//  Menú principal para grados 1 y 2.
//  Muestra las 5 materias con barra de progreso real desde la BD.
// ─────────────────────────────────────────────────────────────

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/providers/app_state_provider.dart';
import '../../data/providers/database_provider.dart';
import 'inicio_view.dart';
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

class _Menu1Y2ScreenState extends ConsumerState<Menu1Y2Screen> {
  Future<void> _confirmarReset() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reiniciar base de datos'),
        content: const Text(
            '¿Borrar todos los datos y empezar desde cero?\nEsta acción no se puede deshacer.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Borrar', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirmar != true || !mounted) return;
    await ref.read(resetDbProvider)();
    await ref.read(sqliteServiceProvider).database;
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const InicioView()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Lee el progreso de todas las materias desde la BD
    final progresoAsync = ref.watch(menuProgresoProvider);
    final estudiante = ref.watch(estudianteActivoProvider);

    final nombre = estudiante?.nombre ?? widget.nombre;
    final avatar = estudiante?.personaje ?? widget.avatar;
    final nivel = estudiante?.grado ?? widget.nivel;

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
                const Padding(
                  padding: EdgeInsets.only(
                    left: 24,
                    right: 24,
                    top: 14,
                    bottom: 4,
                  ),
                  child: Text(
                    '¡Hola!',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                ),

                // ── Barra de perfil ─────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B74FF),
                      borderRadius: BorderRadius.circular(40),
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
                          width: 50,
                          height: 50,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                          ),
                          padding: const EdgeInsets.all(4),
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
                        const SizedBox(width: 12),
                        // Nombre
                        Expanded(
                          child: Text(
                            nombre,
                            style: const TextStyle(
                              fontFamily: 'Hiruko',
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        // Grado
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '$nivel° Grado',
                            style: const TextStyle(
                              fontFamily: 'Hiruko',
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                    ),
                  ),
                ),

                // Espacio fijo para que el pollo nunca toque la barra de perfil
                const SizedBox(height: 72),

                // ── Tarjeta de materias (scrollable) ───────────
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(bottom: 100),
                    child: Stack(
                      alignment: Alignment.topCenter,
                      clipBehavior: Clip.none,
                      children: [
                        // Pollito asomándose
                        Positioned(
                          top: -62,
                          left: 32,
                          child: Image.asset(
                            'assets/images/bienvenida/pollo feliz 2 (2).png',
                            width: 80,
                            height: 80,
                            errorBuilder: (ctx, e, _) => const SizedBox(),
                          ),
                        ),

                        // Tarjeta blanca
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 20),
                          padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF6F6F6),
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.07),
                                blurRadius: 20,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: progresoAsync.when(
                            loading: () => const Padding(
                              padding: EdgeInsets.symmetric(vertical: 40),
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: Color(0xFF3475F7),
                                ),
                              ),
                            ),
                            error: (e, _) => _buildMaterias(context, {}),
                            data: (progreso) =>
                                _buildMaterias(context, progreso),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Botón debug: reiniciar BD (solo en modo debug) ──
          if (kDebugMode)
            Positioned(
              top: 12,
              right: 12,
              child: SafeArea(
                child: IconButton(
                  icon: const Icon(Icons.delete_forever,
                      color: Colors.white54, size: 28),
                  tooltip: 'Reiniciar base de datos',
                  onPressed: _confirmarReset,
                ),
              ),
            ),

          // ── Barra de navegación inferior ────────────────────
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              margin: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
              height: 70,
              decoration: BoxDecoration(
                color: const Color(0xFF6ED0E8),
                borderRadius: BorderRadius.circular(40),
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
                    icon: const Icon(
                      Icons.home_rounded,
                      color: Colors.white,
                      size: 34,
                    ),
                    tooltip: 'Inicio',
                  ),
                  // Progreso (recarga las barras)
                  IconButton(
                    onPressed: () => ref.invalidate(menuProgresoProvider),
                    icon: const Icon(
                      Icons.bar_chart_rounded,
                      color: Colors.white,
                      size: 34,
                    ),
                    tooltip: 'Actualizar progreso',
                  ),
                  // Configuración
                  IconButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const ConfiguracionView(),
                      ),
                    ),
                    icon: const Icon(
                      Icons.settings_rounded,
                      color: Colors.white,
                      size: 34,
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

  Widget _buildMaterias(BuildContext context, Map<String, double> progreso) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _MateriaRow(
          color: const Color(0xFF3E7DFE),
          shadowColor: const Color(0xFF2C60D2),
          icono: 'assets/images/menu_materias/123_1.png',
          nombre: 'Matemáticas',
          porcentaje: progreso['matematicas'] ?? 0.0,
          onTap: () => _irA(context, const MatematicasView()),
        ),
        const SizedBox(height: 12),
        _MateriaRow(
          color: const Color(0xFF3DCC52),
          shadowColor: const Color(0xFF22A45D),
          icono: 'assets/images/menu_materias/planta_1.png',
          nombre: 'Ciencias',
          porcentaje: progreso['ciencias'] ?? 0.0,
          onTap: () => _irA(context, const CienciasView()),
        ),
        const SizedBox(height: 12),
        _MateriaRow(
          color: const Color(0xFFB83232),
          shadowColor: const Color(0xFF8B1A1A),
          icono: 'assets/images/menu_materias/alfabeto_1.png',
          nombre: 'Español',
          porcentaje: progreso['español'] ?? 0.0,
          onTap: () => _irA(context, const EspanolView()),
        ),
        const SizedBox(height: 12),
        _MateriaRow(
          color: const Color(0xFFF5A623),
          shadowColor: const Color(0xFFB8710A),
          icono: 'assets/images/menu_materias/globo_1.png',
          nombre: 'Sociales',
          porcentaje: progreso['sociales'] ?? 0.0,
          onTap: () => _irA(context, const CienciasSocialesView()),
        ),
        const SizedBox(height: 12),
        _MateriaRow(
          color: const Color(0xFF8B5CF6),
          shadowColor: const Color(0xFF6A3592),
          icono: 'assets/images/menu_materias/libros_1.png',
          nombre: 'Inglés',
          porcentaje: progreso['ingles'] ?? 0.0,
          onTap: () => _irA(context, const InglesView()),
        ),
      ],
    );
  }

  void _irA(BuildContext context, Widget vista) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => vista)).then((
      _,
    ) {
      // Recarga el progreso al volver de cualquier materia
      ref.invalidate(menuProgresoProvider);
    });
  }
}

// ─── Fila de materia con icono, nombre y barra de progreso ─────
class _MateriaRow extends StatefulWidget {
  final Color color;
  final Color shadowColor;
  final String icono;
  final String nombre;
  final double porcentaje; // 0..100
  final VoidCallback onTap;

  const _MateriaRow({
    required this.color,
    required this.shadowColor,
    required this.icono,
    required this.nombre,
    required this.porcentaje,
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
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: widget.shadowColor,
                blurRadius: 0,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                // Icono en cuadro blanco
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.all(8),
                  child: Image.asset(
                    widget.icono,
                    fit: BoxFit.contain,
                    errorBuilder: (ctx, e, _) => Icon(
                      Icons.school_rounded,
                      color: widget.color,
                      size: 28,
                    ),
                  ),
                ),

                const SizedBox(width: 12),

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
                            style: const TextStyle(
                              fontFamily: 'Hiruko',
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            '${pct.toInt()}%',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: pct / 100.0,
                          minHeight: 8,
                          backgroundColor: Colors.white.withValues(alpha: 0.3),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 10),

                // Flecha
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
