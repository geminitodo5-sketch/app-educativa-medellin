import 'dart:math';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

const _audio9 = 'assets/images/actividades/ciencias_naturales/audios/audio_naturales9_mezcla.mp3';

const List<Color> _coloresParejas = [
  Color(0xFFE53935),
  Color(0xFF1E88E5),
  Color(0xFF43A047),
];

class JuegoAnimalesScreen extends StatefulWidget {
  final VoidCallback onCompletado;
  const JuegoAnimalesScreen({super.key, required this.onCompletado});

  @override
  State<JuegoAnimalesScreen> createState() => _JuegoAnimalesScreenState();
}

class _JuegoAnimalesScreenState extends State<JuegoAnimalesScreen> {
  final String path = 'assets/images/actividades/ciencias_naturales';

  AudioPlayer? _player;

  final Map<String, String> parejas = {
    'mono': 'Banano',
    'perro': 'comida_para_perro',
    'elefante': 'pasto',
  };

  final Map<String, int> _indiceColor = {
    'mono': 0,
    'perro': 1,
    'elefante': 2,
  };

  String? _seleccionado;
  List<ConnectionModel> conexionesFijas = [];
  final Map<String, Color> _colorConectado = {};
  final Set<String> _yaConectados = {};

  final Map<String, GlobalKey> keys = {
    'mono': GlobalKey(),
    'perro': GlobalKey(),
    'elefante': GlobalKey(),
    'Banano': GlobalKey(),
    'comida_para_perro': GlobalKey(),
    'pasto': GlobalKey(),
  };

  late final List<String> _animalesOrden;
  late final List<String> _comidasOrden;
  final GlobalKey _stackKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    final rng = Random();
    _animalesOrden = ['mono', 'perro', 'elefante']..shuffle(rng);
    _comidasOrden = ['comida_para_perro', 'Banano', 'pasto']..shuffle(rng);
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
      await _player?.setAsset(_audio9);
      await _player?.play();
    } catch (e) {
      debugPrint('Error al reproducir audio animales3: $e');
    }
  }

  bool _esAnimal(String id) => parejas.containsKey(id);

  void _onItemTap(String id) {
    if (_yaConectados.contains(id)) return;

    if (_seleccionado == null) {
      setState(() => _seleccionado = id);
      return;
    }

    if (_seleccionado == id) {
      setState(() => _seleccionado = null);
      return;
    }

    final String first = _seleccionado!;
    final String second = id;

    String? animal;
    String? comida;
    if (_esAnimal(first) && !_esAnimal(second)) {
      animal = first;
      comida = second;
    } else if (_esAnimal(second) && !_esAnimal(first)) {
      animal = second;
      comida = first;
    } else {
      setState(() => _seleccionado = second);
      return;
    }

    setState(() => _seleccionado = null);

    if (parejas[animal] == comida) {
      final color = _coloresParejas[_indiceColor[animal]!];
      setState(() {
        _colorConectado[animal!] = color;
        _colorConectado[comida!] = color;
        _yaConectados.add(animal);
        _yaConectados.add(comida);
        conexionesFijas.add(ConnectionModel(
          startKey: keys[animal]!,
          endKey: keys[comida]!,
          color: color,
        ));
      });
      final esUltimo = conexionesFijas.length == parejas.length;
      if (esUltimo) {
        _mostrarMensaje(true, onContinue: widget.onCompletado);
      }
    } else {
      _mostrarMensaje(false);
    }
  }

  void _mostrarMensaje(bool esCorrecto, {VoidCallback? onContinue}) {
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
                        borderRadius: BorderRadius.circular(15)),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    if (onContinue != null) {
                      WidgetsBinding.instance
                          .addPostFrameCallback((_) => onContinue());
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF3DCC52),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildAppBar(),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(32),
                    topRight: Radius.circular(32),
                  ),
                ),
                child: Stack(
                  key: _stackKey,
                  children: [
                    Positioned.fill(
                      child: CustomPaint(
                        painter: ArrowPainter(
                          conexiones: conexionesFijas,
                          stackKey: _stackKey,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 35, vertical: 30),
                      child: Column(
                        children: [
                          _buildInstruction(),
                          const SizedBox(height: 30),
                          Expanded(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildColumn(_animalesOrden),
                                _buildColumn(_comidasOrden),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(25, 5, 20, 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const SizedBox(width: 40),
          const Text(
            'Animales',
            style: TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w900,
              fontFamily: 'Hiruko',
              color: Colors.white,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white, size: 38),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildInstruction() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // ✅ Botón con estilo cuadrado redondeado igual al de la imagen
        GestureDetector(
          onTap: _reproducirInstruccion,
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.volume_up_rounded,
              color: Color(0xFF3DCC52),
              size: 22,
            ),
          ),
        ),
        const SizedBox(width: 10),
        const Expanded(
          child: Text(
            'Une el animal con su comida',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              color: Color(0xFF424242),
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildColumn(List<String> items) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: items.map((id) => _buildItemCircle(id)).toList(),
    );
  }

  Widget _buildItemCircle(String id) {
    final bool seleccionado = _seleccionado == id;
    final bool conectado = _yaConectados.contains(id);
    final Color borderColor = conectado
        ? _colorConectado[id]!
        : seleccionado
            ? const Color(0xFF3DCC52)
            : const Color(0xFFCCCCCC);

    return GestureDetector(
      onTap: () => _onItemTap(id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        key: keys[id],
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          border: Border.all(color: borderColor, width: seleccionado ? 5 : 4),
          boxShadow: [
            BoxShadow(
              color: seleccionado
                  ? const Color(0xFF3DCC52).withValues(alpha: 0.35)
                  : borderColor.withValues(alpha: 0.15),
              blurRadius: seleccionado ? 12 : 8,
              spreadRadius: seleccionado ? 3 : 2,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Image.asset('$path/$id.png', fit: BoxFit.contain),
        ),
      ),
    );
  }
}

// --- Modelo ---
class ConnectionModel {
  final GlobalKey startKey;
  final GlobalKey endKey;
  final Color color;
  ConnectionModel({
    required this.startKey,
    required this.endKey,
    required this.color,
  });
}

// --- Painter ---
class ArrowPainter extends CustomPainter {
  final List<ConnectionModel> conexiones;
  final GlobalKey stackKey;

  ArrowPainter({required this.conexiones, required this.stackKey});

  static const double _arrowHeadSize = 18.0;
  static const double _arrowHeadAngle = 0.42;

  @override
  void paint(Canvas canvas, Size size) {
    final RenderBox? stackBox =
        stackKey.currentContext?.findRenderObject() as RenderBox?;
    if (stackBox == null) return;

    for (final conn in conexiones) {
      final dataA = _getCenterAndRadius(conn.startKey, stackBox);
      final dataB = _getCenterAndRadius(conn.endKey, stackBox);
      if (dataA == null || dataB == null) continue;

      final centerA = dataA.$1;
      final radiusA = dataA.$2;
      final centerB = dataB.$1;
      final radiusB = dataB.$2;

      final delta = centerB - centerA;
      final dist = delta.distance;
      if (dist == 0) continue;
      final unit = delta / dist;

      final p1 = centerA + unit * radiusA;
      final p2 = centerB - unit * radiusB;

      canvas.drawLine(
        p1,
        p2,
        Paint()
          ..color = conn.color
          ..strokeWidth = 5
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke,
      );
      _drawArrowHead(canvas, p1, p2, conn.color);
    }
  }

  void _drawArrowHead(Canvas canvas, Offset from, Offset to, Color color) {
    final angle = atan2((to - from).dy, (to - from).dx);
    final path = Path()
      ..moveTo(to.dx, to.dy)
      ..lineTo(
        to.dx - _arrowHeadSize * cos(angle - _arrowHeadAngle),
        to.dy - _arrowHeadSize * sin(angle - _arrowHeadAngle),
      )
      ..lineTo(
        to.dx - _arrowHeadSize * cos(angle + _arrowHeadAngle),
        to.dy - _arrowHeadSize * sin(angle + _arrowHeadAngle),
      )
      ..close();
    canvas.drawPath(
        path, Paint()..color = color..style = PaintingStyle.fill);
  }

  (Offset, double)? _getCenterAndRadius(GlobalKey key, RenderBox stackBox) {
    final RenderBox? box =
        key.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return null;
    final centerGlobal = box.localToGlobal(
      Offset(box.size.width / 2, box.size.height / 2),
    );
    final centerLocal = stackBox.globalToLocal(centerGlobal);
    final radius = box.size.shortestSide / 2;
    return (centerLocal, radius);
  }

  @override
  bool shouldRepaint(ArrowPainter oldDelegate) => true;
}