import 'dart:async';
import 'package:flutter/material.dart';
import 'dart:math';
import 'package:media_kit/media_kit.dart';
import 'pasado_presente_2_screen.dart';

class PasadoPresenteScreen extends StatefulWidget {
  const PasadoPresenteScreen({super.key, this.onCompleted});
  final VoidCallback? onCompleted;

  @override
  State<PasadoPresenteScreen> createState() => _PasadoPresenteScreenState();
}

class _PasadoPresenteScreenState extends State<PasadoPresenteScreen>
    with SingleTickerProviderStateMixin {
  static const List<String> _pasado = [
    'assets/images/actividades/sociales/vela (1).png',
    'assets/images/actividades/sociales/botella-de-tinta.png',
    'assets/images/actividades/sociales/carruaje.png',
    'assets/images/actividades/sociales/telefono1.png',
  ];

  static const List<String> _presente = [
    'assets/images/actividades/sociales/bombilla.png',
    'assets/images/actividades/sociales/boligrafo.png',
    'assets/images/actividades/sociales/coche.png',
    'assets/images/actividades/sociales/telefonos-inteligentes.png',
  ];

  late final List<int> _rightOrder;
  int? _selectedLeft;
  final Set<int> _matched = {};

  late final AnimationController _shakeCtrl;
  late final Animation<Offset> _shakeAnim;

  late final Player _player;
  bool _isPlayingAudio = false;
  StreamSubscription<bool>? _playingSub;

  @override
  void initState() {
    super.initState();
    _player = Player();
    _rightOrder = List.generate(4, (i) => i)..shuffle(Random());
    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _shakeAnim = TweenSequence<Offset>([
      TweenSequenceItem(
        tween: Tween(begin: Offset.zero, end: const Offset(0.04, 0)),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: Tween(
            begin: const Offset(0.04, 0), end: const Offset(-0.04, 0)),
        weight: 2,
      ),
      TweenSequenceItem(
        tween: Tween(begin: const Offset(-0.04, 0), end: Offset.zero),
        weight: 1,
      ),
    ]).animate(_shakeCtrl);
    _initAndPlayAudio();
  }

  Future<void> _initAndPlayAudio() async {
    try {
      _playingSub = _player.stream.playing.listen((playing) {
        if (mounted) setState(() => _isPlayingAudio = playing);
      });
      await _player.open(
          Media('asset:///assets/Audio/sociales/audio_sociales7_mezcla.mp3'));
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
    _playingSub?.cancel();
    _shakeCtrl.dispose();
    _player.dispose();
    super.dispose();
  }

  void _onLeftTap(int index) {
    if (_matched.contains(index)) return;
    setState(() => _selectedLeft = _selectedLeft == index ? null : index);
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
                    backgroundColor: esCorrecto
                        ? const Color(0xFF59E347)
                        : const Color(0xFFF65757),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15)),
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

  void _onRightTap(int displayRow) {
    final pairIndex = _rightOrder[displayRow];
    if (_matched.contains(pairIndex) || _selectedLeft == null) return;

    if (_selectedLeft == pairIndex) {
      setState(() {
        _matched.add(pairIndex);
        _selectedLeft = null;
      });
      if (_matched.length == 4) {
        Future.delayed(const Duration(milliseconds: 600), () {
          if (mounted) _showSuccess();
        });
      }
    } else {
      _shakeCtrl.forward().then((_) {
        _shakeCtrl.reverse();
        if (mounted) {
          _mostrarFeedback(false, () {
            setState(() => _selectedLeft = null);
          });
        }
      });
    }
  }

  void _showSuccess() {
    _mostrarFeedback(true, () {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => TelefonoGameScreen(onCompleted: widget.onCompleted),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5A623),
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
      // ✅ Aumentado de 20 a 36 para bajar el recuadro blanco
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 36),
      color: const Color(0xFFF5A623),
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Text(
            'Pasado y Presente',
            style: TextStyle(
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
      child: Column(
        children: [
          const Text(
            'Pasado y Presente\nde  los Objetos',
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
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
                color: Colors.grey,
              ),
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
                  child: const Icon(Icons.check, size: 14, color: Colors.white),
                ),
              ),
          ],
        ),
      ),
    );
  }
}