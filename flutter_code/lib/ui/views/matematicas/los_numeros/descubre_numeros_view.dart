import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import '../../../../data/providers/app_state_provider.dart';
import '../../../viewmodels/descubre_numeros_view_model.dart';
import 'descubre_numeros_view_2.dart';

class DescubreNumerosView extends ConsumerStatefulWidget {
  const DescubreNumerosView({super.key});

  @override
  ConsumerState<DescubreNumerosView> createState() => _DescubreNumerosViewState();
}

class _DescubreNumerosViewState extends ConsumerState<DescubreNumerosView> {
  static const Color azulPrincipal = Color(0xFF3475F7);
  static const Color verdeNumi     = Color(0xFF59E347);
  static const Color rojoNumi      = Color(0xFFF65757);
  static const Color fondoGris     = Color(0xFFF5F7FF);

  late final Player _player;

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
    _player = Player();
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
    if (archivo == null) {
      debugPrint('No hay audio para el número $numero');
      return;
    }
    try {
      await _player.open(
        Media('asset:///assets/Audio/Matematicas/$archivo'),
      );
      await _player.play();
    } catch (e) {
      debugPrint('Error reproduciendo audio fresa $numero: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm       = ref.watch(descubreNumerosViewModelProvider);
    final notifier = ref.read(descubreNumerosViewModelProvider.notifier);

    return Scaffold(
      backgroundColor: azulPrincipal,
      body: SafeArea(
        top: false,
        bottom: false,
        child: Column(
          children: [
            _Header(
              onClose: () => Navigator.of(context).pop(),
              progreso: 0.33,
            ),
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
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    // Alturas fijas reales medidas en pantalla
                    const alturaInstruccion = 100.0;
                    const alturaLabelFresas = 28.0;
                    const alturaLabelRecuadro = 28.0;
                    const alturaBoton = 60.0;
                    const espaciadosV = 20.0 + 14.0 + 8.0 + 12.0 + 6.0 + 12.0 + 20.0;
                    const alturaFija = alturaInstruccion + alturaLabelFresas +
                        alturaLabelRecuadro + alturaBoton + espaciadosV;

                    final espacioLibre = (constraints.maxHeight - alturaFija).clamp(200.0, double.infinity);
                    // 65% fresas, 35% destino
                    final alturaGrilla = espacioLibre * 0.65;
                    final alturaDestino = espacioLibre * 0.35;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                          child: _InstruccionCard(
                            numeroObjetivo: vm.numeroObjetivo,
                            onAudio: () =>
                                _reproducirAudioNumero(vm.numeroObjetivo),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: const _SeccionLabel(texto: 'Arrastra  las fresas'),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: alturaGrilla,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: _GrillaFresas(
                              totalDisponibles: vm.totalFresasDisponibles,
                              enCuadro: vm.fresasEnCuadro.length,
                              verificado: vm.verificado,
                              alturaDisponible: alturaGrilla,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: _buildZonaTitulo(vm, notifier),
                        ),
                        const SizedBox(height: 6),
                        SizedBox(
                          height: alturaDestino,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
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
                        const SizedBox(height: 12),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
                          child: _BotonPrincipal(
                            texto: 'Verificar respuesta',
                            color: azulPrincipal,
                            textColor: Colors.white,
                            habilitado:
                                vm.fresasEnCuadro.isNotEmpty && !vm.verificado,
                            onTap: () {
                              final esCorrecto = vm.fresasEnCuadro.length == vm.numeroObjetivo;
                              notifier.commandVerificar();
                              _showFeedbackSheet(context, esCorrecto, notifier);
                            },
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFeedbackSheet(BuildContext context, bool esCorrecto, dynamic notifier) {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(30),
          decoration: BoxDecoration(
            color: esCorrecto ? const Color(0xFFD7FFD3) : const Color(0xFFFFD3D3),
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
                    size: 40,
                  ),
                  const SizedBox(width: 15),
                  Text(
                    esCorrecto ? '¡Excelente trabajo!' : '¡Casi lo tienes!',
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
                    backgroundColor: esCorrecto ? verdeNumi : rojoNumi,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15)),
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    if (esCorrecto) {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                            builder: (_) => const DescubreNumerosView2()),
                      );
                    } else {
                      notifier.commandIntentarDeNuevo();
                    }
                  },
                  child: Text(
                    esCorrecto ? 'Continuar' : 'Reintentar',
                    style: const TextStyle(
                      color: Colors.white,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
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

  Widget _buildZonaTitulo(dynamic vm, dynamic notifier) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const _SeccionLabel(texto: 'Tu recuadro'),
        if (vm.fresasEnCuadro.isNotEmpty && !vm.verificado)
          GestureDetector(
            onTap: notifier.commandQuitarFresa,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFFFEDED),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Quitar última',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: rojoNumi,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ── WIDGETS DE COMPONENTE ─────────────────────────────────────────────────────

class _Header extends ConsumerWidget {
  final VoidCallback onClose;
  final double progreso;
  const _Header({required this.onClose, required this.progreso});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estudiante = ref.watch(estudianteActivoProvider);
    return SizedBox(
      height: 150,
      child: Stack(
        alignment: Alignment.center,
        children: [
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
                  ),
                ),
                if (estudiante != null)
                  Text(
                    '¡Hola, ${estudiante.nombre}!',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      color: Colors.white,
                    ),
                  ),
              ],
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
          Positioned(
            bottom: 15,
            left: 45,
            right: 45,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: progreso,
                backgroundColor: Colors.white.withOpacity(0.15),
                valueColor: const AlwaysStoppedAnimation<Color>(
                    Color(0xFF59E347)),
                minHeight: 10,
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
  const _InstruccionCard(
      {required this.numeroObjetivo, required this.onAudio});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
              child: const Icon(Icons.volume_up_rounded,
                  color: Color(0xFF3475F7)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 17,
                  color: Color(0xFF1E293B),
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
                      text: numeroObjetivo == 1 ? ' fresa' : ' fresas'),
                  const TextSpan(text: ' en el cuadro'),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          Image.asset(
            'assets/images/actividades/matematicas/fresa.png',
            width: 90,
            height: 90,
          ),
        ],
      ),
    );
  }
}

class _GrillaFresas extends StatelessWidget {
  final int totalDisponibles;
  final int enCuadro;
  final bool verificado;
  final double alturaDisponible;

  const _GrillaFresas({
    required this.totalDisponibles,
    required this.enCuadro,
    required this.verificado,
    required this.alturaDisponible,
  });

  @override
  Widget build(BuildContext context) {
    final columnas = totalDisponibles <= 4 ? 2 : 3;
    final filas = (totalDisponibles / columnas).ceil();

    return LayoutBuilder(
      builder: (context, constraints) {
        const espaciado = 10.0;

        final imgAncho =
            (constraints.maxWidth - espaciado * (columnas - 1)) / columnas;
        final imgAlto =
            (alturaDisponible - espaciado * (filas - 1)) / filas;

        final tamanoImagen =
            (imgAncho < imgAlto ? imgAncho : imgAlto).clamp(0.0, 120.0);

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
              final i = index;
              final usada = i < enCuadro;
              cells.add(
                SizedBox(
                  width: tamanoImagen,
                  height: tamanoImagen,
                  child: Opacity(
                    opacity: usada ? 0.25 : 1.0,
                    child: Draggable<int>(
                      data: 1,
                      maxSimultaneousDrags: (verificado || usada) ? 0 : 1,
                      feedback: fresaImg(tamanoImagen * 0.9),
                      child: fresaImg(tamanoImagen),
                    ),
                  ),
                ),
              );
              index++;
            } else {
              cells.add(SizedBox(width: tamanoImagen, height: tamanoImagen));
            }
            if (c < columnas - 1) cells.add(SizedBox(width: espaciado));
          }
          rows.add(Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: cells,
          ));
          if (f < filas - 1) rows.add(SizedBox(height: espaciado));
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
            color: estaSobre ? const Color(0xFFEEF2FF) : Colors.white,
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
                    final count = fresasEnCuadro.length;
                    const padding = 12.0;
                    const gap = 8.0;
                    final areaW = constraints.maxWidth - padding * 2;
                    final areaH = constraints.maxHeight - padding * 2;
                    double tamano = 0;
                    for (int cols = 1; cols <= count; cols++) {
                      final rows = (count / cols).ceil();
                      final w = (areaW - gap * (cols - 1)) / cols;
                      final h = (areaH - gap * (rows - 1)) / rows;
                      final s = w < h ? w : h;
                      if (s > tamano) tamano = s;
                    }
                    tamano = tamano.clamp(30.0, 100.0);
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
      ),
    );
  }
}

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
      child: ElevatedButton(
        onPressed: habilitado ? onTap : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: textColor,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
        child: Text(
          texto,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}