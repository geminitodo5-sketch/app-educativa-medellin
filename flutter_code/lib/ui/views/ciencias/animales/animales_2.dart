import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../viewmodels/animales_clasificacion_view_model.dart';

// --- Paleta de Colores NUMI (según manual pág. 9) ---
const Color kColorAzulNumi = Color(0xFF3475F7);
const Color kColorVerdeNumi = Color(0xFF59E347); //
const Color kColorRojoNumi = Color(0xFFF65757); //
const Color kColorBlanco = Colors.white;

class PantallaClasificacionAnimales extends ConsumerWidget {
  final VoidCallback onCompletado;
  const PantallaClasificacionAnimales({super.key, required this.onCompletado});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewModel = ref.watch(animalesClasificacionViewModelProvider);

    return Scaffold(
      backgroundColor: kColorVerdeNumi,
      body: SafeArea(
        child: Column(
          children: [
            const _HeaderActividad(titulo: "Animales"),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: kColorBlanco,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      _InstruccionAudio(
                        texto:
                            "Decide si estos animales son domésticos o salvajes",
                        onPressed: () =>
                            viewModel.commandReproducirInstruccion(),
                      ),
                      const Spacer(),
                      // Imagen del animal actual
                      Image.asset(
                        'assets/images/actividades/ciencias_naturales/gato.png',
                        height: 220,
                      ),
                      const Spacer(),
                      // Botones con lógica de selección
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _BotonOpcion(
                            imagenPath:
                                'assets/images/actividades/ciencias_naturales/boton_domestico.png',
                            onPressed: () {
                              final esCorrecto = viewModel.validarRespuesta(
                                'domestico',
                              );
                              _showFeedbackSheet(
                                context,
                                esCorrecto,
                                onContinue: esCorrecto ? onCompletado : null,
                              );
                            },
                          ),
                          _BotonOpcion(
                            imagenPath:
                                'assets/images/actividades/ciencias_naturales/boton_salvaje.png',
                            onPressed: () {
                              final esCorrecto = viewModel.validarRespuesta(
                                'salvaje',
                              );
                              _showFeedbackSheet(context, esCorrecto);
                            },
                          ),
                        ],
                      ),
                      const Spacer(),
                      const _IndicadorProgreso(),
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
}

// --- Componentes de Interfaz ---

class _HeaderActividad extends StatelessWidget {
  final String titulo;
  const _HeaderActividad({required this.titulo});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 90,
      child: Stack(
        children: [
          Align(
            alignment: Alignment.center,
            child: Text(
              titulo,
              style: const TextStyle(
                fontFamily: 'Hiruko',
                fontSize: 34,
                fontWeight: FontWeight.bold,
                color: kColorBlanco,
              ),
            ),
          ),
          Positioned(
            top: 10,
            right: 15,
            child: IconButton(
              icon: const Icon(Icons.close, color: kColorBlanco, size: 32),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }
}

class _InstruccionAudio extends StatelessWidget {
  final String texto;
  final VoidCallback onPressed;
  const _InstruccionAudio({required this.texto, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          icon: const Icon(
            Icons.volume_up_rounded,
            size: 45,
            color: Colors.black87,
          ),
          onPressed: onPressed,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            texto,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}

class _BotonOpcion extends StatelessWidget {
  final String imagenPath;
  final VoidCallback onPressed;
  const _BotonOpcion({required this.imagenPath, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        child: Image.asset(imagenPath, width: 155, fit: BoxFit.contain),
      ),
    );
  }
}

class _IndicadorProgreso extends StatelessWidget {
  const _IndicadorProgreso();
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        3,
        (index) => Container(
          margin: const EdgeInsets.symmetric(horizontal: 5),
          width: 15,
          height: 15,
          decoration: BoxDecoration(
            color: kColorVerdeNumi.withOpacity(index == 1 ? 1.0 : 0.4),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

// --- Pestaña de Retroalimentación (Feedback Sheet) ---

void _showFeedbackSheet(
  BuildContext context,
  bool esCorrecto, {
  VoidCallback? onContinue,
}) {
  showModalBottomSheet(
    context: context,
    isDismissible: false,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return Container(
        padding: const EdgeInsets.all(30),
        decoration: BoxDecoration(
          // Colores pasteles para el fondo según el resultado
          color: esCorrecto ? const Color(0xFFD7FFD3) : const Color(0xFFFFD3D3),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(
                  esCorrecto ? Icons.check_circle : Icons.cancel,
                  color: esCorrecto ? kColorVerdeNumi : kColorRojoNumi,
                  size: 40,
                ),
                const SizedBox(width: 15),
                Text(
                  esCorrecto ? '¡Excelente trabajo!' : '¡Casi lo tienes!',
                  style: TextStyle(
                    fontFamily: 'Hiruko', // [cite: 70]
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
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: esCorrecto
                      ? kColorVerdeNumi
                      : kColorRojoNumi,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  onContinue?.call();
                },
                child: Text(
                  esCorrecto ? 'Continuar' : 'Reintentar',
                  style: const TextStyle(
                    color: kColorBlanco,
                    fontFamily: 'Poppins', // [cite: 71]
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
