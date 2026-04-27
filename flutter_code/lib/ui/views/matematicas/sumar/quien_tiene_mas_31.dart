import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import '../../terminado.dart';
import '../../../viewmodels/matematicas_view_model.dart';

final respuestaSumarProvider = StateProvider<bool?>((ref) => null);

class QuienTieneMasview3 extends ConsumerStatefulWidget {
  const QuienTieneMasview3({super.key});

  @override
  ConsumerState<QuienTieneMasview3> createState() => _QuienTieneMasview3State();
}

class _QuienTieneMasview3State extends ConsumerState<QuienTieneMasview3> {
  Player? _player;
  int? selectedAnswer;

  late final int num1;
  late final int num2;
  late final int correctAnswer;
  late final List<int> options;
  late final List<Alignment> greenPositions;
  late final List<Alignment> purplePositions;

  final List<int> greenTapped = [];
  final List<int> purpleTapped = [];

  static const Color verdeNumi = Color(0xFF59E347);
  static const Color rojoNumi = Color(0xFFF65757);

  // Posiciones base bien separadas para 1-5 naranjas
  static const Map<int, List<Alignment>> _baseLayouts = {
    1: [
      Alignment(0.0, 0.0),
    ],
    2: [
      Alignment(-0.62, 0.0),
      Alignment(0.62, 0.0),
    ],
    3: [
      Alignment(-0.60, -0.58),
      Alignment(0.60, -0.58),
      Alignment(0.00, 0.62),
    ],
    4: [
      Alignment(-0.62, -0.62),
      Alignment(0.62, -0.62),
      Alignment(-0.62, 0.62),
      Alignment(0.62, 0.62),
    ],
    5: [
      Alignment(-0.65, -0.65),
      Alignment(0.65, -0.65),
      Alignment(0.00, -0.05),
      Alignment(-0.65, 0.65),
      Alignment(0.65, 0.65),
    ],
  };

  List<Alignment> _withJitter(List<Alignment> base, Random rng) {
    return base
        .map((a) => Alignment(
              (a.x + (rng.nextDouble() - 0.5) * 0.10).clamp(-0.78, 0.78),
              (a.y + (rng.nextDouble() - 0.5) * 0.10).clamp(-0.78, 0.78),
            ))
        .toList();
  }

  @override
  void initState() {
    super.initState();
    final rng = Random();
    num1 = rng.nextInt(5) + 1; // 1–5
    num2 = rng.nextInt(5) + 1; // 1–5
    correctAnswer = num1 + num2;

    // Genera 2 distractores con distancias aleatorias para más variedad
    final possibleDeltas = [1, -1, 2, -2, 3, -3]..shuffle(rng);
    final distractors = <int>[];
    for (final d in possibleDeltas) {
      final c = correctAnswer + d;
      if (c > 0 && c != correctAnswer && !distractors.contains(c)) {
        distractors.add(c);
        if (distractors.length == 2) break;
      }
    }
    options = [correctAnswer, ...distractors]..shuffle(rng);

    greenPositions = _withJitter(_baseLayouts[num1]!, rng);
    purplePositions = _withJitter(_baseLayouts[num2]!, rng);

    _player = Player();
    Future.microtask(_reproducirInstruccion);
  }

  @override
  void dispose() {
    _player?.dispose();
    super.dispose();
  }

  Future<void> _reproducirInstruccion() async {
    try {
      await _player?.open(
        Media('asset:///assets/Audio/Matematicas/audio_matemaaticasnaranjas_mezcla.mp3'),
      );
    } catch (e) {
      debugPrint('Error al reproducir audio: $e');
    }
  }

  void _tapOrange(bool isGreen, int index) {
    setState(() {
      final list = isGreen ? greenTapped : purpleTapped;
      if (list.contains(index)) {
        list.remove(index);
      } else {
        list.add(index);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF3475F7),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildTopBar(context),
            const SizedBox(height: 10),
            Expanded(child: _buildWhiteCanvas(context)),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Column(
      children: [
        Align(
          alignment: Alignment.topRight,
          child: IconButton(
            icon: const Icon(Icons.close, color: Colors.white, size: 30),
            onPressed: () {
              ref.read(respuestaSumarProvider.notifier).state = null;
              Navigator.of(context).pop();
            },
          ),
        ),
        const Text(
          'Sumar',
          style: TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontFamily: 'Hiruko',
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildWhiteCanvas(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(40),
          topRight: Radius.circular(40),
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInstruction(),
            const SizedBox(height: 24),
            _buildOrangeBoxes(),
            const SizedBox(height: 20),
            _buildEquation(),
            const SizedBox(height: 60),
            _buildAnswerButtons(context),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildInstruction() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.volume_up_rounded, size: 45),
          color: const Color(0xFF3475F7),
          onPressed: _reproducirInstruccion,
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Text(
            'Suma las naranjas de las dos cajas',
            style: TextStyle(
              fontSize: 15,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w700,
              color: Colors.black87,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOrangeBoxes() {
    return Row(
      children: [
        Expanded(
          child: _buildOrangeBox(
            color: const Color(0xFF4CD964),
            positions: greenPositions,
            count: num1,
            isGreen: true,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildOrangeBox(
            color: const Color(0xFFBF3FFF),
            positions: purplePositions,
            count: num2,
            isGreen: false,
          ),
        ),
      ],
    );
  }

  Widget _buildOrangeBox({
    required Color color,
    required List<Alignment> positions,
    required int count,
    required bool isGreen,
  }) {
    final tapped = isGreen ? greenTapped : purpleTapped;
    final orangeSize = count == 1 ? 90.0 : count <= 3 ? 68.0 : 56.0;

    return AspectRatio(
      aspectRatio: 1.0,
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            for (int i = 0; i < count; i++)
              _OrangeItem(
                key: ValueKey('${isGreen ? 'g' : 'p'}_$i'),
                alignment: positions[i],
                isCounted: tapped.contains(i),
                countNumber: tapped.contains(i) ? tapped.indexOf(i) + 1 : 0,
                size: orangeSize,
                entranceDelay:
                    Duration(milliseconds: 80 * i + (isGreen ? 0 : 120)),
                onTap: () => _tapOrange(isGreen, i),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEquation() {
    return Center(
      child: Text(
        '$num1 + $num2 = ?',
        style: const TextStyle(
          fontSize: 42,
          fontWeight: FontWeight.w900,
          fontFamily: 'Hiruko',
          color: Colors.black,
          letterSpacing: 2,
        ),
      ),
    );
  }

  Widget _buildAnswerButtons(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: options.map((option) {
        final isSelected = selectedAnswer == option;
        final isCorrect = option == correctAnswer;

        return GestureDetector(
          onTap: () {
            setState(() => selectedAnswer = option);
            Future.delayed(const Duration(milliseconds: 400), () {
              _showFeedbackSheet(context, isCorrect);
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 90,
            height: 60,
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFF3475F7)
                  : const Color(0xFFDDE8FF),
              borderRadius: BorderRadius.circular(16),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: const Color(0xFF3475F7).withOpacity(0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : [],
            ),
            child: Center(
              child: Text(
                '$option',
                style: TextStyle(
                  fontSize: 24,
                  fontFamily: 'Hiruko',
                  fontWeight: FontWeight.bold,
                  color:
                      isSelected ? Colors.white : const Color(0xFF3475F7),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  void _showFeedbackSheet(BuildContext context, bool esCorrecto) {
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
                    color: esCorrecto ? verdeNumi : rojoNumi,
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
                    backgroundColor: esCorrecto ? verdeNumi : rojoNumi,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    if (esCorrecto) {
                      ref
                          .read(matematicasViewModelProvider)
                          .commandSeleccionarLeccion('Sumar');
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (_) => const ActividadTerminadaScreen(),
                        ),
                      );
                    } else {
                      setState(() => selectedAnswer = null);
                    }
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
}

// Widget individual de naranja con animación de entrada y rebote al tocar
class _OrangeItem extends StatefulWidget {
  final Alignment alignment;
  final bool isCounted;
  final int countNumber;
  final double size;
  final Duration entranceDelay;
  final VoidCallback onTap;

  const _OrangeItem({
    super.key,
    required this.alignment,
    required this.isCounted,
    required this.countNumber,
    required this.size,
    required this.entranceDelay,
    required this.onTap,
  });

  @override
  State<_OrangeItem> createState() => _OrangeItemState();
}

class _OrangeItemState extends State<_OrangeItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _entranceCtrl;
  late Animation<double> _entranceScale;
  double _tapScale = 1.0;

  @override
  void initState() {
    super.initState();
    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _entranceScale =
        CurvedAnimation(parent: _entranceCtrl, curve: Curves.elasticOut);
    Future.delayed(widget.entranceDelay, () {
      if (mounted) _entranceCtrl.forward();
    });
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    super.dispose();
  }

  void _bounce() {
    setState(() => _tapScale = 1.28);
    Future.delayed(const Duration(milliseconds: 130), () {
      if (mounted) setState(() => _tapScale = 1.0);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: widget.alignment,
      child: GestureDetector(
        onTap: () {
          widget.onTap();
          _bounce();
        },
        child: ScaleTransition(
          scale: _entranceScale,
          child: AnimatedScale(
            scale: _tapScale,
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Image.asset(
                  'assets/images/actividades/matematicas/NARANJA_8.png',
                  width: widget.size,
                  height: widget.size,
                ),
                if (widget.isCounted)
                  Positioned(
                    right: -5,
                    top: -5,
                    child: Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          '${widget.countNumber}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepOrange,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
