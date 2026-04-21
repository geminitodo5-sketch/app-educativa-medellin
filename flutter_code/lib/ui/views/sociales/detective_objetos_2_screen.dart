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

  // ── Lógica intacta ────────────────────────────────────────────────────────

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
        if (mounted) {
          _mostrarFeedback(false, () {
            setState(() {
              _selected = null;
              _isCorrect = null;
            });
          });
        }
      });
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
        MaterialPageRoute(builder: (_) => const PuzzleScreen()),
      );
    });
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Fondo naranja para que las esquinas redondeadas del blanco se vean sobre él
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
                  // Solo esquinas superiores redondeadas
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      // Sin esquinas redondeadas — el bloque naranja va de borde a borde
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
          Positioned(
            right: 0,
            child: GestureDetector(
              onTap: () => Navigator.of(context).maybePop(),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.28),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.5),
                    width: 1.5,
                  ),
                ),
                child: const Icon(
                  Icons.close_rounded,
                  size: 20,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
      child: Column(
        children: [
          // Título con Poppins
          const Text(
            'La Caja Secreta',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 12),

          // Instrucción — ícono de audio estilo pantalla 3
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFF5A623).withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFF5A623).withValues(alpha: 0.40),
                    width: 1.5,
                  ),
                ),
                child: const Icon(
                  Icons.volume_up_rounded,
                  color: Color(0xFFF5A623),
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Metí la mano en una caja...\nse siente raro, ¿qué será?\nEs redondo, es suave, y rebota.',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF555555),
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

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

  // ── Widgets de lógica — sin cambios ───────────────────────────────────────

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