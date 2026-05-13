import 'dart:math';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'quien_tiene_mas_3.dart';
import '../../../../data/services/feedback_sounds.dart';

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
    FeedbackSounds.instance.reproducir(esCorrecto);
    final sw       = MediaQuery.of(context).size.width;
    final isTablet = sw >= 600;
    final hPad     = (sw * (isTablet ? 0.08 : 0.06)).clamp(20.0, 60.0);

    showModalBottomSheet(
      context: context,
      isDismissible: false,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 26),
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
                    size: isTablet ? 52 : 40,
                  ),
                  SizedBox(width: isTablet ? 20 : 15),
                  Flexible(
                    child: Text(
                      esCorrecto ? '¡Excelente trabajo!' : '¡Inténtalo de nuevo!',
                      style: TextStyle(
                        fontFamily: 'Hiruko',
                        fontSize: (sw * (isTablet ? 0.04 : 0.056))
                            .clamp(18.0, 30.0),
                        fontWeight: FontWeight.bold,
                        color: esCorrecto ? Colors.green[900] : Colors.red[900],
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: isTablet ? 28 : 20),
              SizedBox(
                width: double.infinity,
                height: isTablet ? 64 : 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: esCorrecto
                        ? const Color(0xFF59E347)
                        : const Color(0xFFF65757),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15)),
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    onAction();
                  },
                  child: Text(
                    esCorrecto ? 'Continuar' : 'Reintentar',
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.bold,
                      fontSize: (sw * (isTablet ? 0.028 : 0.044))
                          .clamp(14.0, 22.0),
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
    final mq       = MediaQuery.of(context);
    final sw       = mq.size.width;
    final sh       = mq.size.height;
    final isTablet = sw >= 600;
    final statusBar = mq.padding.top;

    // Header azul más grande, proporcional a la pantalla
    final headerH   = (sh * 0.11).clamp(70.0, 110.0);
    final titleSize = (sw * (isTablet ? 0.048 : 0.057)).clamp(18.0, 36.0);
    final iconSize  = (sw * 0.07).clamp(22.0, 36.0);
    final hPad      = (sw * (isTablet ? 0.05 : 0.04)).clamp(14.0, 40.0);

    // Textos internos
    final instrSize = (sw * 0.055).clamp(18.0, 40.0);
    final btnFontSz = (sw * (isTablet ? 0.028 : 0.040)).clamp(13.0, 22.0);
    final volIconSz = (sw * 0.13).clamp(44.0, 60.0);

    return Scaffold(
      backgroundColor: const Color(0xFF3475F7),
      body: Column(
        children: [
          // ── Header azul ──────────────────────────────────────────────────
          SizedBox(
            height: statusBar + headerH,
            child: Stack(
              children: [
                // Título centrado
                Positioned(
                  top: statusBar,
                  left: 0,
                  right: 0,
                  bottom: 28, // deja espacio entre título y barra
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: iconSize + 16),
                      child: Text(
                        'Quién tiene más',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: titleSize,
                          fontFamily: 'Hiruko',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
                // Botón cerrar
                Positioned(
                  top: statusBar + 4,
                  right: 4,
                  child: IconButton(
                    icon: Icon(
                      Icons.close_rounded,
                      color: Colors.white,
                      size: iconSize,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                // ── Barra de progreso (2 de 3) ──────────────────────────────
                Positioned(
                  bottom: 10,
                  left: isTablet ? 60 : 40,
                  right: isTablet ? 60 : 40,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: 2 / 3,
                      backgroundColor: Colors.white.withOpacity(0.15),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFF59E347)),
                      minHeight: isTablet ? 12 : 10,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Card blanco — ocupa todo el resto ────────────────────────────
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
              child: Padding(
                padding: EdgeInsets.fromLTRB(hPad, hPad * 0.4, hPad, 0),
                child: Column(
                  children: [
                    // ── Árboles con frutas ──────────────────────────────
                    Expanded(
                      flex: 68,
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          // Calcular tamaño real del árbol dentro del espacio disponible
                          final availW = (constraints.maxWidth - hPad) / 2;
                          final availH = constraints.maxHeight;
                          // Árbol proporción 150:220 (w:h)
                          double tW = availW;
                          double tH = tW * (220 / 150);
                          if (tH > availH * 0.88) {
                            tH = availH * 0.88;
                            tW = tH * (150 / 220);
                          }
                          final numSz = (tW * 0.28).clamp(22.0, 50.0);
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              _buildArbolConFrutas(
                                numeroCuadro: '1',
                                numeroColor: const Color(0xFFF65757),
                                cantidadFrutas: _cantidadManzanas,
                                posiciones: _posicionesArbol1,
                                frutaAsset: 'assets/images/actividades/matematicas/manzana.png',
                                treeW: tW,
                                treeH: tH,
                                numSize: numSz,
                                renderScale: 2.0,
                              ),
                              _buildArbolConFrutas(
                                numeroCuadro: '2',
                                numeroColor: const Color(0xFFEF9325),
                                cantidadFrutas: _cantidadNaranjas,
                                posiciones: _posicionesArbol2,
                                frutaAsset: 'assets/images/actividades/matematicas/NARANJA_8.png',
                                treeW: tW,
                                treeH: tH,
                                numSize: numSz,
                              ),
                            ],
                          );
                        },
                      ),
                    ),

                    SizedBox(height: (sh * 0.012).clamp(6.0, 14.0)),

                    // ── Instrucción ─────────────────────────────────────
                    Row(
                      children: [
                        GestureDetector(
                          onTap: _reproducirInstruccion,
                          child: Container(
                            width: volIconSz,
                            height: volIconSz,
                            decoration: BoxDecoration(
                              color: const Color(0xFFEEF2FF),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(
                              Icons.volume_up_rounded,
                              color: const Color(0xFF3475F7),
                              size: volIconSz * 0.54,
                            ),
                          ),
                        ),
                        SizedBox(width: hPad * 0.5),
                        Expanded(
                          child: Text(
                            '¿Cuál árbol tiene menos frutas?',
                            style: TextStyle(
                              fontSize: instrSize,
                              fontFamily: 'Hiruko',
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: (sh * 0.018).clamp(8.0, 22.0)),

                    // ── Botones ─────────────────────────────────────────
                    Expanded(
                      flex: 13,
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildActionButton(
                              context,
                              label: 'Árbol 1',
                              color: const Color(0xFF3475F7),
                              fontSize: btnFontSz,
                              onPressed: () => _verificarRespuesta(context, 1),
                            ),
                          ),
                          SizedBox(width: hPad),
                          Expanded(
                            child: _buildActionButton(
                              context,
                              label: 'Árbol 2',
                              color: const Color(0xFF3475F7),
                              fontSize: btnFontSz,
                              onPressed: () => _verificarRespuesta(context, 2),
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: (sh * 0.020).clamp(8.0, 24.0)),
                  ],
                ),
              ),
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
    required double treeW,
    required double treeH,
    required double numSize,
    double renderScale = 1.0,
  }) {
    final double scaleX = treeW / 150.0;
    final double scaleY = treeH / 220.0;
    // renderScale permite ampliar la manzana para que coincida
    // visualmente con la naranja sin tocar el algoritmo de posicionamiento
    final double renderW = _frutaSize * scaleX * renderScale;
    final double renderH = _frutaSize * scaleY * renderScale;
    final double half    = renderW / 2;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          numeroCuadro,
          style: TextStyle(
            fontSize: numSize,
            fontFamily: 'Behove',
            fontWeight: FontWeight.w900,
            color: numeroColor,
          ),
        ),
        SizedBox(height: numSize * 0.2),
        SizedBox(
          width: treeW,
          height: treeH,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: Image.asset(
                  'assets/images/actividades/matematicas/arbol.png',
                  fit: BoxFit.fill,
                ),
              ),
              for (int i = 0; i < posiciones.length; i++)
                Positioned(
                  left: posiciones[i].dx * scaleX - half,
                  top:  posiciones[i].dy * scaleY - half,
                  child: Image.asset(
                    frutaAsset,
                    width:  renderW,
                    height: renderH,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
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
    required double fontSize,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: double.infinity,
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
          style: TextStyle(
            fontSize: fontSize,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}