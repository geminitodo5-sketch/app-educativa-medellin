import 'package:flutter/material.dart';
import 'detective_objetos_3_screen.dart';

class DetectiveObjetos2Screen extends StatefulWidget {
  const DetectiveObjetos2Screen({super.key, this.onCompleted});
  final VoidCallback? onCompleted;

  @override
  State<DetectiveObjetos2Screen> createState() =>
      _DetectiveObjetos2ScreenState();
}

class _DetectiveObjetos2ScreenState extends State<DetectiveObjetos2Screen>
    with SingleTickerProviderStateMixin {
  int? _selected;
  bool? _isCorrect;
  late final AnimationController _shakeCtrl;
  late final Animation<Offset> _shakeAnim;

  // Índice 2 = balón es la respuesta correcta
  static const int _correctIndex = 2;

  static const List<_OptionData> _options = [
    _OptionData(
      imagePath: 'assets/images/actividades/sociales/Almohada.png',
      fallbackEmoji: '🛋️',
      label: 'Almohada',
    ),
    _OptionData(
      imagePath: 'assets/images/actividades/sociales/Tuerca.png',
      fallbackEmoji: '🔩',
      label: 'Tuerca',
    ),
    _OptionData(
      imagePath: 'assets/images/actividades/sociales/balon.png',
      fallbackEmoji: '⚽',
      label: 'Balón',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _shakeAnim = TweenSequence<Offset>([
      TweenSequenceItem(
          tween: Tween(begin: Offset.zero, end: const Offset(0.04, 0)),
          weight: 1),
      TweenSequenceItem(
          tween: Tween(
              begin: const Offset(0.04, 0), end: const Offset(-0.04, 0)),
          weight: 2),
      TweenSequenceItem(
          tween: Tween(begin: const Offset(-0.04, 0), end: Offset.zero),
          weight: 1),
    ]).animate(_shakeCtrl);
  }

  @override
  void dispose() {
    _shakeCtrl.dispose();
    super.dispose();
  }

  void _onOptionTapped(int index) {
    if (_isCorrect == true) return;

    setState(() {
      _selected = index;
      _isCorrect = index == _correctIndex;
    });

    if (index == _correctIndex) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) _showSuccess();
      });
    } else {
      _shakeCtrl.forward().then((_) {
        _shakeCtrl.reverse();
        Future.delayed(const Duration(milliseconds: 800), () {
          if (mounted) {
            setState(() {
              _selected = null;
              _isCorrect = null;
            });
          }
        });
      });
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
              const Text(
                '¡Correcto!',
                style: TextStyle(
                  fontFamily: 'Hiruko',
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF3D2B1F),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '¡Era el balón!\nRedondo, suave y rebota.',
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
                        builder: (_) => PuzzleScreen(onCompleted: widget.onCompleted),
                      ),
                    );
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
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
      child: Column(
        children: [
          // Título
          const Text(
            'La Caja\nSecreta',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Hiruko',
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Color(0xFF3D2B1F),
              height: 1.2,
            ),
          ),
          const SizedBox(height: 14),

          // Instrucción
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Icon(Icons.volume_up, color: Color(0xFF333333), size: 26),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Metí la mano en una caja...\nse siente raro, ¿qué será?\nEs redondo, es suave, y rebota.',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF333333),
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Caja imagen grande
          Expanded(
            child: Center(
              child: Image.asset(
                'assets/images/actividades/sociales/Caja.png',
                fit: BoxFit.contain,
                errorBuilder: (ctx, e, _) => const Text(
                  '📦',
                  style: TextStyle(fontSize: 120),
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Opciones
          SlideTransition(
            position: _selected != null && _isCorrect == false
                ? _shakeAnim
                : const AlwaysStoppedAnimation(Offset.zero),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(
                  _options.length,
                  (i) => _buildOption(i),
                ),
              ),
            ),
          ),

          const SizedBox(height: 14),

          // Indicador de páginas
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (i) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: i == 1 ? 10 : 8,
                height: i == 1 ? 10 : 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i == 1
                      ? const Color(0xFFF5A623)
                      : const Color(0xFFDDDDDD),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildOption(int index) {
    final opt = _options[index];
    final isSelected = _selected == index;
    final correct = isSelected ? _isCorrect : null;

    return GestureDetector(
      onTap: () => _onOptionTapped(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: correct == true
              ? Colors.green.shade100
              : correct == false
                  ? Colors.red.shade100
                  : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: correct == true
                ? Colors.green.shade400
                : correct == false
                    ? Colors.red.shade400
                    : const Color(0xFFDDDDDD),
            width: 2.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(10),
        child: Image.asset(
          opt.imagePath,
          fit: BoxFit.contain,
          errorBuilder: (ctx, e, _) => Center(
            child: Text(opt.fallbackEmoji,
                style: const TextStyle(fontSize: 40)),
          ),
        ),
      ),
    );
  }
}

class _OptionData {
  final String imagePath;
  final String fallbackEmoji;
  final String label;

  const _OptionData({
    required this.imagePath,
    required this.fallbackEmoji,
    required this.label,
  });
}
