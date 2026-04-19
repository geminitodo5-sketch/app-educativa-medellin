import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  late AnimationController _feedbackController;
  late Animation<double> _feedbackScale;
  late AnimationController _shakeController;
  late Animation<double> _shake;

  bool _navegandoATerminado = false;

  @override
  void initState() {
    super.initState();

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
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    _shakeController.dispose();
    super.dispose();
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
            nav.pop(); // cierra terminado
            nav.pop(); // cierra PalabraLocaScreen
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(palabraLocaViewModelProvider);
    final notifier = ref.read(palabraLocaViewModelProvider.notifier);
    final pregunta = notifier.preguntaActual;

    ref.listen(palabraLocaViewModelProvider, (prev, next) {
      if (prev == null) return;
      if (prev.respuesta == RespuestaEstado.ninguna &&
          next.respuesta != RespuestaEstado.ninguna) {
        _feedbackController.forward(from: 0);
        if (next.respuesta == RespuestaEstado.incorrecta) {
          _shakeController.forward(from: 0);
        }
      }
      if (prev.preguntaIndex != next.preguntaIndex) {
        _feedbackController.reset();
        _shakeController.reset();
      }
      if (!prev.actividadFinalizada && next.actividadFinalizada) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _irATerminado());
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
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          children: [
                            const SizedBox(height: 32),
                            const _InstruccionRow(
                              texto:
                                  'Elige si la frase está\nbien escrita o mal escrita.',
                            ),
                            const SizedBox(height: 36),
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
                              ),
                            ),
                            const SizedBox(height: 24),
                            _FraseTexto(
                              frase: pregunta.frase,
                              respuesta: state.respuesta,
                            ),
                            const SizedBox(height: 32),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              transitionBuilder: (child, anim) =>
                                  SlideTransition(
                                position: Tween<Offset>(
                                  begin: const Offset(0, 0.3),
                                  end: Offset.zero,
                                ).animate(anim),
                                child:
                                    FadeTransition(opacity: anim, child: child),
                              ),
                              child: state.respondida
                                  ? _BannerResultado(
                                      key: ValueKey(state.preguntaIndex),
                                      correcto: state.respuesta ==
                                          RespuestaEstado.correcta,
                                    )
                                  : const SizedBox.shrink(
                                      key: ValueKey('empty'),
                                    ),
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ),
                    if (state.respondida)
                      _BotonSiguiente(onTap: notifier.commandSiguiente)
                    else
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
            'Palabra loca',
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
  const _InstruccionRow({required this.texto});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFF0F4FF),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.volume_up_rounded,
              color: Color(0xFF3475F7), size: 22),
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

class _BannerResultado extends StatelessWidget {
  final bool correcto;
  const _BannerResultado({super.key, required this.correcto});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color:
            correcto ? const Color(0xFFE8F8EE) : const Color(0xFFFFEBEB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: correcto
              ? const Color(0xFF4CAF50)
              : const Color(0xFFFF5252),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            correcto ? Icons.check_circle_rounded : Icons.cancel_rounded,
            color: correcto
                ? const Color(0xFF2E7D32)
                : const Color(0xFFD32F2F),
            size: 26,
          ),
          const SizedBox(width: 10),
          Text(
            correcto
                ? '¡Muy bien! La frase está correcta.'
                : '¡Ups! La frase está incorrecta.',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: correcto
                  ? const Color(0xFF2E7D32)
                  : const Color(0xFFD32F2F),
            ),
          ),
        ],
      ),
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

class _BotonSiguiente extends StatelessWidget {
  final VoidCallback onTap;
  const _BotonSiguiente({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          height: 52,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF3475F7), Color(0xFF1A56D6)],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF3475F7).withOpacity(0.4),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Text(
                'Siguiente',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: 8),
              Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}
