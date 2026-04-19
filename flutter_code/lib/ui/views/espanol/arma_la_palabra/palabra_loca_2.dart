import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../viewmodels/palabra_loca_view_model.dart';
import '../../terminado.dart';

class ArmaLaPalabraScreen extends ConsumerStatefulWidget {
  const ArmaLaPalabraScreen({super.key});

  @override
  ConsumerState<ArmaLaPalabraScreen> createState() =>
      _ArmaLaPalabraScreenState();
}

class _ArmaLaPalabraScreenState extends ConsumerState<ArmaLaPalabraScreen>
    with TickerProviderStateMixin {
  late AnimationController _successController;
  late Animation<double> _successScale;
  late AnimationController _errorController;
  late Animation<double> _errorShake;

  bool _navegandoATerminado = false;

  @override
  void initState() {
    super.initState();

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

  @override
  void dispose() {
    _successController.dispose();
    _errorController.dispose();
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
            nav.pop(); // cierra terminado
            nav.pop(); // cierra ArmaLaPalabraScreen
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
        _errorController.reset();
        _successController.forward();
      }
      if (!prev.error && next.error) {
        _successController.reset();
        _errorController.forward().then((_) {
          notifier.commandLimpiarError();
        });
      }
      if (prev.palabraIndex != next.palabraIndex) {
        _successController.reset();
        _errorController.reset();
      }
      if (!prev.actividadCompletada && next.actividadCompletada) {
        WidgetsBinding.instance
            .addPostFrameCallback((_) => _irATerminado());
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF65757),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _Header(onClose: () => Navigator.maybePop(context)),
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
                child: Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          children: [
                            const SizedBox(height: 32),
                            const _InstruccionRow(
                              texto: 'Arma la palabra de la imagen.',
                            ),
                            const SizedBox(height: 32),
                            _ImagenAnimal(
                              asset: palabra.imagenAsset,
                              completado: state.completado,
                              error: state.error,
                              scaleAnimation: _successScale,
                            ),
                            const SizedBox(height: 40),
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
                                opcionesMezcladas: palabra.opcionesMezcladas,
                                opcionesDisponibles: state.opcionesDisponibles,
                                onColocarSilaba:
                                    (state.completado || state.error)
                                        ? null
                                        : notifier.commandColocarSilaba,
                                onQuitarSilaba:
                                    (state.completado || state.error)
                                        ? null
                                        : notifier.commandQuitarSilaba,
                              ),
                            ),
                            const SizedBox(height: 16),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              transitionBuilder: (child, anim) =>
                                  SlideTransition(
                                position: Tween<Offset>(
                                  begin: const Offset(0, 0.3),
                                  end: Offset.zero,
                                ).animate(anim),
                                child: FadeTransition(
                                    opacity: anim, child: child),
                              ),
                              child: state.error
                                  ? _BannerError(
                                      key: const ValueKey('error'),
                                      onIntentar:
                                          notifier.commandLimpiarRespuestas,
                                    )
                                  : const SizedBox.shrink(
                                      key: ValueKey('empty'),
                                    ),
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ),
                    if (state.completado)
                      _BotonSiguiente(
                        onTap: () {
                          _successController.reset();
                          notifier.commandSiguientePalabra();
                        },
                      )
                    else
                      _GridSilabas(
                        opciones: palabra.opcionesMezcladas,
                        disponibles: state.opcionesDisponibles,
                        silabasColocadas: state.silabasColocadas,
                        cantidadRecuadros: palabra.silabas.length,
                        onTap: notifier.commandColocarSilaba,
                      ),
                    const SizedBox(height: 24),
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

// ══════════════════════════════════════════════════════════
// Widgets auxiliares
// ══════════════════════════════════════════════════════════

class _Header extends StatelessWidget {
  final VoidCallback onClose;
  const _Header({required this.onClose});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 180,
      width: double.infinity,
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Text(
            'Arma la palabra',
            style: TextStyle(
              fontFamily: 'Hiruko',
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: 0.2,
            ),
          ),
          Positioned(
            top: 12,
            right: 8,
            child: IconButton(
              icon: const Icon(Icons.close_rounded,
                  color: Colors.white, size: 28),
              onPressed: onClose,
            ),
          ),
        ],
      ),
    );
  }
}

class _InstruccionRow extends StatelessWidget {
  final String texto;
  const _InstruccionRow({required this.texto});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFF0F4FF),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.volume_up_rounded,
              color: Color(0xFF3475F7), size: 22),
        ),
        const SizedBox(width: 10),
        Text(
          texto,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: Color(0xFF444444),
          ),
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

  const _ImagenAnimal({
    required this.asset,
    required this.completado,
    required this.error,
    required this.scaleAnimation,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: completado ? (0.9 + 0.1 * scaleAnimation.value) : 1.0,
          child: child,
        );
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: error ? 172 : 0,
            height: error ? 172 : 0,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFFFEBEB),
              border: error
                  ? Border.all(color: const Color(0xFFFF5252), width: 3)
                  : null,
            ),
          ),
          Image.asset(
            asset,
            width: 160,
            height: 160,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.pets, size: 80, color: Color(0xFFCCCCCC)),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecuadrosRespuesta extends StatelessWidget {
  final List<String?> silabas;
  final int cantidadSilabas;
  final bool completado;
  final bool error;
  final List<String> opcionesMezcladas;
  final List<bool> opcionesDisponibles;
  final void Function(int opcionIndex, int recuadroIndex)? onColocarSilaba;
  final void Function(int recuadroIndex)? onQuitarSilaba;

  const _RecuadrosRespuesta({
    required this.silabas,
    required this.cantidadSilabas,
    required this.completado,
    required this.error,
    required this.opcionesMezcladas,
    required this.opcionesDisponibles,
    required this.onColocarSilaba,
    required this.onQuitarSilaba,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(cantidadSilabas, (i) {
        final silabaActual = silabas[i];
        final estaLleno = silabaActual != null;

        final Color lineaColor = completado
            ? const Color(0xFF4CAF50)
            : error
                ? const Color(0xFFFF5252)
                : const Color(0xFF9E9E9E);
        final Color bgColor = completado
            ? const Color(0xFFE8F8EE)
            : error
                ? const Color(0xFFFFEBEB)
                : estaLleno
                    ? Colors.white
                    : Colors.transparent;
        final Color textColor = completado
            ? const Color(0xFF2E7D32)
            : error
                ? const Color(0xFFD32F2F)
                : const Color(0xFF222222);

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: DragTarget<int>(
            onWillAcceptWithDetails: (details) =>
                !completado && !error && opcionesDisponibles[details.data],
            onAcceptWithDetails: (details) {
              onColocarSilaba?.call(details.data, i);
            },
            builder: (context, candidateData, rejectedData) {
              final isHovered = candidateData.isNotEmpty;
              return GestureDetector(
                onTap: (estaLleno && !completado && !error)
                    ? () => onQuitarSilaba?.call(i)
                    : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: 72,
                  height: 52,
                  decoration: BoxDecoration(
                    color: isHovered ? const Color(0xFFEEF4FF) : bgColor,
                    border: Border(
                      bottom: BorderSide(
                        color: isHovered
                            ? const Color(0xFF3475F7)
                            : lineaColor,
                        width: 2.5,
                      ),
                    ),
                    borderRadius: (estaLleno || isHovered)
                        ? BorderRadius.circular(10)
                        : null,
                    boxShadow: estaLleno
                        ? [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.06),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: estaLleno
                      ? Stack(
                          alignment: Alignment.center,
                          clipBehavior: Clip.none,
                          children: [
                            Text(
                              silabaActual,
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: textColor,
                              ),
                            ),
                            if (!completado && !error)
                              Positioned(
                                top: -4,
                                right: -4,
                                child: Container(
                                  width: 16,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade400,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.close,
                                      size: 10, color: Colors.white),
                                ),
                              ),
                          ],
                        )
                      : null,
                ),
              );
            },
          ),
        );
      }),
    );
  }
}

class _BannerError extends StatelessWidget {
  final VoidCallback onIntentar;
  const _BannerError({super.key, required this.onIntentar});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEBEB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFF5252), width: 1.5),
      ),
      child: Row(
        children: [
          const Icon(Icons.sentiment_dissatisfied_rounded,
              color: Color(0xFFD32F2F), size: 28),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              '¡Casi! Toca una sílaba\npara quitarla e intentar de nuevo.',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFFD32F2F),
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onIntentar,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFD32F2F),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Reintentar',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GridSilabas extends StatelessWidget {
  final List<String> opciones;
  final List<bool> disponibles;
  final List<String?> silabasColocadas;
  final int cantidadRecuadros;
  final void Function(int opcionIndex, int recuadroIndex) onTap;

  const _GridSilabas({
    required this.opciones,
    required this.disponibles,
    required this.silabasColocadas,
    required this.cantidadRecuadros,
    required this.onTap,
  });

  int? get _primerRecuadroVacio {
    for (int i = 0; i < silabasColocadas.length; i++) {
      if (silabasColocadas[i] == null) return i;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE0E0E0), width: 1.5),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        alignment: WrapAlignment.center,
        children: List.generate(opciones.length, (i) {
          final disponible = disponibles[i];
          final silaba = opciones[i];

          return Draggable<int>(
            data: i,
            feedback: Material(
              color: Colors.transparent,
              child: _SilabaChip(
                texto: silaba,
                disponible: true,
                isDragging: true,
              ),
            ),
            childWhenDragging: _SilabaChip(
              texto: silaba,
              disponible: false,
              isDragging: false,
              isPlaceholder: true,
            ),
            child: GestureDetector(
              onTap: disponible
                  ? () {
                      final recuadro = _primerRecuadroVacio;
                      if (recuadro != null) onTap(i, recuadro);
                    }
                  : null,
              child: _SilabaChip(
                texto: silaba,
                disponible: disponible,
                isDragging: false,
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _SilabaChip extends StatelessWidget {
  final String texto;
  final bool disponible;
  final bool isDragging;
  final bool isPlaceholder;

  const _SilabaChip({
    required this.texto,
    required this.disponible,
    required this.isDragging,
    this.isPlaceholder = false,
  });

  @override
  Widget build(BuildContext context) {
    final Color bgColor = isPlaceholder
        ? const Color(0xFFF5F5F5)
        : disponible
            ? Colors.white
            : const Color(0xFFF0F0F0);
    final Color textColor = isPlaceholder
        ? Colors.transparent
        : disponible
            ? const Color(0xFF222222)
            : const Color(0xFFBBBBBB);
    final List<BoxShadow> shadows = isDragging
        ? [
            BoxShadow(
              color: Colors.black.withOpacity(0.18),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ]
        : disponible && !isPlaceholder
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ]
            : [];

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: 72,
      height: 52,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isPlaceholder
              ? const Color(0xFFE0E0E0)
              : disponible
                  ? const Color(0xFFDDDDDD)
                  : const Color(0xFFEEEEEE),
          width: 1.5,
        ),
        boxShadow: shadows,
      ),
      alignment: Alignment.center,
      child: Text(
        texto,
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 19,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }
}

class _BotonSiguiente extends StatelessWidget {
  final VoidCallback onTap;
  const _BotonSiguiente({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF4CAF50).withOpacity(0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Text(
                '¡Muy bien! Siguiente',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: 8),
              Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}
