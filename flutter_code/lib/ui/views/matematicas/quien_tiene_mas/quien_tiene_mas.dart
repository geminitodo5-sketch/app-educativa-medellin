import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import '../../../viewmodels/comparacion_cantidades_view_model.dart';
import 'quien_tiene_mas_2.dart';

/// Vista de comparación de cantidades — "¿Quién tiene más?"
class ComparacionCantidadesView extends ConsumerStatefulWidget {
  const ComparacionCantidadesView({super.key});

  @override
  ConsumerState<ComparacionCantidadesView> createState() =>
      _ComparacionCantidadesViewState();
}

class _ComparacionCantidadesViewState
    extends ConsumerState<ComparacionCantidadesView> {
  
  AudioPlayer? _player;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();

    Future.microtask(() {
      if (mounted) {
        ref
            .read(comparacionCantidadesViewModelProvider.notifier)
            .commandNuevaRonda();
        
        _reproducirInstruccion();
      }
    });
  }

  Future<void> _reproducirInstruccion() async {
    try {
      await _player?.setAsset('assets/Audio/Matematicas/audio mate4_mezcla.mp3');
      await _player?.play();
    } catch (e) {
      debugPrint('Error al reproducir audio: $e');
    }
  }

  @override
  void dispose() {
    _player?.dispose();
    super.dispose();
  }

  // ─── Feedback de respuesta ─────────────────────────────────────────────────

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

  void _verificarRespuesta(String nombre) {
    final state = ref.read(comparacionCantidadesViewModelProvider);
    if (state.respondido) return;

    final notifier = ref.read(comparacionCantidadesViewModelProvider.notifier);
    final esCorrecto = notifier.validarSeleccion(nombre);

    _mostrarFeedback(esCorrecto, () {
      if (esCorrecto) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MenosFrutasview()),
        );
      } else {
        notifier.commandNuevaRonda();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(comparacionCantidadesViewModelProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF3475F7),
      body: Stack(
        children: [
          const Positioned(
            top: 60,
            left: 0,
            right: 0,
            child: Text(
              'Quién tiene más',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontFamily: 'Hiruko',
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: MediaQuery.of(context).size.height * 0.82,
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(40),
                  topRight: Radius.circular(40),
                ),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 50),
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.42,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          _PersonCard(
                            color: const Color(0xFFA7F3FF),
                            imagePath: 'assets/images/actividades/matematicas/niño.png',
                            cantidadManzanas: state.manzanasJuan,
                          ),
                          const SizedBox(width: 2),
                          _PersonCard(
                            color: const Color(0xFFFFC1C1),
                            imagePath: 'assets/images/actividades/matematicas/niña.png',
                            cantidadManzanas: state.manzanasSara,
                          ),
                        ],
                      ),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 28),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.volume_up_rounded, size: 50),
                          onPressed: _reproducirInstruccion,
                          color: const Color(0xFF1E293B),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Text(
                            'Quién tiene más manzanas',
                            style: TextStyle(
                              fontSize: 19,
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _SelectionButton(
                          nombre: 'Juan',
                          imagePath: 'assets/images/actividades/matematicas/niño.png',
                          color: const Color(0xFFA7F3FF),
                          onTap: state.respondido ? null : () => _verificarRespuesta('Juan'),
                        ),
                        _SelectionButton(
                          nombre: 'Sara',
                          imagePath: 'assets/images/actividades/matematicas/niña.png',
                          color: const Color(0xFFFFC1C1),
                          onTap: state.respondido ? null : () => _verificarRespuesta('Sara'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          // Personajes desbordando
          Positioned(
            top: MediaQuery.of(context).size.height * 0.25,
            left: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: Center(
                      child: Image.asset(
                        'assets/images/actividades/matematicas/niño.png',
                        height: 130,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Center(
                      child: Image.asset(
                        'assets/images/actividades/matematicas/niña.png',
                        height: 130,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Botón cerrar
          Positioned(
            top: 44,
            right: 16,
            child: SafeArea(
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close_rounded, color: Colors.white, size: 22),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Widgets de apoyo (Asegúrate que los nombres coincidan con los de arriba) ───

class _PersonCard extends StatelessWidget {
  const _PersonCard({
    required this.color,
    required this.imagePath,
    required this.cantidadManzanas,
  });

  final Color color;
  final String imagePath;
  final int cantidadManzanas;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Padding(
          padding: const EdgeInsets.only(top: 60, left: 8, right: 8, bottom: 10),
          child: Wrap(
            spacing: 4,
            runSpacing: 4,
            alignment: WrapAlignment.center,
            children: List.generate(
              cantidadManzanas,
              (_) => Image.asset(
                'assets/images/actividades/matematicas/manzana.png',
                width: 34,
                height: 34,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SelectionButton extends StatelessWidget {
  const _SelectionButton({
    required this.nombre,
    required this.imagePath,
    required this.color,
    required this.onTap,
  });

  final String nombre;
  final String imagePath;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        opacity: onTap == null ? 0.45 : 1.0,
        duration: const Duration(milliseconds: 300),
        child: Container(
          width: 130,
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                nombre,
                style: const TextStyle(
                  fontSize: 20,
                  fontFamily: 'Hiruko',
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Image.asset(imagePath, height: 80),
            ],
          ),
        ),
      ),
    );
  }
}