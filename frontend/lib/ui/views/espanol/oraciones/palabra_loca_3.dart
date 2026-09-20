import 'dart:math' show min;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import '../../../viewmodels/palabra_loca_3_view_model.dart';
import '../../terminado.dart';
import '../../../../data/services/feedback_sounds.dart';

class OracionesActivity extends ConsumerStatefulWidget {
  const OracionesActivity({super.key});

  @override
  ConsumerState<OracionesActivity> createState() => _OracionesActivityState();
}

class _OracionesActivityState extends ConsumerState<OracionesActivity> {
  late final AudioPlayer _player;

  bool _navegandoATerminado = false;
  bool _feedbackMostrado    = false;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _reproducirAudio();
  }

  Future<void> _reproducirAudio() async {
    try {
      await _player.setAsset('assets/Audio/espanol/audio_espanol4_mezcla.mp3');
      await _player.play();
    } catch (e) {
      debugPrint("Error de audio: $e");
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  void _irATerminado() {
    if (_navegandoATerminado || !mounted) return;
    _navegandoATerminado = true;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ActividadTerminadaScreen(
          onVolver: () {
            final nav = Navigator.of(context);
            nav.pop();
            nav.pop();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(oracionesViewModelProvider);
    final notifier = ref.read(oracionesViewModelProvider.notifier);
    final ejercicio = notifier.currentEjercicio;

    if (state.juegoFinalizado) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _irATerminado());
    }

    if (state.mostrandoResultado && !_feedbackMostrado) {
      _feedbackMostrado = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _mostrarFeedback(
          state.respuestaCorrecta,
          state.respuestaCorrecta
              ? notifier.commandSiguiente
              : notifier.commandReiniciar,
        );
      });
    }
    if (!state.mostrandoResultado) _feedbackMostrado = false;

    return Scaffold(
      backgroundColor: const Color(0xFFF65757),
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(state),
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(40),
                    topRight: Radius.circular(40),
                  ),
                ),
                child: Column(
                  children: [

                    // ── Instrucción (fija arriba) ──────────────────────────
                    Padding(
                      // ── MARGEN SUPERIOR instrucción: cambia el 20 ─────────
                      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: _reproducirAudio,
                            child: _AudioBtn(sw: MediaQuery.of(context).size.width),
                          ),
                          SizedBox(width: (MediaQuery.of(context).size.width * 0.03).clamp(8.0, 16.0)),
                          Expanded(
                            child: Text(
                              'Ordena  las palabras y forma  la oración.',
                              style: TextStyle(
                                fontFamily: 'Hiruko',
                                fontSize: (MediaQuery.of(context).size.width * 0.065).clamp(20.0, 46.0),
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ── Zona central centrada: imagen + respuesta ──────────
                    Expanded(
                      child: LayoutBuilder(
                        builder: (ctx, constraints) {
                          final imgH = min(constraints.maxHeight * 0.60, MediaQuery.of(ctx).size.width * 0.78).clamp(150.0, 360.0);
                          final gap = (constraints.maxHeight * 0.05).clamp(12.0, 28.0);
                          return Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                height: imgH,
                                child: Center(
                                  child: Image.asset(
                                    ejercicio.imagenAsset,
                                    fit: BoxFit.contain,
                                    errorBuilder: (_, _, _) => Container(
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        color: Colors.grey[200],
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: const Icon(Icons.image_not_supported,
                                          size: 70, color: Colors.grey),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: gap),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                child: _buildZonaRespuesta(state, notifier, ejercicio),
                              ),
                            ],
                          );
                        },
                      ),
                    ),

                    // ── Banco de palabras (fijo abajo) ────────────────────
                    // ── ESPACIO zona respuesta → palabras: cambia 16 ──────
                    const SizedBox(height: 16),
                    _buildBancoPalabras(state, notifier),
                    // ── ESPACIO palabras → botón: cambia 20 ───────────────
                    const SizedBox(height: 20),
                    _buildBotones(state, notifier),
                    // ── ESPACIO inferior: cambia 28 ───────────────────────
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

  Widget _buildHeader(OracionesEstado state) {
    final sw = MediaQuery.of(context).size.width;
    final progress = (state.ejercicioActual + 1) / 4;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 4, 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(width: 48),
              Text(
                'Oraciones',
                style: TextStyle(
                  fontFamily: 'Hiruko',
                  fontSize: (sw * 0.07).clamp(26.0, 46.0),
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 28),
                onPressed: () => Navigator.of(context).maybePop(),
              ),
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(sw * 0.08, 0, sw * 0.08, 12),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.white30,
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF59E347)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildZonaRespuesta(
    OracionesEstado state,
    OracionesViewModel notifier,
    OracionEjercicio ejercicio,
  ) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: List.generate(
        state.respuestaUsuario.length,
        (i) => _slotRespuesta(i, state, notifier, ejercicio),
      ),
    );
  }

  Widget _slotRespuesta(int index, OracionesEstado state,
      OracionesViewModel notifier, OracionEjercicio ejercicio) {
    final palabra = state.respuestaUsuario[index];
    Color? colorFeedback;
    if (state.mostrandoResultado) {
      colorFeedback = (palabra == ejercicio.respuestaCorrecta[index])
          ? const Color(0xFF59E347)
          : const Color(0xFFF65757);
    }

    final sw = MediaQuery.of(context).size.width;
    final fontSize = (sw * 0.048).clamp(15.0, 26.0);
    final hPad = (sw * 0.035).clamp(10.0, 22.0);
    final vPad = (sw * 0.025).clamp(8.0, 14.0);
    return GestureDetector(
      onTap: () => notifier.commandDevolverPalabra(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        constraints: BoxConstraints(minWidth: (sw * 0.14).clamp(44.0, 80.0)),
        padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
        decoration: BoxDecoration(
          color: palabra != null
              ? (colorFeedback?.withValues(alpha: 0.15) ??
                  const Color(0xFF1EB9D8).withValues(alpha: 0.12))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border(
            bottom: BorderSide(
              color: colorFeedback ?? Colors.grey[400]!,
              width: 2.5,
            ),
          ),
        ),
        child: Text(
          palabra ?? '',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
            color: colorFeedback ?? const Color(0xFF3475F7),
          ),
        ),
      ),
    );
  }

  Widget _buildBancoPalabras(OracionesEstado state, OracionesViewModel notifier) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        alignment: WrapAlignment.center,
        children: List.generate(
          state.palabrasDisponibles.length,
          (i) => _chipPalabra(i, state, notifier),
        ),
      ),
    );
  }

  Widget _chipPalabra(
      int index, OracionesEstado state, OracionesViewModel notifier) {
    final palabra = state.palabrasDisponibles[index];
    final disponible = palabra != null;

    final sw = MediaQuery.of(context).size.width;
    final chipFontSize = (sw * 0.048).clamp(15.0, 26.0);
    final chipHPad = (sw * 0.048).clamp(14.0, 28.0);
    final chipVPad = (sw * 0.03).clamp(10.0, 18.0);
    return GestureDetector(
      onTap: disponible ? () => notifier.commandSeleccionarPalabra(index) : null,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: disponible ? 1.0 : 0.0,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: chipHPad, vertical: chipVPad),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.07),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Text(
            palabra ?? '',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: chipFontSize,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBotones(OracionesEstado state, OracionesViewModel notifier) {
    final todoLleno = state.respuestaUsuario.every((p) => p != null);
    final sw  = MediaQuery.of(context).size.width;
    final btnH = (sw * 0.13).clamp(48.0, 72.0);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: ElevatedButton(
        onPressed: todoLleno ? notifier.commandVerificar : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFF65757),
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.grey[300],
          minimumSize: Size(double.infinity, btnH),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 2,
        ),
        child: const Text(
          'Comprobar',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  void _mostrarFeedback(bool esCorrecto, VoidCallback onAction) {
    FeedbackSounds.instance.reproducir(esCorrecto);
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
                  color: esCorrecto
                      ? const Color(0xFF59E347)
                      : const Color(0xFFF65757),
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
}

class _AudioBtn extends StatelessWidget {
  final double sw;
  const _AudioBtn({required this.sw});

  @override
  Widget build(BuildContext context) {
    final sz = (sw * 0.12).clamp(42.0, 64.0);
    return Container(
      width: sz,
      height: sz,
      decoration: BoxDecoration(
        color: const Color(0xFFFFEEEE),
        borderRadius: BorderRadius.circular(sz * 0.27),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF65757).withValues(alpha: 0.15),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Icon(
        Icons.volume_up_rounded,
        color: const Color(0xFFF65757),
        size: sz * 0.55,
      ),
    );
  }
}