import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'detective_objetos_2_screen.dart';

enum _Item { balon, libro, manzana, pizarra }

class DetectiveObjetosScreen extends StatefulWidget {
  const DetectiveObjetosScreen({super.key, this.onCompleted});
  final VoidCallback? onCompleted;

  @override
  State<DetectiveObjetosScreen> createState() => _DetectiveObjetosScreenState();
}

class _DetectiveObjetosScreenState extends State<DetectiveObjetosScreen> {
  final Map<_Zone, _Item> _placed = {};
  final Set<_Item> _used = {};

  late final Player _player;
  bool _isPlayingAudio = false;

  @override
  void initState() {
    super.initState();
    _player = Player();
    _initAndPlayAudio();
  }

  Future<void> _initAndPlayAudio() async {
    try {
      _player.stream.playing.listen((playing) {
        if (mounted) setState(() => _isPlayingAudio = playing);
      });
      await _player.open(
        Media('asset:///assets/Audio/Sociales/audio_sociales4_mezcla.mp3'),
      );
      await _player.play();
    } catch (e) {
      debugPrint('Error audio: $e');
    }
  }

  Future<void> _toggleAudio() async {
    try {
      if (_player.state.playing) {
        await _player.pause();
      } else {
        await _player.play();
      }
    } catch (e) {
      debugPrint('Error audio: $e');
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  static const Map<_Zone, _Item> _correct = {
    _Zone.estanteria: _Item.libro,
    _Zone.pizarra: _Item.pizarra,
    _Zone.manzana: _Item.manzana,
    _Zone.juguete: _Item.balon,
  };

  static const Map<_Zone, _ZoneRect> _zones = {
    _Zone.estanteria: _ZoneRect(0.14, 0.2, 0.250, 0.1, false),
    _Zone.pizarra: _ZoneRect(0.435, 0.199, 0.390, 0.215, false),
    _Zone.manzana: _ZoneRect(0.275, 0.450, 0.205, 0.125, false),
    _Zone.juguete: _ZoneRect(0.125, 0.752, 0.290, 0.15, true),
  };

  static const double _sceneAspect = 4 / 3;

  static const List<_ItemData> _items = [
    _ItemData(_Item.balon, 'assets/images/actividades/sociales/balon.png', '⚽'),
    _ItemData(
      _Item.libro,
      'assets/images/actividades/sociales/libro.png',
      '📕',
    ),
    _ItemData(
      _Item.manzana,
      'assets/images/actividades/sociales/Manzana.png',
      '🍎',
    ),
    _ItemData(
      _Item.pizarra,
      'assets/images/actividades/sociales/Pizarra.png',
      '🖼️',
    ),
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
      _mostrarFeedback(false, () {});
    }
  }

  void _mostrarFeedback(bool esCorrecto, VoidCallback onAction) {
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

  void _showSuccess() {
    _mostrarFeedback(true, () {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) =>
              DetectiveObjetos2Screen(onCompleted: widget.onCompleted),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFBF47),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
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
                child: _buildBody(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ Botón X simple blanco sin círculo ni borde
  // 👇 Mueve el recuadro blanco cambiando el valor de "vertical":
  //    Subir recuadro → número menor (ej: 10, 12)
  //    Bajar recuadro → número mayor (ej: 28, 36)
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 20,
      ), // ← ajusta "vertical"
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFEE9A10), Color(0xFFFFBF47)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Center(
            child: Text(
              'Detective de Objetos',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Hiruko',
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 0.5,
                shadows: [Shadow(color: Color(0x44000000), blurRadius: 4)],
              ),
            ),
          ),
          // ✅ X simple sin fondo circular
          Positioned(
            right: 0,
            child: GestureDetector(
              onTap: () => Navigator.of(context).maybePop(),
              child: const Icon(
                Icons.close_rounded,
                size: 22,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(
            child: Text(
              'Ordena con Pancho',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A1A),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: _toggleAudio,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: _isPlayingAudio
                        ? const Color(0xFFF5A623).withValues(alpha: 0.25)
                        : const Color(0xFFF5A623).withValues(alpha: 0.14),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _isPlayingAudio
                          ? const Color(0xFFF5A623)
                          : const Color(0xFFF5A623).withValues(alpha: 0.40),
                      width: 1.5,
                    ),
                  ),
                  child: Icon(
                    _isPlayingAudio
                        ? Icons.pause_rounded
                        : Icons.volume_up_rounded,
                    color: const Color(0xFFF5A623),
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Pancho el oso está perdido. Ayúdalo a poner cada objeto en su lugar.',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF555555),
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Expanded(
            flex: 3,
            child: AspectRatio(
              aspectRatio: _sceneAspect,
              child: LayoutBuilder(
                builder: (ctx, constraints) {
                  final w = constraints.maxWidth;
                  final h = constraints.maxHeight;
                  return Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.12),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: Image.asset(
                              'assets/images/actividades/sociales/Fondo.png',
                              fit: BoxFit.fill,
                              errorBuilder: (ctx, e, _) => Container(
                                color: const Color(0xFFF5E6C8),
                                child: const Center(
                                  child: Text(
                                    '🏫',
                                    style: TextStyle(fontSize: 80),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            right: w * 0.1,
                            bottom: h * 0.12,
                            width: w * 0.20,
                            child: Image.asset(
                              'assets/images/actividades/sociales/Oso Pancho.png',
                              fit: BoxFit.contain,
                              errorBuilder: (ctx, e, _) => const Text(
                                '🐻',
                                style: TextStyle(fontSize: 40),
                              ),
                            ),
                          ),
                          ..._zones.entries.map((entry) {
                            final zone = entry.key;
                            final r = entry.value;
                            return Positioned(
                              left: w * r.left,
                              top: h * r.top,
                              width: w * r.width,
                              height: h * r.height,
                              child: _buildDropZone(
                                zone,
                                w * r.width,
                                h * r.height,
                                r.circular,
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: _items
                  .map(
                    (item) => _used.contains(item.item)
                        ? const SizedBox(width: 56, height: 56)
                        : _buildDraggable(item),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropZone(
    _Zone zone,
    double width,
    double height,
    bool circular,
  ) {
    final placed = _placed[zone];

    return DragTarget<_Item>(
      onWillAcceptWithDetails: (_) => placed == null,
      onAcceptWithDetails: (d) => _onDrop(zone, d.data),
      builder: (ctx, candidates, _) {
        final hovering = candidates.isNotEmpty;
        final shape = circular ? BoxShape.circle : BoxShape.rectangle;
        final radius = circular ? null : BorderRadius.circular(10);

        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: width,
          height: height,
          decoration: BoxDecoration(
            shape: shape,
            borderRadius: radius,
            color: hovering
                ? Colors.white.withOpacity(0.30)
                : Colors.transparent,
            border: placed != null
                ? Border.all(color: Colors.green.shade400, width: 2.5)
                : hovering
                ? Border.all(color: const Color(0xFFF5A623), width: 2.5)
                : null,
          ),
          child: placed != null
              ? Padding(
                  padding: const EdgeInsets.all(5),
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
        errorBuilder: (ctx, e, _) => Center(
          child: Text(data.emoji, style: const TextStyle(fontSize: 36)),
        ),
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
            child: Image.asset(
              data.path,
              fit: BoxFit.contain,
              errorBuilder: (ctx, e, _) =>
                  Text(data.emoji, style: const TextStyle(fontSize: 48)),
            ),
          ),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.25, child: child),
      child: child,
    );
  }
}

// ── Tipos ──────────────────────────────────────────────────────────────────
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