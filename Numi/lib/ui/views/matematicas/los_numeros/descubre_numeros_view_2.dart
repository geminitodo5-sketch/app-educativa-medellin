import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import '../../../../data/providers/app_state_provider.dart';
import '../../../viewmodels/descubre_bananos_view_model.dart';
import 'descubre_numeros_view_3.dart';
import '../../../../data/services/feedback_sounds.dart';

/// Vista de conteo de bananos (Fase 2)
class DescubreNumerosView2 extends ConsumerStatefulWidget {
  const DescubreNumerosView2({super.key});

  @override
  ConsumerState<DescubreNumerosView2> createState() =>
      _DescubreNumerosView2State();
}

class _DescubreNumerosView2State
    extends ConsumerState<DescubreNumerosView2> {
  static const Color azulPrincipal = Color(0xFF3475F7);
  static const Color verdeNumi     = Color(0xFF59E347);
  static const Color rojoNumi      = Color(0xFFF65757);
  static const Color fondoGris     = Color(0xFFF5F7FF);

  late final AudioPlayer _player;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _reproducirInstruccion();
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _reproducirInstruccion() async {
    try {
      await _player
          .setAsset('assets/Audio/Matematicas/audio mate2_mezcla.mp3');
      await _player.play();
    } catch (e) {
      debugPrint('Error reproduciendo audio: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm      = ref.watch(descubreBananosViewModelProvider);
    final notifier = ref.read(descubreBananosViewModelProvider.notifier);
    const letras  = ['A', 'B', 'C'];

    final mq       = MediaQuery.of(context);
    final sw       = mq.size.width;
    final sh       = mq.size.height;
    final isTablet = sw >= 600;

    final hPad = isTablet ? sw * 0.06 : sw * 0.05;

    return Scaffold(
      backgroundColor: azulPrincipal,
      body: Column(
        children: [
          // Header gestiona su propio SafeArea internamente
          _Header(
            onClose: () => Navigator.of(context).pop(),
            progreso: 0.66,
          ),
          // Body — ocupa el resto exacto de la pantalla, sin overflow
          Expanded(
            child: Container(
              width: double.infinity,
              clipBehavior: Clip.hardEdge,
              decoration: const BoxDecoration(
                color: fondoGris,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(40),
                  topRight: Radius.circular(40),
                ),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(hPad, sh * 0.02, hPad, sh * 0.015),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Instrucción — tamaño intrínseco
                      _InstruccionCard(
                        onAudio: _reproducirInstruccion,
                        isTablet: isTablet,
                      ),
                      SizedBox(height: sh * 0.016),

                      // Área visual — toma el espacio disponible proporcional
                      Expanded(
                        flex: 38,
                        child: _AreaVisual(
                          cantidadBananos: vm.numeroObjetivo,
                          isTablet: isTablet,
                        ),
                      ),
                      SizedBox(height: sh * 0.014),

                      // Label opciones
                      Text(
                        'Elige  la respuesta correcta',
                        style: TextStyle(
                          fontFamily: 'Hiruko',
                          fontSize: isTablet ? 22 : 16,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                      SizedBox(height: sh * 0.01),

                      // Botones de opción — cada uno ocupa 1/3 del espacio disponible
                      Expanded(
                        flex: 62,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: () {
                            final items = <Widget>[];
                            for (int i = 0; i < vm.opciones.length; i++) {
                              final valor      = vm.opciones[i];
                              final letra      = letras[i];
                              final esCorrecta = valor == vm.numeroObjetivo;

                              if (i > 0) items.add(SizedBox(height: sh * 0.012));

                              items.add(Expanded(
                                child: _BotonOpcion(
                                  letra: letra,
                                  valor: valor,
                                  seleccionada: vm.opcionSeleccionada == valor,
                                  esCorrecta: esCorrecta,
                                  yaRespondio: vm.yaRespondio,
                                  isTablet: isTablet,
                                  onTap: vm.yaRespondio
                                      ? null
                                      : () {
                                          notifier.commandValidarRespuesta(valor);
                                          _showFeedbackSheet(
                                            context,
                                            valor,
                                            vm.numeroObjetivo,
                                            notifier,
                                          );
                                        },
                                ),
                              ));
                            }
                            return items;
                          }(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showFeedbackSheet(
    BuildContext context,
    int seleccion,
    int objetivo,
    dynamic notifier,
  ) {
    final bool esCorrecto = seleccion == objetivo;
    FeedbackSounds.instance.reproducir(esCorrecto);
    final mq      = MediaQuery.of(context);
    final sw      = mq.size.width;
    final isTablet = sw >= 600;

    showModalBottomSheet(
      context: context,
      isDismissible: false,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(bottom: mq.viewInsets.bottom),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: isTablet ? sw * 0.08 : 26,
              vertical: 26,
            ),
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
                      color: esCorrecto ? verdeNumi : rojoNumi,
                      size: isTablet ? 52 : 40,
                    ),
                    SizedBox(width: isTablet ? 20 : 14),
                    Flexible(
                      child: Text(
                        esCorrecto
                            ? '¡Excelente trabajo!'
                            : '¡Inténtalo de nuevo!',
                        style: TextStyle(
                          fontFamily: 'Hiruko',
                          fontSize: isTablet ? 30 : 22,
                          fontWeight: FontWeight.bold,
                          color: esCorrecto
                              ? Colors.green[900]
                              : Colors.red[900],
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: isTablet ? 28 : 18),
                SizedBox(
                  width: double.infinity,
                  height: isTablet ? 64 : 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: esCorrecto ? verdeNumi : rojoNumi,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      if (esCorrecto) {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (_) => const DescubreGlobosView(),
                          ),
                        );
                      } else {
                        notifier.commandIntentarDeNuevo();
                      }
                    },
                    child: Text(
                      esCorrecto ? 'Continuar' : 'Reintentar',
                      style: TextStyle(
                        color: Colors.white,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.bold,
                        fontSize: isTablet ? 22 : 18,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── COMPONENTES ───────────────────────────────────────────────────────────────

class _Header extends ConsumerWidget {
  final VoidCallback onClose;
  final double progreso;

  const _Header({
    required this.onClose,
    required this.progreso,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mq       = MediaQuery.of(context);
    final topPad   = mq.padding.top;
    final sw       = mq.size.width;
    final sh       = mq.size.height;
    final isTablet = sw >= 600;

    final contentH = (sh * 0.13).clamp(80.0, 140.0);
    final totalH   = topPad + contentH;

    return SizedBox(
      height: totalH,
      child: Stack(
        children: [
          // Título centrado debajo del status bar
          Positioned.fill(
            top: topPad,
            child: Center(
              child: Text(
                'Descubre  los números',
                style: TextStyle(
                  fontFamily: 'Hiruko',
                  fontSize: isTablet ? 32 : 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          // Botón cerrar — respeta el status bar
          Positioned(
            top: topPad + 4,
            right: 8,
            child: IconButton(
              icon: Icon(
                Icons.close_rounded,
                color: Colors.white,
                size: isTablet ? 34 : 28,
              ),
              onPressed: onClose,
            ),
          ),
          // Barra de progreso — siempre al fondo del header
          Positioned(
            bottom: 14,
            left: isTablet ? 60 : 40,
            right: isTablet ? 60 : 40,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: progreso,
                backgroundColor: Colors.white.withOpacity(0.15),
                valueColor: const AlwaysStoppedAnimation<Color>(
                  Color(0xFF59E347),
                ),
                minHeight: isTablet ? 12 : 10,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InstruccionCard extends StatelessWidget {
  final VoidCallback onAudio;
  final bool isTablet;

  const _InstruccionCard({
    required this.onAudio,
    required this.isTablet,
  });

  @override
  Widget build(BuildContext context) {
    final sw       = MediaQuery.of(context).size.width;
    final iconSize = isTablet ? 60.0 : 46.0;
    final fontSize = (sw * 0.055).clamp(18.0, 40.0);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: onAudio,
            child: Container(
              width: iconSize,
              height: iconSize,
              decoration: BoxDecoration(
                color: const Color(0xFFEEF2FF),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.volume_up_rounded,
                color: Color(0xFF3475F7),
              ),
            ),
          ),
          SizedBox(width: isTablet ? 18 : 12),
          Text(
            '¿Cuántos bananos\ntiene Muni?',
            style: TextStyle(
              fontFamily: 'Hiruko',
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1E293B),
            ),
          ),
        ],
      ),
    );
  }
}

class _AreaVisual extends StatelessWidget {
  final int cantidadBananos;
  final bool isTablet;

  const _AreaVisual({
    required this.cantidadBananos,
    required this.isTablet,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availH  = constraints.maxHeight;
        final availW  = constraints.maxWidth;

        // El mono ocupa entre el 20-28% del ancho disponible
        final monoW   = (availW * (isTablet ? 0.20 : 0.26)).clamp(60.0, 160.0);
        // Los bananos se escalan según el alto disponible y la cantidad
        final rawBananoW = (availH * 0.30).clamp(24.0, 52.0);
        final bananoW = cantidadBananos > 6
            ? (rawBananoW * 0.8).clamp(20.0, 44.0)
            : rawBananoW;

        return Container(
          padding: EdgeInsets.all(availH * 0.08),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/bienvenida/mono.png',
                width: monoW,
                height: availH * 0.80,
                fit: BoxFit.contain,
              ),
              SizedBox(width: availW * 0.03),
              Expanded(
                child: Center(
                  child: Wrap(
                    spacing: isTablet ? 10 : 7,
                    runSpacing: isTablet ? 10 : 7,
                    alignment: WrapAlignment.center,
                    runAlignment: WrapAlignment.center,
                    children: List.generate(
                      cantidadBananos,
                      (i) => Image.asset(
                        'assets/images/actividades/matematicas/Banano.png',
                        width: bananoW,
                        height: bananoW,
                        fit: BoxFit.contain,
                      ),
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
}

class _BotonOpcion extends StatelessWidget {
  final String letra;
  final int valor;
  final bool seleccionada;
  final bool esCorrecta;
  final bool yaRespondio;
  final bool isTablet;
  final VoidCallback? onTap;

  const _BotonOpcion({
    required this.letra,
    required this.valor,
    required this.seleccionada,
    required this.esCorrecta,
    required this.yaRespondio,
    required this.isTablet,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final sh = MediaQuery.of(context).size.height;

    Color borderCol = const Color(0xFFE2E8F0);
    Color bgCol     = Colors.white;

    if (yaRespondio) {
      if (seleccionada && esCorrecta) {
        borderCol = const Color(0xFF59E347);
        bgCol     = const Color(0xFFEDFBE9);
      } else if (seleccionada && !esCorrecta) {
        borderCol = const Color(0xFFF65757);
        bgCol     = const Color(0xFFFFEDED);
      }
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // El número ocupa ~40% de la altura disponible del botón, con límites razonables
        final numSize   = (constraints.maxHeight * 0.40).clamp(18.0, 48.0);
        final letraSize = (numSize * 0.65).clamp(12.0, 32.0);
        final avatarR   = (numSize * 0.50).clamp(12.0, 26.0);
        final iconSize  = (numSize * 0.75).clamp(16.0, 36.0);

        return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        height: double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: isTablet ? 24 : 16,
        ),
        decoration: BoxDecoration(
          color: bgCol,
          border: Border.all(color: borderCol, width: 2),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: avatarR,
              backgroundColor: borderCol.withOpacity(0.12),
              child: Text(
                letra,
                style: TextStyle(
                  fontFamily: 'Hiruko',
                  fontSize: letraSize,
                  color: borderCol,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(width: isTablet ? 18 : 14),
            Text(
              '$valor',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: numSize,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            if (yaRespondio && seleccionada && esCorrecta)
              Icon(Icons.check_circle,
                  color: const Color(0xFF59E347),
                  size: iconSize),
            if (yaRespondio && seleccionada && !esCorrecta)
              Icon(Icons.cancel,
                  color: const Color(0xFFF65757),
                  size: iconSize),
          ],
        ),
      ),
        );
      },
    );
  }
}