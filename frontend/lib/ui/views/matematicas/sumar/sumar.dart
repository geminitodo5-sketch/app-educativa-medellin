import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'dart:math';
import 'sumar_2.dart';
import '../../../../data/services/feedback_sounds.dart';

final respuestaSumarProvider = StateProvider<bool?>((ref) => null);

enum TipoPatron { sumarUno, sumarDos, sumarTres, sumarCuatro }

class _Patron {
  final String nombre;
  final int incremento;
  const _Patron({required this.nombre, required this.incremento});
}

const _patrones = [
  _Patron(nombre: '+1', incremento: 1),
  _Patron(nombre: '+2', incremento: 2),
  _Patron(nombre: '+3', incremento: 3),
  _Patron(nombre: '+4', incremento: 4),
];

class _DatosActividad {
  final int fila1Num;
  final int incremento;
  final String opcionCorrecta;
  final String opcionIncorrecta;
  final bool correctaEsPrimera;

  _DatosActividad({
    required this.fila1Num,
    required this.incremento,
    required this.opcionCorrecta,
    required this.opcionIncorrecta,
    required this.correctaEsPrimera,
  });

  int get fila2Num => fila1Num + incremento;
  int get fila3Num => fila1Num + incremento * 2;

  String get fila1Suma => '${fila1Num - incremento}+$incremento';
  String get fila2Suma => '${fila2Num - incremento}+$incremento';

  factory _DatosActividad.generar() {
    final rng = Random();
    final patron = _patrones[rng.nextInt(_patrones.length)];
    final inc = patron.incremento;
    final fila1Num = rng.nextInt(6) + (inc + 1);
    final fila3Num = fila1Num + inc * 2;
    final correcto = '${fila3Num - inc}+$inc';
    final distractores = [
      '${fila3Num - inc + 1}+$inc',
      '${fila3Num - inc - 1}+$inc',
      '${fila3Num - inc}+${inc + 1}',
      '${fila3Num - inc}+${inc - 1}',
    ].where((d) => d != correcto && !d.contains('+0') && !d.contains('-')).toList();
    final incorrecto = distractores.isNotEmpty
        ? distractores[rng.nextInt(distractores.length)]
        : '${fila3Num - inc + 1}+$inc';
    final correctaEsPrimera = rng.nextBool();
    return _DatosActividad(
      fila1Num: fila1Num,
      incremento: inc,
      opcionCorrecta: correcto,
      opcionIncorrecta: incorrecto,
      correctaEsPrimera: correctaEsPrimera,
    );
  }
}

class SumarPatronview extends ConsumerStatefulWidget {
  const SumarPatronview({super.key});

  @override
  ConsumerState<SumarPatronview> createState() => _SumarPatronviewState();
}

class _SumarPatronviewState extends ConsumerState<SumarPatronview> {
  AudioPlayer? _player;
  late _DatosActividad _datos;

  static const Color azulPrincipal = Color(0xFF3475F7);
  static const Color azulBoton     = Color(0xFF3878FA);
  static const Color rojoNumi      = Color(0xFFF65757);
  static const Color naranjaNumi   = Color(0xFFEF9325);
  static const Color verdeNumi     = Color(0xFF59E347);

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
      await _player?.setAsset('assets/Audio/Matematicas/audio mate7_mezcla.mp3');
      await _player?.play();
    } catch (e) {
      debugPrint('Error al reproducir audio: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;
    final sh = MediaQuery.of(context).size.height;
    final statusBar = MediaQuery.of(context).padding.top;
    final headerH = (sh * 0.12).clamp(70.0, 110.0);

    return Scaffold(
      backgroundColor: azulPrincipal,
      body: Column(
        children: [
          _buildHeader(context, sw, sh, statusBar, headerH),
          Expanded(child: _buildMainContent(context, sw, sh)),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, double sw, double sh,
      double statusBar, double headerH) {
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
                  color: Colors.white,
                  fontSize: (sw * 0.085).clamp(28.0, 42.0),
                  fontFamily: 'Hiruko',
                  fontWeight: FontWeight.bold,
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
              onPressed: () {
                ref.read(respuestaSumarProvider.notifier).state = null;
                Navigator.of(context).pop();
              },
            ),
          ),
          Positioned(
            bottom: 12,
            left: sw * 0.08,
            right: sw * 0.08,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: const LinearProgressIndicator(
                value: 1 / 3,
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

  Widget _buildMainContent(BuildContext context, double sw, double sh) {
    final hPad = (sw * 0.06).clamp(16.0, 30.0);
    final vPad = (sh * 0.04).clamp(20.0, 45.0);

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(40),
          topRight: Radius.circular(40),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
        child: Column(
          children: [
            _buildInstruction(sw),
            SizedBox(height: sh * 0.025),
            Expanded(child: _buildPatternTable(sw)),
            SizedBox(height: sh * 0.025),
            _buildOptionButton(
              context, sw, sh,
              _datos.correctaEsPrimera
                  ? _datos.opcionCorrecta
                  : _datos.opcionIncorrecta,
              azulBoton, Colors.white,
              _datos.correctaEsPrimera,
            ),
            SizedBox(height: sh * 0.018),
            _buildOptionButton(
              context, sw, sh,
              _datos.correctaEsPrimera
                  ? _datos.opcionIncorrecta
                  : _datos.opcionCorrecta,
              azulBoton, Colors.white,
              !_datos.correctaEsPrimera,
            ),
            SizedBox(height: sh * 0.025),
          ],
        ),
      ),
    );
  }

  Widget _buildInstruction(double sw) {
    return Row(
      children: [
        GestureDetector(
          onTap: _reproducirInstruccion,
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
        Text(
          'Continua el patrón',
          style: TextStyle(
            fontSize: (sw * 0.055).clamp(18.0, 40.0),
            fontFamily: 'Hiruko',
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildPatternTable(double sw) {
    final fontSize = (sw * 0.065).clamp(20.0, 46.0);

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: azulBoton, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Column(
          children: [
            Expanded(child: _buildTableRow(
                '${_datos.fila1Num}', _datos.fila1Suma, rojoNumi, fontSize)),
            Expanded(child: _buildTableRow(
                '${_datos.fila2Num}', _datos.fila2Suma, naranjaNumi, fontSize)),
            Expanded(child: _buildTableRow(
                '${_datos.fila3Num}', '???', verdeNumi, fontSize)),
          ],
        ),
      ),
    );
  }

  Widget _buildTableRow(
      String num, String suma, Color bgColor, double fontSize) {
    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        border: const Border(bottom: BorderSide(color: azulBoton, width: 1)),
      ),
      child: Row(
        children: [
          Expanded(child: _tableText(num, fontSize)),
          const VerticalDivider(color: azulBoton, thickness: 2, width: 0),
          Expanded(child: _tableText(suma, fontSize)),
        ],
      ),
    );
  }

  Widget _tableText(String text, double fontSize) {
    return Center(
      child: Text(
        text,
        style: TextStyle(
          fontSize: fontSize,
          fontFamily: 'Hiruko',
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _buildOptionButton(BuildContext context, double sw, double sh,
      String text, Color bgColor, Color textColor, bool esCorrecto) {
    final btnH = (sh * 0.075).clamp(50.0, 100.0);
    final fontSize = (sw * 0.055).clamp(18.0, 38.0);

    return SizedBox(
      width: double.infinity,
      height: btnH,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15)),
        ),
        onPressed: () {
          ref.read(respuestaSumarProvider.notifier).state = esCorrecto;
          _showFeedbackSheet(context, esCorrecto);
        },
        child: Text(
          text,
          style: TextStyle(
            color: textColor,
            fontSize: fontSize,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  void _showFeedbackSheet(BuildContext context, bool esCorrecto) {
    FeedbackSounds.instance.reproducir(esCorrecto);
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
                    color: esCorrecto ? verdeNumi : rojoNumi,
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
                    backgroundColor: esCorrecto ? verdeNumi : rojoNumi,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15)),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    if (esCorrecto) {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                            builder: (_) => const PantallaSumaUvas()),
                      );
                    } else {
                      setState(() {
                        _datos = _DatosActividad.generar();
                      });
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
}
