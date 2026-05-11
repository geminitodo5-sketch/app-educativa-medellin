import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../viewmodels/palabra_loca_3_view_model.dart';

class OracionesActivity extends ConsumerStatefulWidget {
  const OracionesActivity({super.key});

  @override
  ConsumerState<OracionesActivity> createState() => _OracionesActivityState();
}

class _OracionesActivityState extends ConsumerState<OracionesActivity>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _scaleAnim =
        CurvedAnimation(parent: _animController, curve: Curves.elasticOut);
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _mostrarDialogoFinal(WidgetRef ref) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          '¡Felicitaciones! 🎉',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        content: const Text(
          'Completaste todos los ejercicios.',
          textAlign: TextAlign.center,
          style: TextStyle(fontFamily: 'Poppins', fontSize: 15),
        ),
        actions: [
          Center(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1EB9D8),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                ref.read(oracionesViewModelProvider.notifier).commandReiniciar();
              },
              child: const Text(
                'Volver a empezar',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(oracionesViewModelProvider);
    final notifier = ref.read(oracionesViewModelProvider.notifier);
    final ejercicio = notifier.currentEjercicio;

    if (state.juegoFinalizado) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _mostrarDialogoFinal(ref);
      });
    }

    if (state.mostrandoResultado) {
      _animController.forward();
    } else {
      _animController.reset();
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF65757), // Rojo Numi
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ① Header (130 de alto)
            _buildHeader(),

            // ② Panel Blanco Redondeado
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
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            _buildSeccionImagen(ejercicio),
                            const SizedBox(height: 10),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              child: Column(
                                children: [
                                  _buildZonaRespuesta(state, notifier, ejercicio),
                                  const SizedBox(height: 10),
                                  
                                ],
                              ),
                            ),
                            const SizedBox(height: 30),
                            _buildBancoPalabras(state, notifier),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
                    _buildBotones(state, notifier),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Widgets ──────────────────────────────────────────────────

  Widget _buildHeader() {
    return Container(
      height: 130,
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

  Widget _buildSeccionImagen(OracionEjercicio ejercicio) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.volume_up_rounded,
                color: Color(0xFFF65757),
                size: 26,
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

          const SizedBox(height: 16),
          SizedBox(
            height: 180,
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

  Widget _chipPalabra(int index, OracionesEstado state, OracionesViewModel notifier) {
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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