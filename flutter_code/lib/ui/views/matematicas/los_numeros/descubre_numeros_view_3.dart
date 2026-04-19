import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/providers/app_state_provider.dart';
import '../../../viewmodels/descubre_globos_view_model.dart';
import '../../terminado.dart';

/// Vista de búsqueda del número correcto con globos en movimiento
/// Tipografía Numi: Hiruko (títulos) + Poppins (textos)
/// Colores Numi: Azul #3475F7, Verde #59E347, Rojo #F65757
class DescubreGlobosView extends ConsumerStatefulWidget {
  const DescubreGlobosView({super.key});

  @override
  ConsumerState<DescubreGlobosView> createState() => _DescubreGlobosViewState();
}

class _DescubreGlobosViewState extends ConsumerState<DescubreGlobosView>
    with TickerProviderStateMixin {
  // ── Controlador de movimiento horizontal (bucle infinito) ──────────────
  late final AnimationController _moveController;

  // ── Controladores de flotación vertical (uno por globo, desfasados) ───
  late final List<AnimationController> _floatControllers;
  late final List<Animation<double>> _floatAnimations;

  final double _balloonWidth = 120.0;

  // Desfase de fase para que cada globo flote diferente
  final List<double> _floatPhases = [0.0, 0.33, 0.66];

  @override
  void initState() {
    super.initState();

    // Movimiento horizontal continuo
    _moveController = AnimationController(
      duration: const Duration(seconds: 7),
      vsync: this,
    )..repeat();

    // Flotación vertical: cada globo tiene su propio controller con distinta duración
    // para que no suban y bajen todos al mismo tiempo
    final durations = [
      const Duration(milliseconds: 1800),
      const Duration(milliseconds: 2200),
      const Duration(milliseconds: 1500),
    ];

    _floatControllers = List.generate(
      3,
      (i) =>
          AnimationController(duration: durations[i], vsync: this)
            ..repeat(reverse: true),
    );

    // Cada animación sube y baja entre -14 y 14 píxeles
    _floatAnimations = _floatControllers
        .map(
          (c) => Tween<double>(
            begin: -14,
            end: 14,
          ).animate(CurvedAnimation(parent: c, curve: Curves.easeInOut)),
        )
        .toList();
  }

  @override
  void dispose() {
    _moveController.dispose();
    for (final c in _floatControllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = ref.watch(descubreGlobosViewModelProvider);
    final notifier = ref.read(descubreGlobosViewModelProvider.notifier);
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFF3475F7),
      body: SafeArea(
        top: false,
        bottom: false,
        child: Column(
          children: [
            // ── ENCABEZADO AZUL ──────────────────────────────────────────
            _Header(
              onClose: () => Navigator.of(context).pop(),
              progreso: 1.0, // Fase 3 de 3 (Final)
            ),

            // ── CUERPO PRINCIPAL ─────────────────────────────────────────
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Color(0xFFF5F7FF),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(40),
                    topRight: Radius.circular(40),
                  ),
                ),
                child: Column(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ── Tarjeta de instrucción ──────────────────
                            _InstruccionCard(
                              numeroObjetivo: vm.numeroObjetivo,
                              onAudio: notifier.commandReproducirInstruccion,
                            ),
                            const SizedBox(height: 32),

                            // ── Área de globos animados ──────────────────
                            Expanded(
                              child: ClipRect(
                                child: AnimatedBuilder(
                                  // Escucha todos los controllers a la vez
                                  animation: Listenable.merge([
                                    _moveController,
                                    ..._floatControllers,
                                  ]),
                                  builder: (context, _) {
                                    return Stack(
                                      clipBehavior: Clip.none,
                                      children: List.generate(
                                        vm.numerosEnGlobos.length,
                                        (i) => _buildLoopedBalloon(
                                          screenWidth: screenWidth,
                                          relativeOffset: i / 3,
                                          numero: vm.numerosEnGlobos[i],
                                          floatValue: _floatAnimations[i].value,
                                          yaRespondioCorrectamente:
                                              vm.yaRespondioCorrectamente,
                                          onTap: vm.yaRespondioCorrectamente
                                              ? null
                                              : () => notifier
                                                    .commandValidarRespuesta(
                                                      vm.numerosEnGlobos[i],
                                                    ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // ── PANEL DE FEEDBACK ────────────────────────────────
                    _FeedbackPanel(
                      estado: vm.feedback,
                      numeroObjetivo: vm.numeroObjetivo,
                      onNuevoReto: notifier.commandNuevoReto,
                      onIntentarDeNuevo: notifier.commandIntentarDeNuevo,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Construye un globo con movimiento horizontal en bucle + flotación vertical
  Widget _buildLoopedBalloon({
    required double screenWidth,
    required double relativeOffset,
    required int numero,
    required double floatValue,
    required bool yaRespondioCorrectamente,
    required VoidCallback? onTap,
  }) {
    final double totalDistance = screenWidth + _balloonWidth;

    // Posición X: bucle infinito de derecha a izquierda
    double xPos =
        (screenWidth -
                (_moveController.value * totalDistance) +
                (relativeOffset * totalDistance)) %
            totalDistance -
        _balloonWidth;

    // Posición Y: centro del área + flotación individual
    final double yBase = 20;

    return Positioned(
      left: xPos,
      top: yBase + floatValue, // flotación arriba/abajo
      child: _BalloonWidget(numero: numero, onTap: onTap),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// WIDGETS INTERNOS
// ────────────────────────────────────────────────────────────────────────────

/// Encabezado unificado con barra de progreso y sync status
class _Header extends ConsumerWidget {
  final VoidCallback onClose;
  final double progreso;
  const _Header({required this.onClose, required this.progreso});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncState = ref.watch(syncListenerProvider);
    final estudiante = ref.watch(estudianteActivoProvider);

    return SizedBox(
      height: 150,
      width: double.infinity,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            top: 12,
            left: 20,
            child: syncState.when(
              data: (count) => Icon(
                count > 0 ? Icons.sync_rounded : Icons.cloud_done_rounded,
                color: Colors.white.withOpacity(0.7),
                size: 22,
              ),
              error: (_, __) => const Icon(
                Icons.cloud_off_rounded,
                color: Colors.white30,
                size: 22,
              ),
              loading: () => const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white30,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 60),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Descubre los números',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Hiruko',
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1.2,
                  ),
                ),
                if (estudiante != null)
                  Text(
                    'Fase final: ¡Globos rápidos!',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
              ],
            ),
          ),
          Positioned(
            top: 12,
            right: 8,
            child: IconButton(
              icon: const Icon(
                Icons.close_rounded,
                color: Colors.white,
                size: 28,
              ),
              onPressed: onClose,
            ),
          ),
          Positioned(
            bottom: 15,
            left: 45,
            right: 45,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: progreso,
                backgroundColor: Colors.white.withOpacity(0.15),
                valueColor: const AlwaysStoppedAnimation<Color>(
                  Color(0xFF59E347),
                ),
                minHeight: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Tarjeta de instrucción con número objetivo resaltado
class _InstruccionCard extends StatelessWidget {
  final int numeroObjetivo;
  final VoidCallback onAudio;

  const _InstruccionCard({required this.numeroObjetivo, required this.onAudio});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3475F7).withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Botón audio
          GestureDetector(
            onTap: onAudio,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFEEF2FF),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.volume_up_rounded,
                color: Color(0xFF3475F7),
                size: 26,
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Texto con el número resaltado en azul
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B),
                  height: 1.3,
                ),
                children: [
                  const TextSpan(text: 'Presiona el globo cuando salga el '),
                  TextSpan(
                    text: '$numeroObjetivo',
                    style: const TextStyle(
                      color: Color(0xFF3475F7),
                      fontWeight: FontWeight.w800,
                      fontSize: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Globo individual: imagen de fondo + número perfectamente centrado
class _BalloonWidget extends StatelessWidget {
  final int numero;
  final VoidCallback? onTap;

  const _BalloonWidget({required this.numero, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 120,
        height: 160,
        child: Stack(
          children: [
            // Globo de fondo
            Positioned.fill(
              child: Image.asset(
                'assets/images/actividades/matematicas/globo.png',
                fit: BoxFit.contain,
              ),
            ),

            // Número centrado dentro del "cuerpo" del globo
            // El cuerpo del globo ocupa ~75% de la altura total (sin el nudo ni hilo)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              // El 75% superior es la parte redonda del globo
              bottom: 160 * 0.25,
              child: Center(
                child: Text(
                  '$numero',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 44,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    height: 1,
                    shadows: [
                      Shadow(
                        color: Colors.black26,
                        offset: Offset(1, 2),
                        blurRadius: 3,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// PANEL DE FEEDBACK (pestaña inferior)
// ────────────────────────────────────────────────────────────────────────────

class _FeedbackPanel extends StatelessWidget {
  final FeedbackEstadoGlobos estado;
  final int numeroObjetivo;
  final VoidCallback onNuevoReto;
  final VoidCallback onIntentarDeNuevo;

  const _FeedbackPanel({
    required this.estado,
    required this.numeroObjetivo,
    required this.onNuevoReto,
    required this.onIntentarDeNuevo,
  });

  Color get _bgColor {
    switch (estado) {
      case FeedbackEstadoGlobos.correcto:
        return const Color(0xFF59E347);
      case FeedbackEstadoGlobos.incorrecto:
        return const Color(0xFFF65757);
      case FeedbackEstadoGlobos.esperando:
        return Colors.white;
    }
  }

  String get _icono {
    switch (estado) {
      case FeedbackEstadoGlobos.correcto:
        return '⭐';
      case FeedbackEstadoGlobos.incorrecto:
        return '💡';
      case FeedbackEstadoGlobos.esperando:
        return '🎈';
    }
  }

  String get _mensaje {
    switch (estado) {
      case FeedbackEstadoGlobos.correcto:
        return '¡Excelente! Encontraste el $numeroObjetivo. ¡Muy bien!';
      case FeedbackEstadoGlobos.incorrecto:
        return 'Ese no es el $numeroObjetivo. ¡Sigue buscando!';
      case FeedbackEstadoGlobos.esperando:
        return 'Observa los globos y toca el que tenga el $numeroObjetivo.';
    }
  }

  Color get _textoColor {
    return estado == FeedbackEstadoGlobos.esperando
        ? const Color(0xFF94A3B8)
        : Colors.white;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      width: double.infinity,
      decoration: BoxDecoration(
        color: _bgColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        18,
        20,
        MediaQuery.of(context).padding.bottom + 18,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Ícono + Mensaje ─────────────────────────────────────────
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: estado == FeedbackEstadoGlobos.esperando
                      ? const Color(0xFFEEF2FF)
                      : Colors.white.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(_icono, style: const TextStyle(fontSize: 22)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _mensaje,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _textoColor,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Botones según estado ────────────────────────────────────
          if (estado == FeedbackEstadoGlobos.esperando)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF3475F7).withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text(
                'Toca el globo correcto para responder',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF3475F7),
                ),
              ),
            )
          else if (estado == FeedbackEstadoGlobos.correcto)
            _BotonPrincipal(
              texto: '¡Completar actividad! 🏆',
              bgColor: Colors.white,
              textoColor: const Color(0xFF59E347),
              onTap: () {
                // Usamos pushReplacement para que la pantalla de felicitación tome el lugar
                // de la actividad en la pila de navegación. Al no pasar un callback 'onVolver',
                // la pantalla usará su comportamiento por defecto: pop().
                // Como MatematicasView fue quien inició la secuencia, volveremos ahí directamente.
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const ActividadTerminadaScreen()),
                );
              },
            )
          else ...[
            _BotonPrincipal(
              texto: 'Intentar de nuevo',
              bgColor: Colors.white,
              textoColor: const Color(0xFFF65757),
              onTap: onIntentarDeNuevo,
            ),
            const SizedBox(height: 10),
            _BotonSecundario(texto: 'Cambiar reto', onTap: onNuevoReto),
          ],
        ],
      ),
    );
  }
}

class _BotonPrincipal extends StatelessWidget {
  final String texto;
  final Color bgColor;
  final Color textoColor;
  final VoidCallback onTap;

  const _BotonPrincipal({
    required this.texto,
    required this.bgColor,
    required this.textoColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          foregroundColor: textoColor,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Text(
          texto,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _BotonSecundario extends StatelessWidget {
  final String texto;
  final VoidCallback onTap;

  const _BotonSecundario({required this.texto, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          backgroundColor: Colors.white.withOpacity(0.25),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Text(
          texto,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
