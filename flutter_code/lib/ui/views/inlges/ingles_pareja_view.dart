// lib/ui/views/ingles_pareja_view.dart
// Módulo 2 — Une la pareja  (3 niveles)

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'ingles_congratulations_view.dart';

const _j2 = 'assets/images/areas/ingles/juego_2/';
const _a1 = 'assets/images/areas/ingles/juego_1/audios_1/';

// ── Niveles ───────────────────────────────────────────────────────────────
final _niveles = [
  {
    'pares': [
      {'img': '${_j2}balon.png', 'palabra': 'ball', 'audio': '${_a1}ball.mp3'},
      {
        'img': '${_j2}manzana.png',
        'palabra': 'apple',
        'audio': '${_a1}apple.mp3',
      },
      {'img': '${_j2}gato.png', 'palabra': 'cat', 'audio': '${_a1}cat.mp3'},
    ],
    'palabrasOrden': [1, 0, 2], // apple, ball, cat
  },
  {
    'pares': [
      {'img': '${_j2}pato.png', 'palabra': 'duck', 'audio': '${_a1}duck.mp3'},
      {'img': '${_j2}libro.png', 'palabra': 'book', 'audio': '${_a1}book.mp3'},
      {'img': '${_j2}1.png', 'palabra': 'one', 'audio': '${_a1}one.mp3'},
    ],
    'palabrasOrden': [2, 0, 1], // one, duck, book
  },
  {
    'pares': [
      {
        'img': '${_j2}uva-8.png',
        'palabra': 'grape',
        'audio': '${_a1}grapes.mp3',
      },
      {'img': '${_j2}carro.png', 'palabra': 'car', 'audio': '${_a1}car.mp3'},
      {'img': '${_j2}perro.png', 'palabra': 'dog', 'audio': '${_a1}dog.mp3'},
    ],
    'palabrasOrden': [1, 2, 0], // car, dog, grape
  },
];

// Un color por par
const _coloresPar = [Color(0xFFE53935), Color(0xFF1E88E5), Color(0xFFFF9800)];

// ─────────────────────────────────────────────────────────────────────────
class InglesParejaView extends StatefulWidget {
  const InglesParejaView({super.key, this.onCompleted});
  final VoidCallback? onCompleted;
  @override
  State<InglesParejaView> createState() => _InglesParejaViewState();
}

class _InglesParejaViewState extends State<InglesParejaView> {
  final _player = AudioPlayer();

  int _nivel = 0;
  int _imgSeleccionada = -1;
  final Set<int> _conectados = {};
  int _errorImg = -1;
  int _errorPal = -1;

  List get _pares => (_niveles[_nivel]['pares'] as List);
  List get _palabrasOrden => (_niveles[_nivel]['palabrasOrden'] as List);
  bool get _nivelCompleto => _conectados.length == _pares.length;

  late List<GlobalKey> _imgKeys;
  late List<GlobalKey> _palKeys;

  @override
  void initState() {
    super.initState();
    _resetKeys();
  }

  void _mostrarFeedback(bool esCorrecto, VoidCallback onAction) {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: esCorrecto ? const Color(0xFFD7FFD3) : const Color(0xFFFFD3D3),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              esCorrecto ? Icons.check_circle_rounded : Icons.cancel_rounded,
              color: esCorrecto ? Colors.green[800] : Colors.red[800],
              size: 56,
            ),
            const SizedBox(height: 12),
            Text(
              esCorrecto ? '¡Excelente trabajo!' : '¡Casi lo tienes!',
              style: TextStyle(
                fontFamily: 'Hiruko',
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: esCorrecto ? Colors.green[900] : Colors.red[900],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: esCorrecto ? Colors.green[700] : Colors.red[700],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  onAction();
                },
                child: Text(
                  esCorrecto ? 'Continuar' : 'Reintentar',
                  style: const TextStyle(
                    fontFamily: 'Hiruko',
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _resetKeys() {
    _imgKeys = List.generate(3, (_) => GlobalKey());
    _palKeys = List.generate(3, (_) => GlobalKey());
  }

  Future<void> _play(String path) async {
    try {
      await _player.stop();
      await _player.setAudioSource(AudioSource.asset(path));
      await _player.play();
    } catch (e) {
      debugPrint('Audio: $e');
    }
  }

  void _tocarImagen(int parIdx) {
    if (_conectados.contains(parIdx)) return;
    setState(() {
      _imgSeleccionada = parIdx;
      _errorImg = -1;
      _errorPal = -1;
    });
    _play(_pares[parIdx]['audio'] as String);
  }

  void _tocarPalabra(int posicion) {
    final parIdxPal = _palabrasOrden[posicion] as int;
    if (_conectados.contains(parIdxPal)) return;
    if (_imgSeleccionada == -1) return;

    if (_imgSeleccionada == parIdxPal) {
      setState(() {
        _conectados.add(parIdxPal);
        _imgSeleccionada = -1;
        _errorImg = -1;
        _errorPal = -1;
      });
    } else {
      setState(() {
        _errorImg = _imgSeleccionada;
        _errorPal = parIdxPal;
        _imgSeleccionada = -1;
      });
      Future.delayed(const Duration(milliseconds: 700), () {
        if (mounted) {
          setState(() {
            _errorImg = -1;
            _errorPal = -1;
          });
          _mostrarFeedback(false, () {});
        }
      });
    }
  }

  void _siguiente() {
    if (_nivel < 2) {
      setState(() {
        _nivel++;
        _imgSeleccionada = -1;
        _conectados.clear();
        _errorImg = -1;
        _errorPal = -1;
        _resetKeys();
      });
    } else {
      widget.onCompleted?.call();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const InglesCongratulationsView()),
      );
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  // ── Indicador de nivel (estilo igual a ingles_escucha_view) ──────────────
  Widget _buildIndicador() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (i) {
            final activo = i == _nivel;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: activo ? 26 : 10,
              height: 10,
              decoration: BoxDecoration(
                color: activo ? Colors.white : Colors.white38,
                borderRadius: BorderRadius.circular(5),
              ),
            );
          }),
        ),
        const SizedBox(height: 5),
        Text(
          'Level ${_nivel + 1}',
          style: const TextStyle(
            fontFamily: 'Hiruko',
            color: Colors.white70,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  // ── BUILD ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF8B2FC9),
      body: SafeArea(
        child: Column(
          children: [
            // HEADER — padding reducido para que el recuadro blanco sea más pequeño
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 16, 20, 16), // ← MODIFICADO
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Align(
                    alignment: Alignment.topRight,
                    child: GestureDetector(
                      onTap: () => Navigator.maybePop(context),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4), // ← MODIFICADO
                  const Text(
                    '¡Une  la pareja!',
                    style: TextStyle(
                      fontFamily: 'Hiruko',
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6), // ← MODIFICADO
                  _buildIndicador(),
                ],
              ),
            ),

            // CUERPO BLANCO
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 36, 20, 0),
                  child: Column(
                    children: [
                      // Subtítulo — mismo estilo que ingles_escucha_view
                      Row(
                        children: const [
                          Icon(
                            Icons.volume_up,
                            color: Colors.black87,
                            size: 24,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Une  la pareja',
                            style: TextStyle(
                              fontFamily: 'Hiruko',
                              fontSize: 17,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      // Área de juego
                      Expanded(
                        child: LayoutBuilder(
                          builder: (ctx, constraints) {
                            return Stack(
                              children: [
                                // Flechas dibujadas debajo de las columnas
                                Positioned.fill(
                                  child: CustomPaint(
                                    painter: _FlechasPainter(
                                      imgKeys: _imgKeys,
                                      palKeys: _palKeys,
                                      palabrasOrden: _palabrasOrden,
                                      conectados: _conectados,
                                      seleccionada: _imgSeleccionada,
                                    ),
                                  ),
                                ),

                                // Columnas
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    // ── IMÁGENES ──────────────────────────
                                    SizedBox(
                                      width: 100,
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceEvenly,
                                        children: List.generate(_pares.length, (
                                          i,
                                        ) {
                                          final par = _pares[i];
                                          final conectado = _conectados
                                              .contains(i);
                                          final seleccion =
                                              _imgSeleccionada == i;
                                          final esError = _errorImg == i;

                                          return GestureDetector(
                                            key: _imgKeys[i],
                                            onTap: () => _tocarImagen(i),
                                            child: AnimatedContainer(
                                              duration: const Duration(
                                                milliseconds: 200,
                                              ),
                                              width: 80,
                                              height: 80,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: esError
                                                    ? Colors.red.shade100
                                                    : seleccion
                                                    ? const Color(
                                                        0xFF8B2FC9,
                                                      ).withOpacity(0.12)
                                                    : Colors.grey.shade100,
                                                border: seleccion
                                                    ? Border.all(
                                                        color: const Color(
                                                          0xFF8B2FC9,
                                                        ),
                                                        width: 2.5,
                                                      )
                                                    : conectado
                                                    ? Border.all(
                                                        color: _coloresPar[i],
                                                        width: 2.5,
                                                      )
                                                    : null,
                                              ),
                                              padding: const EdgeInsets.all(10),
                                              child: Opacity(
                                                opacity: conectado ? 0.5 : 1.0,
                                                child: Image.asset(
                                                  par['img'] as String,
                                                  fit: BoxFit.contain,
                                                  errorBuilder: (_, _, _) =>
                                                      const SizedBox(),
                                                ),
                                              ),
                                            ),
                                          );
                                        }),
                                      ),
                                    ),

                                    // Espacio central para flechas
                                    const Spacer(),

                                    // ── PALABRAS ──────────────────────────
                                    SizedBox(
                                      width: 110,
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceEvenly,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: List.generate(
                                          _palabrasOrden.length,
                                          (pos) {
                                            final parIdx =
                                                _palabrasOrden[pos] as int;
                                            final par = _pares[parIdx];
                                            final conectado = _conectados
                                                .contains(parIdx);
                                            final esError = _errorPal == parIdx;
                                            final color = _coloresPar[parIdx];

                                            return GestureDetector(
                                              key: _palKeys[pos],
                                              onTap: () => _tocarPalabra(pos),
                                              child: AnimatedContainer(
                                                duration: const Duration(
                                                  milliseconds: 200,
                                                ),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 10,
                                                      vertical: 8,
                                                    ),
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                  color: esError
                                                      ? Colors.red.shade50
                                                      : Colors.transparent,
                                                ),
                                                child: Text(
                                                  par['palabra'] as String,
                                                  style: TextStyle(
                                                    fontFamily: 'Hiruko',
                                                    fontSize: 26,
                                                    fontWeight: FontWeight.bold,
                                                    color: conectado
                                                        ? Colors.grey.shade300
                                                        : esError
                                                        ? Colors.red
                                                        : color,
                                                  ),
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            );
                          },
                        ),
                      ),

                      // Botón siguiente — mismo estilo que ingles_escucha_view
                      if (_nivelCompleto)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 24, top: 12),
                          child: ElevatedButton(
                            onPressed: _siguiente,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF8B2FC9),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 48,
                                vertical: 14,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              elevation: 4,
                            ),
                            child: Text(
                              _nivel < 2 ? 'Next' : 'Finish!',
                              style: const TextStyle(
                                fontFamily: 'Hiruko',
                                fontSize: 17,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),

                      if (!_nivelCompleto) const SizedBox(height: 24),
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

// ══════════════════════════════════════════════════════════════════════════
// PAINTER — flechas que terminan ANTES del borde izquierdo de la palabra
// ══════════════════════════════════════════════════════════════════════════
class _FlechasPainter extends CustomPainter {
  final List<GlobalKey> imgKeys;
  final List<GlobalKey> palKeys;
  final List palabrasOrden;
  final Set<int> conectados;
  final int seleccionada;

  _FlechasPainter({
    required this.imgKeys,
    required this.palKeys,
    required this.palabrasOrden,
    required this.conectados,
    required this.seleccionada,
  });

  Offset? _localCenter(GlobalKey key, RenderBox paintBox) {
    final ctx = key.currentContext;
    if (ctx == null) return null;
    final box = ctx.findRenderObject() as RenderBox?;
    if (box == null) return null;
    final global = box.localToGlobal(box.size.center(Offset.zero));
    return paintBox.globalToLocal(global);
  }

  // Borde IZQUIERDO del widget de palabra (no el centro)
  Offset? _localLeft(GlobalKey key, RenderBox paintBox) {
    final ctx = key.currentContext;
    if (ctx == null) return null;
    final box = ctx.findRenderObject() as RenderBox?;
    if (box == null) return null;
    final global = box.localToGlobal(Offset(0, box.size.height / 2));
    return paintBox.globalToLocal(global);
  }

  void _flecha(Canvas canvas, Offset from, Offset to, Color color) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawLine(from, to, paint);

    // Punta de flecha
    final angle = (to - from).direction;
    const size = 12.0;
    final p1 =
        to +
        Offset(
          size * math.cos(angle + math.pi - 0.4),
          size * math.sin(angle + math.pi - 0.4),
        );
    final p2 =
        to +
        Offset(
          size * math.cos(angle + math.pi + 0.4),
          size * math.sin(angle + math.pi + 0.4),
        );

    canvas.drawLine(to, p1, paint);
    canvas.drawLine(to, p2, paint);
  }

  @override
  void paint(Canvas canvas, Size size) {
    RenderBox? paintBox;
    for (final k in imgKeys) {
      final ctx = k.currentContext;
      if (ctx == null) continue;
      paintBox = ctx.findAncestorRenderObjectOfType<RenderBox>();
      if (paintBox != null) break;
    }
    if (paintBox == null) return;

    for (final parIdx in conectados) {
      final posEnPal = palabrasOrden.indexWhere((p) => p == parIdx);
      if (posEnPal == -1) continue;

      final origen = _localCenter(imgKeys[parIdx], paintBox);
      final destinoLeft = _localLeft(palKeys[posEnPal], paintBox);
      if (origen == null || destinoLeft == null) continue;

      final o = Offset(origen.dx + 40, origen.dy);
      final d = Offset(destinoLeft.dx - 8, destinoLeft.dy);

      _flecha(canvas, o, d, _coloresPar[parIdx]);
    }
  }

  @override
  bool shouldRepaint(_FlechasPainter old) => true;
}