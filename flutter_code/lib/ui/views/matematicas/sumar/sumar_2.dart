import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'dart:math';
import 'quien_tiene_mas_31.dart';

const Color kColorAzulNumi    = Color(0xFF3475F7);
const Color kColorRojoNumi    = Color(0xFFF65757);
const Color kColorNaranjaNumi = Color(0xFFEF9325);
const Color kColorVerdeNumi   = Color(0xFF59E347);

class _DatosActividad {
  final int cantidadA;
  final int cantidadB;
  final List<int> opciones;
  final int indexCorrecto;

  _DatosActividad({
    required this.cantidadA,
    required this.cantidadB,
    required this.opciones,
    required this.indexCorrecto,
  });

  int get respuestaCorrecta => cantidadA + cantidadB;

  factory _DatosActividad.generar() {
    final rng = Random();
    final a = rng.nextInt(6) + 1;
    final b = rng.nextInt(6) + 1;
    final correcto = a + b;
    final Set<int> distSet = {};
    while (distSet.length < 2) {
      final delta = rng.nextInt(2) + 1;
      final candidato = rng.nextBool() ? correcto + delta : correcto - delta;
      if (candidato != correcto && candidato > 0) {
        distSet.add(candidato);
      }
    }
    final List<int> opciones = distSet.toList();
    final posCorrecta = rng.nextInt(3);
    opciones.insert(posCorrecta, correcto);
    return _DatosActividad(
      cantidadA: a,
      cantidadB: b,
      opciones: opciones,
      indexCorrecto: posCorrecta,
    );
  }
}

class PantallaSumaUvas extends ConsumerStatefulWidget {
  const PantallaSumaUvas({super.key});

  @override
  ConsumerState<PantallaSumaUvas> createState() => _PantallaSumaUvasState();
}

class _PantallaSumaUvasState extends ConsumerState<PantallaSumaUvas> {
  AudioPlayer? _player;
  late _DatosActividad _datos;

  @override
  void initState() {
    super.initState();
    _datos = _DatosActividad.generar();
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
      await _player?.setAsset('assets/Audio/Matematicas/audio mate8_mezcla.mp3');
      await _player?.play();
    } catch (e) {
      debugPrint('Error al reproducir audio: $e');
    }
  }

  void _regenerar() {
    setState(() {
      _datos = _DatosActividad.generar();
    });
  }

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;
    final sh = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: kColorAzulNumi,
      body: Column(
        children: [
          _HeaderSuma(onClose: () => Navigator.pop(context)),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(40)),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: (sw * 0.06).clamp(16.0, 30.0),
                  vertical: (sh * 0.035).clamp(16.0, 40.0),
                ),
                child: Column(
                  children: [
                    _InstruccionAudio(onPlay: _reproducirInstruccion),
                    const Spacer(),
                    _SeccionCajas(
                      cantidadA: _datos.cantidadA,
                      cantidadB: _datos.cantidadB,
                    ),
                    const Spacer(),
                    Text(
                      '${_datos.cantidadA}+${_datos.cantidadB}=?',
                      style: TextStyle(
                        fontFamily: 'Hiruko',
                        fontSize: (sw * 0.12).clamp(36.0, 85.0),
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const Spacer(),
                    _OpcionesRespuesta(
                      datos: _datos,
                      onRegenerar: _regenerar,
                    ),
                    SizedBox(height: sh * 0.025),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderSuma extends StatelessWidget {
  final VoidCallback onClose;
  const _HeaderSuma({required this.onClose});

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;
    final sh = MediaQuery.of(context).size.height;
    final statusBar = MediaQuery.of(context).padding.top;
    final headerH = (sh * 0.12).clamp(70.0, 110.0);

    return SizedBox(
      height: statusBar + headerH,
      width: double.infinity,
      child: Stack(
        children: [
          Positioned(
            bottom: 28,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                'Sumar',
                style: TextStyle(
                  fontFamily: 'Hiruko',
                  fontSize: (sw * 0.085).clamp(28.0, 42.0),
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          Positioned(
            top: statusBar + 4,
            right: 8,
            child: IconButton(
              icon: Icon(
                Icons.close,
                color: Colors.white,
                size: (sw * 0.075).clamp(24.0, 36.0),
              ),
              onPressed: onClose,
            ),
          ),
          Positioned(
            bottom: 12,
            left: sw * 0.08,
            right: sw * 0.08,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: const LinearProgressIndicator(
                value: 2 / 3,
                minHeight: 8,
                backgroundColor: Colors.white30,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF59E347)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InstruccionAudio extends StatelessWidget {
  final VoidCallback onPlay;
  const _InstruccionAudio({required this.onPlay});

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;
    return Row(
      children: [
        GestureDetector(
          onTap: onPlay,
          child: Container(
            width: (sw * 0.13).clamp(44.0, 60.0),
            height: (sw * 0.13).clamp(44.0, 60.0),
            decoration: BoxDecoration(
              color: const Color(0xFFEEF2FF),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.volume_up_rounded,
              color: const Color(0xFF3475F7),
              size: (sw * 0.07).clamp(24.0, 34.0),
            ),
          ),
        ),
        SizedBox(width: sw * 0.03),
        Expanded(
          child: Text(
            'Suma  las uvas de  las dos cajas',
            style: TextStyle(
              fontFamily: 'Hiruko',
              fontSize: (sw * 0.055).clamp(18.0, 40.0),
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),
      ],
    );
  }
}

class _SeccionCajas extends StatelessWidget {
  final int cantidadA;
  final int cantidadB;
  const _SeccionCajas({required this.cantidadA, required this.cantidadB});

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _CajaFruta(color: kColorRojoNumi, cantidad: cantidadA),
        SizedBox(width: sw * 0.05),
        _CajaFruta(color: kColorNaranjaNumi, cantidad: cantidadB),
      ],
    );
  }
}

class _CajaFruta extends StatelessWidget {
  final Color color;
  final int cantidad;
  const _CajaFruta({required this.color, required this.cantidad});

  double _tamanoUva(double boxSize) {
    if (cantidad <= 2) return boxSize * 0.38;
    if (cantidad <= 4) return boxSize * 0.33;
    if (cantidad <= 6) return boxSize * 0.26;
    if (cantidad <= 9) return boxSize * 0.21;
    return boxSize * 0.17;
  }

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;
    final boxSize = (sw * 0.38).clamp(100.0, 320.0);
    final uvaSize = _tamanoUva(boxSize);

    return Container(
      width: boxSize,
      height: boxSize,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Center(
              child: Wrap(
                spacing: 4,
                runSpacing: 4,
                alignment: WrapAlignment.center,
                runAlignment: WrapAlignment.center,
                children: List.generate(
                  cantidad,
                  (index) => ColorFiltered(
                    colorFilter: const ColorFilter.matrix([
                      1.5, 0, 0, 0, -64,
                      0, 1.5, 0, 0, -64,
                      0, 0, 1.5, 0, -64,
                      0, 0, 0, 1, 0,
                    ]),
                    child: Image.asset(
                      'assets/images/actividades/matematicas/mora.png',
                      width: uvaSize,
                      height: uvaSize,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 8,
            right: 12,
            child: Text(
              '$cantidad',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: (sw * 0.065).clamp(20.0, 44.0),
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OpcionesRespuesta extends StatelessWidget {
  final _DatosActividad datos;
  final VoidCallback onRegenerar;
  const _OpcionesRespuesta(
      {required this.datos, required this.onRegenerar});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(3, (i) {
        final esCorrecto = i == datos.indexCorrecto;
        return _BotonOpcion(
          numero: '${datos.opciones[i]}',
          onTap: () => _showFeedbackSheet(context, esCorrecto, onRegenerar),
        );
      }),
    );
  }
}

class _BotonOpcion extends StatelessWidget {
  final String numero;
  final VoidCallback onTap;
  const _BotonOpcion({required this.numero, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;
    final sh = MediaQuery.of(context).size.height;
    final btnW = (sw * 0.22).clamp(65.0, 150.0);
    final btnH = (sh * 0.09).clamp(58.0, 110.0);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: btnW,
        height: btnH,
        decoration: BoxDecoration(
          color: kColorAzulNumi,
          borderRadius: BorderRadius.circular(15),
        ),
        alignment: Alignment.center,
        child: Text(
          numero,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: (sw * 0.06).clamp(20.0, 44.0),
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

void _showFeedbackSheet(
    BuildContext context, bool esCorrecto, VoidCallback onRegenerar) {
  showModalBottomSheet(
    context: context,
    isDismissible: false,
    backgroundColor: Colors.transparent,
    builder: (context) {
      final sw = MediaQuery.of(context).size.width;
      return Container(
        padding: EdgeInsets.all((sw * 0.07).clamp(20.0, 35.0)),
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
                  color: esCorrecto ? kColorVerdeNumi : kColorRojoNumi,
                  size: (sw * 0.1).clamp(32.0, 48.0),
                ),
                SizedBox(width: sw * 0.04),
                Text(
                  esCorrecto ? '¡Excelente trabajo!' : '¡Inténtalo de nuevo!',
                  style: TextStyle(
                    fontFamily: 'Hiruko',
                    fontSize: (sw * 0.06).clamp(20.0, 28.0),
                    fontWeight: FontWeight.bold,
                    color: esCorrecto ? Colors.green[900] : Colors.red[900],
                  ),
                ),
              ],
            ),
            SizedBox(height: sw * 0.05),
            SizedBox(
              width: double.infinity,
              height: (sw * 0.13).clamp(48.0, 60.0),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      esCorrecto ? kColorVerdeNumi : kColorRojoNumi,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15)),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  if (esCorrecto) {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                          builder: (_) => const QuienTieneMasview3()),
                    );
                  } else {
                    onRegenerar();
                  }
                },
                child: Text(
                  esCorrecto ? 'Continuar' : 'Reintentar',
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.bold,
                    fontSize: (sw * 0.045).clamp(16.0, 22.0),
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
