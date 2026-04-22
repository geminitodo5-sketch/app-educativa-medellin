import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import '../../../../data/models/sync_queue_model.dart';
import '../../../../data/providers/app_state_provider.dart'
    show estudianteActivoProvider;
import '../../../../data/providers/database_provider.dart';
import '../../terminado.dart';

// ══════════════════════════════════════════════════════════
// MODELO
// ══════════════════════════════════════════════════════════

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

// ══════════════════════════════════════════════════════════
// ESTADO
// ══════════════════════════════════════════════════════════

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

// ══════════════════════════════════════════════════════════
// VIEW MODEL
// ══════════════════════════════════════════════════════════

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

// ══════════════════════════════════════════════════════════
// SCREEN
// ══════════════════════════════════════════════════════════

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
      await _player.stream.completed.firstWhere((done) => done);

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
                    esCorrecto ? '¡Excelente trabajo!' : '¡Casi lo tienes!',
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
            _Header(onClose: () => Navigator.maybePop(context)),
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
                    Expanded(
                      child: SingleChildScrollView(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          children: [
                            const SizedBox(height: 32),
                            _InstruccionRow(
                              texto:
                                  'Elige si la frase está\nbien escrita o mal escrita.',
                              onPlay: _reproducirAudio,
                            ),
                            const SizedBox(height: 36),
                            AnimatedBuilder(
                              animation: _shake,
                              builder: (context, child) =>
                                  Transform.translate(
                                offset: Offset(_shake.value, 0),
                                child: child,
                              ),
                              child: _ImagenPregunta(
                                asset: pregunta.imagenAsset,
                                respuesta: state.respuesta,
                                scaleAnimation: _feedbackScale,
                              ),
                            ),
                            const SizedBox(height: 24),
                            _FraseTexto(
                              frase: pregunta.frase,
                              respuesta: state.respuesta,
                            ),
                            const SizedBox(height: 48),
                          ],
                        ),
                      ),
                    ),
                    if (!state.respondida)
                      _BotonesRespuesta(
                        onCorrecto: () => notifier.commandResponder(true),
                        onIncorrecto: () =>
                            notifier.commandResponder(false),
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

// ══════════════════════════════════════════════════════════
// WIDGETS AUXILIARES
// ══════════════════════════════════════════════════════════

class _Header extends StatelessWidget {
  final VoidCallback onClose;
  const _Header({required this.onClose});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 180,
      width: double.infinity,
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Text(
            'Palabra   loca',
            style: TextStyle(
              fontFamily: 'Hiruko',
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: 0.3,
            ),
          ),
          Positioned(
            top: 12,
            right: 8,
            child: IconButton(
              icon: const Icon(Icons.close_rounded,
                  color: Colors.white, size: 28),
              onPressed: onClose,
            ),
          ),
        ],
      ),
    );
  }
}

class _InstruccionRow extends StatelessWidget {
  final String texto;
  final VoidCallback onPlay;

  const _InstruccionRow({required this.texto, required this.onPlay});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: onPlay,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F4FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.volume_up_rounded,
                color: Color(0xFF3475F7), size: 22),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          texto,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Color(0xFF444444),
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

class _ImagenPregunta extends StatelessWidget {
  final String asset;
  final RespuestaEstado respuesta;
  final Animation<double> scaleAnimation;

  const _ImagenPregunta({
    required this.asset,
    required this.respuesta,
    required this.scaleAnimation,
  });

  @override
  Widget build(BuildContext context) {
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
            width: respuesta != RespuestaEstado.ninguna ? 178 : 0,
            height: respuesta != RespuestaEstado.ninguna ? 178 : 0,
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
            width: 160,
            height: 160,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => Container(
              width: 160,
              height: 160,
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
    final Color color = respuesta == RespuestaEstado.correcta
        ? const Color(0xFF2E7D32)
        : respuesta == RespuestaEstado.incorrecta
            ? const Color(0xFFD32F2F)
            : const Color(0xFF222222);

    return AnimatedDefaultTextStyle(
      duration: const Duration(milliseconds: 300),
      style: TextStyle(
        fontFamily: 'Poppins',
        fontSize: 22,
        fontWeight: FontWeight.w800,
        color: color,
        height: 1.35,
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
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
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}