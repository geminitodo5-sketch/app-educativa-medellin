import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import '../../../viewmodels/comparacion_cantidades_view_model.dart';
import 'quien_tiene_mas_2.dart';
import '../../../../data/services/feedback_sounds.dart';

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
      await _player?.setAsset(
          'assets/Audio/Matematicas/audio mate4_mezcla.mp3');
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

  void _mostrarFeedback(bool esCorrecto, VoidCallback onAction) {
    FeedbackSounds.instance.reproducir(esCorrecto);
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final sw = MediaQuery.of(context).size.width;
        final isTablet = sw >= 600;
        final hPad = (sw * (isTablet ? 0.08 : 0.06)).clamp(20.0, 60.0);

        return Container(
          padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 26),
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
                    color: esCorrecto
                        ? const Color(0xFF59E347)
                        : const Color(0xFFF65757),
                    size: isTablet ? 52 : 40,
                  ),
                  SizedBox(width: isTablet ? 20 : 15),
                  Expanded(
                    child: Text(
                      esCorrecto
                          ? '¡Excelente trabajo!'
                          : '¡Inténtalo de nuevo!',
                      style: TextStyle(
                        fontFamily: 'Hiruko',
                        fontSize: (sw * (isTablet ? 0.04 : 0.056))
                            .clamp(18.0, 30.0),
                        fontWeight: FontWeight.bold,
                        color: esCorrecto
                            ? Colors.green[900]
                            : Colors.red[900],
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
                    backgroundColor: esCorrecto
                        ? const Color(0xFF59E347)
                        : const Color(0xFFF65757),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15)),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    onAction();
                  },
                  child: Text(
                    esCorrecto ? 'Continuar' : 'Reintentar',
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.bold,
                      fontSize: (sw * (isTablet ? 0.028 : 0.044))
                          .clamp(14.0, 22.0),
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

    final notifier =
        ref.read(comparacionCantidadesViewModelProvider.notifier);
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
    final mq = MediaQuery.of(context);
    final screenW = mq.size.width;
    final screenH = mq.size.height;
    final statusBar = mq.padding.top;

    final isTablet = screenW >= 600;

    final titleSize = (screenW * (isTablet ? 0.048 : 0.057)).clamp(18.0, 36.0);
    final iconSize = (screenW * 0.07).clamp(22.0, 36.0);
    final headerH = (screenH * 0.10).clamp(60.0, 100.0);

    final instrSize = (screenW * 0.055).clamp(18.0, 40.0);
    final volIconSz = (screenW * 0.13).clamp(44.0, 60.0);
    final btnFontSz = (screenW * (isTablet ? 0.028 : 0.040)).clamp(13.0, 22.0);
    final hPad = (screenW * (isTablet ? 0.05 : 0.04)).clamp(14.0, 40.0);

    // Tamaño del personaje: flota sobre la tarjeta
    final charSize = (screenW * (isTablet ? 0.22 : 0.30)).clamp(80.0, 170.0);
    // Cuánto del personaje queda por encima del borde de la tarjeta
    final charOverflow = charSize * 0.78;

    return Scaffold(
      backgroundColor: const Color(0xFF3475F7),
      body: Column(
        children: [
          // ── Header azul ──────────────────────────────────────────────────────
          SizedBox(
            height: statusBar + headerH,
            child: Stack(
              children: [
                Positioned(
                  top: statusBar,
                  left: 0,
                  right: 0,
                  bottom: 28, // deja espacio entre título y barra
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
                  top: statusBar + 4,
                  right: 4,
                  child: IconButton(
                    icon: Icon(Icons.close_rounded,
                        color: Colors.white, size: iconSize),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                // ── Barra de progreso (1 de 3) ──────────────────────────────
                Positioned(
                  bottom: 10,
                  left: isTablet ? 60 : 40,
                  right: isTablet ? 60 : 40,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: 1 / 3,
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

          // ── Panel blanco ─────────────────────────────────────────────────────
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
              child: Padding(
                padding: EdgeInsets.fromLTRB(hPad, 0, hPad, 0),
                child: Column(
                  children: [
                    // ── Área de tarjetas (personajes flotan encima) ─────────
                    Expanded(
                      flex: 6,
                      child: Padding(
                        // El top padding reserva espacio visible para los personajes
                        padding: EdgeInsets.only(top: charOverflow),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            // Ambas tarjetas tienen el mismo ancho y alto
                            final cardW =
                                (constraints.maxWidth - hPad * 0.5) / 2;
                            final cardH = constraints.maxHeight;
                            // Padding reducido para ceder más espacio a las manzanas
                            final sidePad = (cardW * 0.04).clamp(4.0, 12.0);
                            final topPad = (cardH * 0.03).clamp(6.0, 12.0);
                            final bottomPad = (cardH * 0.03).clamp(6.0, 12.0);
                            final availW = cardW - sidePad * 2;
                            final availH = cardH - topPad - bottomPad;

                            final maxCount = max(
                                state.manzanasJuan, state.manzanasSara);

                            // Siempre 2 columnas → manzanas más grandes.
                            // byH garantiza que entran en el recuadro.
                            final cols = maxCount == 1 ? 1 : 2;
                            final rows = maxCount == 0
                                ? 1
                                : (maxCount / cols).ceil().clamp(1, 6);
                            const spacing = 3.0;
                            final byW =
                                (availW - spacing * (cols - 1)) / cols;
                            final byH =
                                (availH - spacing * (rows - 1)) / rows;
                            final appleSize =
                                (byW < byH ? byW : byH).clamp(36.0, 110.0);

                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _PersonCard(
                                  color: const Color(0xFFA7F3FF),
                                  imagePath:
                                      'assets/images/actividades/matematicas/niño.png',
                                  cantidadManzanas: state.manzanasJuan,
                                  charSize: charSize,
                                  charOverflow: charOverflow,
                                  appleSize: appleSize,
                                ),
                                SizedBox(width: hPad * 0.5),
                                _PersonCard(
                                  color: const Color(0xFFFFC1C1),
                                  imagePath:
                                      'assets/images/actividades/matematicas/niña.png',
                                  cantidadManzanas: state.manzanasSara,
                                  charSize: charSize,
                                  charOverflow: charOverflow,
                                  appleSize: appleSize,
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),

                    // ── Instrucción ─────────────────────────────────────────
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: screenH * 0.016),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: _reproducirInstruccion,
                            child: Container(
                              width: volIconSz,
                              height: volIconSz,
                              decoration: BoxDecoration(
                                color: const Color(0xFFEEF2FF),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(
                                Icons.volume_up_rounded,
                                color: const Color(0xFF3475F7),
                                size: volIconSz * 0.54,
                              ),
                            ),
                          ),
                          SizedBox(width: hPad * 0.5),
                          Expanded(
                            child: Text(
                              'Quién tiene más manzanas',
                              style: TextStyle(
                                fontSize: instrSize,
                                fontFamily: 'Hiruko',
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ── Botones de selección ────────────────────────────────
                    Expanded(
                      flex: 3,
                      child: Row(
                        children: [
                          Expanded(
                            child: _SelectionButton(
                              nombre: 'Juan',
                              imagePath:
                                  'assets/images/actividades/matematicas/niño.png',
                              color: const Color(0xFFA7F3FF),
                              fontSize: btnFontSz,
                              onTap: state.respondido
                                  ? null
                                  : () => _verificarRespuesta('Juan'),
                            ),
                          ),
                          SizedBox(width: hPad * 0.5),
                          Expanded(
                            child: _SelectionButton(
                              nombre: 'Sara',
                              imagePath:
                                  'assets/images/actividades/matematicas/niña.png',
                              color: const Color(0xFFFFC1C1),
                              fontSize: btnFontSz,
                              onTap: state.respondido
                                  ? null
                                  : () => _verificarRespuesta('Sara'),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: screenH * 0.025),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Widgets de apoyo ────────────────────────────────────────────────────────

class _PersonCard extends StatelessWidget {
  const _PersonCard({
    required this.color,
    required this.imagePath,
    required this.cantidadManzanas,
    required this.charSize,
    required this.charOverflow,
    required this.appleSize,
  });

  final Color color;
  final String imagePath;
  final int cantidadManzanas;
  final double charSize;
  final double charOverflow;
  final double appleSize; // igual en ambas tarjetas

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final cardW = constraints.maxWidth;
          final cardH = constraints.maxHeight;

          // Mismo padding que el LayoutBuilder padre para que appleSize sea exacto
          final sidePad = (cardW * 0.04).clamp(4.0, 12.0);
          final topPad = (cardH * 0.03).clamp(6.0, 12.0);
          final bottomPad = (cardH * 0.03).clamp(6.0, 12.0);

          return Stack(
            clipBehavior: Clip.none,
            children: [
              // ── Tarjeta con manzanas ────────────────────────────────────
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(
                      (cardW * 0.08).clamp(16.0, 28.0),
                    ),
                  ),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                        sidePad, topPad, sidePad, bottomPad),
                    child: Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      alignment: WrapAlignment.center,
                      runAlignment: WrapAlignment.center,
                      children: List.generate(
                        cantidadManzanas,
                        (_) => Image.asset(
                          'assets/images/actividades/matematicas/manzana.png',
                          width: appleSize,
                          height: appleSize,
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.high,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // ── Personaje flotando encima del borde superior ────────────
              Positioned(
                top: -charOverflow,
                left: 0,
                right: 0,
                height: charSize,
                child: Center(
                  child: Image.asset(
                    imagePath,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SelectionButton extends StatelessWidget {
  const _SelectionButton({
    required this.nombre,
    required this.imagePath,
    required this.color,
    required this.fontSize,
    required this.onTap,
  });

  final String nombre;
  final String imagePath;
  final Color color;
  final double fontSize;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        opacity: onTap == null ? 0.45 : 1.0,
        duration: const Duration(milliseconds: 300),
        child: Container(
          width: double.infinity,
          height: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                nombre,
                style: TextStyle(
                  fontSize: fontSize,
                  fontFamily: 'Hiruko',
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Expanded(
                child: Image.asset(
                  imagePath,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
