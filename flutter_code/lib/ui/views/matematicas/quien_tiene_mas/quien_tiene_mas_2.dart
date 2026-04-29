import 'dart:math';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'quien_tiene_mas_3.dart';

class MenosFrutasview extends StatefulWidget {
  const MenosFrutasview({super.key});

  @override
  State<MenosFrutasview> createState() => _MenosFrutasviewState();
}

class _MenosFrutasviewState extends State<MenosFrutasview> {
  AudioPlayer? _player;

  late int _cantidadManzanas;
  late int _cantidadNaranjas;
  late List<Offset> _posicionesArbol1;
  late List<Offset> _posicionesArbol2;
  late int _respuestaCorrecta;

  // ─── Parámetros de la copa ────────────────────────────────────────────────
  // Stack: 150 × 220 px
  // Copa verde (óvalo): centro (75, 68), radio horizontal 52, radio vertical 52
  // Borde oscuro ~11px de grosor → zona útil: radio 41 px desde el centro
  // Fruta: 22 × 22 px → radio fruta = 11 px
  // Separación mínima entre centros = 22 + 8 = 30 px
  // ──────────────────────────────────────────────────────────────────────────
  static const double _copaCx     = 75.0;
  static const double _copaCy     = 65.0;
  static const double _copaRadio  = 40.0; // radio útil (sin tocar borde oscuro)
  static const double _frutaSize  = 30.0;
  static const double _minDist    = 30.0; // separación mínima entre centros

  // Genera N posiciones distribuidas dentro del óvalo de la copa,
  // sin que ninguna se solape, usando "Poisson-disk sampling" simplificado.
  List<Offset> _generarPosiciones(int cantidad, Random random) {
    final List<Offset> resultado = [];
    int intentos = 0;
    const int maxIntentos = 2000;

    while (resultado.length < cantidad && intentos < maxIntentos) {
      intentos++;

      // Punto aleatorio dentro de un círculo de radio _copaRadio
      final double angulo = random.nextDouble() * 2 * pi;
      // sqrt para distribución uniforme (no concentrada en el centro)
      final double radio  = _copaRadio * sqrt(random.nextDouble());
      final double px     = _copaCx + radio * cos(angulo);
      final double py     = _copaCy + radio * sin(angulo);

      // Verificar que el BORDE de la fruta no salga del radio útil
      final double distAlCentro = sqrt(pow(px - _copaCx, 2) + pow(py - _copaCy, 2));
      if (distAlCentro + (_frutaSize / 2) > _copaRadio) continue;

      // Verificar separación mínima con todas las frutas ya colocadas
      bool solapa = false;
      for (final prev in resultado) {
        final double d = sqrt(pow(px - prev.dx, 2) + pow(py - prev.dy, 2));
        if (d < _minDist) {
          solapa = true;
          break;
        }
      }
      if (solapa) continue;

      resultado.add(Offset(px, py));
    }

    return resultado;
  }

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _generarFrutasAleatorias();
    Future.microtask(() => _reproducirInstruccion());
  }

  void _generarFrutasAleatorias() {
    final random = Random();

    // Reintenta hasta que ambos arboles tengan cantidades distintas
    // Y el Poisson-disk haya colocado EXACTAMENTE las frutas pedidas.
    while (true) {
      final int pedidoA = random.nextInt(5) + 2; // 2-6
      final int pedidoB = random.nextInt(5) + 2;
      if (pedidoA == pedidoB) continue;

      final List<Offset> posA = _generarPosiciones(pedidoA, random);
      final List<Offset> posB = _generarPosiciones(pedidoB, random);

      // Solo aceptar si el algoritmo coloco exactamente lo pedido
      if (posA.length != pedidoA || posB.length != pedidoB) continue;
      // Doble seguridad: conteos reales distintos
      if (posA.length == posB.length) continue;

      _cantidadManzanas = posA.length;
      _cantidadNaranjas  = posB.length;
      _posicionesArbol1  = posA;
      _posicionesArbol2  = posB;
      _respuestaCorrecta = _cantidadManzanas < _cantidadNaranjas ? 1 : 2;
      break;
    }
  }

  @override
  void dispose() {
    _player?.dispose();
    super.dispose();
  }

  Future<void> _reproducirInstruccion() async {
    try {
      await _player?.setAsset('assets/Audio/Matematicas/audio mate5_mezcla.mp3');
      await _player?.play();
    } catch (e) {
      debugPrint('Error al reproducir audio: $e');
    }
  }

  void _mostrarFeedback(
      BuildContext context, bool esCorrecto, VoidCallback onAction) {
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

  void _verificarRespuesta(BuildContext context, int seleccion) {
    final esCorrecto = seleccion == _respuestaCorrecta;
    _mostrarFeedback(context, esCorrecto, () {
      if (esCorrecto) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const QuienTieneMasview3()),
        );
      } else {
        setState(() => _generarFrutasAleatorias());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF3475F7),
      body: Stack(
        children: [
          const Positioned(
            top: 70,
            left: 0,
            right: 0,
            child: Text(
              'Quién tiene más',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontFamily: 'Hiruko',
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: MediaQuery.of(context).size.height * 0.82,
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(50),
                  topRight: Radius.circular(50),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 25, vertical: 40),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _buildArbolConFrutas(
                          numeroCuadro: '1',
                          numeroColor: const Color(0xFFF65757),
                          cantidadFrutas: _cantidadManzanas,
                          posiciones: _posicionesArbol1,
                          frutaAsset:
                              'assets/images/actividades/matematicas/manzana.png',
                        ),
                        _buildArbolConFrutas(
                          numeroCuadro: '2',
                          numeroColor: const Color(0xFFEF9325),
                          cantidadFrutas: _cantidadNaranjas,
                          posiciones: _posicionesArbol2,
                          frutaAsset:
                              'assets/images/actividades/matematicas/NARANJA_8.png',
                        ),
                      ],
                    ),

                    const Spacer(),

                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.volume_up_outlined, size: 60),
                          color: Colors.black87,
                          onPressed: _reproducirInstruccion,
                        ),
                        const SizedBox(width: 15),
                        const Expanded(
                          child: Text(
                            '¿Cuál árbol tiene menos frutas?',
                            style: TextStyle(
                              fontSize: 22,
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w700,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 40),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildActionButton(
                          context,
                          label: 'Árbol 1',
                          color: const Color(0xFF3475F7),
                          onPressed: () => _verificarRespuesta(context, 1),
                        ),
                        _buildActionButton(
                          context,
                          label: 'Árbol 2',
                          color: const Color(0xFF3475F7),
                          onPressed: () => _verificarRespuesta(context, 2),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),

          Positioned(
            top: 35,
            right: 15,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 30),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArbolConFrutas({
    required String numeroCuadro,
    required Color numeroColor,
    required int cantidadFrutas,
    required List<Offset> posiciones,
    required String frutaAsset,
  }) {
    const double stackAncho = 150;
    const double stackAlto  = 220;
    const double half       = _frutaSize / 2;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          numeroCuadro,
          style: TextStyle(
            fontSize: 45,
            fontFamily: 'Behove',
            fontWeight: FontWeight.w900,
            color: numeroColor,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: stackAncho,
          height: stackAlto,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Árbol base
              Positioned.fill(
                child: Image.asset(
                  'assets/images/actividades/matematicas/arbol.png',
                  fit: BoxFit.fill,
                ),
              ),

              // Frutas distribuidas orgánicamente
              for (int i = 0; i < posiciones.length; i++)
                Positioned(
                  left: posiciones[i].dx - half,
                  top:  posiciones[i].dy - half,
                  child: Image.asset(
                    frutaAsset,
                    width:  _frutaSize,
                    height: _frutaSize,
                    fit: BoxFit.contain,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: 150,
      height: 55,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 18,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}