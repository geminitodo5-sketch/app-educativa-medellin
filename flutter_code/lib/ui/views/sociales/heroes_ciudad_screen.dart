import 'dart:async';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'heroes_ciudad_2_screen.dart';

class HeroesCiudadScreen extends StatefulWidget {
  const HeroesCiudadScreen({super.key, this.onCompleted});
  final VoidCallback? onCompleted;

  @override
  State<HeroesCiudadScreen> createState() => _HeroesCiudadScreenState();
}

class _HeroesCiudadScreenState extends State<HeroesCiudadScreen>
    with TickerProviderStateMixin {
  int? _selectedIndex;
  bool? _isCorrect;
  late final AnimationController _shakeCtrl;
  late final Animation<Offset> _shakeAnim;

  late final AudioPlayer _player;
  bool _isPlayingAudio = false;
  StreamSubscription<bool>? _playingSub;

  static const int _correctIndex = 0;

  static const List<_CharData> _chars = [
    _CharData(
      name: 'Bombero',
      imagePath: 'assets/images/actividades/sociales/Bombero.png',
      fallbackEmoji: '🧑‍🚒',
      bgColor: Color(0xFF7B4FBE),
    ),
    _CharData(
      name: 'Doctora',
      imagePath: 'assets/images/actividades/sociales/Doctora.png',
      fallbackEmoji: '👩‍⚕️',
      bgColor: Color(0xFF4CAF50),
    ),
    _CharData(
      name: 'Bailarina',
      imagePath: 'assets/images/actividades/sociales/Bailarina.png',
      fallbackEmoji: '🩰',
      bgColor: Color(0xFFE57373),
    ),
    _CharData(
      name: 'Chef',
      imagePath: 'assets/images/actividades/sociales/Chef.png',
      fallbackEmoji: '👨‍🍳',
      bgColor: Color(0xFFF9C74F),
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
        weight: 1,
      ),
      TweenSequenceItem(
        tween: Tween(begin: const Offset(0.04, 0), end: const Offset(-0.04, 0)),
        weight: 2,
      ),
      TweenSequenceItem(
        tween: Tween(begin: const Offset(-0.04, 0), end: Offset.zero),
        weight: 1,
      ),
    ]).animate(_shakeCtrl);

    _player = AudioPlayer();
    _initAndPlayAudio();
  }

  Future<void> _initAndPlayAudio() async {
    try {
      _playingSub = _player.playingStream.listen((playing) {
        if (mounted) setState(() => _isPlayingAudio = playing);
      });
      await _player.setAsset('assets/Audio/sociales/audio_sociales1_mezcla_fix.mp3');
      await _player.play();
    } catch (e) {
      debugPrint('Error cargando audio: $e');
    }
  }

  Future<void> _toggleAudio() async {
    try {
      if (_player.playing) {
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
          builder: (_) => HeroesCiudad2Screen(onCompleted: widget.onCompleted),
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
                'Héroes de la Ciudad',
                style: TextStyle(
                  fontFamily: 'Hiruko',
                  fontSize: (sw * 0.065).clamp(22.0, 42.0),
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  wordSpacing: 7,
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
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: _toggleAudio,
                child: _AudioBtn(sw: sw, isPlaying: _isPlayingAudio),
              ),
              SizedBox(width: sw * 0.03),
              Expanded(
                child: Text(
                  'Ayúdame a encontrar a  la persona que apaga incendios y usa una manguera.',
                  style: TextStyle(
                    fontFamily: 'Hiruko',
                    fontSize: (sw * 0.055).clamp(18.0, 38.0),
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: (sw * 0.05).clamp(16.0, 32.0)),

          Expanded(
            child: SlideTransition(
              position: _selectedIndex != null && _isCorrect == false
                  ? _shakeAnim
                  : const AlwaysStoppedAnimation(Offset.zero),
              child: LayoutBuilder(
                builder: (ctx, constraints) {
                  const spacing = 14.0;
                  final cardW = (constraints.maxWidth - spacing) / 2;
                  final cardH = (constraints.maxHeight - spacing) / 2;
                  final ratio = cardW / cardH.clamp(1.0, double.infinity);
                  return GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: spacing,
                    mainAxisSpacing: spacing,
                    childAspectRatio: ratio,
                    physics: const NeverScrollableScrollPhysics(),
                    children: List.generate(_chars.length, (i) => _buildCard(i)),
                  );
                },
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
            LayoutBuilder(
              builder: (ctx, constraints) {
                final pad = constraints.maxWidth * 0.08;
                return Center(
                  child: Padding(
                    padding: EdgeInsets.all(pad),
                    child: Image.asset(
                      char.imagePath,
                      fit: BoxFit.contain,
                      errorBuilder: (ctx, e, _) => Center(
                        child: Text(char.fallbackEmoji, style: const TextStyle(fontSize: 64)),
                      ),
                    ),
                  ),
                );
              },
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
                        correct ? Icons.check_circle_rounded : Icons.cancel_rounded,
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
