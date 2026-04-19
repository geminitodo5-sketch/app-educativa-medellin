import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../viewmodels/animales_view_model.dart';

// --- Paleta de Colores NUMI (según manual pág. 9) ---
const Color kColorAzulNumi = Color(0xFF3475F7);
const Color kColorVerdeNumi = Color(0xFF59E347); // HEX 59e347 [cite: 64]
const Color kColorRojoNumi = Color(0xFFF65757); // HEX f65757 [cite: 64]
const Color kColorBlanco = Colors.white;

class PantallaActividadAnimales extends ConsumerWidget {
  final VoidCallback onCompletado;
  const PantallaActividadAnimales({super.key, required this.onCompletado});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewModel = ref.watch(animalesViewModelProvider);
    final aciertos = viewModel.aciertos;

    return Scaffold(
      backgroundColor: kColorVerdeNumi,
      body: SafeArea(
        child: Column(
          children: [
            // Header corregido con Stack y Positioned
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
                            "Devuelve a estos animales a su hogar, empareja sus hábitats",
                        onPressed: () =>
                            viewModel.commandReproducirInstruccion(),
                      ),
                      const Spacer(),

                      // HÁBITATS (Destinos del arrastre)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _HabitatTarget(
                            tipo: 'pinguino',
                            imagen:
                                'assets/images/actividades/ciencias_naturales/polar.png',
                            onAccept: (val) {
                              bool esCorrecto = viewModel.commandValidarHabitat(
                                val,
                                'pinguino',
                              );
                              _showFeedbackSheet(
                                context,
                                esCorrecto,
                                onContinue: (esCorrecto && viewModel.completado)
                                    ? onCompletado
                                    : null,
                              );
                            },
                          ),
                          _HabitatTarget(
                            tipo: 'cocodrilo',
                            imagen:
                                'assets/images/actividades/ciencias_naturales/selva.png',
                            onAccept: (val) {
                              bool esCorrecto = viewModel.commandValidarHabitat(
                                val,
                                'cocodrilo',
                              );
                              _showFeedbackSheet(
                                context,
                                esCorrecto,
                                onContinue: (esCorrecto && viewModel.completado)
                                    ? onCompletado
                                    : null,
                              );
                            },
                          ),
                        ],
                      ),

                      const Spacer(),

                      // ANIMALES (Elementos arrastrables)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          if (!aciertos['cocodrilo']!)
                            const _AnimalDraggable(
                              id: 'cocodrilo',
                              imagen:
                                  'assets/images/actividades/ciencias_naturales/cocodrilo.png',
                            )
                          else
                            const SizedBox(width: 140, height: 140),

                          if (!aciertos['pinguino']!)
                            const _AnimalDraggable(
                              id: 'pinguino',
                              imagen:
                                  'assets/images/actividades/ciencias_naturales/pinguino.png',
                            )
                          else
                            const SizedBox(width: 140, height: 140),
                        ],
                      ),
                      const Spacer(),

                      // Indicador de tres puntos corregido
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

// --- Componentes Especializados ---

class _HeaderActividad extends StatelessWidget {
  final String titulo;
  const _HeaderActividad({required this.titulo});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 90,
      width: double.infinity,
      child: Stack(
        children: [
          // Título centrado con tipografía Hiruko (Decorativa Numi)
          Align(
            alignment: Alignment.center,
            child: Text(
              titulo,
              style: const TextStyle(
                fontFamily: 'Hiruko',
                fontSize: 38,
                fontWeight: FontWeight.bold,
                color: kColorBlanco,
              ),
            ),
          ),
          // Botón X posicionado en la esquina superior derecha
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
              fontFamily: 'Poppins', // Tipografía de lectura
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
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
            // Estilo de puntos verdes [cite: 72]
            color: kColorVerdeNumi.withOpacity(index == 0 ? 1.0 : 0.4),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

class _HabitatTarget extends StatelessWidget {
  final String tipo;
  final String imagen;
  final Function(String) onAccept;

  const _HabitatTarget({
    required this.tipo,
    required this.imagen,
    required this.onAccept,
  });

  @override
  Widget build(BuildContext context) {
    return DragTarget<String>(
      onAcceptWithDetails: (details) => onAccept(details.data),
      builder: (context, candidateData, rejectedData) {
        return Container(
          width: 150,
          height: 150,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: candidateData.isNotEmpty
                  ? kColorVerdeNumi
                  : Colors.grey.shade300,
              width: 3,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(17),
            child: Image.asset(imagen, fit: BoxFit.cover),
          ),
        );
      },
    );
  }
}

class _AnimalDraggable extends StatelessWidget {
  final String id;
  final String imagen;
  const _AnimalDraggable({required this.id, required this.imagen});

  @override
  Widget build(BuildContext context) {
    return Draggable<String>(
      data: id,
      feedback: Image.asset(
        imagen,
        width: 160,
        opacity: const AlwaysStoppedAnimation(0.8),
      ),
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: Image.asset(imagen, width: 140),
      ),
      child: Image.asset(imagen, width: 140),
    );
  }
}

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
