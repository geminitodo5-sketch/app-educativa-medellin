import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'dart:math';
import 'sumar_2.dart';

final respuestaSumarProvider = StateProvider<bool?>((ref) => null);

// ─── Tipos de patrón disponibles ───────────────────────────────────────────
enum TipoPatron { sumarUno, sumarDos, sumarTres, sumarCuatro }

class _Patron {
  final String nombre;      // descripción interna
  final int incremento;     // cuánto suma cada fila

  const _Patron({required this.nombre, required this.incremento});
}

const _patrones = [
  _Patron(nombre: '+1', incremento: 1),
  _Patron(nombre: '+2', incremento: 2),
  _Patron(nombre: '+3', incremento: 3),
  _Patron(nombre: '+4', incremento: 4),
];

// ─── Modelo de la actividad generada aleatoriamente ────────────────────────
class _DatosActividad {
  final int fila1Num;         // número columna izquierda fila 1
  final int incremento;       // de qué en qué sube
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

  // Números de cada fila (columna izquierda)
  int get fila2Num => fila1Num + incremento;
  int get fila3Num => fila1Num + incremento * 2;

  // Suma que se muestra en columna derecha (fila1: anterior+incremento)
  // Fila 1: (fila1Num - incremento) + incremento  →  se muestra como "prev+inc"
  // Usamos: fila1Num = prev + incremento, entonces prev = fila1Num - incremento
  String get fila1Suma => '${fila1Num - incremento}+$incremento';
  String get fila2Suma => '${fila2Num - incremento}+$incremento';
  // fila3Suma es la respuesta correcta → se muestra "???"

  factory _DatosActividad.generar() {
    final rng = Random();

    // Elegir patrón aleatorio
    final patron = _patrones[rng.nextInt(_patrones.length)];
    final inc = patron.incremento;

    // Número inicial de fila1: debe ser al menos inc+1 para que fila1Suma tenga sentido
    // Rango: (inc+1) .. (inc+6)  para que los números sean manejables para niños
    final fila1Num = rng.nextInt(6) + (inc + 1); // ej: si inc=2 → 3..8

    // Respuesta correcta: fila3Num - incremento + incremento
    final fila3Num = fila1Num + inc * 2;
    final correcto = '${fila3Num - inc}+$inc';

    // Distractores: variar el primer o segundo operando
    final distractores = [
      '${fila3Num - inc + 1}+$inc',
      '${fila3Num - inc - 1}+$inc',
      '${fila3Num - inc}+${inc + 1}',
      '${fila3Num - inc}+${inc - 1}',
    ].where((d) => d != correcto && !d.contains('+0') && !d.contains('-')).toList();

    // Si por algún edge-case no hay distractores válidos, usar fallback
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

// ─── Widget principal ───────────────────────────────────────────────────────
class SumarPatronview extends ConsumerStatefulWidget {
  const SumarPatronview({super.key});

  @override
  ConsumerState<SumarPatronview> createState() => _SumarPatronviewState();
}

class _SumarPatronviewState extends ConsumerState<SumarPatronview> {
  AudioPlayer? _player;
  late _DatosActividad _datos;

  static const Color azulPrincipal   = Color(0xFF3475F7);
  static const Color azulBoton       = Color(0xFF3878FA);
  static const Color rojoNumi        = Color(0xFFF65757);
  static const Color naranjaNumi     = Color(0xFFEF9325);
  static const Color verdeNumi       = Color(0xFF59E347);

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
    return Scaffold(
      backgroundColor: azulPrincipal,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildTopBar(context),
            const SizedBox(height: 10),
            Expanded(child: _buildMainContent(context)),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Column(
      children: [
        Align(
          alignment: Alignment.topRight,
          child: IconButton(
            icon: const Icon(Icons.close, color: Colors.white, size: 30),
            onPressed: () {
              ref.read(respuestaSumarProvider.notifier).state = null;
              Navigator.of(context).pop();
            },
          ),
        ),
        const Text(
          'Sumar',
          style: TextStyle(
            color: Colors.white,
            fontSize: 34,
            fontFamily: 'Hiruko',
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildMainContent(BuildContext context) {
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
        padding: const EdgeInsets.symmetric(horizontal: 25.0, vertical: 40.0),
        child: Column(
          children: [
            _buildInstruction(),
            const SizedBox(height: 40),
            _buildPatternTable(),
            const Spacer(),
            _buildOptionButton(
              context,
              _datos.correctaEsPrimera
                  ? _datos.opcionCorrecta
                  : _datos.opcionIncorrecta,
              azulBoton,
              Colors.white,
              _datos.correctaEsPrimera,
            ),
            const SizedBox(height: 15),
            _buildOptionButton(
              context,
              _datos.correctaEsPrimera
                  ? _datos.opcionIncorrecta
                  : _datos.opcionCorrecta,
              azulBoton,
              Colors.white,
              !_datos.correctaEsPrimera,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildInstruction() {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.volume_up_rounded, size: 50),
          color: Colors.black87,
          onPressed: _reproducirInstruccion,
        ),
        const SizedBox(width: 15),
        const Text(
          'Continua el patrón',
          style: TextStyle(
            fontSize: 20,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _buildPatternTable() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: azulBoton, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Column(
          children: [
            // ✅ Las 3 filas usan los datos generados aleatoriamente
            _buildTableRow('${_datos.fila1Num}', _datos.fila1Suma, rojoNumi),
            _buildTableRow('${_datos.fila2Num}', _datos.fila2Suma, naranjaNumi),
            _buildTableRow('${_datos.fila3Num}', '???',            verdeNumi),
          ],
        ),
      ),
    );
  }

  Widget _buildTableRow(String num, String suma, Color bgColor) {
    return Container(
      height: 65,
      decoration: BoxDecoration(
        color: bgColor,
        border: const Border(bottom: BorderSide(color: azulBoton, width: 1)),
      ),
      child: Row(
        children: [
          Expanded(child: _tableText(num)),
          const VerticalDivider(color: azulBoton, thickness: 2, width: 0),
          Expanded(child: _tableText(suma)),
        ],
      ),
    );
  }

  Widget _tableText(String text) {
    return Center(
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 28,
          fontFamily: 'Hiruko',
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _buildOptionButton(BuildContext context, String text, Color bgColor,
      Color textColor, bool esCorrecto) {
    return SizedBox(
      width: double.infinity,
      height: 60,
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
            fontSize: 22,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  void _showFeedbackSheet(BuildContext context, bool esCorrecto) {
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
                    color: esCorrecto ? verdeNumi : rojoNumi,
                    size: 40,
                  ),
                  const SizedBox(width: 15),
                  Text(
                    esCorrecto ? '¡Excelente trabajo!' : '¡Inténtalo de nuevo!',
                    style: TextStyle(
                      fontFamily: 'Hiruko',
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color:
                          esCorrecto ? Colors.green[900] : Colors.red[900],
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
                      // ✅ Reintentar genera un patrón completamente nuevo
                      setState(() {
                        _datos = _DatosActividad.generar();
                      });
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
}