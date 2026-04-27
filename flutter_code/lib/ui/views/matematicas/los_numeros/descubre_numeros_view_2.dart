import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import '../../../../data/providers/app_state_provider.dart';
import '../../../viewmodels/descubre_bananos_view_model.dart';
import 'descubre_numeros_view_3.dart';

/// Vista de conteo de bananos (Fase 2)
/// Implementación con Feedback Modal consistente con el Manual Numi
class DescubreNumerosView2 extends ConsumerStatefulWidget {
  const DescubreNumerosView2({super.key});

  @override
  ConsumerState<DescubreNumerosView2> createState() =>
      _DescubreNumerosView2State();
}

class _DescubreNumerosView2State extends ConsumerState<DescubreNumerosView2> {
  static const Color azulPrincipal = Color(0xFF3475F7);
  static const Color verdeNumi = Color(0xFF59E347);
  static const Color rojoNumi = Color(0xFFF65757);
  static const Color fondoGris = Color(0xFFF5F7FF);

  late final Player _player;

  @override
  void initState() {
    super.initState();
    _player = Player();
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
      await _player.open(
        Media('asset:///assets/Audio/Matematicas/audio mate2_mezcla.mp3'),
      );
      await _player.play();
    } catch (e) {
      debugPrint('Error reproduciendo audio: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = ref.watch(descubreBananosViewModelProvider);
    final notifier = ref.read(descubreBananosViewModelProvider.notifier);
    const letras = ['A', 'B', 'C'];

    return Scaffold(
      backgroundColor: azulPrincipal,
      body: SafeArea(
        top: false,
        bottom: false,
        child: Column(
          children: [
            _Header(onClose: () => Navigator.of(context).pop(), progreso: 0.66),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: fondoGris,
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
                            _InstruccionCard(onAudio: _reproducirInstruccion),
                            const SizedBox(height: 28),
                            _AreaVisual(cantidadBananos: vm.numeroObjetivo),
                            const SizedBox(height: 32),
                            const Text(
                              'Elige  la respuesta correcta',
                              style: TextStyle(
                                fontFamily: 'Hiruko',
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                            const SizedBox(height: 14),
                            ...List.generate(vm.opciones.length, (i) {
                              final valor = vm.opciones[i];
                              final letra = letras[i];
                              final esCorrecta = valor == vm.numeroObjetivo;

                              return _BotonOpcion(
                                letra: letra,
                                valor: valor,
                                seleccionada: vm.opcionSeleccionada == valor,
                                esCorrecta: esCorrecta,
                                yaRespondio: vm.yaRespondio,
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
                              );
                            }),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
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

  void _showFeedbackSheet(
    BuildContext context,
    int seleccion,
    int objetivo,
    dynamic notifier,
  ) {
    final bool esCorrecto = seleccion == objetivo;

    showModalBottomSheet(
      context: context,
      isDismissible: false,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(30),
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
}

// ── COMPONENTES INTERNOS ──

class _Header extends ConsumerWidget {
  final VoidCallback onClose;
  final double progreso;
  const _Header({required this.onClose, required this.progreso});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Obtener el padding superior del sistema (zona de la cámara/notch)
    final topPadding = MediaQuery.of(context).padding.top;

    return SizedBox(
      height: 150 + topPadding,
      child: Padding(
        padding: EdgeInsets.only(top: topPadding),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Título centrado
            const Center(
              child: Text(
                'Descubre  los números',
                style: TextStyle(
                  fontFamily: 'Hiruko',
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            // ✅ Botón X en la esquina superior derecha
            Positioned(
              top: 4,
              right: 8,
              child: IconButton(
                icon: const Icon(
                  Icons.close_rounded,
                  color: Colors.white,
                  size: 28,
                ),
                onPressed: onClose,
              ),
            ),
            // Barra de progreso abajo
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
                    Color(0xFF59E347),
                  ),
                  minHeight: 10,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InstruccionCard extends StatelessWidget {
  final VoidCallback onAudio;
  const _InstruccionCard({required this.onAudio});

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
              child: const Icon(
                Icons.volume_up_rounded,
                color: Color(0xFF3475F7),
              ),
            ),
          ),
          const SizedBox(width: 14),
          const Text(
            '¿Cuántos bananos\ntiene Muni?',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
        ],
      ),
    );
  }
}

class _AreaVisual extends StatelessWidget {
  final int cantidadBananos;
  const _AreaVisual({required this.cantidadBananos});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Image.asset(
            'assets/images/bienvenida/mono.png',
            width: 100,
            fit: BoxFit.contain,
          ),
          SizedBox(
            width: 140,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(
                cantidadBananos,
                (i) => Image.asset(
                  'assets/images/actividades/matematicas/Banano.png',
                  width: 35,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

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

  @override
  Widget build(BuildContext context) {
    Color borderCol = const Color(0xFFE2E8F0);
    Color bgCol = Colors.white;
    if (yaRespondio) {
      if (esCorrecta) {
        borderCol = const Color(0xFF59E347);
        bgCol = const Color(0xFFEDFBE9);
      } else if (seleccionada) {
        borderCol = const Color(0xFFF65757);
        bgCol = const Color(0xFFFFEDED);
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: bgCol,
            border: Border.all(color: borderCol, width: 2),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 15,
                backgroundColor: borderCol.withOpacity(0.1),
                child: Text(
                  letra,
                  style: TextStyle(
                    fontFamily: 'Hiruko',
                    color: borderCol,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 15),
              Text(
                '$valor',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (yaRespondio && esCorrecta)
                const Icon(Icons.check_circle, color: Color(0xFF59E347)),
              if (yaRespondio && seleccionada && !esCorrecta)
                const Icon(Icons.cancel, color: Color(0xFFF65757)),
            ],
          ),
        ),
      ),
    );
  }
}
