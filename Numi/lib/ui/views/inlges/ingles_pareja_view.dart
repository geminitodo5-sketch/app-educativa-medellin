import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'ingles_congratulations_view.dart';
import '../../../data/services/feedback_sounds.dart';

const _j2 = 'assets/images/areas/ingles/juego_2/';
const _a1 = 'assets/images/areas/ingles/juego_1/audios_1/';
const _audioInstruccion =
    'assets/images/areas/ingles/juego_2/une_la_pareja.mp3';

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
    'palabrasOrden': [1, 0, 2],
  },
  {
    'pares': [
      {'img': '${_j2}pato.png', 'palabra': 'duck', 'audio': '${_a1}duck.mp3'},
      {'img': '${_j2}libro.png', 'palabra': 'book', 'audio': '${_a1}book.mp3'},
      {'img': '${_j2}1.png', 'palabra': 'one', 'audio': '${_a1}one.mp3'},
    ],
    'palabrasOrden': [2, 0, 1],
  },
  {
    'pares': [
      {
        'img': '${_j2}uva-8.png',
        'palabra': 'grapes',
        'audio': '${_a1}grapes.mp3',
      },
      {'img': '${_j2}carro.png', 'palabra': 'car', 'audio': '${_a1}car.mp3'},
      {'img': '${_j2}perro.png', 'palabra': 'dog', 'audio': '${_a1}dog.mp3'},
    ],
    'palabrasOrden': [1, 2, 0],
  },
];

const _coloresPar = [Color(0xFFE53935), Color(0xFF1E88E5), Color(0xFFFF9800)];

class InglesParejaView extends StatefulWidget {
  const InglesParejaView({super.key, this.onCompleted});
  final VoidCallback? onCompleted;

  @override
  State<InglesParejaView> createState() => _InglesParejaViewState();
}

class _InglesParejaViewState extends State<InglesParejaView> {
  late final AudioPlayer _player;

  int _nivel = 0;
  int _imgSeleccionada = -1;
  final Set<int> _conectados = {};
  int _errorImg = -1;
  int _errorPal = -1;

  // ── NUEVO: orden aleatorio de imágenes ──────────────────────────────────
  late List<int> _imgsOrden;

  List get _pares => (_niveles[_nivel]['pares'] as List);
  List get _palabrasOrden => (_niveles[_nivel]['palabrasOrden'] as List);
  bool get _nivelCompleto => _conectados.length == _pares.length;

  late List<GlobalKey> _imgKeys;
  late List<GlobalKey> _palKeys;

  // ── NUEVO: genera orden aleatorio para imágenes ─────────────────────────
  List<int> _generarOrdenAleatorio() {
    final orden = List<int>.generate(_pares.length, (i) => i);
    orden.shuffle(math.Random());
    return orden;
  }

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _resetKeys();
    _imgsOrden = _generarOrdenAleatorio(); // ← NUEVO
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _reproducirInstruccion();
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  void _resetKeys() {
    _imgKeys = List.generate(3, (_) => GlobalKey());
    _palKeys = List.generate(3, (_) => GlobalKey());
  }

  Future<void> _reproducirInstruccion() async {
    try {
      await _player.setAsset(_audioInstruccion);
      await _player.play();
    } catch (e) {
      debugPrint('Error audio instrucción: $e');
    }
  }

  Future<void> _play(String assetPath) async {
    try {
      await _player.setAsset(assetPath);
      await _player.play();
    } catch (e) {
      debugPrint('Audio: $e');
    }
  }

  void _mostrarFeedback(bool esCorrecto, VoidCallback onAction) {
    FeedbackSounds.instance.reproducir(esCorrecto);
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
                    backgroundColor: esCorrecto
                        ? const Color(0xFF59E347)
                        : const Color(0xFFF65757),
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

  // ── _tocarImagen recibe la posición visual → obtiene el parIdx real ─────
  void _tocarImagen(int posicion) {
    final parIdx = _imgsOrden[posicion]; // ← NUEVO: índice real del par
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
        _imgsOrden =
            _generarOrdenAleatorio(); // ← NUEVO: nuevo orden al cambiar nivel
      });
    } else {
      widget.onCompleted?.call();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const InglesCongratulationsView()),
      );
    }
  }

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF8B2FC9),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 16, 20, 16),
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
                  const SizedBox(height: 4),
                  const Text(
                    '¡Une  la pareja!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Hiruko',
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: (_nivel + 1) / 3,
                      minHeight: 8,
                      backgroundColor: Colors.white30,
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF59E347)),
                    ),
                  ),
                ],
              ),
            ),
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
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          GestureDetector(
                            onTap: _reproducirInstruccion,
                            child: Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: const Color(0xFFEDE7F6),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.volume_up_rounded,
                                  color: Color(0xFF7B2FBE),
                                  size: 30,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Text(
                              'Une  la pareja',
                              style: TextStyle(
                                fontFamily: 'Hiruko',
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF3E2000),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: LayoutBuilder(
                          builder: (ctx, constraints) {
                            return Stack(
                              children: [
                                Positioned.fill(
                                  child: CustomPaint(
                                    painter: _FlechasPainter(
                                      imgKeys: _imgKeys,
                                      palKeys: _palKeys,
                                      palabrasOrden: _palabrasOrden,
                                      // ← NUEVO: painter necesita saber el orden visual
                                      imgsOrden: _imgsOrden,
                                      conectados: _conectados,
                                      seleccionada: _imgSeleccionada,
                                    ),
                                  ),
                                ),
                                Positioned.fill(
                                  child: Column(
                                  children: List.generate(_pares.length, (pos) {
                                    // Imagen
                                    final parIdx = _imgsOrden[pos];
                                    final par = _pares[parIdx];
                                    final conectado = _conectados.contains(parIdx);
                                    final seleccion = _imgSeleccionada == parIdx;
                                    final esErrorImg = _errorImg == parIdx;

                                    // Palabra (columna derecha)
                                    final parIdxPal = _palabrasOrden[pos] as int;
                                    final parPal = _pares[parIdxPal];
                                    final conectadoPal = _conectados.contains(parIdxPal);
                                    final esErrorPal = _errorPal == parIdxPal;
                                    final colorPal = _coloresPar[parIdxPal];

                                    final rowHeight = constraints.maxHeight / _pares.length;
                                    final imgSizeActual = (rowHeight * 0.82).clamp(70.0, 160.0);

                                    return Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 6),
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.center,
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            // ── Imagen (pegada a la izquierda) ──
                                            GestureDetector(
                                              key: _imgKeys[pos],
                                              onTap: () => _tocarImagen(pos),
                                              child: AnimatedContainer(
                                                duration: const Duration(milliseconds: 200),
                                                width: imgSizeActual,
                                                height: imgSizeActual,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: esErrorImg
                                                      ? Colors.red.shade100
                                                      : seleccion
                                                      ? const Color(0xFF8B2FC9).withOpacity(0.12)
                                                      : Colors.grey.shade100,
                                                  border: seleccion
                                                      ? Border.all(color: const Color(0xFF8B2FC9), width: 2.5)
                                                      : conectado
                                                      ? Border.all(color: _coloresPar[parIdx], width: 2.5)
                                                      : null,
                                                ),
                                                padding: const EdgeInsets.all(10),
                                                child: Opacity(
                                                  opacity: conectado ? 0.5 : 1.0,
                                                  child: Image.asset(
                                                    par['img'] as String,
                                                    fit: BoxFit.contain,
                                                    errorBuilder: (_, __, ___) => const SizedBox(),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            // ── Palabra (pegada a la derecha) ────
                                            GestureDetector(
                                              key: _palKeys[pos],
                                              onTap: () => _tocarPalabra(pos),
                                              child: AnimatedContainer(
                                                duration: const Duration(milliseconds: 200),
                                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                                decoration: BoxDecoration(
                                                  borderRadius: BorderRadius.circular(8),
                                                  color: esErrorPal ? Colors.red.shade50 : Colors.transparent,
                                                ),
                                                child: Text(
                                                  parPal['palabra'] as String,
                                                  style: TextStyle(
                                                    fontFamily: 'Hiruko',
                                                    fontSize: (constraints.maxWidth * 0.11).clamp(26.0, 46.0),
                                                    fontWeight: FontWeight.bold,
                                                    color: conectadoPal
                                                        ? Colors.grey.shade300
                                                        : esErrorPal
                                                        ? Colors.red
                                                        : colorPal,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
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
// PAINTER
// ══════════════════════════════════════════════════════════════════════════
class _FlechasPainter extends CustomPainter {
  final List<GlobalKey> imgKeys;
  final List<GlobalKey> palKeys;
  final List palabrasOrden;
  final List<int> imgsOrden; // ← NUEVO
  final Set<int> conectados;
  final int seleccionada;

  _FlechasPainter({
    required this.imgKeys,
    required this.palKeys,
    required this.palabrasOrden,
    required this.imgsOrden, // ← NUEVO
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
      // ── NUEVO: buscar la posición visual de esta imagen en _imgsOrden ──
      final posImg = imgsOrden.indexWhere((p) => p == parIdx);
      final posEnPal = palabrasOrden.indexWhere((p) => p == parIdx);
      if (posImg == -1 || posEnPal == -1) continue;

      final origen = _localCenter(imgKeys[posImg], paintBox); // ← usa posImg
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