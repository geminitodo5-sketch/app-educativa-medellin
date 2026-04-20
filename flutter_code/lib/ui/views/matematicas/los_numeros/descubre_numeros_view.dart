import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/providers/app_state_provider.dart';
import '../../../viewmodels/descubre_numeros_view_model.dart';
import 'descubre_numeros_view_2.dart';

/// Vista para la actividad "Descubre los números"
/// Manual de marca Numi: Hiruko (decorativa/títulos) + Poppins (principal/textos)
/// Colores: Azul #3475F7, Cian #1EB9D8, Verde #59E347, Rojo #F65757
class DescubreNumerosView extends ConsumerWidget {
  const DescubreNumerosView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vm = ref.watch(descubreNumerosViewModelProvider);
    final notifier = ref.read(descubreNumerosViewModelProvider.notifier);

    return Scaffold(
      backgroundColor: const Color(0xFF3475F7),
      body: SafeArea(
        top: false,
        bottom: false,
        child: Column(
          children: [
            // ── ENCABEZADO ──────────────────────────────────────────────
            _Header(
              onClose: () => Navigator.of(context).pop(),
              progreso: 0.33, // Fase 1 de 3
            ),

            // ── CUERPO PRINCIPAL ────────────────────────────────────────
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Color(0xFFF5F7FF),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(40),
                    topRight: Radius.circular(40),
                  ),
                ),
                child: Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Tarjeta de instrucción
                            _InstruccionCard(
                              numeroObjetivo: vm.numeroObjetivo,
                              onAudio: notifier.commandReproducirInstruccion,
                            ),
                            const SizedBox(height: 28),

                            // Sección: fresas disponibles
                            const _SeccionLabel(texto: 'Arrastra las fresas'),
                            const SizedBox(height: 14),
                            _GrillaFresas(
                              totalDisponibles: vm.totalFresasDisponibles,
                              enCuadro: vm.fresasEnCuadro.length,
                              verificado: vm.verificado,
                            ),
                            const SizedBox(height: 28),

                            // Sección: recuadro destino
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const _SeccionLabel(texto: 'Tu recuadro'),
                                // Botón de quitar (accesible para touch)
                                if (vm.fresasEnCuadro.isNotEmpty && !vm.verificado)
                                  GestureDetector(
                                    onTap: notifier.commandQuitarFresa,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFFEDED),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: const Text(
                                        'Quitar última',
                                        style: TextStyle(
                                          fontFamily: 'Poppins',
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFFF65757),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 10),

                            _ZonaDestino(
                              fresasEnCuadro: vm.fresasEnCuadro,
                              verificado: vm.verificado,
                              feedbackEstado: vm.feedback,
                              onAceptar: vm.verificado
                                  ? null
                                  : notifier.commandAgregarFresa,
                            ),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),

                    // ── PANEL DE FEEDBACK (pestaña inferior) ─────────────
                    _FeedbackPanel(
                      estado: vm.feedback,
                      diferencia: vm.diferencia,
                      numeroObjetivo: vm.numeroObjetivo,
                      fresasEnCuadro: vm.fresasEnCuadro.length,
                      onVerificar: vm.fresasEnCuadro.isNotEmpty && !vm.verificado
                          ? notifier.commandVerificar
                          : null,
                      onNuevoReto: () => Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => const DescubreNumerosView2()),
                      ),
                      onIntentarDeNuevo: notifier.commandIntentarDeNuevo,
                    ),
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

// ────────────────────────────────────────────────────────────────────────────
// WIDGETS INTERNOS
// ────────────────────────────────────────────────────────────────────────────

/// Encabezado azul con título y botón cerrar
class _Header extends ConsumerWidget {
  final VoidCallback onClose;
  final double progreso;
  const _Header({super.key, required this.onClose, required this.progreso});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncState = ref.watch(syncListenerProvider);
    final estudiante = ref.watch(estudianteActivoProvider);

    return SizedBox(
      height: 150,
      width: double.infinity,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Indicador de Sincronización (Offline/Sync status)
          Positioned(
            top: 12,
            left: 20,
            child: syncState.when(
              data: (count) => Icon(
                count > 0 ? Icons.sync_rounded : Icons.cloud_done_rounded,
                color: Colors.white.withOpacity(0.7),
                size: 22,
              ),
              error: (_, __) => const Icon(Icons.cloud_off_rounded, color: Colors.white30, size: 22),
              loading: () => const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white30)),
            ),
          ),

          // Título centrado — Hiruko (tipografía decorativa Numi)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 60),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Descubre  los números',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Hiruko',
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1.2,
                  ),
                ),
                if (estudiante != null)
                  Text(
                    '¡Hola, ${estudiante.nombre}!',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
              ],
            ),
          ),

          // Botón X arriba a la derecha
          Positioned(
            top: 12,
            right: 8,
            child: IconButton(
              icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
              onPressed: onClose,
            ),
          ),

          // Barra de progreso — Numi Verde #59E347
          Positioned(
            bottom: 15,
            left: 45,
            right: 45,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: progreso,
                backgroundColor: Colors.white.withOpacity(0.15),
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF59E347)),
                minHeight: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Tarjeta blanca con instrucción + botón de audio
class _InstruccionCard extends StatelessWidget {
  final int numeroObjetivo;
  final VoidCallback onAudio;

  const _InstruccionCard({
    required this.numeroObjetivo,
    required this.onAudio,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3475F7).withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Botón de audio
          GestureDetector(
            onTap: onAudio,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFEEF2FF),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.volume_up_rounded,
                color: Color(0xFF3475F7),
                size: 26,
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Texto instrucción — Poppins (tipografía principal Numi)
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B),
                  height: 1.3,
                ),
                children: [
                  const TextSpan(text: 'Coloca '),
                  TextSpan(
                    text: '$numeroObjetivo',
                    style: const TextStyle(
                      color: Color(0xFF3475F7),
                      fontWeight: FontWeight.w800,
                      fontSize: 19,
                    ),
                  ),
                  TextSpan(
                    text: numeroObjetivo == 1 ? ' fresa' : ' fresas',
                  ),
                  const TextSpan(text: ' en el cuadro'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Etiqueta de sección — Hiruko bold
class _SeccionLabel extends StatelessWidget {
  final String texto;
  const _SeccionLabel({required this.texto});

  @override
  Widget build(BuildContext context) {
    return Text(
      texto,
      style: const TextStyle(
        fontFamily: 'Hiruko',
        fontSize: 17,
        fontWeight: FontWeight.bold,
        color: Color(0xFF1E293B),
      ),
    );
  }
}

/// Grilla de fresas arrastrables
/// Muestra en gris las que ya están en el cuadro
class _GrillaFresas extends StatelessWidget {
  final int totalDisponibles;
  final int enCuadro;
  final bool verificado;

  const _GrillaFresas({
    required this.totalDisponibles,
    required this.enCuadro,
    required this.verificado,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 14,
      runSpacing: 14,
      children: List.generate(totalDisponibles, (index) {
        final usada = index < enCuadro;
        return _FresaArrastrable(usada: usada, desactivada: verificado || usada);
      }),
    );
  }
}

/// Fresa individual arrastrable
class _FresaArrastrable extends StatelessWidget {
  final bool usada;
  final bool desactivada;

  const _FresaArrastrable({required this.usada, required this.desactivada});

  @override
  Widget build(BuildContext context) {
    final widget = Opacity(
      opacity: usada ? 0.25 : 1.0,
      child: Image.asset(
        'assets/images/actividades/matematicas/fresa.png',
        width: 55,
        height: 55,
        fit: BoxFit.contain,
      ),
    );

    if (desactivada) return widget;

    return Draggable<int>(
      data: 1,
      feedback: Material(
        color: Colors.transparent,
        child: Transform.scale(
          scale: 1.2,
          child: Image.asset(
            'assets/images/actividades/matematicas/fresa.png',
            width: 55,
            height: 55,
            fit: BoxFit.contain,
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.2,
        child: Image.asset(
          'assets/images/actividades/matematicas/fresa.png',
          width: 55,
          height: 55,
        ),
      ),
      child: widget,
    );
  }
}

/// Zona destino del drag-and-drop
class _ZonaDestino extends StatelessWidget {
  final List<Key> fresasEnCuadro;
  final bool verificado;
  final FeedbackEstado feedbackEstado;
  final VoidCallback? onAceptar;

  const _ZonaDestino({
    required this.fresasEnCuadro,
    required this.verificado,
    required this.feedbackEstado,
    required this.onAceptar,
  });

  Color get _borderColor {
    switch (feedbackEstado) {
      case FeedbackEstado.correcto:
        return const Color(0xFF59E347);
      case FeedbackEstado.incorrecto:
        return const Color(0xFFF65757);
      case FeedbackEstado.esperando:
        return const Color(0xFF3475F7);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DragTarget<int>(
      onWillAcceptWithDetails: (_) => !verificado,
      onAcceptWithDetails: (_) => onAceptar?.call(),
      builder: (context, candidateData, rejectedData) {
        final estaSobreZona = candidateData.isNotEmpty;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          constraints: const BoxConstraints(minHeight: 120),
          width: double.infinity,
          decoration: BoxDecoration(
            color: estaSobreZona
                ? const Color(0xFFEEF2FF)
                : Colors.white,
            border: Border.all(
              color: estaSobreZona
                  ? const Color(0xFF1EB9D8)
                  : _borderColor,
              width: 2.5,
              strokeAlign: BorderSide.strokeAlignInside,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: fresasEnCuadro.isEmpty
              ? const Center(
                  child: Text(
                    '+ Aquí',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      color: Color(0xFFADB5BD),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(12),
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    runAlignment: WrapAlignment.center,
                    spacing: 6,
                    runSpacing: 6,
                    children: fresasEnCuadro
                        .map(
                          (key) => Image.asset(
                            'assets/images/actividades/matematicas/fresa.png',
                            key: key,
                            width: 46,
                            height: 46,
                            fit: BoxFit.contain,
                          ),
                        )
                        .toList(),
                  ),
                ),
        );
      },
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// PANEL DE FEEDBACK (pestaña inferior)
// ────────────────────────────────────────────────────────────────────────────

class _FeedbackPanel extends StatelessWidget {
  final FeedbackEstado estado;
  final int diferencia;
  final int numeroObjetivo;
  final int fresasEnCuadro;
  final VoidCallback? onVerificar;
  final VoidCallback onNuevoReto;
  final VoidCallback onIntentarDeNuevo;

  const _FeedbackPanel({
    required this.estado,
    required this.diferencia,
    required this.numeroObjetivo,
    required this.fresasEnCuadro,
    required this.onVerificar,
    required this.onNuevoReto,
    required this.onIntentarDeNuevo,
  });

  // ── Colores según estado
  Color get _bgColor {
    switch (estado) {
      case FeedbackEstado.correcto:
        return const Color(0xFF59E347); // Verde Numi
      case FeedbackEstado.incorrecto:
        return const Color(0xFFF65757); // Rojo Numi
      case FeedbackEstado.esperando:
        return Colors.white;
    }
  }

  Color get _textColor {
    return estado == FeedbackEstado.esperando
        ? const Color(0xFF94A3B8)
        : Colors.white;
  }

  String get _mensajeFeedback {
    switch (estado) {
      case FeedbackEstado.correcto:
        return '¡Excelente! Pusiste exactamente '
            '$numeroObjetivo ${numeroObjetivo == 1 ? "fresa" : "fresas"}. ¡Muy bien!';
      case FeedbackEstado.incorrecto:
        if (diferencia < 0) {
          // faltan fresas
          final faltan = diferencia.abs();
          return 'Casi... Te ${faltan == 1 ? "falta" : "faltan"} $faltan '
              '${faltan == 1 ? "fresa" : "fresas"}. ¡Inténtalo de nuevo!';
        } else {
          // sobran fresas
          return 'Pusiste $diferencia de más. Recuerda: solo $numeroObjetivo '
              '${numeroObjetivo == 1 ? "fresa" : "fresas"}.';
        }
      case FeedbackEstado.esperando:
        return fresasEnCuadro > 0
            ? 'Tienes $fresasEnCuadro ${fresasEnCuadro == 1 ? "fresa" : "fresas"}. '
              'Presiona verificar cuando estés listo.'
            : 'Arrastra las fresas al recuadro.';
    }
  }

  String get _iconoFeedback {
    switch (estado) {
      case FeedbackEstado.correcto:
        return '⭐';
      case FeedbackEstado.incorrecto:
        return '💡';
      case FeedbackEstado.esperando:
        return '🍓';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      width: double.infinity,
      decoration: BoxDecoration(
        color: _bgColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        18,
        20,
        MediaQuery.of(context).padding.bottom + 18,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Fila de ícono + mensaje ──────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Ícono en círculo
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: estado == FeedbackEstado.esperando
                      ? const Color(0xFFEEF2FF)
                      : Colors.white.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    _iconoFeedback,
                    style: const TextStyle(fontSize: 22),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Mensaje
              Expanded(
                child: Text(
                  _mensajeFeedback,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _textColor,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Botón principal ──────────────────────────────────────
          if (estado == FeedbackEstado.esperando)
            _BotonPrincipal(
              texto: 'Verificar respuesta',
              color: const Color(0xFF3475F7),
              textColor: Colors.white,
              habilitado: onVerificar != null,
              onTap: onVerificar ?? () {},
            )
          else if (estado == FeedbackEstado.correcto) ...[
            _BotonPrincipal(
              texto: '¡Siguiente fase! →',
              color: Colors.white,
              textColor: const Color(0xFF59E347),
              habilitado: true,
              onTap: onNuevoReto, // Ahora navega a la vista 2
            ),
          ] else ...[
            _BotonPrincipal(
              texto: 'Intentar de nuevo',
              color: Colors.white,
              textColor: const Color(0xFFF65757),
              habilitado: true,
              onTap: onIntentarDeNuevo,
            ),
            const SizedBox(height: 10),
            _BotonSecundario(
              texto: 'Cambiar reto',
              color: Colors.white.withOpacity(0.25),
              textColor: Colors.white,
              onTap: onNuevoReto,
            ),
          ],
        ],
      ),
    );
  }
}

/// Botón primario redondeado
class _BotonPrincipal extends StatelessWidget {
  final String texto;
  final Color color;
  final Color textColor;
  final bool habilitado;
  final VoidCallback onTap;

  const _BotonPrincipal({
    required this.texto,
    required this.color,
    required this.textColor,
    required this.habilitado,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: AnimatedOpacity(
        opacity: habilitado ? 1.0 : 0.45,
        duration: const Duration(milliseconds: 200),
        child: ElevatedButton(
          onPressed: habilitado ? onTap : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: textColor,
            disabledBackgroundColor: color.withOpacity(0.6),
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: Text(
            texto,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

/// Botón secundario más pequeño
class _BotonSecundario extends StatelessWidget {
  final String texto;
  final Color color;
  final Color textColor;
  final VoidCallback onTap;

  const _BotonSecundario({
    required this.texto,
    required this.color,
    required this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          backgroundColor: color,
          foregroundColor: textColor,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Text(
          texto,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}