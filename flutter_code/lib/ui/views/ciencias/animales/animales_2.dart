import 'dart:math';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../viewmodels/animales_clasificacion_view_model.dart';

const _audio8 = 'assets/images/actividades/ciencias_naturales/audios/audio_naturales8_mezcla.mp3';

// --- Paleta de Colores NUMI ---
const Color kColorAzulNumi = Color(0xFF3475F7);
const Color kColorVerdeNumi = Color(0xFF59E347);
const Color kColorRojoNumi = Color(0xFFF65757);
const Color kColorBlanco = Colors.white;

const _listaAnimales = [
  {
    'imagen': 'assets/images/actividades/ciencias_naturales/gato.png',
    'respuestaCorrecta': 'domestico',
  },
  {
    'imagen': 'assets/images/actividades/ciencias_naturales/perro.png',
    'respuestaCorrecta': 'domestico',
  },
  {
    'imagen': 'assets/images/actividades/ciencias_naturales/elefante.png',
    'respuestaCorrecta': 'salvaje',
  },
  {
    'imagen': 'assets/images/actividades/ciencias_naturales/mono.png',
    'respuestaCorrecta': 'salvaje',
  },
];

class PantallaClasificacionAnimales extends ConsumerStatefulWidget {
  final VoidCallback onCompletado;
  final double progress;
  const PantallaClasificacionAnimales({super.key, required this.onCompletado, this.progress = 2 / 3});

  @override
  ConsumerState<PantallaClasificacionAnimales> createState() =>
      _PantallaClasificacionAnimalesState();
}

class _PantallaClasificacionAnimalesState
    extends ConsumerState<PantallaClasificacionAnimales> {

  AudioPlayer? _player;
  int _indiceActual = 0;
  late final List<Map<String, String>> _animalesAleatorios;

  @override
  void initState() {
    super.initState();
    _animalesAleatorios = List.from(_listaAnimales)..shuffle(Random());
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
      await _player?.setAsset(_audio8);
      await _player?.play();
    } catch (e) {
      debugPrint('Error al reproducir audio clasificacion: $e');
    }
  }

  void _responder(String respuesta) {
    final animal = _animalesAleatorios[_indiceActual];
    final esCorrecto = respuesta == animal['respuestaCorrecta'];
    final esUltimo = _indiceActual == _animalesAleatorios.length - 1;

    _showFeedbackSheet(
      context,
      esCorrecto,
      onContinue: esCorrecto
          ? () {
              if (esUltimo) {
                widget.onCompletado();
              } else {
                setState(() => _indiceActual++);
              }
            }
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(animalesClasificacionViewModelProvider);
    final animal = _animalesAleatorios[_indiceActual];

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
                  child: LayoutBuilder(
                    builder: (ctx, constraints) {
                      final btnW = (constraints.maxWidth * 0.44).clamp(100.0, 360.0);
                      return Column(
                        children: [
                          _InstruccionAudio(
                            texto: "Decide si estos animales son domésticos o salvajes",
                            onReproducir: _reproducirInstruccion,
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Image.asset(
                                animal['imagen']!,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _BotonOpcion(
                                label: 'Doméstico',
                                color: kColorAzulNumi,
                                width: btnW,
                                onPressed: () => _responder('domestico'),
                              ),
                              _BotonOpcion(
                                label: 'Salvaje',
                                color: kColorVerdeNumi,
                                width: btnW,
                                onPressed: () => _responder('salvaje'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _IndicadorProgreso(
                            indiceActual: _indiceActual,
                            total: _animalesAleatorios.length,
                          ),
                          const SizedBox(height: 8),
                        ],
                      );
                    },
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

// --- Componentes de Interfaz ---

class _HeaderActividad extends StatelessWidget {
  final String titulo;
  const _HeaderActividad({required this.titulo});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 90,
      child: Stack(
        children: [
          Align(
            alignment: Alignment.center,
            child: Text(
              titulo,
              style: const TextStyle(
                fontFamily: 'Hiruko',
                fontSize: 34,
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

class _BotonOpcion extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onPressed;
  final double width;
  const _BotonOpcion({
    required this.label,
    required this.color,
    required this.onPressed,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: width,
        padding: EdgeInsets.symmetric(vertical: (width * 0.1).clamp(10.0, 32.0)),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular((width * 0.12).clamp(14.0, 30.0)),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.4),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Hiruko',
            fontSize: (width * 0.13).clamp(14.0, 36.0),
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ),
    );
  }
}

class _IndicadorProgreso extends StatelessWidget {
  final int indiceActual;
  final int total;
  const _IndicadorProgreso({required this.indiceActual, required this.total});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        total,
        (index) => Container(
          margin: const EdgeInsets.symmetric(horizontal: 5),
          width: 15,
          height: 15,
          decoration: BoxDecoration(
            color: const Color(0xFF3DCC52)
                .withOpacity(index == indiceActual ? 1.0 : 0.4),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

// --- Pestaña de Retroalimentación ---

void _showFeedbackSheet(
  BuildContext context,
  bool esCorrecto, {
  VoidCallback? onContinue,
}) {
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
                  onContinue?.call();
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