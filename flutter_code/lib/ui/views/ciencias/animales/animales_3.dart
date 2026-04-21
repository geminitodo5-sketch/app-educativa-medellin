import 'package:flutter/material.dart';

class JuegoAnimalesScreen extends StatefulWidget {
  final VoidCallback onCompletado;
  const JuegoAnimalesScreen({super.key, required this.onCompletado});

  @override
  State<JuegoAnimalesScreen> createState() => _JuegoAnimalesScreenState();
}

class _JuegoAnimalesScreenState extends State<JuegoAnimalesScreen> {
  final String path = 'assets/images/actividades/ciencias_naturales';

  final Map<String, String> parejas = {
    'mono': 'banano',
    'perro': 'comida_para_perro',
    'elefante': 'pasto',
  };

  List<ConnectionModel> conexionesFijas = [];
  Offset? cursorMovil;
  String? animalActivo;

  final Map<String, GlobalKey> keys = {
    'mono': GlobalKey(),
    'perro': GlobalKey(),
    'elefante': GlobalKey(),
    'banano': GlobalKey(),
    'comida_para_perro': GlobalKey(),
    'pasto': GlobalKey(),
  };

  void _validarUnion(String animal, String comida) {
    if (parejas[animal] == comida) {
      setState(() {
        conexionesFijas.add(ConnectionModel(
          startKey: keys[animal]!,
          endKey: keys[comida]!,
        ));
      });
      final esUltimo = conexionesFijas.length == parejas.length;
      // ── FIX: pasamos el callback SOLO si es el último ──
      _mostrarMensaje(true, onContinue: esUltimo ? widget.onCompletado : null);
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
                    color: esCorrecto ? const Color(0xFF59E347) : const Color(0xFFF65757),
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
                    backgroundColor: esCorrecto ? const Color(0xFF59E347) : const Color(0xFFF65757),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    if (onContinue != null) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        onContinue();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF59E347),
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
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(45)),
                ),
                child: Stack(
                  children: [
                    // Capa de líneas (siempre detrás de las imágenes)
                    Positioned.fill(
                      child: CustomPaint(
                        painter: LinePainter(
                          conexiones: conexionesFijas,
                          cursor: cursorMovil,
                          activeKey: animalActivo != null
                              ? keys[animalActivo]
                              : null,
                          context: context,
                        ),
                      ),
                    ),

                    // Capa de UI
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 35, vertical: 30),
                      child: Column(
                        children: [
                          _buildInstruction(),
                          const SizedBox(height: 50),
                          Expanded(
                            child: Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                _buildColumn(
                                    ['mono', 'perro', 'elefante'], true),
                                _buildColumn(
                                    ['comida_para_perro', 'banano', 'pasto'],
                                    false),
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
    return const Row(
      children: [
        Icon(Icons.volume_up_rounded, size: 45, color: Colors.black87),
        SizedBox(width: 15),
        Expanded(
          child: Text(
            'Une al animal a su comida',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              fontFamily: 'Poppins',
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildColumn(List<String> items, bool isAnimal) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: items.map((id) {
        return Draggable<String>(
          data: id,
          feedback: _buildItemImage(id, true),
          childWhenDragging:
              Opacity(opacity: 0.3, child: _buildItemImage(id, false)),
          onDragStarted: () =>
              setState(() => animalActivo = isAnimal ? id : null),
          onDragUpdate: (details) =>
              setState(() => cursorMovil = details.globalPosition),
          onDragEnd: (_) => setState(() {
            animalActivo = null;
            cursorMovil = null;
          }),
          child: DragTarget<String>(
            onAccept: (animalId) => _validarUnion(animalId, id),
            builder: (context, _, __) => _buildItemImage(id, false),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildItemImage(String id, bool isFloating) {
    return Image.asset(
      '$path/$id.png',
      key: isFloating ? null : keys[id],
      width: isFloating ? 130 : 110,
      height: isFloating ? 130 : 110,
      fit: BoxFit.contain,
    );
  }
}

// Modelo de datos para las líneas
class ConnectionModel {
  final GlobalKey startKey;
  final GlobalKey endKey;
  ConnectionModel({required this.startKey, required this.endKey});
}

// El "Pintor" que dibuja las líneas desde el centro exacto de cada imagen
class LinePainter extends CustomPainter {
  final List<ConnectionModel> conexiones;
  final Offset? cursor;
  final GlobalKey? activeKey;
  final BuildContext context;

  LinePainter({
    required this.conexiones,
    this.cursor,
    this.activeKey,
    required this.context,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFEF9325)
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;

    final RenderBox? container =
        context.findRenderObject() as RenderBox?;
    if (container == null) return;

    // 1. Dibujar líneas ya completadas
    for (var conn in conexiones) {
      final p1 = _getCenter(conn.startKey, container);
      final p2 = _getCenter(conn.endKey, container);
      if (p1 == Offset.zero || p2 == Offset.zero) continue;
      canvas.drawLine(p1, p2, paint);
    }

    // 2. Dibujar línea elástica mientras se arrastra
    if (activeKey != null && cursor != null) {
      final p1 = _getCenter(activeKey!, container);
      if (p1 != Offset.zero) {
        final p2 = container.globalToLocal(cursor!);
        canvas.drawLine(
          p1,
          p2,
          paint..color = const Color(0xFFEF9325).withOpacity(0.6),
        );
      }
    }
  }

  Offset _getCenter(GlobalKey key, RenderBox container) {
    final RenderBox? box =
        key.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return Offset.zero;
    final Offset centerGlobal = box.localToGlobal(
      Offset(box.size.width / 2, box.size.height / 2),
    );
    return container.globalToLocal(centerGlobal);
  }

  @override
  bool shouldRepaint(LinePainter oldDelegate) => true;
}