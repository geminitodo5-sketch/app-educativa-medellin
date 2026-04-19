import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../terminado.dart';
import '../../../viewmodels/comparacion_cantidades_view_model.dart';

// Proveedor de estado para feedback visual
final respuestaProvider = StateProvider<bool?>((ref) => null);

class QuienTieneMasview3 extends ConsumerWidget {
  const QuienTieneMasview3({super.key});

  static const String _crocPath = 'assets/images/actividades/matematicas/cocodrilo.png';
  static const String _elephantPath = 'assets/images/actividades/matematicas/elefante.png';
  static const String _duckPath = 'assets/images/actividades/matematicas/pato.png';
  static const String _penguinPath = 'assets/images/actividades/matematicas/pinguino.png';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final esCorrecto = ref.watch(respuestaProvider);

    return Scaffold(
      // Usando el azul del manual de marca si es necesario
      backgroundColor: const Color(0xFF3475F7), 
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildTopBar(context, ref),
            const SizedBox(height: 10),
            Expanded(child: _buildWhiteCanvas(context, ref, esCorrecto)),
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
            onPressed: () => ref.read(respuestaProvider.notifier).state = null,
          ),
        ),
        const Text(
          'Quién tiene más',
          style: TextStyle(
            color: Colors.white,
            fontSize: 32,
            // Aplicando Hiruko Bold para el título principal
            fontFamily: 'Hiruko', 
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildWhiteCanvas(BuildContext context, WidgetRef ref, bool? esCorrecto) {
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

            // Feedback Visual en Pantalla
            if (esCorrecto != null)
              _buildFeedback(context, ref, esCorrecto),

            Row(
              children: [
                const Icon(Icons.volume_up_rounded, size: 45, color: Color(0xFF3475F7)),
                const SizedBox(width: 15),
                const Expanded(
                  child: Text(
                    '¿Cuál de estos animales hay en mayor cantidad?',
                    style: TextStyle(
                      fontSize: 18,
                      // Poppins para textos de lectura/instrucciones
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
              onTap: () => ref.read(respuestaProvider.notifier).state = true,
              isSelected: esCorrecto == true,
            ),
            _OptionButton(
              image: _elephantPath,
              letter: 'B)',
              name: 'Elefante',
              onTap: () => ref.read(respuestaProvider.notifier).state = false,
              isSelected: false, // Lógica simple para ejemplo
            ),
            _OptionButton(
              image: _duckPath,
              letter: 'C)',
              name: 'Pato',
              onTap: () => ref.read(respuestaProvider.notifier).state = false,
              isSelected: false,
            ),
            _OptionButton(
              image: _penguinPath,
              letter: 'D)',
              name: 'Pingüino',
              onTap: () => ref.read(respuestaProvider.notifier).state = false,
              isSelected: false,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedback(BuildContext context, WidgetRef ref, bool esCorrecto) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      margin: const EdgeInsets.only(bottom: 25),
      decoration: BoxDecoration(
        color: esCorrecto ? const Color(0xFF59E347).withOpacity(0.2) : const Color(0xFFF65757).withOpacity(0.2),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: esCorrecto ? const Color(0xFF59E347) : const Color(0xFFF65757)),
      ),
      child: Row(
        children: [
          Icon(
            esCorrecto ? Icons.check_circle : Icons.error,
            color: esCorrecto ? const Color(0xFF59E347) : const Color(0xFFF65757),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              esCorrecto ? "¡Excelente! El cocodrilo es el mayor" : "¡Inténtalo de nuevo!",
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: esCorrecto ? Colors.green[900] : Colors.red[900],
              ),
            ),
          ),
          if (esCorrecto)
            IconButton(
              icon: const Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.green,
              ),
              onPressed: () {
                // 1. Guardar progreso final de la lección "Sumar" (Offline-first)
                ref.read(comparacionCantidadesViewModelProvider.notifier)
                   .commandGuardarProgresoFinal('Sumar');

                // 2. Navegar a la pantalla de felicitaciones final
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const ActividadTerminadaScreen()),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildCountingGrid() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _img(_crocPath), _img(_elephantPath), _img(_penguinPath), _img(_crocPath),
          ],
        ),
        const SizedBox(height: 15),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _img(_duckPath), _img(_crocPath), _img(_duckPath), _img(_elephantPath),
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
  final bool isSelected;

  const _OptionButton({
    required this.image,
    required this.letter,
    required this.name,
    required this.onTap,
    required this.isSelected,
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
            color: isSelected ? const Color(0xFF59E347).withOpacity(0.1) : Colors.white,
            border: Border.all(
              color: isSelected ? const Color(0xFF59E347) : Colors.grey.shade300,
              width: 2,
            ),
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
                  fontFamily: 'Hiruko', // Letras de opción en Hiruko
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                name,
                style: const TextStyle(
                  fontSize: 18,
                  fontFamily: 'Poppins', // Nombre del animal en Poppins
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