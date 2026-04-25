import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import '../../../viewmodels/palabra_loca_3_view_model.dart';
import '../../terminado.dart';

class OracionesActivity extends ConsumerStatefulWidget {
  const OracionesActivity({super.key});

  @override
  ConsumerState<OracionesActivity> createState() => _OracionesActivityState();
}

class _OracionesActivityState extends ConsumerState<OracionesActivity>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnim;
  late final Player _player;

  bool _navegandoATerminado = false;

  @override
  void initState() {
    super.initState();
    _player = Player();
    _reproducirAudio();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _scaleAnim =
        CurvedAnimation(parent: _animController, curve: Curves.elasticOut);
  }

  Future<void> _reproducirAudio() async {
    try {
      await _player.open(
        Media('asset:///assets/Audio/espanol/audio_espanol4_mezcla.mp3'),
      );
    } catch (e) {
      debugPrint("Error de audio: $e");
    }
  }

  @override
  void dispose() {
    _player.dispose();
    _animController.dispose();
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

    if (state.mostrandoResultado) {
      _animController.forward();
    } else {
      _animController.reset();
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF65757),
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(),
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
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF0F4FF),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.volume_up_rounded,
                                color: Color(0xFF3475F7),
                                size: 26,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Ordena las palabras y forma la oración.',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[800],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ── Zona central centrada: imagen + respuesta ──────────
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // ── TAMAÑO IMAGEN: cambia 190 ──────────────────
                          SizedBox(
                            height: 190,
                            child: Center(
                              child: Image.asset(
                                ejercicio.imagenAsset,
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => Container(
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
                          // ── ESPACIO imagen → zona respuesta: cambia 20 ─
                          const SizedBox(height: 20),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: _buildZonaRespuesta(state, notifier, ejercicio),
                          ),
                        ],
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

  Widget _buildHeader() {
    return Container(
      // ── ALTURA HEADER: cambia 80 ───────────────────────────────────────
      height: 80,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Text(
            'Oraciones',
            style: TextStyle(
              fontFamily: 'Hiruko',
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Positioned(
            right: 0,
            child: GestureDetector(
              onTap: () => Navigator.of(context).maybePop(),
              child: const Icon(Icons.close, color: Colors.white, size: 26),
            ),
          ),
        ],
      ),
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

    return GestureDetector(
      onTap: () => notifier.commandDevolverPalabra(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        constraints: const BoxConstraints(minWidth: 56),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: palabra != null
              ? (colorFeedback?.withOpacity(0.15) ??
                  const Color(0xFF1EB9D8).withOpacity(0.12))
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
            fontSize: 16,
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

    return GestureDetector(
      onTap: disponible ? () => notifier.commandSeleccionarPalabra(index) : null,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: disponible ? 1.0 : 0.0,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.07),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Text(
            palabra ?? '',
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBotones(OracionesEstado state, OracionesViewModel notifier) {
    if (state.mostrandoResultado) {
      return ScaleTransition(
        scale: _scaleAnim,
        child: state.respuestaCorrecta
            ? _botonSiguiente(notifier)
            : _botonReintentar(notifier),
      );
    }

    final todoLleno = state.respuestaUsuario.every((p) => p != null);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: ElevatedButton(
        onPressed: todoLleno ? notifier.commandVerificar : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFF65757),
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.grey[300],
          minimumSize: const Size(double.infinity, 52),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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

  Widget _botonSiguiente(OracionesViewModel notifier) {
    return Column(
      children: [
        const Text(
          '¡Muy bien! ✅',
          style: TextStyle(
            fontFamily: 'Poppins',
            color: Color(0xFF2E7D32),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: ElevatedButton(
            onPressed: notifier.commandSiguiente,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF59E347),
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              elevation: 2,
            ),
            child: const Text(
              'Continuar',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _botonReintentar(OracionesViewModel notifier) {
    return Column(
      children: [
        const Text(
          'Inténtalo de nuevo ❌',
          style: TextStyle(
            fontFamily: 'Poppins',
            color: Color(0xFFF65757),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: ElevatedButton(
            onPressed: notifier.commandReiniciar,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF65757),
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              elevation: 2,
            ),
            child: const Text(
              'Reintentar',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }
}