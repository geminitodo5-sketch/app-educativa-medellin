import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import '../../terminado.dart';
import '../../../viewmodels/matematicas_view_model.dart';
import '../../../../data/services/feedback_sounds.dart';

final respuestaSumarProvider = StateProvider<bool?>((ref) => null);

class QuienTieneMasview3 extends ConsumerStatefulWidget {
  const QuienTieneMasview3({super.key});

  @override
  ConsumerState<QuienTieneMasview3> createState() => _QuienTieneMasview3State();
}

class _QuienTieneMasview3State extends ConsumerState<QuienTieneMasview3> {
  AudioPlayer? _player;
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
  static const Color rojoNumi  = Color(0xFFF65757);

  static const Map<int, List<Alignment>> _baseLayouts = {
    1: [Alignment(0.0, 0.0)],
    2: [Alignment(-0.62, 0.0), Alignment(0.62, 0.0)],
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
    num1 = rng.nextInt(5) + 1;
    num2 = rng.nextInt(5) + 1;
    correctAnswer = num1 + num2;

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

    greenPositions  = _withJitter(_baseLayouts[num1]!, rng);
    purplePositions = _withJitter(_baseLayouts[num2]!, rng);

    _player = AudioPlayer();
    Future.microtask(_reproducirInstruccion);
  }

  @override
  void dispose() {
    _player?.dispose();
    super.dispose();
  }

  Future<void> _reproducirInstruccion() async {
    try {
      await _player?.setAsset(
          'assets/Audio/Matematicas/audio_matemaaticasnaranjas_mezcla.mp3');
      await _player?.play();
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
    final sw        = MediaQuery.of(context).size.width;
    final sh        = MediaQuery.of(context).size.height;
    final statusBar = MediaQuery.of(context).padding.top;
    final headerH  = (sh * 0.12).clamp(70.0, 110.0);

    return Scaffold(
      backgroundColor: const Color(0xFF3475F7),
      body: Column(
        children: [
          _buildHeader(context, sw, sh, statusBar, headerH),
          Expanded(child: _buildWhiteCanvas(context, sw, sh)),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, double sw, double sh,
      double statusBar, double headerH) {
    return SizedBox(
      height: statusBar + headerH,
      width: double.infinity,
      child: Stack(
        children: [
          Positioned(
            bottom: 28,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                'Sumar',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: (sw * 0.085).clamp(28.0, 42.0),
                  fontFamily: 'Hiruko',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          Positioned(
            top: statusBar + 4,
            right: 8,
            child: IconButton(
              icon: Icon(
                Icons.close,
                color: Colors.white,
                size: (sw * 0.075).clamp(24.0, 36.0),
              ),
              onPressed: () {
                ref.read(respuestaSumarProvider.notifier).state = null;
                Navigator.of(context).pop();
              },
            ),
          ),
          Positioned(
            bottom: 12,
            left: sw * 0.08,
            right: sw * 0.08,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: const LinearProgressIndicator(
                value: 1.0,
                minHeight: 8,
                backgroundColor: Colors.white30,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF59E347)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWhiteCanvas(BuildContext context, double sw, double sh) {
    final hPad = (sw * 0.06).clamp(16.0, 30.0);
    final vPad = (sh * 0.035).clamp(16.0, 40.0);
    final gap  = sw * 0.05;
    final boxW = (sw - hPad * 2 - gap) / 2;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(40),
          topRight: Radius.circular(40),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
        child: Column(
          children: [
            _buildInstruction(sw),
            const Spacer(),
            _buildOrangeBoxes(sw, gap, boxW),
            const Spacer(),
            _buildEquation(sw),
            const Spacer(),
            _buildAnswerButtons(context, sw, sh),
            SizedBox(height: sh * 0.025),
          ],
        ),
      ),
    );
  }

  Widget _buildInstruction(double sw) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: _reproducirInstruccion,
          child: Container(
            width: (sw * 0.13).clamp(44.0, 60.0),
            height: (sw * 0.13).clamp(44.0, 60.0),
            decoration: BoxDecoration(
              color: const Color(0xFFEEF2FF),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.volume_up_rounded,
              color: const Color(0xFF3475F7),
              size: (sw * 0.07).clamp(24.0, 34.0),
            ),
          ),
        ),
        SizedBox(width: sw * 0.03),
        Expanded(
          child: Text(
            'Suma  las naranjas de  las dos cajas',
            style: TextStyle(
              fontSize: (sw * 0.055).clamp(18.0, 40.0),
              fontFamily: 'Hiruko',
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOrangeBoxes(double sw, double gap, double boxW) {
    return Row(
      children: [
        Expanded(
          child: _buildOrangeBox(
            color: const Color(0xFF4CD964),
            positions: greenPositions,
            count: num1,
            isGreen: true,
            containerWidth: boxW,
          ),
        ),
        SizedBox(width: gap),
        Expanded(
          child: _buildOrangeBox(
            color: const Color(0xFFBF3FFF),
            positions: purplePositions,
            count: num2,
            isGreen: false,
            containerWidth: boxW,
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
    required double containerWidth,
  }) {
    final tapped = isGreen ? greenTapped : purpleTapped;
    final orangeSize = (count == 1
            ? containerWidth * 0.55
            : count <= 3
                ? containerWidth * 0.42
                : containerWidth * 0.34)
        .clamp(30.0, 220.0);

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
                entranceDelay: Duration(
                    milliseconds: 80 * i + (isGreen ? 0 : 120)),
                onTap: () => _tapOrange(isGreen, i),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEquation(double sw) {
    return Center(
      child: Text(
        '$num1 + $num2 = ?',
        style: TextStyle(
          fontSize: (sw * 0.11).clamp(34.0, 72.0),
          fontWeight: FontWeight.w900,
          fontFamily: 'Hiruko',
          color: Colors.black,
          letterSpacing: 2,
        ),
      ),
    );
  }

  Widget _buildAnswerButtons(BuildContext context, double sw, double sh) {
    final btnW     = (sw * 0.23).clamp(68.0, 160.0);
    final btnH     = (sh * 0.08).clamp(52.0, 100.0);
    final fontSize = (sw * 0.06).clamp(20.0, 42.0);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: options.map((option) {
        final isSelected = selectedAnswer == option;
        final isCorrect  = option == correctAnswer;

        return GestureDetector(
          onTap: () {
            setState(() => selectedAnswer = option);
            Future.delayed(const Duration(milliseconds: 400), () {
              _showFeedbackSheet(context, isCorrect);
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: btnW,
            height: btnH,
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFF3475F7)
                  : const Color(0xFFDDE8FF),
              borderRadius: BorderRadius.circular(16),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: const Color(0xFF3475F7).withValues(alpha: 0.4),
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
                  fontSize: fontSize,
                  fontFamily: 'Hiruko',
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : const Color(0xFF3475F7),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  void _showFeedbackSheet(BuildContext context, bool esCorrecto) {
    FeedbackSounds.instance.reproducir(esCorrecto);
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final sw = MediaQuery.of(context).size.width;
        return Container(
          padding: EdgeInsets.all((sw * 0.07).clamp(20.0, 35.0)),
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
                    size: (sw * 0.1).clamp(32.0, 48.0),
                  ),
                  SizedBox(width: sw * 0.04),
                  Text(
                    esCorrecto
                        ? '¡Excelente trabajo!'
                        : '¡Inténtalo de nuevo!',
                    style: TextStyle(
                      fontFamily: 'Hiruko',
                      fontSize: (sw * 0.06).clamp(20.0, 28.0),
                      fontWeight: FontWeight.bold,
                      color:
                          esCorrecto ? Colors.green[900] : Colors.red[900],
                    ),
                  ),
                ],
              ),
              SizedBox(height: sw * 0.05),
              SizedBox(
                width: double.infinity,
                height: (sw * 0.13).clamp(48.0, 60.0),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: esCorrecto ? verdeNumi : rojoNumi,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15)),
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
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.bold,
                      fontSize: (sw * 0.045).clamp(16.0, 22.0),
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

// ── Naranja interactiva con animación de entrada y rebote ──────────────────
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
    final badgeSize = (widget.size * 0.32).clamp(20.0, 30.0);
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
                ColorFiltered(
                  colorFilter: const ColorFilter.matrix([
                    1.5, 0, 0, 0, -64,
                    0, 1.5, 0, 0, -64,
                    0, 0, 1.5, 0, -64,
                    0, 0, 0, 1, 0,
                  ]),
                  child: Image.asset(
                    'assets/images/actividades/matematicas/NARANJA_8.png',
                    width: widget.size,
                    height: widget.size,
                  ),
                ),
                if (widget.isCounted)
                  Positioned(
                    right: -badgeSize * 0.2,
                    top: -badgeSize * 0.2,
                    child: Container(
                      width: badgeSize,
                      height: badgeSize,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: Colors.black26, blurRadius: 4),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          '${widget.countNumber}',
                          style: TextStyle(
                            fontSize: badgeSize * 0.5,
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
