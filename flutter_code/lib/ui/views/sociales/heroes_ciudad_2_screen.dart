import 'dart:async';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
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

  // ── Audio ─────────────────────────────────────────────────────────────────
  late final Player _player;
  bool _isPlayingAudio = false;
  StreamSubscription<bool>? _playingSub;

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

    _player = Player();
    _initAndPlayAudio();
  }

  Future<void> _initAndPlayAudio() async {
    try {
      _playingSub = _player.stream.playing.listen((playing) {
        if (mounted) setState(() => _isPlayingAudio = playing);
      });
      await _player.open(
          Media('asset:///assets/Audio/sociales/audio_sociales2_mezcla.mp3'));
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
    _playingSub?.cancel();
    _shakeCtrl.dispose();
    _player.dispose();
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

  void _showSuccessDialog() {
    _mostrarFeedback(true, () {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => HeroesCiudad3Screen(onCompleted: widget.onCompleted),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5A623),
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
      padding: const EdgeInsets.fromLTRB(20, 50, 20, 60),
      color: const Color(0xFFF5A623),
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Text(
            'Héroes de  la Ciudad',
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

          // Enunciado sin cuadro — solo ícono de audio y texto
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: _toggleAudio,
                child: Icon(
                  _isPlayingAudio ? Icons.pause_rounded : Icons.volume_up_rounded,
                  color: const Color(0xFFF5A623),
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Uso uniforme azul, ayudo a  las personas  en  la  calle, y cuido que todos estén seguros.',
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