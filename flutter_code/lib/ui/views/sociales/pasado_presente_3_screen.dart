import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import '../terminado.dart';

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: EscuchaYEligePage(),
  ));
}

class EscuchaYEligePage extends StatefulWidget {
  const EscuchaYEligePage({super.key, this.onCompleted});
  final VoidCallback? onCompleted;

  @override
  _EscuchaYEligePageState createState() => _EscuchaYEligePageState();
}

class _EscuchaYEligePageState extends State<EscuchaYEligePage> {
  final List<Map<String, dynamic>> animals = [
    {'image': 'assets/images/actividades/sociales/gato.png',      'color': const Color(0xFFA1E296), 'isCorrect': false, 'audio': 'asset:///assets/Audio/Sociales/gato.mp3'},
    {'image': 'assets/images/actividades/sociales/Cocodrilo.png', 'color': const Color(0xFFFFE082), 'isCorrect': true,  'audio': 'asset:///assets/Audio/Sociales/cocodrilo.mp3'},
    {'image': 'assets/images/actividades/sociales/pato.png',      'color': const Color(0xFFEF9A9A), 'isCorrect': false, 'audio': 'asset:///assets/Audio/Sociales/pato.mp3'},
    {'image': 'assets/images/actividades/sociales/pollo.png',     'color': const Color(0xFFCE93D8), 'isCorrect': false, 'audio': 'asset:///assets/Audio/Sociales/pollo.mp3'},
  ];

  late final Player _player;
  bool _isPlayingAudio = false;
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
      _player.stream.playing.listen((playing) {
        if (mounted) setState(() => _isPlayingAudio = playing);
      });
      _player.stream.completed.listen((completed) {
        if (completed && mounted) _playCocodrilo();
      });
      await _player.open(
          Media('asset:///assets/Audio/Sociales/audio_sociales9l_mezcla.mp3'));
      await _player.play();
    } catch (e) {
      debugPrint('Error audio: $e');
    }
  }

  Future<void> _playCocodrilo() async {
    try {
      await _animalPlayer.open(
          Media('asset:///assets/Audio/Sociales/cocodrilo.mp3'));
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
            color: esCorrecto
                ? const Color(0xFFD7FFD3)
                : const Color(0xFFFFD3D3),
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
                    color: esCorrecto
                        ? const Color(0xFF59E347)
                        : const Color(0xFFF65757),
                    size: 40,
                  ),
                  const SizedBox(width: 15),
                  Text(
                    esCorrecto ? '¡Excelente trabajo!' : '¡Casi lo tienes!',
                    style: TextStyle(
                      fontFamily: 'Hiruko',
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: esCorrecto
                          ? Colors.green[900]
                          : Colors.red[900],
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
            MaterialPageRoute(
                builder: (_) => const ActividadTerminadaScreen()),
          );
        });
      } else {
        _mostrarFeedback(false, () {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF39C12),
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
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 60),
                  child: Column(
                    children: [
                      const Text(
                        'Escucha y elige',
                        style: TextStyle(
                          fontFamily: 'Hiruko',
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF3D2B1F),
                        ),
                      ),
                      const SizedBox(height: 16),

                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GestureDetector(
                            onTap: _toggleAudio,
                            child: Icon(
                              _isPlayingAudio
                                  ? Icons.pause_rounded
                                  : Icons.volume_up_rounded,
                              color: const Color(0xFFF5A623),
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Escucha y elige al animal\ncorrecto',
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
                      const SizedBox(height: 28),

                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
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
            height: 90,
            width: 90,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }

  // ✅ Botón X simple blanco sin círculo
  // 👇 Mueve el recuadro blanco cambiando el último valor del padding:
  //    Subir recuadro → número menor (ej: 8, 10)
  //    Bajar recuadro → número mayor (ej: 24, 36)
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 80), // ← ajusta el 14
      color: const Color(0xFFF39C12),
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
          // ✅ X simple sin fondo circular
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: () => Navigator.maybePop(context),
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
          child: Image.asset(
            imagePath,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}