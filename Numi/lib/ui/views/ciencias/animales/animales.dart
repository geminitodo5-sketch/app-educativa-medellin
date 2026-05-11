import 'dart:math' show min;
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../viewmodels/animales_view_model.dart';
import '../../../../data/services/feedback_sounds.dart';

const _audio7 = 'assets/images/actividades/ciencias_naturales/audios/audio_naturales7_mezcla.mp3';

// --- Paleta de Colores NUMI ---
const Color kColorAzulNumi = Color(0xFF3475F7);
const Color kColorVerdeNumi = Color(0xFF59E347);
const Color kColorRojoNumi = Color(0xFFF65757);
const Color kColorBlanco = Colors.white;

class PantallaActividadAnimales extends ConsumerStatefulWidget {
  final VoidCallback onCompletado;
  final double progress;
  const PantallaActividadAnimales({super.key, required this.onCompletado, this.progress = 1 / 3});

  @override
  ConsumerState<PantallaActividadAnimales> createState() =>
      _PantallaActividadAnimalesState();
}

class _PantallaActividadAnimalesState
    extends ConsumerState<PantallaActividadAnimales> {

  AudioPlayer? _player;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    Future.microtask(() => _reproducirInstruccion());
  }

  @override
  void dispose() {
    _player?.dispose();
    super.dispose();
  }

  Future<void> _reproducirInstruccion() async {
    try {
      await _player?.setAsset(_audio7);
      await _player?.play();
    } catch (e) {
      debugPrint('Error al reproducir audio animales: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = ref.watch(animalesViewModelProvider);
    final aciertos = viewModel.aciertos;

    final sw = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: const Color(0xFF3DCC52),
      body: SafeArea(
        child: Column(
          children: [
            const _HeaderActividad(titulo: "Animales"),
            Padding(
              padding: EdgeInsets.fromLTRB(sw * 0.08, 0, sw * 0.08, 14),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: widget.progress,
                  minHeight: 8,
                  backgroundColor: Colors.white30,
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF59E347)),
                ),
              ),
            ),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: kColorBlanco,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(32),
                    topRight: Radius.circular(32),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      _InstruccionAudio(
                        texto: "Devuelve a estos animales a su hogar, empareja sus hábitats",
                        onReproducir: _reproducirInstruccion,
                      ),
                      Expanded(
                        child: LayoutBuilder(
                          builder: (ctx, constraints) {
                            final byW = (constraints.maxWidth - 48) / 2;
                            final byH = (constraints.maxHeight - 56) / 2;
                            final side = min(byW, byH).clamp(80.0, 320.0);
                            return Column(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    _HabitatTarget(
                                      tipo: 'pinguino',
                                      imagen: 'assets/images/actividades/ciencias_naturales/polar.png',
                                      size: side,
                                      onAccept: (val) {
                                        bool esCorrecto = viewModel.commandValidarHabitat(val, 'pinguino');
                                        if (!esCorrecto) {
                                          _mostrarFeedback(context, false, () {});
                                        } else if (viewModel.completado) {
                                          _mostrarFeedback(context, true, () { widget.onCompletado(); });
                                        }
                                      },
                                    ),
                                    _HabitatTarget(
                                      tipo: 'cocodrilo',
                                      imagen: 'assets/images/actividades/ciencias_naturales/selva.png',
                                      size: side,
                                      onAccept: (val) {
                                        bool esCorrecto = viewModel.commandValidarHabitat(val, 'cocodrilo');
                                        if (!esCorrecto) {
                                          _mostrarFeedback(context, false, () {});
                                        } else if (viewModel.completado) {
                                          _mostrarFeedback(context, true, () { widget.onCompletado(); });
                                        }
                                      },
                                    ),
                                  ],
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    if (!aciertos['cocodrilo']!)
                                      _AnimalDraggable(
                                        id: 'cocodrilo',
                                        imagen: 'assets/images/actividades/ciencias_naturales/cocodrilo.png',
                                        size: side,
                                      )
                                    else
                                      SizedBox(width: side, height: side),
                                    if (!aciertos['pinguino']!)
                                      _AnimalDraggable(
                                        id: 'pinguino',
                                        imagen: 'assets/images/actividades/ciencias_naturales/pinguino.png',
                                        size: side,
                                      )
                                    else
                                      SizedBox(width: side, height: side),
                                  ],
                                ),
                                const _IndicadorProgreso(),
                              ],
                            );
                          },
                        ),
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

// --- Componentes Especializados ---

class _HeaderActividad extends StatelessWidget {
  final String titulo;
  const _HeaderActividad({required this.titulo});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 90,
      width: double.infinity,
      child: Stack(
        children: [
          Align(
            alignment: Alignment.center,
            child: Text(
              titulo,
              style: const TextStyle(
                fontFamily: 'Hiruko',
                fontSize: 38,
                fontWeight: FontWeight.bold,
                color: kColorBlanco,
              ),
            ),
          ),
          Positioned(
            top: 10,
            right: 15,
            child: IconButton(
              icon: const Icon(Icons.close, color: kColorBlanco, size: 32),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }
}

class _InstruccionAudio extends StatelessWidget {
  final String texto;
  final VoidCallback onReproducir;

  const _InstruccionAudio({
    required this.texto,
    required this.onReproducir,
  });

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: onReproducir,
            child: Container(
              width: (sw * 0.13).clamp(44.0, 60.0),
              height: (sw * 0.13).clamp(44.0, 60.0),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                Icons.volume_up_rounded,
                color: const Color(0xFF3DCC52),
                size: (sw * 0.07).clamp(24.0, 34.0),
              ),
            ),
          ),
          SizedBox(width: sw * 0.03),
          Expanded(
            child: Text(
              texto,
              style: TextStyle(
                fontFamily: 'Hiruko',
                fontSize: (sw * 0.065).clamp(20.0, 46.0),
                fontWeight: FontWeight.bold,
                color: const Color(0xFF424242),
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IndicadorProgreso extends StatelessWidget {
  const _IndicadorProgreso();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        3,
        (index) => Container(
          margin: const EdgeInsets.symmetric(horizontal: 5),
          width: 15,
          height: 15,
          decoration: BoxDecoration(
            color: const Color(0xFF3DCC52).withOpacity(index == 0 ? 1.0 : 0.4),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

class _HabitatTarget extends StatelessWidget {
  final String tipo;
  final String imagen;
  final Function(String) onAccept;
  final double size;

  const _HabitatTarget({
    required this.tipo,
    required this.imagen,
    required this.onAccept,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return DragTarget<String>(
      onAcceptWithDetails: (details) => onAccept(details.data),
      builder: (context, candidateData, rejectedData) {
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: candidateData.isNotEmpty
                  ? kColorVerdeNumi
                  : Colors.grey.shade300,
              width: 3,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(17),
            child: Image.asset(imagen, fit: BoxFit.cover),
          ),
        );
      },
    );
  }
}

class _AnimalDraggable extends StatelessWidget {
  final String id;
  final String imagen;
  final double size;
  const _AnimalDraggable({required this.id, required this.imagen, required this.size});

  @override
  Widget build(BuildContext context) {
    return Draggable<String>(
      data: id,
      feedback: SizedBox(
        width: size,
        height: size,
        child: Image.asset(
          imagen,
          fit: BoxFit.contain,
          opacity: const AlwaysStoppedAnimation(0.8),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: SizedBox(
          width: size,
          height: size,
          child: Image.asset(imagen, fit: BoxFit.contain),
        ),
      ),
      child: SizedBox(
        width: size,
        height: size,
        child: Image.asset(imagen, fit: BoxFit.contain),
      ),
    );
  }
}

void _mostrarFeedback(
  BuildContext context,
  bool esCorrecto,
  VoidCallback onAction,
) {
  FeedbackSounds.instance.reproducir(esCorrecto);
  showModalBottomSheet(
    context: context,
    isDismissible: false,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return Container(
        padding: const EdgeInsets.all(30),
        decoration: BoxDecoration(
          color: esCorrecto ? const Color(0xFFD7FFD3) : const Color(0xFFFFD3D3),
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
                  color: esCorrecto ? kColorVerdeNumi : kColorRojoNumi,
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
                  backgroundColor: esCorrecto ? kColorVerdeNumi : kColorRojoNumi,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
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