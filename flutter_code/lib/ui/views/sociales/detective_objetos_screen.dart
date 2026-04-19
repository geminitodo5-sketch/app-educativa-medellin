import 'package:flutter/material.dart';
import 'detective_objetos_2_screen.dart';

enum _Item { balon, libro, manzana, pizarra }

class DetectiveObjetosScreen extends StatefulWidget {
  const DetectiveObjetosScreen({super.key, this.onCompleted});
  final VoidCallback? onCompleted;

  @override
  State<DetectiveObjetosScreen> createState() =>
      _DetectiveObjetosScreenState();
}

class _DetectiveObjetosScreenState extends State<DetectiveObjetosScreen> {
  final Map<_Zone, _Item> _placed = {};
  final Set<_Item> _used = {};

  // Zonas de drop y sus items correctos
  static const Map<_Zone, _Item> _correct = {
    _Zone.estanteria: _Item.libro,
    _Zone.pizarra: _Item.pizarra,
    _Zone.manzana: _Item.manzana,
    _Zone.juguete: _Item.balon,
  };

  // Posiciones relativas sobre la imagen (left%, top%, width%, height%)
  static const Map<_Zone, _ZoneRect> _zones = {
    _Zone.estanteria: _ZoneRect(0.03, 0.17, 0.26, 0.14, false),
    _Zone.pizarra:    _ZoneRect(0.39, 0.07, 0.37, 0.32, false),
    _Zone.manzana:    _ZoneRect(0.34, 0.50, 0.44, 0.16, false),
    _Zone.juguete:    _ZoneRect(0.04, 0.72, 0.26, 0.24, true),
  };

  static const List<_ItemData> _items = [
    _ItemData(_Item.balon,   'assets/images/actividades/sociales/balon.png',   '⚽'),
    _ItemData(_Item.libro,   'assets/images/actividades/sociales/libro.png',   '📕'),
    _ItemData(_Item.manzana, 'assets/images/actividades/sociales/Manzana.png', '🍎'),
    _ItemData(_Item.pizarra, 'assets/images/actividades/sociales/Pizarra.png', '🖼️'),
  ];

  void _onDrop(_Zone zone, _Item item) {
    if (_correct[zone] == item) {
      setState(() {
        _placed[zone] = item;
        _used.add(item);
      });
      if (_placed.length == _correct.length) {
        Future.delayed(const Duration(milliseconds: 600), () {
          if (mounted) _showSuccess();
        });
      }
    } else {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Inténtalo de nuevo!',
              style: TextStyle(fontFamily: 'Poppins')),
          duration: Duration(milliseconds: 800),
          backgroundColor: Color(0xFFE57373),
        ),
      );
    }
  }

  void _showSuccess() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.star_rounded,
                  color: Color(0xFFF5A623), size: 80),
              const SizedBox(height: 12),
              const Text('¡Muy bien!',
                  style: TextStyle(
                    fontFamily: 'Hiruko',
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF3D2B1F),
                  )),
              const SizedBox(height: 8),
              const Text(
                '¡Ayudaste a Pancho a\nordenar su salón!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 15,
                  color: Color(0xFF555555),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF5A623),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 4,
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (_) => DetectiveObjetos2Screen(onCompleted: widget.onCompleted),
                      ),
                    );
                  },
                  child: const Text('Continuar',
                      style: TextStyle(
                        fontFamily: 'Hiruko',
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      )),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F0F0),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: const BoxDecoration(color: Color(0xFFF5A623)),
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Text(
            'Detective de Objetos',
            style: TextStyle(
              fontFamily: 'Hiruko',
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: () => Navigator.of(context).maybePop(),
              child: Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                    color: Colors.white, shape: BoxShape.circle),
                child: const Icon(Icons.close,
                    size: 18, color: Color(0xFFF5A623)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título
          const Center(
            child: Text(
              'Ordena con Pancho',
              style: TextStyle(
                fontFamily: 'Hiruko',
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF3D2B1F),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Instrucción
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Icon(Icons.volume_up, color: Color(0xFF333333), size: 26),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Pancho el oso está perdido. Ayúdalo a poner cada objeto en su lugar.',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF333333),
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Escena con zonas de drop
          Expanded(
            child: LayoutBuilder(
              builder: (ctx, constraints) {
                final w = constraints.maxWidth;
                final h = constraints.maxHeight;
                return Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Stack(
                      children: [
                        // Fondo salón
                        Positioned.fill(
                          child: Image.asset(
                            'assets/images/actividades/sociales/Fondo.png',
                            fit: BoxFit.cover,
                            errorBuilder: (ctx, e, _) => Container(
                              color: const Color(0xFFF5E6C8),
                              child: const Center(
                                  child: Text('🏫',
                                      style: TextStyle(fontSize: 80))),
                            ),
                          ),
                        ),

                        // Oso Pancho
                        Positioned(
                          right: w * 0.02,
                          bottom: h * 0.05,
                          width: w * 0.28,
                          child: Image.asset(
                            'assets/images/actividades/sociales/Oso Pancho.png',
                            fit: BoxFit.contain,
                            errorBuilder: (ctx, e, _) =>
                                const Text('🐻', style: TextStyle(fontSize: 40)),
                          ),
                        ),

                        // Zonas de drop
                        ..._zones.entries.map((e) {
                          final zone = e.key;
                          final rect = e.value;
                          return Positioned(
                            left: w * rect.left,
                            top: h * rect.top,
                            width: w * rect.width,
                            height: h * rect.height,
                            child: _buildDropZone(zone, w * rect.width,
                                h * rect.height, rect.circular),
                          );
                        }),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 12),

          // Bandeja de objetos
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: _items
                  .map((item) => _used.contains(item.item)
                      ? SizedBox(width: 56, height: 56)
                      : _buildDraggable(item))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropZone(
      _Zone zone, double width, double height, bool circular) {
    final placed = _placed[zone];

    return DragTarget<_Item>(
      onWillAcceptWithDetails: (_) => placed == null,
      onAcceptWithDetails: (d) => _onDrop(zone, d.data),
      builder: (ctx, candidates, _) {
        final hovering = candidates.isNotEmpty;
        final shape = circular ? BoxShape.circle : BoxShape.rectangle;
        final radius = circular ? null : BorderRadius.circular(8);

        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: width,
          height: height,
          decoration: BoxDecoration(
            shape: shape,
            borderRadius: radius,
            color: placed != null
                ? Colors.white.withValues(alpha: 0.85)
                : hovering
                    ? Colors.white.withValues(alpha: 0.6)
                    : Colors.white.withValues(alpha: 0.35),
            border: Border.all(
              color: placed != null
                  ? Colors.green.shade400
                  : hovering
                      ? const Color(0xFFF5A623)
                      : Colors.grey.shade400,
              width: 2,
            ),
          ),
          child: placed != null
              ? Padding(
                  padding: const EdgeInsets.all(4),
                  child: Image.asset(
                    _items.firstWhere((i) => i.item == placed).path,
                    fit: BoxFit.contain,
                    errorBuilder: (ctx, e, _) => Center(
                      child: Text(
                        _items.firstWhere((i) => i.item == placed).emoji,
                        style: TextStyle(fontSize: height * 0.5),
                      ),
                    ),
                  ),
                )
              : const SizedBox(),
        );
      },
    );
  }

  Widget _buildDraggable(_ItemData data) {
    final child = SizedBox(
      width: 56,
      height: 56,
      child: Image.asset(
        data.path,
        fit: BoxFit.contain,
        errorBuilder: (ctx, e, _) =>
            Center(child: Text(data.emoji, style: const TextStyle(fontSize: 36))),
      ),
    );

    return Draggable<_Item>(
      data: data.item,
      feedback: Material(
        color: Colors.transparent,
        child: Opacity(
          opacity: 0.85,
          child: SizedBox(
            width: 72,
            height: 72,
            child: Image.asset(data.path, fit: BoxFit.contain,
                errorBuilder: (ctx, e, _) =>
                    Text(data.emoji, style: const TextStyle(fontSize: 48))),
          ),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.25, child: child),
      child: child,
    );
  }
}

enum _Zone { estanteria, pizarra, manzana, juguete }

class _ZoneRect {
  final double left, top, width, height;
  final bool circular;
  const _ZoneRect(this.left, this.top, this.width, this.height, this.circular);
}

class _ItemData {
  final _Item item;
  final String path;
  final String emoji;
  const _ItemData(this.item, this.path, this.emoji);
}
