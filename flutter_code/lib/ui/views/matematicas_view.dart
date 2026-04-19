// ─────────────────────────────────────────────────────────────
//  lib/ui/views/matematicas_view.dart
// ─────────────────────────────────────────────────────────────

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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 10),

                  // Fila Superior: Volver + Sync Status
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: () {
                            vm.commandVolver();
                            Navigator.of(context).maybePop();
                          },
                          child: const Icon(
                            Icons.arrow_back_rounded,
                            size: 36,
                            color: Colors.black,
                          ),
                        ),
                        // Indicador de Sincronización Offline (Base de Datos)
                        syncState.when(
                          data: (count) => Icon(
                            count > 0
                                ? Icons.sync_rounded
                                : Icons.cloud_done_rounded,
                            color: Colors.black45,
                            size: 24,
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

                  const SizedBox(height: 8),

                  // Título
                  const Text(
                    'Matemáticas',
                    style: TextStyle(
                      fontFamily: 'Hiruko',
                      fontSize: 38,
                      fontWeight: FontWeight.w900,
                      color: Colors.black,
                    ),
                  ),
                  if (estudiante != null)
                    Text(
                      'Hola, ${estudiante.nombre}',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        color: Colors.black54,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                  // Barra de progreso real (actividades completadas / total)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 4,
                    ),
                    child: _BarraProgreso(
                      porcentaje: vm.progresoTotal,
                      color: const Color(0xFF3475F7),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Botones + Pollo
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // Pollo detrás
                        Positioned(
                          top: -18,
                          left: 10,
                          child: Image.asset(
                            'assets/images/avatares/pollo feliz 2 (2).png',
                            width: 80,
                            errorBuilder: (ctx, e, _) => const SizedBox(),
                          ),
                        ),

                        Column(
                          children: [
                            const SizedBox(height: 55),
                            _BotonMateria(
                              rutaIcono:
                                  'assets/images/areas/matematicas/Group 40 (1) (1).png',
                              texto: 'Los números',
                              completado: _estaCompletado(vm, 'Los números'),
                              onTap: () async {
                                // Iniciamos la secuencia de fases
                                await Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const DescubreNumerosView(),
                                  ),
                                );
                                // REFRESCAR: Al regresar de 'Terminado', actualizamos la UI con la DB
                                ref
                                    .read(matematicasViewModelProvider)
                                    .commandCargarProgreso();
                              },
                            ),

                            const SizedBox(height: 14),
                            _BotonMateria(
                              rutaIcono:
                                  'assets/images/areas/matematicas/_ (1) (1).png',
                              texto: 'Quien tiene más',
                              completado: _estaCompletado(
                                vm,
                                'Quien tiene más',
                              ),
                              onTap: () async {
                                // Iniciamos la secuencia de "Quién tiene más"
                                await Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const ComparacionCantidadesView(),
                                  ),
                                );
                                // Al volver de la pantalla de éxito, refrescamos el progreso
                                ref.read(matematicasViewModelProvider).commandCargarProgreso();
                              },
                            ),
                            const SizedBox(height: 14),
                            _BotonMateria(
                              rutaIcono:
                                  'assets/images/areas/matematicas/Group 41 (1) (2).png',
                              texto: 'Sumar',
                              completado: _estaCompletado(vm, 'Sumar'),
                              onTap: () async {
                                await Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const SumarPatronview(),
                                  ),
                                );
                                ref.read(matematicasViewModelProvider).commandCargarProgreso();
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),
                ],
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
                fontFamily: 'Poppins',
                fontSize: 12,
                color: Colors.black54,
              ),
            ),
            Text(
              '${porcentaje.toInt()}%',
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                fontWeight: FontWeight.w600,
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

// ─── Botón de lección ──────────────────────────────────────────
class _BotonMateria extends StatefulWidget {
  final String rutaIcono;
  final String texto;
  final bool completado;
  final VoidCallback onTap;

  const _BotonMateria({
    required this.rutaIcono,
    required this.texto,
    required this.completado,
    required this.onTap,
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
          height: 84,
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
                width: 68,
                height: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(8),
                child: Image.asset(
                  widget.rutaIcono,
                  fit: BoxFit.contain,
                  errorBuilder: (ctx, e, _) => const Icon(
                    Icons.calculate_rounded,
                    color: Color(0xFF3475F7),
                    size: 32,
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
                      fontSize: 21,
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
                    ? const Icon(
                        Icons.check_circle_rounded,
                        color: Colors.white,
                        size: 28,
                      )
                    : const Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
