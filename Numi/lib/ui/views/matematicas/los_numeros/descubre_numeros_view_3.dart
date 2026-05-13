import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import '../../../../data/providers/app_state_provider.dart';
import '../../../viewmodels/descubre_globos_view_model.dart';
import '../../terminado.dart';
import '../../../../data/services/feedback_sounds.dart';

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
    FeedbackSounds.instance.reproducir(esCorrecto);
    final mq       = MediaQuery.of(context);
    final sw       = mq.size.width;
    final isTablet = sw >= 600;

    showModalBottomSheet(
      context: context,
      isDismissible: false,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: isTablet ? sw * 0.08 : 26,
            vertical: 26,
          ),
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
                    size: isTablet ? 52 : 40,
                  ),
                  SizedBox(width: isTablet ? 20 : 14),
                  Flexible(
                    child: Text(
                      esCorrecto ? '¡Excelente trabajo!' : '¡Inténtalo de nuevo!',
                      style: TextStyle(
                        fontFamily: 'Hiruko',
                        fontSize: isTablet ? 30 : 22,
                        fontWeight: FontWeight.bold,
                        color: esCorrecto ? Colors.green[900] : Colors.red[900],
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: isTablet ? 28 : 18),
              SizedBox(
                width: double.infinity,
                height: isTablet ? 64 : 52,
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
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.bold,
                      fontSize: isTablet ? 22 : 18,
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

    final mq       = MediaQuery.of(context);
    final sw       = mq.size.width;
    final sh       = mq.size.height;
    final isTablet = sw >= 600;
    final hPad     = isTablet ? sw * 0.06 : sw * 0.05;

    return Scaffold(
      backgroundColor: const Color(0xFF3475F7),
      body: Column(
        children: [
          _Header(onClose: () => Navigator.of(context).pop(), progreso: 1.0),
          Expanded(
            child: Container(
              width: double.infinity,
              clipBehavior: Clip.hardEdge,
              decoration: const BoxDecoration(
                color: Color(0xFFF5F7FF),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(40),
                  topRight: Radius.circular(40),
                ),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(hPad, sh * 0.025, hPad, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _InstruccionCard(
                              numeroObjetivo: vm.numeroObjetivo,
                              onAudio: () =>
                                  _reproducirAudioNumero(vm.numeroObjetivo),
                            ),
                            SizedBox(height: sh * 0.022),
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
          ),
        ],
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
    const double floatMargin = 28.0;

    // Escalar usando tanto el alto como el ancho disponible:
    // el globo no debe ser más alto que el área, ni más ancho que ~55% de la pantalla
    final double maxH = availableHeight - floatMargin * 2;
    final double scaleByH = maxH / _BalloonWidget.kHeight;
    final double scaleByW = (screenWidth * 0.55) / _BalloonWidget.kWidth;
    final double scale = scaleByH < scaleByW ? scaleByH : scaleByW;

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
    final syncState  = ref.watch(syncListenerProvider);
    final estudiante = ref.watch(estudianteActivoProvider);
    final mq         = MediaQuery.of(context);
    final topPad     = mq.padding.top;
    final sw         = mq.size.width;
    final sh         = mq.size.height;
    final isTablet   = sw >= 600;

    final contentH = (sh * 0.13).clamp(80.0, 140.0);
    final totalH   = topPad + contentH;

    return SizedBox(
      height: totalH,
      width: double.infinity,
      child: Stack(
        children: [
          // Icono sync — debajo del status bar
          Positioned(
            top: topPad + 8,
            left: 20,
            child: syncState.when(
              data: (count) => Icon(
                count > 0 ? Icons.sync_rounded : Icons.cloud_done_rounded,
                color: Colors.white.withOpacity(0.7),
                size: isTablet ? 26 : 22,
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
          // Título + subtítulo centrados
          Positioned.fill(
            top: topPad,
            child: Align(
              alignment: const Alignment(0, -0.2),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: isTablet ? 80 : 60),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Descubre  los números',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Hiruko',
                        fontSize: isTablet ? 32 : 22,
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
                          fontSize: isTablet ? 14 : 12,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          // Botón cerrar
          Positioned(
            top: topPad + 4,
            right: 8,
            child: IconButton(
              icon: Icon(
                Icons.close_rounded,
                color: Colors.white,
                size: isTablet ? 34 : 28,
              ),
              onPressed: onClose,
            ),
          ),
          // Barra de progreso
          Positioned(
            bottom: 14,
            left: isTablet ? 60 : 40,
            right: isTablet ? 60 : 40,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: progreso,
                backgroundColor: Colors.white.withOpacity(0.15),
                valueColor: const AlwaysStoppedAnimation<Color>(
                  Color(0xFF59E347),
                ),
                minHeight: isTablet ? 12 : 10,
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
    final mq       = MediaQuery.of(context);
    final sw       = mq.size.width;
    final sh       = mq.size.height;
    final isTablet = sw >= 600;

    final iconSize  = (sh * 0.062).clamp(40.0, 72.0);
    final fontSize  = (sw * 0.055).clamp(18.0, 40.0);
    final numSize   = fontSize * 1.18;
    final globoW    = (sw * 0.16).clamp(52.0, 90.0);
    final globoH    = globoW * 1.28;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 18 : 14,
        vertical: (sh * 0.016).clamp(10.0, 18.0),
      ),
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
              width: iconSize,
              height: iconSize,
              decoration: BoxDecoration(
                color: const Color(0xFFEEF2FF),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                Icons.volume_up_rounded,
                color: const Color(0xFF3475F7),
                size: iconSize * 0.54,
              ),
            ),
          ),
          SizedBox(width: isTablet ? 16 : 12),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                  fontFamily: 'Hiruko',
                  fontSize: fontSize,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1E293B),
                  height: 1.3,
                ),
                children: [
                  const TextSpan(text: 'Presiona el globo cuando salga el '),
                  TextSpan(
                    text: '$numeroObjetivo',
                    style: TextStyle(
                      color: const Color(0xFF3475F7),
                      fontWeight: FontWeight.w800,
                      fontSize: numSize,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(width: isTablet ? 12 : 8),
          Image.asset(
            'assets/images/actividades/matematicas/globo.png',
            width: globoW,
            height: globoH,
            fit: BoxFit.contain,
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
              // El hilo/cuerda ocupa ~22% inferior de la imagen.
              // Centramos el número dentro del área del globo (78% superior).
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                height: constraints.maxHeight * 0.93,
                child: Center(
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
              ),
            ],
          );
        },
      ),
    );
  }
}