import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import 'dart:math';
import 'quien_tiene_mas_31.dart';

const Color kColorAzulNumi = Color(0xFF3475F7);
const Color kColorRojoNumi = Color(0xFFF65757);
const Color kColorNaranjaNumi = Color(0xFFEF9325);
const Color kColorVerdeNumi = Color(0xFF59E347);

// ─── Modelo de actividad aleatoria ─────────────────────────────────────────
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

    final a = rng.nextInt(6) + 1; // 1..6
    final b = rng.nextInt(6) + 1; // 1..6
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

// ─── Pantalla principal ─────────────────────────────────────────────────────
class PantallaSumaUvas extends ConsumerStatefulWidget {
  const PantallaSumaUvas({super.key});

  @override
  ConsumerState<PantallaSumaUvas> createState() => _PantallaSumaUvasState();
}

class _PantallaSumaUvasState extends ConsumerState<PantallaSumaUvas> {
  Player? _player;
  late _DatosActividad _datos;

  @override
  void initState() {
    super.initState();
    _datos = _DatosActividad.generar();
    _player = Player();
    Future.microtask(() => _reproducirInstruccion());
  }

  @override
  void dispose() {
    _player?.dispose();
    super.dispose();
  }

  Future<void> _reproducirInstruccion() async {
    try {
      await _player?.open(
        Media('asset:///assets/Audio/Matematicas/audio mate8_mezcla.mp3'),
      );
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
    return Scaffold(
      backgroundColor: kColorAzulNumi,
      body: SafeArea(
        child: Column(
          children: [
            const _HeaderSuma(),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(40)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      const SizedBox(height: 10),
                      _InstruccionAudio(onPlay: _reproducirInstruccion),
                      const Spacer(),
                      _SeccionCajas(
                        cantidadA: _datos.cantidadA,
                        cantidadB: _datos.cantidadB,
                      ),
                      const Spacer(),
                      Text(
                        '${_datos.cantidadA}+${_datos.cantidadB}=?',
                        style: const TextStyle(
                          fontFamily: 'Hiruko',
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const Spacer(),
                      _OpcionesRespuesta(
                        datos: _datos,
                        onRegenerar: _regenerar,
                      ),
                      const SizedBox(height: 20),
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

// ─── Header ──────────────────────────────────────────────────────────────────
class _HeaderSuma extends StatelessWidget {
  const _HeaderSuma();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      width: double.infinity,
      child: Stack(
        children: [
          const Align(
            alignment: Alignment.center,
            child: Text(
              'Sumar',
              style: TextStyle(
                fontFamily: 'Hiruko',
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          Positioned(
            top: 10,
            right: 15,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 30),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Instrucción con audio ────────────────────────────────────────────────────
class _InstruccionAudio extends StatelessWidget {
  final VoidCallback onPlay;
  const _InstruccionAudio({required this.onPlay});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.volume_up_outlined, size: 50),
          color: Colors.black87,
          onPressed: onPlay,
        ),
        const SizedBox(width: 15),
        const Expanded(
          child: Text(
            'Suma  las uvas de  las dos cajas',
            style: TextStyle(
              fontFamily: 'Hiruko',
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Sección de cajas ─────────────────────────────────────────────────────────
class _SeccionCajas extends StatelessWidget {
  final int cantidadA;
  final int cantidadB;
  const _SeccionCajas({required this.cantidadA, required this.cantidadB});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _CajaFruta(color: kColorRojoNumi, cantidad: cantidadA),
        const SizedBox(width: 20),
        _CajaFruta(color: kColorNaranjaNumi, cantidad: cantidadB),
      ],
    );
  }
}

// ─── Caja individual con uvas adaptativas ────────────────────────────────────
class _CajaFruta extends StatelessWidget {
  final Color color;
  final int cantidad;
  const _CajaFruta({required this.color, required this.cantidad});

  // ✅ Tamaño de uva se adapta según cuántas hay
  double get _tamanoUva {
    if (cantidad <= 2) return 55;
    if (cantidad <= 4) return 48;
    if (cantidad <= 6) return 38;
    if (cantidad <= 9) return 30;
    return 24; // 10..12
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 145,
      height: 145,
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
                runAlignment: WrapAlignment.center, // ✅ centra filas verticalmente
                children: List.generate(
                  cantidad,
                  (index) => Image.asset(
                    'assets/images/actividades/matematicas/mora.png',
                    width: _tamanoUva,
                    height: _tamanoUva,
                    fit: BoxFit.contain,
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
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 26,
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

// ─── Opciones de respuesta ────────────────────────────────────────────────────
class _OpcionesRespuesta extends StatelessWidget {
  final _DatosActividad datos;
  final VoidCallback onRegenerar;
  const _OpcionesRespuesta({required this.datos, required this.onRegenerar});

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

// ─── Botón de opción ──────────────────────────────────────────────────────────
class _BotonOpcion extends StatelessWidget {
  final String numero;
  final VoidCallback onTap;
  const _BotonOpcion({required this.numero, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        height: 70,
        decoration: BoxDecoration(
          color: kColorAzulNumi,
          borderRadius: BorderRadius.circular(15),
        ),
        alignment: Alignment.center,
        child: Text(
          numero,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

// ─── Bottom sheet de feedback ─────────────────────────────────────────────────
void _showFeedbackSheet(
    BuildContext context, bool esCorrecto, VoidCallback onRegenerar) {
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
                  color: esCorrecto ? kColorVerdeNumi : kColorRojoNumi,
                  size: 40,
                ),
                const SizedBox(width: 15),
                Text(
                  esCorrecto ? '¡Excelente trabajo!' : '¡Casi lo tienes!',
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