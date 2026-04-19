import 'package:flutter/material.dart';
import 'dart:math';
import 'pasado_presente_2_screen.dart';

class PasadoPresenteScreen extends StatefulWidget {
  const PasadoPresenteScreen({super.key, this.onCompleted});
  final VoidCallback? onCompleted;

  @override
  State<PasadoPresenteScreen> createState() => _PasadoPresenteScreenState();
}

class _PasadoPresenteScreenState extends State<PasadoPresenteScreen>
    with SingleTickerProviderStateMixin {
  // Par i: _pasado[i] se empareja con _presente[i]
  static const List<String> _pasado = [
    'assets/images/actividades/sociales/vela (1).png',
    'assets/images/actividades/sociales/botella-de-tinta.png',
    'assets/images/actividades/sociales/carruaje.png',
    'assets/images/actividades/sociales/telefono.png',
  ];

  static const List<String> _presente = [
    'assets/images/actividades/sociales/bombilla.png',
    'assets/images/actividades/sociales/boligrafo.png',
    'assets/images/actividades/sociales/coche.png',
    'assets/images/actividades/sociales/telefonos-inteligentes.png',
  ];

  late final List<int> _rightOrder; // orden aleatorio de la columna derecha
  int? _selectedLeft;               // índice del item izquierdo seleccionado
  final Set<int> _matched = {};     // índices de pares ya emparejados

  late final AnimationController _shakeCtrl;
  late final Animation<Offset> _shakeAnim;

  @override
  void initState() {
    super.initState();
    _rightOrder = List.generate(4, (i) => i)..shuffle(Random());
    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _shakeAnim = TweenSequence<Offset>([
      TweenSequenceItem(
          tween: Tween(begin: Offset.zero, end: const Offset(0.04, 0)),
          weight: 1),
      TweenSequenceItem(
          tween:
              Tween(begin: const Offset(0.04, 0), end: const Offset(-0.04, 0)),
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

  void _onLeftTap(int index) {
    if (_matched.contains(index)) return;
    setState(() => _selectedLeft = _selectedLeft == index ? null : index);
  }

  void _onRightTap(int displayRow) {
    final pairIndex = _rightOrder[displayRow];
    if (_matched.contains(pairIndex) || _selectedLeft == null) return;

    if (_selectedLeft == pairIndex) {
      setState(() {
        _matched.add(pairIndex);
        _selectedLeft = null;
      });
      if (_matched.length == 4) {
        Future.delayed(const Duration(milliseconds: 600),
            () { if (mounted) _showSuccess(); });
      }
    } else {
      _shakeCtrl.forward().then((_) => _shakeCtrl.reverse());
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted) setState(() => _selectedLeft = null);
      });
    }
  }

  void _showSuccess() {
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
              const Text('¡Excelente!',
                  style: TextStyle(
                    fontFamily: 'Hiruko',
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF3D2B1F),
                  )),
              const SizedBox(height: 8),
              const Text(
                '¡Emparejaste todos\nlos objetos!',
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
                        builder: (_) => TelefonoGameScreen(onCompleted: widget.onCompleted),
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
            'Pasado y Presente',
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
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
      child: Column(
        children: [
          // Título
          const Text(
            'Pasado y Presente\nde los Objetos',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Hiruko',
              fontSize: 24,
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
                  'Une el pasado con el presente,\ny empareja los objetos.',
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
          const SizedBox(height: 22),

          // Pares
          Expanded(
            child: SlideTransition(
              position: _shakeAnim,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(4, (row) => _buildRow(row)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(int row) {
    final rightPairIndex = _rightOrder[row];

    return Row(
      children: [
        Expanded(
          child: _buildItem(
            imagePath: _pasado[row],
            isSelected: _selectedLeft == row,
            isMatched: _matched.contains(row),
            onTap: () => _onLeftTap(row),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildItem(
            imagePath: _presente[rightPairIndex],
            isSelected: false,
            isMatched: _matched.contains(rightPairIndex),
            onTap: () => _onRightTap(row),
          ),
        ),
      ],
    );
  }

  Widget _buildItem({
    required String imagePath,
    required bool isSelected,
    required bool isMatched,
    required VoidCallback onTap,
  }) {
    final Color borderColor = isMatched
        ? const Color(0xFF4CAF50)
        : isSelected
            ? const Color(0xFFF5A623)
            : const Color(0xFFDDDDDD);

    final Color bgColor = isMatched
        ? const Color(0xFFE8F5E9)
        : isSelected
            ? const Color(0xFFFFF3E0)
            : Colors.white;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 90,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 2.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.07),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        padding: const EdgeInsets.all(10),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Image.asset(
              imagePath,
              fit: BoxFit.contain,
              errorBuilder: (ctx, e, _) => const Icon(
                  Icons.image_not_supported,
                  size: 36,
                  color: Colors.grey),
            ),
            if (isMatched)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: const BoxDecoration(
                    color: Color(0xFF4CAF50),
                    shape: BoxShape.circle,
                  ),
                  child:
                      const Icon(Icons.check, size: 14, color: Colors.white),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
