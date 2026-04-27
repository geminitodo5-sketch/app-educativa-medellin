import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import '../../terminado.dart';
import '../../../viewmodels/comparacion_cantidades_view_model.dart';

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

    // Ganador: 4–5 imágenes. Resto: 1–3 distintos. Total máximo ~14 imágenes.
    final winnerCount = 4 + rng.nextInt(2); // 4 o 5
    final otherCounts = <int>[];
    while (otherCounts.length < 3) {
      final c = 1 + rng.nextInt(3); // 1, 2 o 3
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
  Player? _player;
  late _RoundData _round;

  static const Color verdeNumi = Color(0xFF59E347);
  static const Color rojoNumi  = Color(0xFFF65757);

  @override
  void initState() {
    super.initState();
    _player = Player();
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
      await _player?.open(
        Media('asset:///assets/Audio/Matematicas/audio_matemaaticasnaranjas_mezcla.mp3'),
      );
    } catch (e) {
      debugPrint('Error al reproducir audio: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF3475F7),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildTopBar(),
            const SizedBox(height: 10),
            Expanded(child: _buildWhiteCanvas()),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Column(
      children: [
        Align(
          alignment: Alignment.topRight,
          child: IconButton(
            icon: const Icon(Icons.close, color: Colors.white, size: 30),
            onPressed: () {
              ref.read(respuestaProvider.notifier).state = null;
              Navigator.of(context).pop();
            },
          ),
        ),
        const Text(
          'Quién tiene más',
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

  Widget _buildWhiteCanvas() {
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
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Grilla ocupa el espacio sobrante entre el título y las opciones
            Expanded(child: _buildCountingGrid()),
            const SizedBox(height: 8),
            // Pregunta
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.volume_up_rounded, size: 38),
                  color: const Color(0xFF3475F7),
                  onPressed: _reproducirInstruccion,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    '¿Cuál de estos animales hay en mayor cantidad?',
                    style: TextStyle(
                      fontSize: 15,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // 4 opciones compactas
            ...List.generate(4, (i) {
              final animal    = _round.animals[i];
              final isCorrect = i == _round.correctIndex;
              return _OptionButton(
                image: animal.path,
                letter: '${String.fromCharCode(65 + i)})',
                name: animal.name,
                onTap: () => _showFeedbackSheet(isCorrect),
              );
            }),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  void _showFeedbackSheet(bool esCorrecto) {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
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
      ),
    );
  }

  Widget _buildCountingGrid() {
    final allImages = <String>[];
    for (int i = 0; i < 4; i++) {
      for (int k = 0; k < _round.counts[i]; k++) {
        allImages.add(_round.animals[i].path);
      }
    }
    allImages.shuffle(Random());

    return LayoutBuilder(
      builder: (context, constraints) {
        const cols    = 4;
        final imgSize = (constraints.maxWidth / cols) * 0.70;
        final cellH   = imgSize + 10;

        final wrap = Wrap(
          spacing: 0,
          // ── ESPACIADO VERTICAL entre filas ──────────────────────────────
          // Aumenta runSpacing para separar más las filas de animales,
          // o disminúyelo para juntarlas. Valor actual: 4
          runSpacing: 4,
          alignment: WrapAlignment.spaceEvenly,
          children: allImages
              .map((p) => SizedBox(
                    width:  constraints.maxWidth / cols,
                    height: cellH,
                    child: Center(
                      child: Image.asset(p, width: imgSize, height: imgSize),
                    ),
                  ))
              .toList(),
        );

        // ── POSICIÓN VERTICAL de la grilla dentro del espacio disponible ──
        // mainAxisAlignment.center  → centrado (actual)
        // mainAxisAlignment.start   → pegado arriba
        // mainAxisAlignment.end     → pegado abajo
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [wrap],
        );
      },
    );
  }
}

class _OptionButton extends StatelessWidget {
  final String image;
  final String letter;
  final String name;
  final VoidCallback onTap;

  const _OptionButton({
    required this.image,
    required this.letter,
    required this.name,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.grey.shade300, width: 2),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Image.asset(image, width: 38, height: 38),
              const SizedBox(width: 12),
              Text(
                letter,
                style: const TextStyle(
                  fontSize: 17,
                  fontFamily: 'Hiruko',
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                name,
                style: const TextStyle(
                  fontSize: 15,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}