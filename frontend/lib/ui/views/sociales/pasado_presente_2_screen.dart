import 'dart:async';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'pasado_presente_3_screen.dart';
import '../../../data/services/feedback_sounds.dart';

class _LetterData {
  final String letter;
  final Color color;
  const _LetterData(this.letter, this.color);
}

class TelefonoGameScreen extends StatefulWidget {
  const TelefonoGameScreen({super.key, this.onCompleted});
  final VoidCallback? onCompleted;

  @override
  State<TelefonoGameScreen> createState() => _TelefonoGameScreenState();
}

class _TelefonoGameScreenState extends State<TelefonoGameScreen> {
  late final AudioPlayer _player;
  bool _isPlayingAudio = false;
  StreamSubscription<bool>? _playingSub;

  final String targetWord = "TELÉFONO";

  // T E _ É _ O _ O
  List<String?> userSlots = ['T', 'E', null, 'É', null, 'O', null, 'O'];

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _initAndPlayAudio();
  }

  Future<void> _initAndPlayAudio() async {
    try {
      _playingSub = _player.playingStream.listen((playing) {
        if (mounted) setState(() => _isPlayingAudio = playing);
      });
      await _player.setAsset('assets/Audio/sociales/audio_sociales8_mezcla.mp3');
      await _player.play();
    } catch (e) {
      debugPrint('Error audio: $e');
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
      debugPrint('Error audio: $e');
    }
  }

  @override
  void dispose() {
    _playingSub?.cancel();
    _player.dispose();
    super.dispose();
  }

  static const List<_LetterData> keyboardLetters = [
    _LetterData('A', Color(0xFF7B5EA7)),
    _LetterData('U', Color(0xFFD94040)),
    _LetterData('M', Color(0xFF3A7BD5)),
    _LetterData('E', Color(0xFFE8A820)),
    _LetterData('C', Color(0xFFE8857A)),
    _LetterData('L', Color(0xFF6AAEE8)),
    _LetterData('N', Color(0xFF2BBFA0)),
    _LetterData('T', Color(0xFF7B5EA7)),
    _LetterData('F', Color(0xFFE8C030)),
  ];

  void _handleLetterTap(String letter) {
    setState(() {
      int emptyIndex = userSlots.indexOf(null);
      if (emptyIndex != -1) {
        userSlots[emptyIndex] = letter;
      }
    });

    if (!userSlots.contains(null) && userSlots.join('') == targetWord) {
      _showSuccessDialog();
    }
  }

  void _removeLetter(int index) {
    if (index == 2 || index == 4 || index == 6) {
      setState(() {
        userSlots[index] = null;
      });
    }
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

  void _showSuccessDialog() {
    _mostrarFeedback(true, () {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => EscuchaYEligePage(onCompleted: widget.onCompleted),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: const Color(0xFFF39C12),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildHeader(sw),
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
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                  child: Column(
                    children: [
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GestureDetector(
                            onTap: _toggleAudio,
                            child: _AudioBtn(sw: sw, isPlaying: _isPlayingAudio),
                          ),
                          SizedBox(width: sw * 0.03),
                          Expanded(
                            child: Text(
                              'Toca  las  letras que faltan para completar  la palabra',
                              style: TextStyle(
                                fontFamily: 'Hiruko',
                                fontSize: (sw * 0.055).clamp(18.0, 38.0),
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF3D2B1F),
                                height: 1.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Image.asset(
                        'assets/images/actividades/sociales/telefono1.png',
                        height: (sw * 0.40).clamp(120.0, 220.0),
                        errorBuilder: (c, e, s) => Icon(Icons.image, size: sw * 0.25),
                      ),
                      const SizedBox(height: 16),
                      LayoutBuilder(
                        builder: (ctx, constraints) {
                          final slotW = ((constraints.maxWidth - 48) / 8).clamp(24.0, 44.0);
                          final slotH = slotW * 1.3;
                          final fontSize = (slotW * 0.7).clamp(18.0, 32.0);
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(userSlots.length, (index) {
                              return GestureDetector(
                                onTap: () => _removeLetter(index),
                                child: Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 3),
                                  decoration: const BoxDecoration(
                                    border: Border(
                                      bottom: BorderSide(width: 2, color: Colors.black),
                                    ),
                                  ),
                                  width: slotW,
                                  height: slotH,
                                  child: Center(
                                    child: Text(
                                      userSlots[index] ?? "",
                                      style: TextStyle(
                                        fontSize: fontSize,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: LayoutBuilder(
                          builder: (ctx, constraints) {
                            final btnW = (constraints.maxWidth - 30) / 3;
                            final btnH = (constraints.maxHeight - 30) / 3;
                            final fontSize = (btnH * 0.38).clamp(14.0, 48.0);
                            return GridView.builder(
                              shrinkWrap: false,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                mainAxisSpacing: 15,
                                crossAxisSpacing: 15,
                                childAspectRatio: btnW / btnH,
                              ),
                              itemCount: keyboardLetters.length,
                              itemBuilder: (context, index) {
                                return LetterButton(
                                  letter: keyboardLetters[index].letter,
                                  color: keyboardLetters[index].color,
                                  fontSize: fontSize,
                                  onTap: () => _handleLetterTap(keyboardLetters[index].letter),
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(double sw) {
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
                'Pasado y Presente',
                style: TextStyle(
                  fontFamily: 'Hiruko',
                  fontSize: (sw * 0.065).clamp(22.0, 42.0),
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 28),
                onPressed: () => Navigator.maybePop(context),
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
}

class LetterButton extends StatelessWidget {
  final String letter;
  final Color color;
  final double fontSize;
  final VoidCallback onTap;

  const LetterButton({
    required this.letter,
    required this.color,
    required this.fontSize,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final hsl = HSLColor.fromColor(color);
    final shadowColor = hsl.withLightness((hsl.lightness - 0.15).clamp(0.0, 1.0)).toColor();
    final textColor = hsl.withLightness((hsl.lightness - 0.25).clamp(0.0, 1.0)).toColor();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          border: Border(
            bottom: BorderSide(color: shadowColor, width: 4),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Text(
            letter,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              fontFamily: 'Hiruko',
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }
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