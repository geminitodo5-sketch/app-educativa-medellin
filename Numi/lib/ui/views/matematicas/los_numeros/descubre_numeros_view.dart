import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import '../../../../data/providers/app_state_provider.dart';
import '../../../viewmodels/descubre_numeros_view_model.dart';
import 'descubre_numeros_view_2.dart';
import '../../../../data/services/feedback_sounds.dart';

class DescubreNumerosView extends ConsumerStatefulWidget {
  const DescubreNumerosView({super.key});

  @override
  ConsumerState<DescubreNumerosView> createState() =>
      _DescubreNumerosViewState();
}

class _DescubreNumerosViewState extends ConsumerState<DescubreNumerosView> {
  static const Color azulPrincipal = Color(0xFF3475F7);
  static const Color verdeNumi     = Color(0xFF59E347);
  static const Color rojoNumi      = Color(0xFFF65757);
  static const Color fondoGris     = Color(0xFFF5F7FF);

  // Progreso de esta pantalla: es la pantalla 1 de 3 en la actividad
  static const double _progreso = 1 / 3;

  late final AudioPlayer _player;

  static const Map<int, String> _audioMap = {
    1:  'audio_mate_fresa1_mezcla.mp3',
    2:  'audio_mate_fresa2_mezcla.mp3',
    3:  'audio_mate_fresa3_mezcla.mp3',
    4:  'audio_mate_fresa4_mezcla.mp3',
    5:  'audio_mate_fresa5_mezcla.mp3',
    6:  'audio_mate_fresa6_mezcla.mp3',
    7:  'audio_mate_fresa7_mezcla.mp3',
    8:  'audio_mate_fresa8_mezcla.mp3',
    9:  'audio_mate_fresa9_mezcla.mp3',
    10: 'audio_mate_fresa10_mezcla.mp3',
  };

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vm = ref.read(descubreNumerosViewModelProvider);
      _reproducirAudioNumero(vm.numeroObjetivo);
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _reproducirAudioNumero(int numero) async {
    final archivo = _audioMap[numero];
    if (archivo == null) return;
    try {
      await _player.setAsset('assets/Audio/Matematicas/$archivo');
      await _player.play();
    } catch (e) {
      debugPrint('Error reproduciendo audio fresa $numero: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm       = ref.watch(descubreNumerosViewModelProvider);
    final notifier = ref.read(descubreNumerosViewModelProvider.notifier);

    final mq       = MediaQuery.of(context);
    final sw       = mq.size.width;
    final sh       = mq.size.height;
    final isTablet = sw >= 600;

    // Padding horizontal escala al ancho real de pantalla
    final hPad = (sw * (isTablet ? 0.06 : 0.05)).clamp(16.0, 48.0);

    // Espaciados verticales clampados para pantallas muy pequeñas
    final vGapLg  = (sh * 0.020).clamp(6.0, 20.0);
    final vGapMd  = (sh * 0.012).clamp(4.0, 14.0);
    final vGapSm  = (sh * 0.008).clamp(3.0, 10.0);
    final vGapXs  = (sh * 0.006).clamp(2.0, 8.0);

    // Altura del botón verificar escala con pantalla
    final btnH = (sh * 0.065).clamp(44.0, 68.0);

    return Scaffold(
      backgroundColor: azulPrincipal,
      body: Column(
        children: [
          // Header con SafeArea integrada para notch / barra de estado
          _Header(
            onClose: () => Navigator.of(context).pop(),
            progreso: _progreso,
          ),
          // Cuerpo — ocupa todo el espacio restante sin overflow
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: vGapLg),

                    // Instrucción
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: hPad),
                      child: _InstruccionCard(
                        numeroObjetivo: vm.numeroObjetivo,
                        onAudio: () =>
                            _reproducirAudioNumero(vm.numeroObjetivo),
                        isTablet: isTablet,
                        screenWidth: sw,
                      ),
                    ),
                    SizedBox(height: vGapMd),

                    // Label fresas
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: hPad),
                      child: _SeccionLabel(
                        texto: 'Arrastra  las fresas',
                        isTablet: isTablet,
                        screenWidth: sw,
                      ),
                    ),
                    SizedBox(height: vGapSm),

                    // Grilla de fresas — toma el 55 % del espacio libre
                    Expanded(
                      flex: 55,
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: hPad),
                        child: _GrillaFresas(
                          totalDisponibles: vm.totalFresasDisponibles,
                          enCuadro: vm.fresasEnCuadro.length,
                          verificado: vm.verificado,
                        ),
                      ),
                    ),
                    SizedBox(height: vGapSm),

                    // Label destino + quitar
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: hPad),
                      child: _buildZonaTitulo(vm, notifier, isTablet, sw),
                    ),
                    SizedBox(height: vGapXs),

                    // Zona destino — toma el 45 % del espacio libre
                    Expanded(
                      flex: 45,
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: hPad),
                        child: _ZonaDestino(
                          fresasEnCuadro: vm.fresasEnCuadro,
                          verificado: vm.verificado,
                          feedbackEstado: vm.feedback,
                          onAceptar: vm.verificado
                              ? null
                              : notifier.commandAgregarFresa,
                        ),
                      ),
                    ),

                    // Botón verificar
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                          hPad, vGapSm, hPad, vGapLg),
                      child: SizedBox(
                        height: btnH,
                        width: double.infinity,
                        child: _BotonPrincipal(
                          texto: 'Verificar respuesta',
                          color: azulPrincipal,
                          textColor: Colors.white,
                          habilitado: vm.fresasEnCuadro.isNotEmpty &&
                              !vm.verificado,
                          isTablet: isTablet,
                          screenWidth: sw,
                          onTap: () {
                            final esCorrecto =
                                vm.fresasEnCuadro.length ==
                                    vm.numeroObjetivo;
                            notifier.commandVerificar();
                            _showFeedbackSheet(
                                context, esCorrecto, notifier);
                          },
                        ),
                      ),
                    ),
                  ],
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
    bool esCorrecto,
    dynamic notifier,
  ) {
    FeedbackSounds.instance.reproducir(esCorrecto);
    final mq       = MediaQuery.of(context);
    final sw       = mq.size.width;
    final isTablet = sw >= 600;

    // Padding horizontal del sheet escala al ancho real
    final sheetHPad = (sw * (isTablet ? 0.08 : 0.06)).clamp(20.0, 60.0);

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
              horizontal: sheetHPad,
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
                            builder: (_) => const DescubreNumerosView2(),
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
                        fontSize: (sw * (isTablet ? 0.028 : 0.044))
                            .clamp(14.0, 22.0),
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

  Widget _buildZonaTitulo(
      dynamic vm, dynamic notifier, bool isTablet, double sw) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _SeccionLabel(
            texto: 'Tu recuadro', isTablet: isTablet, screenWidth: sw),
        if (vm.fresasEnCuadro.isNotEmpty && !vm.verificado)
          GestureDetector(
            onTap: notifier.commandQuitarFresa,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFFFEDED),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Quitar última',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: (sw * (isTablet ? 0.022 : 0.030)).clamp(11.0, 16.0),
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFF65757),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ── WIDGETS ───────────────────────────────────────────────────────────────────

class _Header extends ConsumerWidget {
  final VoidCallback onClose;
  final double progreso;

  const _Header({
    required this.onClose,
    required this.progreso,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mq         = MediaQuery.of(context);
    final topPad     = mq.padding.top;
    final sw         = mq.size.width;
    final sh         = mq.size.height;
    final isTablet   = sw >= 600;
    final estudiante = ref.watch(estudianteActivoProvider);

    // Área de contenido bajo la status bar: escala proporcional con clamp
    final contentH = (sh * 0.13).clamp(72.0, 130.0);
    final totalH   = topPad + contentH;

    // Tamaños de fuente escalados al ancho real
    final titleSize = (sw * (isTablet ? 0.048 : 0.057)).clamp(18.0, 36.0);
    final greetSize = (sw * (isTablet ? 0.022 : 0.030)).clamp(11.0, 18.0);
    final iconSize  = (sw * (isTablet ? 0.055 : 0.070)).clamp(22.0, 38.0);
    final hPadBtn   = isTablet ? 80.0 : 56.0;
    final progressH = (sh * 0.013).clamp(8.0, 14.0);

    return SizedBox(
      height: totalH,
      child: Stack(
        children: [
          // Título + saludo — centrados bajo la barra de estado
          Positioned.fill(
            top: topPad,
            child: Align(
              alignment: const Alignment(0, -0.3),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: hPadBtn),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Descubre  los números',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Hiruko',
                        fontSize: titleSize,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    if (estudiante != null)
                      Text(
                        '¡Hola, ${estudiante.nombre}!',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: greetSize,
                          color: Colors.white,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          // Botón cerrar — respeta la status bar
          Positioned(
            top: topPad + 4,
            right: 8,
            child: IconButton(
              icon: Icon(
                Icons.close_rounded,
                color: Colors.white,
                size: iconSize,
              ),
              onPressed: onClose,
            ),
          ),
          // Barra de progreso — siempre en la parte inferior del header
          Positioned(
            bottom: 10,
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
                minHeight: progressH,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InstruccionCard extends StatelessWidget {
  final int numeroObjetivo;
  final VoidCallback onAudio;
  final bool isTablet;
  final double screenWidth;

  const _InstruccionCard({
    required this.numeroObjetivo,
    required this.onAudio,
    required this.isTablet,
    required this.screenWidth,
  });

  @override
  Widget build(BuildContext context) {
    // Todos los tamaños derivados del ancho real de pantalla
    final iconSize = (screenWidth * (isTablet ? 0.09 : 0.115)).clamp(40.0, 72.0);
    final fontSize = (screenWidth * 0.055).clamp(18.0, 40.0);
    final numSize  = (screenWidth * (isTablet ? 0.036 : 0.046)).clamp(15.0, 26.0);
    final imgSize  = (screenWidth * (isTablet ? 0.15 : 0.18)).clamp(56.0, 110.0);
    final hPadCard = (screenWidth * 0.035).clamp(10.0, 20.0);
    final vPadCard = (screenWidth * 0.022).clamp(8.0, 14.0);
    final gap      = (screenWidth * (isTablet ? 0.028 : 0.025)).clamp(8.0, 18.0);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: hPadCard, vertical: vPadCard),
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
              child: Icon(
                Icons.volume_up_rounded,
                color: const Color(0xFF3475F7),
                size: iconSize * 0.52,
              ),
            ),
          ),
          SizedBox(width: gap),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                  fontFamily: 'Hiruko',
                  fontSize: fontSize,
                  color: const Color(0xFF1E293B),
                ),
                children: [
                  const TextSpan(text: 'Coloca '),
                  TextSpan(
                    text: '$numeroObjetivo',
                    style: TextStyle(
                      color: const Color(0xFF3475F7),
                      fontWeight: FontWeight.w800,
                      fontSize: numSize,
                    ),
                  ),
                  TextSpan(
                      text: numeroObjetivo == 1 ? ' fresa' : ' fresas'),
                  const TextSpan(text: ' en el cuadro'),
                ],
              ),
            ),
          ),
          SizedBox(width: gap * 0.6),
          Image.asset(
            'assets/images/actividades/matematicas/fresa.png',
            width: imgSize,
            height: imgSize,
            fit: BoxFit.contain,
          ),
        ],
      ),
    );
  }
}

class _SeccionLabel extends StatelessWidget {
  final String texto;
  final bool isTablet;
  final double screenWidth;

  const _SeccionLabel({
    required this.texto,
    required this.isTablet,
    required this.screenWidth,
  });

  @override
  Widget build(BuildContext context) {
    final fontSize =
        (screenWidth * (isTablet ? 0.034 : 0.040)).clamp(13.0, 24.0);
    return Text(
      texto,
      style: TextStyle(
        fontFamily: 'Hiruko',
        fontSize: fontSize,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

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
    final columnas = totalDisponibles <= 4 ? 2 : 3;
    final filas    = (totalDisponibles / columnas).ceil();

    return LayoutBuilder(
      builder: (context, constraints) {
        const espaciado = 10.0;

        final imgAncho =
            (constraints.maxWidth - espaciado * (columnas - 1)) / columnas;
        final imgAlto =
            (constraints.maxHeight - espaciado * (filas - 1)) / filas;

        final tamanoImagen =
            (imgAncho < imgAlto ? imgAncho : imgAlto).clamp(0.0, 130.0);

        Widget fresaImg(double size) => Image.asset(
              'assets/images/actividades/matematicas/fresa.png',
              width: size,
              height: size,
              fit: BoxFit.contain,
            );

        int index = 0;
        final rows = <Widget>[];

        for (int f = 0; f < filas; f++) {
          final cells = <Widget>[];
          for (int c = 0; c < columnas; c++) {
            if (index < totalDisponibles) {
              final i     = index;
              final usada = i < enCuadro;
              cells.add(
                SizedBox(
                  width: tamanoImagen,
                  height: tamanoImagen,
                  child: Opacity(
                    opacity: usada ? 0.25 : 1.0,
                    child: Draggable<int>(
                      data: 1,
                      maxSimultaneousDrags:
                          (verificado || usada) ? 0 : 1,
                      feedback: fresaImg(tamanoImagen * 0.9),
                      child: fresaImg(tamanoImagen),
                    ),
                  ),
                ),
              );
              index++;
            } else {
              cells.add(
                  SizedBox(width: tamanoImagen, height: tamanoImagen));
            }
            if (c < columnas - 1)
              cells.add(const SizedBox(width: 10));
          }
          rows.add(Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: cells,
          ));
          if (f < filas - 1) rows.add(const SizedBox(height: 10));
        }

        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: rows,
        );
      },
    );
  }
}

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

  @override
  Widget build(BuildContext context) {
    return DragTarget<int>(
      onAcceptWithDetails: (_) => onAceptar?.call(),
      builder: (context, candidateData, _) {
        final estaSobre = candidateData.isNotEmpty;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            color: estaSobre
                ? const Color(0xFFEEF2FF)
                : Colors.white,
            border: Border.all(
              color: estaSobre
                  ? const Color(0xFF1EB9D8)
                  : const Color(0xFF3475F7),
              width: 2.5,
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
                    ),
                  ),
                )
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final count   = fresasEnCuadro.length;
                    const padding = 12.0;
                    const gap     = 8.0;
                    final areaW   = constraints.maxWidth - padding * 2;
                    final areaH   = constraints.maxHeight - padding * 2;
                    double tamano = 0;
                    for (int cols = 1; cols <= count; cols++) {
                      final rows = (count / cols).ceil();
                      final w    = (areaW - gap * (cols - 1)) / cols;
                      final h    = (areaH - gap * (rows - 1)) / rows;
                      final s    = w < h ? w : h;
                      if (s > tamano) tamano = s;
                    }
                    tamano = tamano.clamp(24.0, 110.0);
                    return Center(
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        runAlignment: WrapAlignment.center,
                        spacing: gap,
                        runSpacing: gap,
                        children: fresasEnCuadro
                            .map(
                              (key) => Image.asset(
                                'assets/images/actividades/matematicas/fresa.png',
                                key: key,
                                width: tamano,
                                height: tamano,
                                fit: BoxFit.contain,
                              ),
                            )
                            .toList(),
                      ),
                    );
                  },
                ),
        );
      },
    );
  }
}

class _BotonPrincipal extends StatelessWidget {
  final String texto;
  final Color color;
  final Color textColor;
  final bool habilitado;
  final bool isTablet;
  final double screenWidth;
  final VoidCallback onTap;

  const _BotonPrincipal({
    required this.texto,
    required this.color,
    required this.textColor,
    required this.habilitado,
    required this.isTablet,
    required this.screenWidth,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final fontSize =
        (screenWidth * (isTablet ? 0.030 : 0.038)).clamp(13.0, 22.0);
    return SizedBox(
      width: double.infinity,
      height: double.infinity,
      child: ElevatedButton(
        onPressed: habilitado ? onTap : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: textColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: Text(
          texto,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}