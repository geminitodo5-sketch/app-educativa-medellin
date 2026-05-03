import 'dart:async';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import '../terminado.dart';

class EscuchaYEligePage extends StatefulWidget {
  const EscuchaYEligePage({super.key, this.onCompleted});
  final VoidCallback? onCompleted;

  @override
  _EscuchaYEligePageState createState() => _EscuchaYEligePageState();
}

class _EscuchaYEligePageState extends State<EscuchaYEligePage> {
  final List<Map<String, dynamic>> animals = [
    {'image': 'assets/images/actividades/sociales/gato.png',      'color': const Color(0xFFA1E296), 'isCorrect': false, 'audio': 'asset:///assets/Audio/sociales/gato.mp3'},
    {'image': 'assets/images/actividades/sociales/cocodrilo.png', 'color': const Color(0xFFFFE082), 'isCorrect': true,  'audio': 'asset:///assets/Audio/sociales/cocodrilo.mp3'},
    {'image': 'assets/images/actividades/sociales/pato.png',      'color': const Color(0xFFEF9A9A), 'isCorrect': false, 'audio': 'asset:///assets/Audio/sociales/pato.mp3'},
    {'image': 'assets/images/actividades/sociales/pollo.png',     'color': const Color(0xFFCE93D8), 'isCorrect': false, 'audio': 'asset:///assets/Audio/sociales/pollo.mp3'},
  ];

  late final Player _player;
  bool _isPlayingAudio = false;
  StreamSubscription<bool>? _playingSub;
  StreamSubscription<bool>? _completedSub;
  late final Player _animalPlayer;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _player = Player();
    _animalPlayer = Player();
    _initAndPlayAudio();
  }

  Future<void> _initAndPlayAudio() async {
    try {
      _playingSub = _player.stream.playing.listen((playing) {
        if (mounted) setState(() => _isPlayingAudio = playing);
      });
      _completedSub = _player.stream.completed.listen((completed) {
        if (completed && mounted) _playCocodrilo();
      });
      await _player.open(Media('asset:///assets/Audio/sociales/audio_sociales9l_mezcla.mp3'));
      await _player.play();
    } catch (e) {
      debugPrint('Error audio: $e');
    }
  }

  Future<void> _playCocodrilo() async {
    try {
      await _animalPlayer.open(Media('asset:///assets/Audio/sociales/cocodrilo.mp3'));
      await _animalPlayer.play();
    } catch (e) {
      debugPrint('Error cocodrilo audio: $e');
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
    _player.dispose();
    _animalPlayer.dispose();
    super.dispose();
  }

  void _onPlayButtonPressed() => _playCocodrilo();

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

  void _onAnimalSelected(int index) {
    if (_isProcessing) return;
    _isProcessing = true;

    final audio = animals[index]['audio'] as String;

    _player.pause();
    _animalPlayer.open(Media(audio)).then((_) => _animalPlayer.play());

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      _isProcessing = false;
      if (animals[index]['isCorrect']) {
        _mostrarFeedback(true, () {
          widget.onCompleted?.call();
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const ActividadTerminadaScreen()),
          );
        });
      } else {
        _mostrarFeedback(false, () {});
      }
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
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 80),
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
                              'Escucha y elige al animal correcto',
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
                      const SizedBox(height: 28),

                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 20,
                          crossAxisSpacing: 20,
                          childAspectRatio: 1.0,
                        ),
                        itemCount: animals.length,
                        itemBuilder: (context, index) {
                          return AnimalCard(
                            imagePath: animals[index]['image'],
                            backgroundColor: animals[index]['color'],
                            onTap: () => _onAnimalSelected(index),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 10.0),
        child: GestureDetector(
          onTap: _onPlayButtonPressed,
          child: Image.asset(
            'assets/images/actividades/sociales/Botón.png',
            height: (sw * 0.22).clamp(72.0, 110.0),
            width: (sw * 0.22).clamp(72.0, 110.0),
            fit: BoxFit.contain,
          ),
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
              value: 3 / 3,
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

class AnimalCard extends StatelessWidget {
  final String imagePath;
  final Color backgroundColor;
  final VoidCallback onTap;

  const AnimalCard({
    Key? key,
    required this.imagePath,
    required this.backgroundColor,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(15.0),
          child: Image.asset(imagePath, fit: BoxFit.contain),
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