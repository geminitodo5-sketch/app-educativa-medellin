import 'package:flutter/material.dart';
import 'heroes_ciudad_3_screen.dart';

class HeroesCiudad2Screen extends StatefulWidget {
  const HeroesCiudad2Screen({super.key, this.onCompleted});
  final VoidCallback? onCompleted;

  @override
  State<HeroesCiudad2Screen> createState() => _HeroesCiudad2ScreenState();
}

class _HeroesCiudad2ScreenState extends State<HeroesCiudad2Screen>
    with TickerProviderStateMixin {
  int? _selectedIndex;
  bool? _isCorrect;
  late final AnimationController _shakeCtrl;
  late final Animation<Offset> _shakeAnim;

  // Policía (índice 3) es la respuesta correcta
  static const int _correctIndex = 3;

  static const List<_CharData> _chars = [
    _CharData(
      name: 'Bombero',
      imagePath: 'assets/images/actividades/sociales/Bombero.png',
      fallbackEmoji: '🧑‍🚒',
      bgColor: Color(0xFFF5A623),
    ),
    _CharData(
      name: 'Doctora',
      imagePath: 'assets/images/actividades/sociales/Doctora.png',
      fallbackEmoji: '👩‍⚕️',
      bgColor: Color(0xFF7B4FBE),
    ),
    _CharData(
      name: 'Bailarina',
      imagePath: 'assets/images/actividades/sociales/Bailarina.png',
      fallbackEmoji: '🩰',
      bgColor: Color(0xFF4CAF50),
    ),
    _CharData(
      name: 'Policía',
      imagePath: 'assets/images/actividades/sociales/Policia.png',
      fallbackEmoji: '👮',
      bgColor: Color(0xFFE57373),
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

  void _onCardTapped(int index) {
    if (_isCorrect == true) return;

    setState(() {
      _selectedIndex = index;
      _isCorrect = index == _correctIndex;
    });

    if (index == _correctIndex) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) _showSuccessDialog();
      });
    } else {
      _shakeCtrl.forward().then((_) {
        _shakeCtrl.reverse();
        if (mounted) {
          _mostrarFeedback(false, () {
            setState(() {
              _selectedIndex = null;
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
      enableDrag: false,
      backgroundColor: esCorrecto ? const Color(0xFFD7FFD3) : const Color(0xFFFFD3D3),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              esCorrecto ? Icons.check_circle_rounded : Icons.cancel_rounded,
              color: esCorrecto ? Colors.green[800] : Colors.red[800],
              size: 56,
            ),
            const SizedBox(height: 12),
            Text(
              esCorrecto ? '¡Excelente trabajo!' : '¡Casi lo tienes!',
              style: TextStyle(
                fontFamily: 'Hiruko',
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: esCorrecto ? Colors.green[900] : Colors.red[900],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: esCorrecto ? Colors.green[700] : Colors.red[700],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  onAction();
                },
                child: Text(
                  esCorrecto ? 'Continuar' : 'Reintentar',
                  style: const TextStyle(
                    fontFamily: 'Hiruko',
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showSuccessDialog() {
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
                '¡Muy bien!',
                style: TextStyle(
                  fontFamily: 'Hiruko',
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF3D2B1F),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '¡Encontraste a la Policía!\nElla cuida y protege\na todos en la ciudad.',
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
                        builder: (_) => HeroesCiudad3Screen(onCompleted: widget.onCompleted),
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
      // Fondo amarillo para que el header se integre sin costuras
      backgroundColor: const Color(0xFFF5A623),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildHeader(),
            // Bloque blanco con esquinas superiores redondeadas
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(28),
                    topRight: Radius.circular(28),
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
      // Sin bordes redondeados — color plano amarillo
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      color: const Color(0xFFF5A623),
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
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(
            child: Text(
              '¿Quién soy?\nEscucha y toca',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Hiruko',
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Color(0xFF3D2B1F),
                height: 1.3,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Enunciado con fuente Hiruko bold, igual que la imagen de referencia
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8EE),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFF5A623), width: 1.5),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Icon(Icons.volume_up_rounded,
                    color: Color(0xFFF5A623), size: 28),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Uso uniforme azul, ayudo a las personas en la calle, y cuido que todos estén seguros.',
                    style: TextStyle(
                      fontFamily: 'Hiruko',
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF3D2B1F),
                      height: 1.55,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          Expanded(
            child: SlideTransition(
              position: _selectedIndex != null && _isCorrect == false
                  ? _shakeAnim
                  : const AlwaysStoppedAnimation(Offset.zero),
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                physics: const NeverScrollableScrollPhysics(),
                children: List.generate(_chars.length, (i) => _buildCard(i)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(int index) {
    final char = _chars[index];
    final isSelected = _selectedIndex == index;
    final correct = isSelected ? _isCorrect : null;

    return GestureDetector(
      onTap: () => _onCardTapped(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: char.bgColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: correct == true
                ? Colors.green.shade400
                : correct == false
                    ? Colors.red.shade400
                    : Colors.transparent,
            width: 4,
          ),
          boxShadow: [
            BoxShadow(
              color: char.bgColor.withValues(alpha: 0.45),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Stack(
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Image.asset(
                  char.imagePath,
                  fit: BoxFit.contain,
                  errorBuilder: (ctx, e, _) => Center(
                    child: Text(char.fallbackEmoji,
                        style: const TextStyle(fontSize: 64)),
                  ),
                ),
              ),
            ),
            if (correct != null)
              Positioned.fill(
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: 1,
                  child: Container(
                    decoration: BoxDecoration(
                      color: correct
                          ? Colors.green.withValues(alpha: 0.35)
                          : Colors.red.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Center(
                      child: Icon(
                        correct
                            ? Icons.check_circle_rounded
                            : Icons.cancel_rounded,
                        color: Colors.white,
                        size: 56,
                      ),
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

class _CharData {
  final String name;
  final String imagePath;
  final String fallbackEmoji;
  final Color bgColor;

  const _CharData({
    required this.name,
    required this.imagePath,
    required this.fallbackEmoji,
    required this.bgColor,
  });
}