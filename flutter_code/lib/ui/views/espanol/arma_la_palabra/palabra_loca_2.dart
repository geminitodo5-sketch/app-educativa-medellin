import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import '../../../viewmodels/palabra_loca_view_model.dart';
import '../../terminado.dart';

class ArmaLaPalabraScreen extends ConsumerStatefulWidget {
  const ArmaLaPalabraScreen({super.key});

  @override
  ConsumerState<ArmaLaPalabraScreen> createState() => _ArmaLaPalabraScreenState();
}

class _ArmaLaPalabraScreenState extends ConsumerState<ArmaLaPalabraScreen>
    with TickerProviderStateMixin {

  late final AudioPlayer _player;
  late AnimationController _successController;
  late Animation<double> _successScale;
  late AnimationController _errorController;
  late Animation<double> _errorShake;

  bool _navegandoATerminado = false;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _reproducirAudio();

    _successController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _successScale = CurvedAnimation(
      parent: _successController,
      curve: Curves.elasticOut,
    );

    _errorController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _errorShake = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: -8), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -8, end: 8), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 8, end: -8), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -8, end: 8), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 8, end: 0), weight: 1),
    ]).animate(CurvedAnimation(
      parent: _errorController,
      curve: Curves.easeInOut,
    ));
  }

  Future<void> _reproducirAudio() async {
    try {
      await _player.setAsset('assets/Audio/espanol/audio_espanol2_mezcla.mp3');
      await _player.play();
    } catch (e) {
      debugPrint("Error de audio: $e");
    }
  }

  @override
  void dispose() {
    _player.dispose();
    _successController.dispose();
    _errorController.dispose();
    super.dispose();
  }

  void _mostrarFeedback(bool esCorrecto, VoidCallback onAction) {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
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
                  backgroundColor:
                      esCorrecto ? const Color(0xFF59E347) : const Color(0xFFF65757),
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
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _irATerminado() {
    if (_navegandoATerminado || !mounted) return;
    _navegandoATerminado = true;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ActividadTerminadaScreen(
          onVolver: () {
            Navigator.pop(context);
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(armaLaPalabraViewModelProvider);
    final notifier = ref.read(armaLaPalabraViewModelProvider.notifier);
    final palabra = notifier.palabraActual;

    ref.listen(armaLaPalabraViewModelProvider, (prev, next) {
      if (prev == null) return;
      if (!prev.completado && next.completado) {
        _successController.forward();
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            _mostrarFeedback(true, () => notifier.commandSiguientePalabra());
          }
        });
      }
      if (!prev.error && next.error) {
        _errorController.forward().then((_) {
          if (mounted) {
            _mostrarFeedback(false, () => notifier.commandLimpiarRespuestas());
          }
        });
      }
      if (!prev.actividadCompletada && next.actividadCompletada) {
        _irATerminado();
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF65757),
      body: SafeArea(
        child: Column(
          children: [
            _Header(onClose: () => Navigator.maybePop(context)),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
                ),
                child: Column(
                  children: [

                    // ── Instrucción (fija arriba) ────────────────────────
                    Padding(
                      // ── MARGEN SUPERIOR instrucción: cambia el 24 ──────
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                      child: _InstruccionRow(
                        texto: 'Arma  la palabra de  la imagen.',
                        onPlay: _reproducirAudio,
                      ),
                    ),

                    // ── Zona central centrada: imagen + recuadros ────────
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // ── TAMAÑO DE IMAGEN: cambia 200 ───────────────
                          _ImagenAnimal(
                            asset: palabra.imagenAsset,
                            completado: state.completado,
                            error: state.error,
                            scaleAnimation: _successScale,
                            size: 200,
                          ),
                          // ── ESPACIO imagen → recuadros: cambia 28 ──────
                          const SizedBox(height: 28),
                          AnimatedBuilder(
                            animation: _errorShake,
                            builder: (context, child) => Transform.translate(
                              offset: Offset(_errorShake.value, 0),
                              child: child,
                            ),
                            child: _RecuadrosRespuesta(
                              silabas: state.silabasColocadas,
                              cantidadSilabas: palabra.silabas.length,
                              completado: state.completado,
                              error: state.error,
                              onQuitarSilaba: notifier.commandQuitarSilaba,
                              onColocarSilaba: notifier.commandColocarSilaba,
                              opcionesDisponibles: state.opcionesDisponibles,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ── Grid de sílabas (fijo abajo) ─────────────────────
                    // ── ESPACIO recuadros → sílabas: cambia 16 ────────────
                    const SizedBox(height: 16),
                    _GridSilabas(
                      opciones: palabra.opcionesMezcladas,
                      disponibles: state.opcionesDisponibles,
                      silabasColocadas: state.silabasColocadas,
                      onTap: (idx, target) =>
                          notifier.commandColocarSilaba(idx, target),
                    ),
                    // ── ESPACIO inferior: cambia 28 ────────────────────────
                    const SizedBox(height: 28),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// WIDGETS AUXILIARES
// ─────────────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final VoidCallback onClose;
  const _Header({required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SizedBox(
          height: 80,
          child: Center(
            child: const Text(
              'Arma  la palabra',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
                fontFamily: 'Hiruko',
              ),
            ),
          ),
        ),
        Positioned(
          top: 0, right: 4, bottom: 0,
          child: Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: onClose,
            ),
          ),
        ),
      ],
    );
  }
}

class _InstruccionRow extends StatelessWidget {
  final String texto;
  final VoidCallback onPlay;
  const _InstruccionRow({required this.texto, required this.onPlay});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: onPlay,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F4FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.volume_up_rounded,
                color: Color(0xFF3475F7), size: 22),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          texto,
          style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Color(0xFF444444)),
        ),
      ],
    );
  }
}

class _ImagenAnimal extends StatelessWidget {
  final String asset;
  final bool completado;
  final bool error;
  final Animation<double> scaleAnimation;
  // ── Parámetro de tamaño: pásale otro valor desde el build para ajustar ──
  final double size;

  const _ImagenAnimal({
    required this.asset,
    required this.completado,
    required this.error,
    required this.scaleAnimation,
    this.size = 200,
  });

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: completado
          ? scaleAnimation
          : const AlwaysStoppedAnimation(1.0),
      child: Container(
        width: size,
        height: size,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: error ? const Color(0xFFFFEBEB) : Colors.transparent,
          border: error
              ? Border.all(color: const Color(0xFFFF5252), width: 3)
              : null,
        ),
        child: Image.asset(asset, fit: BoxFit.contain),
      ),
    );
  }
}

class _RecuadrosRespuesta extends StatelessWidget {
  final List<String?> silabas;
  final int cantidadSilabas;
  final bool completado;
  final bool error;
  final Function(int) onQuitarSilaba;
  final Function(int, int) onColocarSilaba;
  final List<bool> opcionesDisponibles;

  const _RecuadrosRespuesta({
    required this.silabas,
    required this.cantidadSilabas,
    required this.completado,
    required this.error,
    required this.onQuitarSilaba,
    required this.onColocarSilaba,
    required this.opcionesDisponibles,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(cantidadSilabas, (i) {
        final silaba = silabas[i];
        return DragTarget<int>(
          onWillAcceptWithDetails: (details) =>
              !completado && !error && opcionesDisponibles[details.data],
          onAcceptWithDetails: (details) =>
              onColocarSilaba(details.data, i),
          builder: (context, _, __) => GestureDetector(
            onTap: (silaba != null && !completado && !error)
                ? () => onQuitarSilaba(i)
                : null,
            child: Container(
              width: 70, height: 55,
              margin: const EdgeInsets.symmetric(horizontal: 5),
              decoration: BoxDecoration(
                color: silaba != null ? Colors.white : Colors.grey[100],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: error
                      ? Colors.red
                      : (completado ? Colors.green : Colors.grey[300]!),
                  width: 2,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                silaba ?? '',
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _GridSilabas extends StatelessWidget {
  final List<String> opciones;
  final List<bool> disponibles;
  final List<String?> silabasColocadas;
  final Function(int, int) onTap;

  const _GridSilabas({
    required this.opciones,
    required this.disponibles,
    required this.silabasColocadas,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12, runSpacing: 12,
      alignment: WrapAlignment.center,
      children: List.generate(opciones.length, (i) {
        return Draggable<int>(
          data: i,
          feedback: _SilabaChip(texto: opciones[i], disponible: true),
          childWhenDragging:
              _SilabaChip(texto: opciones[i], disponible: false, opacity: 0.3),
          child: GestureDetector(
            onTap: disponibles[i]
                ? () {
                    int emptyIdx = silabasColocadas.indexOf(null);
                    if (emptyIdx != -1) onTap(i, emptyIdx);
                  }
                : null,
            child: _SilabaChip(texto: opciones[i], disponible: disponibles[i]),
          ),
        );
      }),
    );
  }
}

class _SilabaChip extends StatelessWidget {
  final String texto;
  final bool disponible;
  final double opacity;
  const _SilabaChip(
      {required this.texto, required this.disponible, this.opacity = 1.0});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: disponible ? opacity : 0.2,
      child: Container(
        width: 72, height: 52,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!, width: 1.5),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          texto,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}