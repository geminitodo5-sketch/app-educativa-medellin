import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../terminado.dart';
import '../../../viewmodels/comparacion_cantidades_view_model.dart';

// Proveedor de estado para feedback visual
final respuestaProvider = StateProvider<bool?>((ref) => null);

class QuienTieneMasview3 extends ConsumerWidget {
  const QuienTieneMasview3({super.key});

  static const String _crocPath =
      'assets/images/actividades/matematicas/cocodrilo.png';
  static const String _elephantPath =
      'assets/images/actividades/matematicas/elefante.png';
  static const String _duckPath =
      'assets/images/actividades/matematicas/pato.png';
  static const String _penguinPath =
      'assets/images/actividades/matematicas/pinguino.png';

  // Colores del Manual de Marca
  static const Color verdeNumi = Color(0xFF59E347);
  static const Color rojoNumi = Color(0xFFF65757);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: const Color(0xFF3475F7),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildTopBar(context, ref),
            const SizedBox(height: 10),
            Expanded(child: _buildWhiteCanvas(context, ref)),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, WidgetRef ref) {
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

  Widget _buildWhiteCanvas(BuildContext context, WidgetRef ref) {
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
        padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 40.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCountingGrid(),
            const SizedBox(height: 40),
            Row(
              children: [
                const Icon(
                  Icons.volume_up_rounded,
                  size: 45,
                  color: Color(0xFF3475F7),
                ),
                const SizedBox(width: 15),
                const Expanded(
                  child: Text(
                    '¿Cuál de estos animales hay en mayor cantidad?',
                    style: TextStyle(
                      fontSize: 18,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
            _OptionButton(
              image: _crocPath,
              letter: 'A)',
              name: 'Cocodrilo',
              onTap: () => _showFeedbackSheet(context, ref, true),
            ),
            _OptionButton(
              image: _elephantPath,
              letter: 'B)',
              name: 'Elefante',
              onTap: () => _showFeedbackSheet(context, ref, false),
            ),
            _OptionButton(
              image: _duckPath,
              letter: 'C)',
              name: 'Pato',
              onTap: () => _showFeedbackSheet(context, ref, false),
            ),
            _OptionButton(
              image: _penguinPath,
              letter: 'D)',
              name: 'Pingüino',
              onTap: () => _showFeedbackSheet(context, ref, false),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Pestaña intermitente igual a sumar_patron_view.dart ───────────────────
  void _showFeedbackSheet(BuildContext context, WidgetRef ref, bool esCorrecto) {
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
                    backgroundColor: esCorrecto ? verdeNumi : rojoNumi,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15)),
                  ),
                  onPressed: () {
                    Navigator.pop(context); // cierra la pestaña
                    if (esCorrecto) {
                      // Guardar progreso en SQLite y Sync Queue (Offline-first)
                      ref
                          .read(comparacionCantidadesViewModelProvider.notifier)
                          .commandGuardarProgresoFinal('Quien tiene más');

                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (_) => const ActividadTerminadaScreen(),
                        ),
                      );
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
  // ───────────────────────────────────────────────────────────────────────────

  Widget _buildCountingGrid() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _img(_crocPath),
            _img(_elephantPath),
            _img(_penguinPath),
            _img(_crocPath),
          ],
        ),
        const SizedBox(height: 15),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _img(_duckPath),
            _img(_crocPath),
            _img(_duckPath),
            _img(_elephantPath),
          ],
        ),
      ],
    );
  }

  Widget _img(String p) => Image.asset(p, width: 60, height: 60);
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
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.grey.shade300, width: 2),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Row(
            children: [
              Image.asset(image, width: 50, height: 50),
              const SizedBox(width: 15),
              Text(
                letter,
                style: const TextStyle(
                  fontSize: 20,
                  fontFamily: 'Hiruko',
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                name,
                style: const TextStyle(
                  fontSize: 18,
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