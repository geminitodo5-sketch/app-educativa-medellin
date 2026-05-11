import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import '../../terminado.dart';
import '../../../viewmodels/comparacion_cantidades_view_model.dart';
import '../../../../data/services/feedback_sounds.dart';

final respuestaProvider = StateProvider<bool?>((ref) => null);

class _Animal {
  final String name;
  final String path;
  const _Animal(this.name, this.path);
}

class _RoundData {
  final List<_Animal> animals;
  final List<int> counts;
  final int correctIndex;

  const _RoundData({
    required this.animals,
    required this.counts,
    required this.correctIndex,
  });

  static _RoundData generate() {
    final rng = Random();
    const allAnimals = [
      _Animal('Cocodrilo', 'assets/images/actividades/matematicas/cocodrilo.png'),
      _Animal('Elefante',  'assets/images/actividades/matematicas/elefante.png'),
      _Animal('Pato',      'assets/images/actividades/matematicas/pato.png'),
      _Animal('Pingüino',  'assets/images/actividades/matematicas/pinguino.png'),
    ];

    final shuffled = List<_Animal>.from(allAnimals)..shuffle(rng);

    final winnerCount = 4 + rng.nextInt(2);
    final otherCounts = <int>[];
    while (otherCounts.length < 3) {
      final c = 1 + rng.nextInt(3);
      if (!otherCounts.contains(c)) otherCounts.add(c);
    }
    otherCounts.shuffle(rng);

    final winnerPos = rng.nextInt(4);
    final counts = List<int>.filled(4, 0);
    int otherIdx = 0;
    for (int i = 0; i < 4; i++) {
      counts[i] = (i == winnerPos) ? winnerCount : otherCounts[otherIdx++];
    }

    return _RoundData(animals: shuffled, counts: counts, correctIndex: winnerPos);
  }
}

class QuienTieneMasview3 extends ConsumerStatefulWidget {
  const QuienTieneMasview3({super.key});

  @override
  ConsumerState<QuienTieneMasview3> createState() => _QuienTieneMasview3State();
}

class _QuienTieneMasview3State extends ConsumerState<QuienTieneMasview3> {
  AudioPlayer? _player;
  late _RoundData _round;

  static const Color verdeNumi = Color(0xFF59E347);
  static const Color rojoNumi  = Color(0xFFF65757);

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _round  = _RoundData.generate();
    Future.microtask(() => _reproducirInstruccion());
  }

  @override
  void dispose() {
    _player?.dispose();
    super.dispose();
  }

  void _nuevaRonda() {
    setState(() {
      _round = _RoundData.generate();
      ref.read(respuestaProvider.notifier).state = null;
    });
  }

  Future<void> _reproducirInstruccion() async {
    try {
      await _player?.setAsset('assets/Audio/Matematicas/audio mate6_mezcla.mp3');
      await _player?.play();
    } catch (e) {
      debugPrint('Error al reproducir audio: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final mq        = MediaQuery.of(context);
    final sw        = mq.size.width;
    final sh        = mq.size.height;
    final isTablet  = sw >= 600;
    final statusBar = mq.padding.top;
    final headerH   = (sh * 0.09).clamp(60.0, 100.0);
    final titleSize = (sw * (isTablet ? 0.048 : 0.057)).clamp(18.0, 36.0);
    final iconSize  = (sw * 0.07).clamp(22.0, 36.0);

    return Scaffold(
      backgroundColor: const Color(0xFF3475F7),
      body: Column(
        children: [
          // ── Header azul ───────────────────────────────────────────────────
          SizedBox(
            height: statusBar + headerH,
            child: Stack(
              children: [
                Positioned(
                  top: statusBar, left: 0, right: 0, bottom: 28,
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: iconSize + 16),
                      child: Text(
                        'Quién tiene más',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: titleSize,
                          fontFamily: 'Hiruko',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: statusBar + 4, right: 4,
                  child: IconButton(
                    icon: Icon(Icons.close_rounded, color: Colors.white, size: iconSize),
                    onPressed: () {
                      ref.read(respuestaProvider.notifier).state = null;
                      Navigator.of(context).pop();
                    },
                  ),
                ),
                // ── Barra de progreso (3 de 3) ──────────────────────────────
                Positioned(
                  bottom: 10,
                  left: isTablet ? 60 : 40,
                  right: isTablet ? 60 : 40,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: 1.0,
                      backgroundColor: Colors.white.withOpacity(0.15),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFF59E347)),
                      minHeight: isTablet ? 12 : 10,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Panel blanco ──────────────────────────────────────────────────
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(40),
                  topRight: Radius.circular(40),
                ),
              ),
              // LayoutBuilder solo para medir ancho — NO calculamos altura aquí
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final availW  = constraints.maxWidth;
                  final isTab   = availW >= 600;
                  final hPad    = (availW * (isTab ? 0.05 : 0.045)).clamp(14.0, 40.0);
                  final instrSz    = (availW * (isTab ? 0.032 : 0.040)).clamp(13.0, 28.0);
                  final enunciadoSz = (availW * 0.055).clamp(18.0, 40.0);
                  final volSz      = (availW * 0.13).clamp(44.0, 60.0);

                  final sh = MediaQuery.of(context).size.height;
                  final topPad = (sh * 0.075).clamp(40.0, 70.0);
                  return Padding(
                    padding: EdgeInsets.fromLTRB(hPad, topPad, hPad, hPad * 0.4),
                    child: Column(
                      children: [

                        // ── GRILLA ───────────────────────────────────────
                        Expanded(
                          flex: 58,
                          child: LayoutBuilder(
                            builder: (ctx, gc) {
                              final gridH = gc.maxHeight;
                              final gridW = gc.maxWidth;
                              final cols  = 4;
                              final totalAnimals = _round.counts.fold(0, (a, b) => a + b);
                              final maxRows = (totalAnimals / cols).ceil().clamp(1, 5);
                              final cellW    = gridW / cols;
                              final imgByCol = cellW * 0.82;
                              // Divide by 1.2 to account for cellH = imgSz * 1.18
                              final imgByRow = gridH / (maxRows * 1.2);
                              final imgSz = (imgByCol < imgByRow ? imgByCol : imgByRow)
                                  .clamp(24.0, 200.0);
                              return _buildCountingGrid(gridW, imgSz);
                            },
                          ),
                        ),

                        SizedBox(height: hPad * 0.4),

                        // ── INSTRUCCIÓN ──────────────────────────────────
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            GestureDetector(
                              onTap: _reproducirInstruccion,
                              child: Container(
                                width: volSz,
                                height: volSz,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEEF2FF),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Icon(
                                  Icons.volume_up_rounded,
                                  color: const Color(0xFF3475F7),
                                  size: volSz * 0.54,
                                ),
                              ),
                            ),
                            SizedBox(width: hPad * 0.4),
                            Expanded(
                              child: Text(
                                '¿Cuál de estos animales hay en mayor cantidad?',
                                style: TextStyle(
                                  fontSize: enunciadoSz,
                                  fontFamily: 'Hiruko',
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: hPad * 0.4),

                        // ── BOTONES ──────────────────────────────────────
                        Expanded(
                          flex: 42,
                          child: Column(
                            children: List.generate(4, (i) {
                              final animal    = _round.animals[i];
                              final isCorrect = i == _round.correctIndex;
                              return Expanded(
                                child: Padding(
                                  padding: EdgeInsets.only(
                                    bottom: i < 3 ? hPad * 0.2 : 0,
                                  ),
                                  // LayoutBuilder para que la imagen del botón
                                  // se adapte al alto real de cada botón
                                  child: LayoutBuilder(
                                    builder: (ctx, btnConstraints) {
                                      final btnImgSz = (btnConstraints.maxHeight * 0.72)
                                          .clamp(24.0, 90.0);
                                      return _OptionButton(
                                        image: animal.path,
                                        letter: '${String.fromCharCode(65 + i)})',
                                        name: animal.name,
                                        imgSize: btnImgSz,
                                        fontSize: instrSz,
                                        hPad: hPad * 0.75,
                                        onTap: () => _showFeedbackSheet(isCorrect),
                                      );
                                    },
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),

                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showFeedbackSheet(bool esCorrecto) {
    FeedbackSounds.instance.reproducir(esCorrecto);
    final sw       = MediaQuery.of(context).size.width;
    final isTablet = sw >= 600;
    final hPad     = (sw * (isTablet ? 0.08 : 0.06)).clamp(20.0, 60.0);

    showModalBottomSheet(
      context: context,
      isDismissible: false,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 26),
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
                  color: esCorrecto ? verdeNumi : rojoNumi,
                  size: isTablet ? 52 : 40,
                ),
                SizedBox(width: isTablet ? 20 : 15),
                Flexible(
                  child: Text(
                    esCorrecto ? '¡Excelente trabajo!' : '¡Inténtalo de nuevo!',
                    style: TextStyle(
                      fontFamily: 'Hiruko',
                      fontSize: (sw * (isTablet ? 0.04 : 0.056)).clamp(18.0, 30.0),
                      fontWeight: FontWeight.bold,
                      color: esCorrecto ? Colors.green[900] : Colors.red[900],
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: isTablet ? 28 : 20),
            SizedBox(
              width: double.infinity,
              height: isTablet ? 64 : 52,
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
                        .read(comparacionCantidadesViewModelProvider.notifier)
                        .commandGuardarProgresoFinal('Quien tiene más');
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (_) => const ActividadTerminadaScreen(),
                      ),
                    );
                  } else {
                    _nuevaRonda();
                  }
                },
                child: Text(
                  esCorrecto ? 'Continuar' : 'Reintentar',
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.bold,
                    fontSize: (sw * (isTablet ? 0.028 : 0.044)).clamp(14.0, 22.0),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCountingGrid(double gridW, double imgSz) {
    final allImages = <String>[];
    for (int i = 0; i < 4; i++) {
      for (int k = 0; k < _round.counts[i]; k++) {
        allImages.add(_round.animals[i].path);
      }
    }
    allImages.shuffle(Random());

    final cellW = gridW / 4;
    final cellH = imgSz * 1.18; // proporcional, sin padding fijo

    return Wrap(
      spacing: 0,
      runSpacing: 0,
      alignment: WrapAlignment.spaceEvenly,
      children: allImages
          .map((p) => SizedBox(
                width: cellW,
                height: cellH,
                child: Center(
                  child: _sharpAnimalImage(p, imgSz),
                ),
              ))
          .toList(),
    );
  }

  // Imagen de animal con filtro de contraste para bordes y colores muy definidos
  Widget _sharpAnimalImage(String path, double size) {
    return ColorFiltered(
      colorFilter: const ColorFilter.matrix(<double>[
        1.5, 0,   0,   0, -64,
        0,   1.5, 0,   0, -64,
        0,   0,   1.5, 0, -64,
        0,   0,   0,   1, 0,
      ]),
      child: Image.asset(
        path,
        width: size,
        height: size,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
      ),
    );
  }
}

class _OptionButton extends StatelessWidget {
  final String image;
  final String letter;
  final String name;
  final double imgSize;
  final double fontSize;
  final double hPad;
  final VoidCallback onTap;

  const _OptionButton({
    required this.image,
    required this.letter,
    required this.name,
    required this.imgSize,
    required this.fontSize,
    required this.hPad,
    required this.onTap,
  });

  static const _sharpFilter = ColorFilter.matrix(<double>[
    1.3, 0,   0,   0, -38,
    0,   1.3, 0,   0, -38,
    0,   0,   1.3, 0, -38,
    0,   0,   0,   1, 0,
  ]);

  @override
  Widget build(BuildContext context) {
    final sw      = MediaQuery.of(context).size.width;
    final radius  = (sw * 0.038).clamp(10.0, 18.0);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(radius),
      child: Container(
        width: double.infinity,
        height: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey.shade300, width: 2),
          borderRadius: BorderRadius.circular(radius),
        ),
        child: Row(
          children: [
            ColorFiltered(
              colorFilter: _sharpFilter,
              child: Image.asset(
                image,
                width: imgSize,
                height: imgSize,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
              ),
            ),
            SizedBox(width: hPad),
            Text(
              letter,
              style: TextStyle(
                fontSize: fontSize,
                fontFamily: 'Hiruko',
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(width: hPad * 0.5),
            Flexible(
              child: Text(
                name,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: fontSize * 0.9,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}