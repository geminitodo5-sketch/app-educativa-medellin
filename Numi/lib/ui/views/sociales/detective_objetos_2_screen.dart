import 'dart:async';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'detective_objetos_3_screen.dart';
import '../../../data/services/feedback_sounds.dart';


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

  late final Player _player;
  bool _isPlayingAudio = false;
  StreamSubscription<bool>? _playingSub;

  late final Player _animPlayer;
  late final VideoController _animController;
  bool _showAnimation = false;
  bool _animHandled = false;
  StreamSubscription<bool>? _completedSub;
  StreamSubscription<Duration>? _durationSub;
  StreamSubscription<Duration>? _positionSub;
  Duration _animDuration = Duration.zero;

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
    _player = Player();
    _animPlayer = Player();
    _animController = VideoController(_animPlayer);

    _durationSub = _animPlayer.stream.duration.listen((d) {
      if (d > Duration.zero) _animDuration = d;
    });
    _completedSub = _animPlayer.stream.completed.listen((completed) {
      if (completed && _showAnimation && !_animHandled) {
        _finishAnimation();
      }
    });

    _initAnimPlayer();
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

    _initAndPlayAudio();
  }

  Future<void> _initAnimPlayer() async {
    await _animPlayer.setPlaylistMode(PlaylistMode.none);
    await _animPlayer.open(
        Media('asset:///assets/animations/balon_en_caja.mp4'), play: false);
  }

  Future<void> _initAndPlayAudio() async {
    try {
      _playingSub = _player.stream.playing.listen((playing) {
        if (mounted) setState(() => _isPlayingAudio = playing);
      });
      await _player.open(
          Media('asset:///assets/Audio/sociales/audio_sociales5_mezcla.mp3'));
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
    _completedSub?.cancel();
    _durationSub?.cancel();
    _positionSub?.cancel();
    _shakeCtrl.dispose();
    _player.dispose();
    _animPlayer.dispose();
    super.dispose();
  }

  void _onOptionTapped(int index) {
    if (_isCorrect == true) return;

    setState(() {
      _selected = index;
      _isCorrect = index == _correctIndex;
    });

    if (index == _correctIndex) {
      _playAnimation();
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

  void _finishAnimation() {
    if (!mounted || _animHandled) return;
    _animHandled = true;
    _completedSub?.cancel();
    _positionSub?.cancel();
    _completedSub = null;
    _positionSub = null;
    final dur = _animPlayer.state.duration;
    if (dur > Duration.zero) {
      _animPlayer.seek(dur - const Duration(milliseconds: 50));
    }
    _animPlayer.pause();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _showSuccess();
    });
  }

  Future<void> _playAnimation() async {
    _animHandled = false;
    await _animPlayer.seek(Duration.zero);
    setState(() => _showAnimation = true);

    // Interceptar posición: cuando queden ≤200ms del total, pausar antes del loop
    _positionSub = _animPlayer.stream.position.listen((pos) {
      if (_animDuration > Duration.zero && !_animHandled) {
        final remaining = _animDuration.inMilliseconds - pos.inMilliseconds;
        if (pos.inMilliseconds > 800 && remaining >= 0 && remaining <= 200) {
          _finishAnimation();
        }
      }
    });

    await _animPlayer.play();

    // Respaldo absoluto si el listener de posición no dispara
    final duration = _animDuration > Duration.zero
        ? _animDuration
        : const Duration(seconds: 3);
    Future.delayed(duration + const Duration(milliseconds: 300), _finishAnimation);
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
        MaterialPageRoute(builder: (_) => PuzzleScreen(onCompleted: widget.onCompleted)),
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
              value: 2 / 3,
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
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
      child: Column(
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
                  'Metí  la mano en una caja... se siente raro, ¿qué será? Es redondo, es suave, y rebota.',
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
          const SizedBox(height: 16),

          Expanded(
            child: Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: _showAnimation
                    ? ClipRRect(
                        key: const ValueKey('anim'),
                        borderRadius: BorderRadius.circular(16),
                        child: Video(
                          controller: _animController,
                          controls: NoVideoControls,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Image.asset(
                        key: const ValueKey('caja'),
                        'assets/images/actividades/sociales/caja.png',
                        fit: BoxFit.contain,
                        errorBuilder: (ctx, e, _) => const Text(
                          '📦',
                          style: TextStyle(fontSize: 120),
                        ),
                      ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          SlideTransition(
            position: _selected != null && _isCorrect == false
                ? _shakeAnim
                : const AlwaysStoppedAnimation(Offset.zero),
            child: LayoutBuilder(
              builder: (ctx, constraints) {
                final optSz = (constraints.maxWidth / 4).clamp(70.0, 120.0);
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(_options.length, (i) => _buildOption(i, optSz)),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 14),
        ],
      ),
    );
  }

  Widget _buildOption(int index, double sz) {
    final opt = _options[index];
    final isSelected = _selected == index;
    final correct = isSelected ? _isCorrect : null;

    return GestureDetector(
      onTap: () => _onOptionTapped(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: sz,
        height: sz,
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
            child: Text(opt.fallbackEmoji, style: TextStyle(fontSize: sz * 0.45)),
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
