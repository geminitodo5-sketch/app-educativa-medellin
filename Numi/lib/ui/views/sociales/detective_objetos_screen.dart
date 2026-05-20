import 'dart:async';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'detective_objetos_2_screen.dart';
import '../../../data/services/feedback_sounds.dart';

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

  late final AudioPlayer _player;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _reproducirInstruccion();
    });
  }

  Future<void> _reproducirInstruccion() async {
    try {
      await _player.setAsset('assets/Audio/sociales/audio_sociales4_mezcla_fix.mp3');
      await _player.play();
    } catch (e) {
      debugPrint('Error reproduciendo audio: $e');
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
    _ItemData(_Item.libro, 'assets/images/actividades/sociales/libro.png', '📕'),
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
      _mostrarFeedback(false, () {});
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
                    backgroundColor: esCorrecto ? const Color(0xFF59E347) : const Color(0xFFF65757),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
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
          builder: (_) => DetectiveObjetos2Screen(onCompleted: widget.onCompleted),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFBF47),
      body: SafeArea(
        bottom: false,
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

  Widget _buildHeader() {
    final sw = MediaQuery.of(context).size.width;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 4, 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(width: 48),
              Text(
                'Detective de Objetos',
                style: TextStyle(
                  fontFamily: 'Hiruko',
                  fontSize: (sw * 0.065).clamp(22.0, 42.0),
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 28),
                onPressed: () => Navigator.of(context).maybePop(),
              ),
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(sw * 0.08, 0, sw * 0.08, 12),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: 1 / 3,
              minHeight: 8,
              backgroundColor: Colors.white30,
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF59E347)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBody() {
    final sw = MediaQuery.of(context).size.width;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: _reproducirInstruccion,
                child: _AudioBtn(sw: sw),
              ),
              SizedBox(width: sw * 0.03),
              Expanded(
                child: Text(
                  'Pancho el oso está perdido. Ayúdalo a poner cada objeto en su lugar.',
                  style: TextStyle(
                    fontFamily: 'Hiruko',
                    fontSize: (sw * 0.055).clamp(18.0, 38.0),
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF424242),
                    height: 1.3,
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
                                  child: Text('🏫', style: TextStyle(fontSize: 80)),
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
                              errorBuilder: (ctx, e, _) => const Text('🐻', style: TextStyle(fontSize: 40)),
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
                              child: _buildDropZone(zone, w * r.width, h * r.height, r.circular),
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

          LayoutBuilder(
            builder: (ctx, constraints) {
              final itemSz = (constraints.maxWidth / 5).clamp(52.0, 90.0);
              return Container(
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
                  children: _items.map((item) =>
                    _used.contains(item.item)
                      ? SizedBox(width: itemSz, height: itemSz)
                      : _buildDraggable(item, itemSz),
                  ).toList(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDropZone(_Zone zone, double width, double height, bool circular) {
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
            color: hovering ? Colors.white.withOpacity(0.30) : Colors.transparent,
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

  Widget _buildDraggable(_ItemData data, double sz) {
    final child = SizedBox(
      width: sz,
      height: sz,
      child: Image.asset(
        data.path,
        fit: BoxFit.contain,
        errorBuilder: (ctx, e, _) => Center(
          child: Text(data.emoji, style: TextStyle(fontSize: sz * 0.6)),
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
            width: sz * 1.3,
            height: sz * 1.3,
            child: Image.asset(
              data.path,
              fit: BoxFit.contain,
              errorBuilder: (ctx, e, _) => Text(data.emoji, style: TextStyle(fontSize: sz * 0.8)),
            ),
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

class _AudioBtn extends StatelessWidget {
  final double sw;
  final bool isPlaying;
  const _AudioBtn({required this.sw, this.isPlaying = false});

  @override
  Widget build(BuildContext context) {
    final sz = (sw * 0.12).clamp(42.0, 64.0);
    return Container(
      width: sz,
      height: sz,
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E0),
        borderRadius: BorderRadius.circular(sz * 0.27),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF5A623).withValues(alpha: 0.15),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Icon(
        isPlaying ? Icons.pause_rounded : Icons.volume_up_rounded,
        color: const Color(0xFFF5A623),
        size: sz * 0.55,
      ),
    );
  }
}
