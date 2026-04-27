import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import '../terminado.dart';

enum _Tool { casco, placa, zapatillas, cuchara }

class HeroesCiudad3Screen extends StatefulWidget {
  const HeroesCiudad3Screen({super.key, this.onCompleted});
  final VoidCallback? onCompleted;

  @override
  State<HeroesCiudad3Screen> createState() => _HeroesCiudad3ScreenState();
}

class _HeroesCiudad3ScreenState extends State<HeroesCiudad3Screen> {
  final Map<int, _Tool> _placed = {};
  final Set<_Tool> _usedTools = {};

  // ── Audio ─────────────────────────────────────────────────────────────────
  late final Player _player;
  bool _isPlayingAudio = false;

  static const List<_HeroData> _heroes = [
    _HeroData(
      name: 'Bombero',
      imagePath: 'assets/images/actividades/sociales/Bombero.png',
      fallbackEmoji: '🧑‍🚒',
      correctTool: _Tool.casco,
    ),
    _HeroData(
      name: 'Policía',
      imagePath: 'assets/images/actividades/sociales/Policia.png',
      fallbackEmoji: '👮',
      correctTool: _Tool.placa,
    ),
    _HeroData(
      name: 'Bailarina',
      imagePath: 'assets/images/actividades/sociales/Bailarina.png',
      fallbackEmoji: '🩰',
      correctTool: _Tool.zapatillas,
    ),
    _HeroData(
      name: 'Chef',
      imagePath: 'assets/images/actividades/sociales/Chef.png',
      fallbackEmoji: '👨‍🍳',
      correctTool: _Tool.cuchara,
    ),
  ];

  static const List<_ToolData> _tools = [
    _ToolData(
      tool: _Tool.zapatillas,
      imagePath: 'assets/images/actividades/sociales/Zapatillas.png',
      fallbackEmoji: '🩰',
    ),
    _ToolData(
      tool: _Tool.placa,
      imagePath: 'assets/images/actividades/sociales/placa.png',
      fallbackEmoji: '🪪',
    ),
    _ToolData(
      tool: _Tool.cuchara,
      imagePath: 'assets/images/actividades/sociales/Cuchara.png',
      fallbackEmoji: '🥄',
    ),
    _ToolData(
      tool: _Tool.casco,
      imagePath: 'assets/images/actividades/sociales/Casco.png',
      fallbackEmoji: '🪖',
    ),
  ];

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
          Media('asset:///assets/Audio/Sociales/audio_sociales3_mezcla.mp3'));
      await _player.play();
    } catch (e) {
      debugPrint('Error cargando audio: $e');
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
      debugPrint('Error al reproducir audio: $e');
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
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

  void _onDrop(int heroIndex, _Tool tool) {
    final hero = _heroes[heroIndex];
    if (tool == hero.correctTool) {
      setState(() {
        _placed[heroIndex] = tool;
        _usedTools.add(tool);
      });
      if (_placed.length == _heroes.length) {
        Future.delayed(const Duration(milliseconds: 600), () {
          if (mounted) {
            _mostrarFeedback(true, () {
              widget.onCompleted?.call();
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const ActividadTerminadaScreen()),
              );
            });
          }
        });
      }
    } else {
      _mostrarFeedback(false, () {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5A623), // fondo amarillo para que el header se extienda visualmente
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
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
      // Sin border radius: esquinas completamente rectas
      color: const Color(0xFFF5A623),
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Text(
            'Héroes de la Ciudad',
            style: TextStyle(
              // Fuente sans-serif bold como en la imagen de referencia
              fontFamily: 'Poppins',
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: 0.3,
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: () => Navigator.of(context).maybePop(),
              child: const Icon(
                Icons.close,
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
    return Container(
      width: double.infinity,
      // Esquinas superiores redondeadas, inferiores rectas (como la imagen de referencia)
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Título
            const Text(
              'Herramientas\ndel Héroe',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Hiruko',
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF3D2B1F),
                height: 1.3,
              ),
            ),
            const SizedBox(height: 12),

            // Instrucción
            Row(
              children: [
                GestureDetector(
                  onTap: _toggleAudio,
                  child: Icon(
                    _isPlayingAudio ? Icons.pause_rounded : Icons.volume_up,
                    color: const Color(0xFF333333),
                    size: 26,
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Arrastra cada objeto al personaje correcto',
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
            const SizedBox(height: 16),

            // Fila personajes + drop zones
            LayoutBuilder(
              builder: (ctx, constraints) {
                final cardSize = (constraints.maxWidth - 24) / 4;
                return Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(
                          _heroes.length, (i) => _buildHeroCard(i, cardSize)),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(
                          _heroes.length, (i) => _buildDropZone(i, cardSize)),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 16),
            const Divider(thickness: 1.5, color: Color(0xFFEEEEEE)),
            const SizedBox(height: 12),

            // Zona de herramientas 2x2
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 20,
                mainAxisSpacing: 12,
                physics: const NeverScrollableScrollPhysics(),
                children: _tools
                    .map((t) => _usedTools.contains(t.tool)
                        ? const SizedBox()
                        : _buildDraggable(t))
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroCard(int index, double size) {
    final hero = _heroes[index];
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFFF5A623),
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.all(6),
      child: Image.asset(
        hero.imagePath,
        fit: BoxFit.contain,
        errorBuilder: (ctx, e, _) => Center(
          child:
              Text(hero.fallbackEmoji, style: const TextStyle(fontSize: 28)),
        ),
      ),
    );
  }

  Widget _buildDropZone(int index, double size) {
    final placedTool = _placed[index];

    return DragTarget<_Tool>(
      onWillAcceptWithDetails: (_) => placedTool == null,
      onAcceptWithDetails: (details) => _onDrop(index, details.data),
      builder: (ctx, candidateData, _) {
        final isHovering = candidateData.isNotEmpty;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: placedTool != null
                ? Colors.green.shade50
                : isHovering
                    ? const Color(0xFFFFF8E1)
                    : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: placedTool != null
                  ? Colors.green.shade300
                  : isHovering
                      ? const Color(0xFFF5A623)
                      : const Color(0xFFCCCCCC),
              width: 2,
            ),
          ),
          child: placedTool != null
              ? Padding(
                  padding: const EdgeInsets.all(6),
                  child: Image.asset(
                    _tools
                        .firstWhere((t) => t.tool == placedTool)
                        .imagePath,
                    fit: BoxFit.contain,
                    errorBuilder: (ctx, e, _) => Center(
                      child: Text(
                        _tools
                            .firstWhere((t) => t.tool == placedTool)
                            .fallbackEmoji,
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                  ),
                )
              : const SizedBox(),
        );
      },
    );
  }

  Widget _buildDraggable(_ToolData toolData) {
    final img = Image.asset(
      toolData.imagePath,
      fit: BoxFit.contain,
      errorBuilder: (ctx, e, _) => Center(
        child: Text(toolData.fallbackEmoji,
            style: const TextStyle(fontSize: 52)),
      ),
    );

    return Draggable<_Tool>(
      data: toolData.tool,
      feedback: SizedBox(
        width: 90,
        height: 90,
        child: Material(
          color: Colors.transparent,
          child: Opacity(opacity: 0.85, child: img),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.25, child: img),
      child: img,
    );
  }
}

class _HeroData {
  final String name;
  final String imagePath;
  final String fallbackEmoji;
  final _Tool correctTool;

  const _HeroData({
    required this.name,
    required this.imagePath,
    required this.fallbackEmoji,
    required this.correctTool,
  });
}

class _ToolData {
  final _Tool tool;
  final String imagePath;
  final String fallbackEmoji;

  const _ToolData({
    required this.tool,
    required this.imagePath,
    required this.fallbackEmoji,
  });
}