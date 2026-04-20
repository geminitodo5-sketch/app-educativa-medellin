import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/providers/app_state_provider.dart';
import '../../../viewmodels/descubre_bananos_view_model.dart';
import 'descubre_numeros_view_3.dart';

/// Vista de conteo de bananos (Matemáticas)
/// Tipografía Numi: Hiruko (títulos/decorativa) + Poppins (principal/textos)
/// Colores Numi: Azul #3475F7, Verde #59E347, Rojo #F65757, Naranja #EF9325
class DescubreNumerosView2 extends ConsumerWidget {
  const DescubreNumerosView2({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vm = ref.watch(descubreBananosViewModelProvider);
    final notifier = ref.read(descubreBananosViewModelProvider.notifier);

    // Letras para las opciones
    const letras = ['A', 'B', 'C'];

    return Scaffold(
      backgroundColor: const Color(0xFF3475F7),
      body: SafeArea(
        top: false,
        bottom: false,
        child: Column(
          children: [
            // ── ENCABEZADO AZUL ──────────────────────────────────────────
            _Header(
              onClose: () => Navigator.of(context).pop(),
              progreso: 0.66, // Fase 2 de 3
            ),

            // ── CUERPO PRINCIPAL (fondo gris claro) ──────────────────────
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
                        padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ── Tarjeta de instrucción ──────────────────
                            _InstruccionCard(
                              onAudio: notifier.commandReproducirInstruccion,
                            ),
                            const SizedBox(height: 28),

                            // ── Área visual: mono + bananos ─────────────
                            _AreaVisual(cantidadBananos: vm.numeroObjetivo),
                            const SizedBox(height: 32),

                            // ── Etiqueta de opciones ────────────────────
                            const Text(
                              'Elige la respuesta correcta',
                              style: TextStyle(
                                fontFamily: 'Hiruko',
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                            const SizedBox(height: 14),

                            // ── Botones de opción A / B / C ─────────────
                            ...List.generate(vm.opciones.length, (i) {
                              final valor = vm.opciones[i];
                              final letra = letras[i];
                              final seleccionada = vm.opcionSeleccionada == valor;
                              final esCorrecta = valor == vm.numeroObjetivo;

                              return _BotonOpcion(
                                letra: letra,
                                valor: valor,
                                seleccionada: seleccionada,
                                esCorrecta: esCorrecta,
                                yaRespondio: vm.yaRespondio,
                                onTap: vm.yaRespondio
                                    ? null
                                    : () => notifier.commandValidarRespuesta(valor),
                              );
                            }),

                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ),

                    // ── PANEL DE FEEDBACK (pestaña inferior) ─────────────
                    _FeedbackPanel(
                      estado: vm.feedback,
                      numeroObjetivo: vm.numeroObjetivo,
                      onNuevoReto: () => Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => const DescubreGlobosView()),
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

/// Encabezado unificado con barra de progreso y sync status
class _Header extends ConsumerWidget {
  final VoidCallback onClose;
  final double progreso;
  const _Header({required this.onClose, required this.progreso});

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
          Positioned(
            top: 12,
            left: 20,
            child: syncState.when(
              data: (count) => Icon(
                count > 0 ? Icons.sync_rounded : Icons.cloud_done_rounded,
                color: Colors.white.withOpacity(0.7), size: 22,
              ),
              error: (_, __) => const Icon(Icons.cloud_off_rounded, color: Colors.white30, size: 22),
              loading: () => const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white30)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 60),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Descubre  los números',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Hiruko', fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white, height: 1.2,
                  ),
                ),
                if (estudiante != null)
                  Text('Fase: Conteo con Muni', style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: Colors.white.withOpacity(0.9))),
              ],
            ),
          ),
          Positioned(
            top: 12,
            right: 8,
            child: IconButton(
              icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
              onPressed: onClose,
            ),
          ),
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

/// Tarjeta blanca con la pregunta y botón de audio
class _InstruccionCard extends StatelessWidget {
  final VoidCallback onAudio;
  const _InstruccionCard({required this.onAudio});

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
          const Expanded(
            child: Text(
              '¿Cuántos bananos\ntiene Muni?',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E293B),
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Área central con el mono Muni y la cuadrícula de bananos
/// Usa LayoutBuilder para adaptarse al ancho real de la pantalla
class _AreaVisual extends StatelessWidget {
  final int cantidadBananos;
  const _AreaVisual({required this.cantidadBananos});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3475F7).withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // El mono ocupa ~40% del ancho disponible, los bananos el resto
          final monoWidth = constraints.maxWidth * 0.40;
          final bananosWidth = constraints.maxWidth - monoWidth - 20; // 20 = gap

          // Cada banano ocupa la mitad del área (2 columnas), menos el spacing
          final bananSize = ((bananosWidth - 10) / 2).clamp(40.0, 65.0);

          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Mono Muni — ancho proporcional
              SizedBox(
                width: monoWidth,
                child: Image.asset(
                  'assets/images/bienvenida/mono.png',
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(width: 20),

              // Cuadrícula de bananos — 2 columnas, tamaño relativo
              SizedBox(
                width: bananosWidth,
                child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: List.generate(
                    cantidadBananos,
                    (index) => Image.asset(
                      'assets/images/actividades/matematicas/Banano.png',
                      width: bananSize,
                      height: bananSize,
                      fit: BoxFit.contain,
                    ),
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

/// Botón de opción individual (A, B o C)
/// Se colorea después de responder: verde si es correcta, rojo si es incorrecta
class _BotonOpcion extends StatelessWidget {
  final String letra;
  final int valor;
  final bool seleccionada;
  final bool esCorrecta;
  final bool yaRespondio;
  final VoidCallback? onTap;

  const _BotonOpcion({
    required this.letra,
    required this.valor,
    required this.seleccionada,
    required this.esCorrecta,
    required this.yaRespondio,
    required this.onTap,
  });

  Color get _bgColor {
    if (!yaRespondio) return Colors.white;
    if (esCorrecta) return const Color(0xFFEDFBE9);   // verde suave
    if (seleccionada) return const Color(0xFFFFEDED);  // rojo suave si eligió esta
    return Colors.white;
  }

  Color get _borderColor {
    if (!yaRespondio) return const Color(0xFFE2E8F0);
    if (esCorrecta) return const Color(0xFF59E347);
    if (seleccionada) return const Color(0xFFF65757);
    return const Color(0xFFE2E8F0);
  }

  Color get _letraColor {
    if (!yaRespondio) return const Color(0xFF3475F7);
    if (esCorrecta) return const Color(0xFF2EAF1C);
    if (seleccionada) return const Color(0xFFF65757);
    return const Color(0xFF94A3B8);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: _bgColor,
          border: Border.all(color: _borderColor, width: 2),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                children: [
                  // Letra de la opción
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: _letraColor.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        letra,
                        style: TextStyle(
                          fontFamily: 'Hiruko',
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: _letraColor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Valor numérico
                  Text(
                    '$valor',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: yaRespondio
                          ? (esCorrecta
                              ? const Color(0xFF2EAF1C)
                              : seleccionada
                                  ? const Color(0xFFF65757)
                                  : const Color(0xFF94A3B8))
                          : const Color(0xFF1E293B),
                    ),
                  ),

                  const Spacer(),

                  // Ícono de resultado (solo después de responder)
                  if (yaRespondio && esCorrecta)
                    const Icon(Icons.check_circle_rounded,
                        color: Color(0xFF59E347), size: 24)
                  else if (yaRespondio && seleccionada)
                    const Icon(Icons.cancel_rounded,
                        color: Color(0xFFF65757), size: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// PANEL DE FEEDBACK (pestaña inferior)
// ────────────────────────────────────────────────────────────────────────────

class _FeedbackPanel extends StatelessWidget {
  final FeedbackEstadoBananos estado;
  final int numeroObjetivo;
  final VoidCallback onNuevoReto;
  final VoidCallback onIntentarDeNuevo;

  const _FeedbackPanel({
    required this.estado,
    required this.numeroObjetivo,
    required this.onNuevoReto,
    required this.onIntentarDeNuevo,
  });

  Color get _bgColor {
    switch (estado) {
      case FeedbackEstadoBananos.correcto:
        return const Color(0xFF59E347);
      case FeedbackEstadoBananos.incorrecto:
        return const Color(0xFFF65757);
      case FeedbackEstadoBananos.esperando:
        return Colors.white;
    }
  }

  String get _icono {
    switch (estado) {
      case FeedbackEstadoBananos.correcto:
        return '⭐';
      case FeedbackEstadoBananos.incorrecto:
        return '💡';
      case FeedbackEstadoBananos.esperando:
        return '🍌';
    }
  }

  String get _mensaje {
    switch (estado) {
      case FeedbackEstadoBananos.correcto:
        return '¡Excelente! Muni tiene exactamente $numeroObjetivo '
            '${numeroObjetivo == 1 ? "banano" : "bananos"}. ¡Súper!';
      case FeedbackEstadoBananos.incorrecto:
        return '¡Casi! Intenta contar los bananos de nuevo con calma.';
      case FeedbackEstadoBananos.esperando:
        return 'Cuenta los bananos de Muni y elige la opción correcta.';
    }
  }

  Color get _textoColor {
    return estado == FeedbackEstadoBananos.esperando
        ? const Color(0xFF94A3B8)
        : Colors.white;
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
          // ── Ícono + Mensaje ─────────────────────────────────────────
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: estado == FeedbackEstadoBananos.esperando
                      ? const Color(0xFFEEF2FF)
                      : Colors.white.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(_icono, style: const TextStyle(fontSize: 22)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _mensaje,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _textoColor,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Botones según estado ────────────────────────────────────
          if (estado == FeedbackEstadoBananos.esperando)
            // Estado inicial: el botón de verificar está en los propios botones
            // Solo mostramos un hint visual
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF3475F7).withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text(
                'Elige una opción para responder',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF3475F7),
                ),
              ),
            )
          else if (estado == FeedbackEstadoBananos.correcto)
            _BotonPrincipal(
              texto: '¡Fase final! →',
              bgColor: Colors.white,
              textoColor: const Color(0xFF59E347),
              onTap: onNuevoReto, // Navega a la vista 3
            )
          else ...[
            _BotonPrincipal(
              texto: 'Intentar de nuevo',
              bgColor: Colors.white,
              textoColor: const Color(0xFFF65757),
              onTap: onIntentarDeNuevo,
            ),
            const SizedBox(height: 10),
            _BotonSecundario(
              texto: 'Cambiar reto',
              onTap: onNuevoReto,
            ),
          ],
        ],
      ),
    );
  }
}

class _BotonPrincipal extends StatelessWidget {
  final String texto;
  final Color bgColor;
  final Color textoColor;
  final VoidCallback onTap;

  const _BotonPrincipal({
    required this.texto,
    required this.bgColor,
    required this.textoColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          foregroundColor: textoColor,
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
    );
  }
}

class _BotonSecundario extends StatelessWidget {
  final String texto;
  final VoidCallback onTap;

  const _BotonSecundario({required this.texto, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          backgroundColor: Colors.white.withOpacity(0.25),
          foregroundColor: Colors.white,
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