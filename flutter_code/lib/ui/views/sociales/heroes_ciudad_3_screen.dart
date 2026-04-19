import 'package:flutter/material.dart';

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

  void _onDrop(int heroIndex, _Tool tool) {
    final hero = _heroes[heroIndex];
    if (tool == hero.correctTool) {
      setState(() {
        _placed[heroIndex] = tool;
        _usedTools.add(tool);
      });
      if (_placed.length == _heroes.length) {
        Future.delayed(const Duration(milliseconds: 600), () {
          if (mounted) _showSuccessDialog();
        });
      }
    } else {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Inténtalo de nuevo!',
              style: TextStyle(fontFamily: 'Poppins')),
          duration: Duration(milliseconds: 900),
          backgroundColor: Color(0xFFE57373),
        ),
      );
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.star_rounded,
                  color: Color(0xFFF5A623), size: 80),
              const SizedBox(height: 12),
              const Text(
                '¡Excelente!',
                style: TextStyle(
                  fontFamily: 'Hiruko',
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF3D2B1F),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '¡Emparejaste todas las\nherramientas correctamente!',
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
                    widget.onCompleted?.call();
                    Navigator.of(context).pop();
                    Navigator.of(context).pop();
                  },
                  child: const Text(
                    'Continuar',
                    style: TextStyle(
                      fontFamily: 'Hiruko',
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
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
      backgroundColor: Colors.white,
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
            'Héroes de la Ciudad',
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
            children: const [
              Icon(Icons.volume_up, color: Color(0xFF333333), size: 26),
              SizedBox(width: 10),
              Expanded(
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
