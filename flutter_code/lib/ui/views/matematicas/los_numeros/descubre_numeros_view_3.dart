import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import '../../../../data/providers/app_state_provider.dart';
import '../../../viewmodels/descubre_globos_view_model.dart';
import '../../terminado.dart';

class DescubreGlobosView extends ConsumerStatefulWidget {
  const DescubreGlobosView({super.key});

  @override
  ConsumerState<DescubreGlobosView> createState() => _DescubreGlobosViewState();
}

class _DescubreGlobosViewState extends ConsumerState<DescubreGlobosView>
    with TickerProviderStateMixin {
  late final AudioPlayer _player;
  late final AnimationController _moveController;
  late final List<AnimationController> _floatControllers;
  late final List<Animation<double>> _floatAnimations;

  final double _balloonWidth = _BalloonWidget.kWidth;
  final List<double> _floatPhases = [0.0, 0.33, 0.66];

  static const Map<int, String> _audioMap = {
    1: 'audio_mate_globo1_mezcla.mp3',
    2: 'audio_mate_globo2_mezcla.mp3',
    3: 'audio_mate_globo3_mezcla.mp3',
    4: 'audio_mate_globo4_mezcla.mp3',
    5: 'audio_mate_globo5_mezcla.mp3',
    6: 'audio_mate_globo6_mezcla.mp3',
    7: 'audio_mate_globo7_mezcla.mp3',
    8: 'audio_mate_globo8_mezcla.mp3',
    9: 'audio_mate_globo9_mezcla.mp3',
    10: 'audio_mate_globo10_mezcla.mp3',
  };

  int? _ultimoNumeroReproducido;

  @override
  void initState() {
    super.initState();

    _player = AudioPlayer();

    _moveController = AnimationController(
      duration: const Duration(seconds: 7),
      vsync: this,
    )..repeat();

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

    _floatAnimations = _floatControllers
        .map(
          (c) => Tween<double>(
            begin: -14,
            end: 14,
          ).animate(CurvedAnimation(parent: c, curve: Curves.easeInOut)),
        )
        .toList();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vm = ref.read(descubreGlobosViewModelProvider);
      _reproducirAudioNumero(vm.numeroObjetivo);
    });
  }

  Future<void> _reproducirAudioNumero(int numero) async {
    if (_ultimoNumeroReproducido == numero) return;
    _ultimoNumeroReproducido = numero;

    final archivo = _audioMap[numero];
    if (archivo == null) {
      debugPrint('No hay audio para el número $numero');
      return;
    }

    try {
      await _player.setAsset('assets/Audio/Matematicas/$archivo');
      await _player.play();
    } catch (e) {
      debugPrint('Error reproduciendo audio del globo $numero: $e');
    }
  }

  void _showFeedbackSheet(bool esCorrecto, dynamic notifier) {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(30),
          decoration: BoxDecoration(
            color: esCorrecto
                ? const Color(0xFFD7FFD3)
                : const Color(0xFFFFD3D3),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(30),
              topRight: Radius.circular(30),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(
                    esCorrecto ? Icons.check_circle : Icons.cancel,
                    color: esCorrecto
                        ? const Color(0xFF59E347)
                        : const Color(0xFFF65757),
                    size: 40,
                  ),
                  const SizedBox(width: 15),
                  Text(
                    esCorrecto ? '¡Excelente trabajo!' : '¡Inténtalo de nuevo!',
                    style: TextStyle(
                      fontFamily: 'Hiruko',
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: esCorrecto ? Colors.green[900] : Colors.red[900],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: esCorrecto
                        ? const Color(0xFF59E347)
                        : const Color(0xFFF65757),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    if (esCorrecto) {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (_) => const ActividadTerminadaScreen(),
                        ),
                      );
                    } else {
                      notifier.commandIntentarDeNuevo();
                    }
                  },
                  child: Text(
                    esCorrecto ? 'Continuar' : 'Reintentar',
                    style: const TextStyle(
                      color: Colors.white,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _player.dispose();
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

    ref.listen(descubreGlobosViewModelProvider, (prev, next) {
      if (prev?.numeroObjetivo != next.numeroObjetivo) {
        _reproducirAudioNumero(next.numeroObjetivo);
      }
      if (prev?.feedback != next.feedback &&
          next.feedback != FeedbackEstadoGlobos.esperando) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _showFeedbackSheet(
              next.feedback == FeedbackEstadoGlobos.correcto,
              ref.read(descubreGlobosViewModelProvider.notifier),
            );
          }
        });
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFF3475F7),
      body: SafeArea(
        top: false,
        bottom: false,
        child: Column(
          children: [
            _Header(onClose: () => Navigator.of(context).pop(), progreso: 1.0),
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
                            _InstruccionCard(
                              numeroObjetivo: vm.numeroObjetivo,
                              onAudio: () =>
                                  _reproducirAudioNumero(vm.numeroObjetivo),
                            ),
                            const SizedBox(height: 32),
                            Expanded(
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  return ClipRect(
                                    child: AnimatedBuilder(
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
                                              availableHeight:
                                                  constraints.maxHeight,
                                              relativeOffset: i / 3,
                                              numero: vm.numerosEnGlobos[i],
                                              floatValue:
                                                  _floatAnimations[i].value,
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
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
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

  Widget _buildLoopedBalloon({
    required double screenWidth,
    required double availableHeight,
    required double relativeOffset,
    required int numero,
    required double floatValue,
    required bool yaRespondioCorrectamente,
    required VoidCallback? onTap,
  }) {
    // Escalar el globo para que quepa verticalmente con margen, máx tamaño original
    const double floatMargin = 30.0; // espacio para la animación flotante
    final double maxH = availableHeight - floatMargin * 2;
    final double scale = (maxH / _BalloonWidget.kHeight).clamp(0.3, 1.0);
    final double scaledW = _BalloonWidget.kWidth * scale;
    final double scaledH = _BalloonWidget.kHeight * scale;

    final double totalDistance = screenWidth + scaledW;

    double xPos =
        (screenWidth -
                (_moveController.value * totalDistance) +
                (relativeOffset * totalDistance)) %
            totalDistance -
        scaledW;

    final double yBase = (availableHeight - scaledH) / 2;

    return Positioned(
      left: xPos,
      top: yBase + floatValue,
      child: SizedBox(
        width: scaledW,
        height: scaledH,
        child: _BalloonWidget(numero: numero, onTap: onTap),
      ),
    );
  }
}

// ── WIDGETS ──────────────────────────────────────────────────────────────────

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
                  'Descubre  los números',
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
          const SizedBox(width: 10),
          Image.asset(
            'assets/images/actividades/matematicas/globo.png',
            width: 70,
            height: 90,
          ),
        ],
      ),
    );
  }
}

class _BalloonWidget extends StatelessWidget {
  final int numero;
  final VoidCallback? onTap;

  const _BalloonWidget({required this.numero, required this.onTap});

  // Dimensiones del globo — usadas también en _buildLoopedBalloon
  static const double kWidth = 400.0;
  static const double kHeight = 490.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      // Sin SizedBox fijo: respeta el tamaño que le pase el padre
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Escalar fuente proporcionalmente al alto disponible
          final double fontSize = (constraints.maxHeight * 0.12).clamp(
            28.0,
            70.0,
          );
          return Stack(
            children: [
              Positioned.fill(
                child: Image.asset(
                  'assets/images/actividades/matematicas/globo.png',
                  fit: BoxFit.contain,
                ),
              ),
              Align(
                alignment: const Alignment(0, -0.15),
                child: Text(
                  '$numero',
                  style: TextStyle(
                    fontFamily: 'Hiruko',
                    fontSize: fontSize,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1,
                    shadows: const [
                      Shadow(
                        color: Colors.black26,
                        offset: Offset(1, 2),
                        blurRadius: 3,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
