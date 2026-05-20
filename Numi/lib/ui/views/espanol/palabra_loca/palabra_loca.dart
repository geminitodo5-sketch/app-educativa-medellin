import 'dart:convert';
import 'dart:math' show min;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import '../../../../data/services/feedback_sounds.dart';
import '../../../../data/models/sync_queue_model.dart';
import '../../../../data/providers/app_state_provider.dart'
    show estudianteActivoProvider;
import '../../../../data/providers/database_provider.dart';
import '../../terminado.dart';

// MODELO

class PalabraLocaData {
  final String imagenAsset;
  final String frase;
  final bool estaCorrecta;

  const PalabraLocaData({
    required this.imagenAsset,
    required this.frase,
    required this.estaCorrecta,
  });
}

// ESTADO

enum RespuestaEstado { ninguna, correcta, incorrecta }

class PalabraLocaState {
  final int preguntaIndex;
  final RespuestaEstado respuesta;
  final bool actividadFinalizada;

  const PalabraLocaState({
    required this.preguntaIndex,
    required this.respuesta,
    this.actividadFinalizada = false,
  });

  bool get respondida => respuesta != RespuestaEstado.ninguna;

  PalabraLocaState copyWith({
    int? preguntaIndex,
    RespuestaEstado? respuesta,
    bool? actividadFinalizada,
  }) {
    return PalabraLocaState(
      preguntaIndex: preguntaIndex ?? this.preguntaIndex,
      respuesta: respuesta ?? this.respuesta,
      actividadFinalizada: actividadFinalizada ?? this.actividadFinalizada,
    );
  }
}

// VIEW MODEL

class PalabraLocaViewModel extends StateNotifier<PalabraLocaState> {
  final Ref _ref;

  PalabraLocaViewModel(this._ref)
      : super(const PalabraLocaState(
          preguntaIndex: 0,
          respuesta: RespuestaEstado.ninguna,
        ));

  static const List<PalabraLocaData> preguntas = [
    PalabraLocaData(
      imagenAsset: 'assets/images/actividades/espanol/mono_corazon.png',
      frase: 'El mono sonriente\nte está',
      estaCorrecta: false,
    ),
    PalabraLocaData(
      imagenAsset: 'assets/images/actividades/espanol/manzana.png',
      frase: 'La manzana es roja',
      estaCorrecta: true,
    ),
    PalabraLocaData(
      imagenAsset: 'assets/images/actividades/espanol/pinguinos.png',
      frase: 'Los pingüinos\nde tres son',
      estaCorrecta: false,
    ),
  ];

  PalabraLocaData get preguntaActual => preguntas[state.preguntaIndex];

  void commandResponder(bool eligioCorrecto) {
    if (state.respondida) return;
    final correcto = eligioCorrecto == preguntaActual.estaCorrecta;
    state = state.copyWith(
      respuesta: correcto
          ? RespuestaEstado.correcta
          : RespuestaEstado.incorrecta,
    );
  }

  void commandSiguiente() {
    final esUltima = state.preguntaIndex == preguntas.length - 1;
    if (esUltima) {
      _guardarProgreso();
      state = state.copyWith(actividadFinalizada: true);
    } else {
      state = PalabraLocaState(
        preguntaIndex: state.preguntaIndex + 1,
        respuesta: RespuestaEstado.ninguna,
      );
    }
  }

  Future<void> _guardarProgreso() async {
    try {
      final estudiante = _ref.read(estudianteActivoProvider);
      final estudianteId = estudiante?.id ?? 1;
      final grado = estudiante?.grado ?? 1;

      await _ref.read(progresoRepositoryProvider).registrarIntento(
            estudianteId: estudianteId,
            grado: grado,
            materia: 'español',
            actividad: 'Palabra loca',
            porcentaje: 100.0,
          );

      await _ref.read(syncQueueRepositoryProvider).encolar(SyncQueueModel(
            tipoAccion: 'progreso',
            payload: jsonEncode({
              'estudiante_id': estudianteId,
              'grado': grado,
              'materia': 'español',
              'actividad': 'Palabra loca',
              'porcentaje': 100.0,
            }),
            fecha: DateTime.now().toIso8601String(),
          ));
    } catch (e) {
      debugPrint('Error guardando progreso Palabra loca: $e');
    }
  }
}

final palabraLocaViewModelProvider =
    StateNotifierProvider.autoDispose<PalabraLocaViewModel, PalabraLocaState>(
  (ref) => PalabraLocaViewModel(ref),
);

// SCREEN

class PalabraLocaScreen extends ConsumerStatefulWidget {
  const PalabraLocaScreen({super.key});

  @override
  ConsumerState<PalabraLocaScreen> createState() => _PalabraLocaScreenState();
}

class _PalabraLocaScreenState extends ConsumerState<PalabraLocaScreen>
    with TickerProviderStateMixin {

  late final Player _player;
  late AnimationController _feedbackController;
  late Animation<double> _feedbackScale;
  late AnimationController _shakeController;
  late Animation<double> _shake;

  bool _navegandoATerminado = false;

  static const Map<int, String> _audioFraseMap = {
    0: 'el_mono_sonrriente_esta.mp3',
    1: 'la_manzana_es_roja.mp3',
    2: 'los_pinguinos_de_tres_son.mp3',
  };

  @override
  void initState() {
    super.initState();
    _player = Player();

    _feedbackController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _feedbackScale = CurvedAnimation(
      parent: _feedbackController,
      curve: Curves.elasticOut,
    );

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _shake = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: -10), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -10, end: 10), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 10, end: -10), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -10, end: 10), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 10, end: 0), weight: 1),
    ]).animate(CurvedAnimation(
      parent: _shakeController,
      curve: Curves.easeInOut,
    ));

    _reproducirAudioInicial();
  }

  /// Reproduce la instrucción general y al terminar encadena el audio de la frase 0
  Future<void> _reproducirAudioInicial() async {
    try {
      await _player.open(
        Media('asset:///assets/Audio/espanol/audio_espanol3_mezcla.mp3'),
      );
      await _player.play();

      // Espera a que el primer audio termine antes de reproducir el de la frase
      await _player.stream.completed
          .firstWhere((done) => done)
          .timeout(const Duration(seconds: 15), onTimeout: () => true);

      if (mounted) await _reproducirAudioFrase(0);
    } catch (e) {
      debugPrint('Error en audio inicial: $e');
    }
  }

  /// Audio del ícono de volumen: repite solo la instrucción general
  Future<void> _reproducirAudio() async {
    try {
      await _player.open(
        Media('asset:///assets/Audio/espanol/audio_espanol3_mezcla.mp3'),
      );
      await _player.play();
    } catch (e) {
      debugPrint('Error de audio: $e');
    }
  }

  /// Reproduce el audio de la frase correspondiente al índice
  Future<void> _reproducirAudioFrase(int index) async {
    final archivo = _audioFraseMap[index];
    if (archivo == null) return;
    try {
      await _player.open(
        Media('asset:///assets/Audio/espanol/$archivo'),
      );
      await _player.play();
    } catch (e) {
      debugPrint('Error reproduciendo audio de frase $index: $e');
    }
  }

  @override
  void dispose() {
    _player.dispose();
    _feedbackController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  void _mostrarFeedback(bool esCorrecto, VoidCallback onAction) {
    FeedbackSounds.instance.reproducir(esCorrecto);
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      backgroundColor: Colors.transparent,
      builder: (context) {
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
                      color: esCorrecto
                          ? Colors.green[900]
                          : Colors.red[900],
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
                        borderRadius: BorderRadius.circular(15)),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    onAction();
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

  void _irATerminado() {
    if (_navegandoATerminado || !mounted) return;
    _navegandoATerminado = true;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ActividadTerminadaScreen(
          onVolver: () {
            final nav = Navigator.of(context);
            nav.pop();
            nav.pop();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state    = ref.watch(palabraLocaViewModelProvider);
    final notifier = ref.read(palabraLocaViewModelProvider.notifier);
    final pregunta = notifier.preguntaActual;
    final sw = MediaQuery.of(context).size.width;

    ref.listen(palabraLocaViewModelProvider, (prev, next) {
      if (prev == null) return;

      if (prev.respuesta == RespuestaEstado.ninguna &&
          next.respuesta != RespuestaEstado.ninguna) {
        final esCorrecto = next.respuesta == RespuestaEstado.correcta;
        _feedbackController.forward(from: 0);
        if (!esCorrecto) _shakeController.forward(from: 0);
        Future.delayed(const Duration(milliseconds: 400), () {
          if (mounted) {
            _mostrarFeedback(esCorrecto, () {
              _feedbackController.reset();
              _shakeController.reset();
              notifier.commandSiguiente();
            });
          }
        });
      }

      if (prev.preguntaIndex != next.preguntaIndex) {
        _feedbackController.reset();
        _shakeController.reset();
        _reproducirAudioFrase(next.preguntaIndex);
      }

      if (!prev.actividadFinalizada && next.actividadFinalizada) {
        WidgetsBinding.instance
            .addPostFrameCallback((_) => _irATerminado());
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF65757),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _Header(
              onClose: () => Navigator.maybePop(context),
              progress: (state.preguntaIndex + 1) / PalabraLocaViewModel.preguntas.length,
            ),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(40),
                    topRight: Radius.circular(40),
                  ),
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                      child: _InstruccionRow(
                        texto: 'Elige si  la frase está bien escrita o mal escrita.',
                        onPlay: _reproducirAudio,
                      ),
                    ),
                    Expanded(
                      child: LayoutBuilder(
                        builder: (ctx, constraints) {
                          final imgSz = min(sw * 0.75, constraints.maxHeight * 0.70).clamp(160.0, 420.0);
                          return Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              AnimatedBuilder(
                                animation: _shake,
                                builder: (context, child) => Transform.translate(
                                  offset: Offset(_shake.value, 0),
                                  child: child,
                                ),
                                child: _ImagenPregunta(
                                  asset: pregunta.imagenAsset,
                                  respuesta: state.respuesta,
                                  scaleAnimation: _feedbackScale,
                                  size: imgSz,
                                ),
                              ),
                              SizedBox(height: (constraints.maxHeight * 0.06).clamp(12.0, 32.0)),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 24),
                                child: _FraseTexto(
                                  frase: pregunta.frase,
                                  respuesta: state.respuesta,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    if (!state.respondida)
                      _BotonesRespuesta(
                        onCorrecto: () => notifier.commandResponder(true),
                        onIncorrecto: () => notifier.commandResponder(false),
                      ),
                    const SizedBox(height: 28),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// WIDGETS AUXILIARES

class _Header extends StatelessWidget {
  final VoidCallback onClose;
  final double progress;
  const _Header({required this.onClose, required this.progress});

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 4, 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(width: 48),
              Text(
                'Palabra  loca',
                style: TextStyle(
                  fontFamily: 'Hiruko',
                  fontSize: (sw * 0.07).clamp(26.0, 46.0),
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
                onPressed: onClose,
              ),
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(sw * 0.08, 0, sw * 0.08, 12),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.white30,
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF59E347)),
            ),
          ),
        ),
      ],
    );
  }
}

class _InstruccionRow extends StatelessWidget {
  final String texto;
  final VoidCallback onPlay;

  const _InstruccionRow({required this.texto, required this.onPlay});

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: onPlay,
          child: _AudioBtn(sw: sw),
        ),
        SizedBox(width: (sw * 0.03).clamp(8.0, 16.0)),
        Expanded(
          child: Text(
            texto,
            style: TextStyle(
              fontFamily: 'Hiruko',
              fontSize: (sw * 0.065).clamp(20.0, 46.0),
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),
      ],
    );
  }
}

class _AudioBtn extends StatelessWidget {
  final double sw;
  const _AudioBtn({required this.sw});

  @override
  Widget build(BuildContext context) {
    final sz = (sw * 0.12).clamp(42.0, 64.0);
    return Container(
      width: sz,
      height: sz,
      decoration: BoxDecoration(
        color: const Color(0xFFFFEEEE),
        borderRadius: BorderRadius.circular(sz * 0.27),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF65757).withValues(alpha: 0.15),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Icon(
        Icons.volume_up_rounded,
        color: const Color(0xFFF65757),
        size: sz * 0.55,
      ),
    );
  }
}

class _ImagenPregunta extends StatelessWidget {
  final String asset;
  final RespuestaEstado respuesta;
  final Animation<double> scaleAnimation;
  final double size;

  const _ImagenPregunta({
    required this.asset,
    required this.respuesta,
    required this.scaleAnimation,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final sz = size;
    final circleSz = sz * 1.11;
    return AnimatedBuilder(
      animation: scaleAnimation,
      builder: (context, child) {
        final scale = respuesta != RespuestaEstado.ninguna
            ? (0.92 + 0.08 * scaleAnimation.value)
            : 1.0;
        return Transform.scale(scale: scale, child: child);
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: respuesta != RespuestaEstado.ninguna ? circleSz : 0,
            height: respuesta != RespuestaEstado.ninguna ? circleSz : 0,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: respuesta == RespuestaEstado.correcta
                  ? const Color(0xFFE8F8EE)
                  : respuesta == RespuestaEstado.incorrecta
                      ? const Color(0xFFFFEBEB)
                      : Colors.transparent,
              border: respuesta != RespuestaEstado.ninguna
                  ? Border.all(
                      color: respuesta == RespuestaEstado.correcta
                          ? const Color(0xFF4CAF50)
                          : const Color(0xFFFF5252),
                      width: 3,
                    )
                  : null,
            ),
          ),
          Image.asset(
            asset,
            width: sz,
            height: sz,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => Container(
              width: sz,
              height: sz,
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.image_not_supported_rounded,
                  size: 60, color: Color(0xFFCCCCCC)),
            ),
          ),
        ],
      ),
    );
  }
}

class _FraseTexto extends StatelessWidget {
  final String frase;
  final RespuestaEstado respuesta;

  const _FraseTexto({required this.frase, required this.respuesta});

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;
    final Color color = respuesta == RespuestaEstado.correcta
        ? const Color(0xFF2E7D32)
        : respuesta == RespuestaEstado.incorrecta
            ? const Color(0xFFD32F2F)
            : const Color(0xFF222222);

    return AnimatedDefaultTextStyle(
      duration: const Duration(milliseconds: 300),
      style: TextStyle(
        fontFamily: 'Hiruko',
        fontSize: (sw * 0.085).clamp(26.0, 54.0),
        fontWeight: FontWeight.bold,
        color: color,
        height: 1.3,
      ),
      child: Text(frase, textAlign: TextAlign.center),
    );
  }
}

class _BotonesRespuesta extends StatelessWidget {
  final VoidCallback onCorrecto;
  final VoidCallback onIncorrecto;

  const _BotonesRespuesta({
    required this.onCorrecto,
    required this.onIncorrecto,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Expanded(
            child: _BotonOpcion(
              label: 'Correcto',
              color: const Color(0xFF4CAF50),
              shadowColor: const Color(0xFF388E3C),
              onTap: onCorrecto,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _BotonOpcion(
              label: 'Incorrecto',
              color: const Color(0xFFF65757),
              shadowColor: const Color(0xFFB71C1C),
              onTap: onIncorrecto,
            ),
          ),
        ],
      ),
    );
  }
}

class _BotonOpcion extends StatelessWidget {
  final String label;
  final Color color;
  final Color shadowColor;
  final VoidCallback onTap;

  const _BotonOpcion({
    required this.label,
    required this.color,
    required this.shadowColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: (sw * 0.13).clamp(46.0, 72.0),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: shadowColor.withOpacity(0.45),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: (sw * 0.04).clamp(14.0, 22.0),
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}