import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart'; // ✅ Importante
import 'quien_tiene_mas_31.dart';

// --- Paleta de Colores NUMI ---
const Color kColorAzulNumi = Color(0xFF3475F7);
const Color kColorRojoNumi = Color(0xFFF65757);
const Color kColorNaranjaNumi = Color(0xFFEF9325);
const Color kColorVerdeNumi = Color(0xFF59E347);

class PantallaSumaUvas extends ConsumerStatefulWidget {
  const PantallaSumaUvas({super.key});

  @override
  ConsumerState<PantallaSumaUvas> createState() => _PantallaSumaUvasState();
}

class _PantallaSumaUvasState extends ConsumerState<PantallaSumaUvas> {
  // ✅ Controlador del reproductor
  Player? _player;

  @override
  void initState() {
    super.initState();
    _player = Player();
    // Reproducción automática al entrar
    Future.microtask(() => _reproducirInstruccion());
  }

  @override
  void dispose() {
    _player?.dispose(); // ✅ Liberación de memoria
    super.dispose();
  }

  Future<void> _reproducirInstruccion() async {
    try {
      await _player?.open(
        Media('asset:///assets/Audio/Matematicas/audio mate8_mezcla.mp3'),
      );
    } catch (e) {
      debugPrint('Error al reproducir audio: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kColorAzulNumi,
      body: SafeArea(
        child: Column(
          children: [
            const _HeaderSuma(),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      const SizedBox(height: 10),
                      // ✅ Pasamos la función de reproducción al widget de instrucción
                      _InstruccionAudio(onPlay: _reproducirInstruccion),
                      const Spacer(),
                      const _SeccionCajas(),
                      const Spacer(),
                      const Text(
                        "4+3=?",
                        style: TextStyle(
                          fontFamily: 'Hiruko',
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const Spacer(),
                      const _OpcionesRespuesta(),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderSuma extends StatelessWidget {
  const _HeaderSuma();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      width: double.infinity,
      child: Stack(
        children: [
          const Align(
            alignment: Alignment.center,
            child: Text(
              "Sumar",
              style: TextStyle(
                fontFamily: 'Hiruko',
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          Positioned(
            top: 10,
            right: 15,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 30),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }
}

class _InstruccionAudio extends StatelessWidget {
  final VoidCallback onPlay; // ✅ Callback para repetir el audio
  const _InstruccionAudio({required this.onPlay});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // ✅ Botón interactivo para repetir instrucción
        IconButton(
          icon: const Icon(Icons.volume_up_outlined, size: 50),
          color: Colors.black87,
          onPressed: onPlay,
        ),
        const SizedBox(width: 15),
        const Expanded(
          child: Text(
            "Suma las uvas de  las dos cajas",
            style: TextStyle(
              fontFamily: 'Hiruko',
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),
      ],
    );
  }
}

class _SeccionCajas extends StatelessWidget {
  const _SeccionCajas();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: const [
        _CajaFruta(color: kColorRojoNumi, cantidad: 3),
        SizedBox(width: 20),
        _CajaFruta(color: kColorNaranjaNumi, cantidad: 4),
      ],
    );
  }
}

class _CajaFruta extends StatelessWidget {
  final Color color;
  final int cantidad;
  const _CajaFruta({required this.color, required this.cantidad});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 145,
      height: 145,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Stack(
        children: [
          Center(
            child: Wrap(
              spacing: 5,
              runSpacing: 5,
              alignment: WrapAlignment.center,
              children: List.generate(
                cantidad,
                (index) => Image.asset(
                  'assets/images/actividades/matematicas/mora.png',
                  width: 55,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 10,
            right: 15,
            child: Text(
              "$cantidad",
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OpcionesRespuesta extends StatelessWidget {
  const _OpcionesRespuesta();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _BotonOpcion(
          numero: "6",
          onTap: () => _showFeedbackSheet(context, false),
        ),
        _BotonOpcion(
          numero: "8",
          onTap: () => _showFeedbackSheet(context, false),
        ),
        _BotonOpcion(
          numero: "7",
          onTap: () => _showFeedbackSheet(context, true),
        ),
      ],
    );
  }
}

class _BotonOpcion extends StatelessWidget {
  final String numero;
  final VoidCallback onTap;

  const _BotonOpcion({
    required this.numero,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        height: 70,
        decoration: BoxDecoration(
          color: kColorAzulNumi,
          borderRadius: BorderRadius.circular(15),
        ),
        alignment: Alignment.center,
        child: Text(
          numero,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white, // Ajustado a blanco para contraste con azul
          ),
        ),
      ),
    );
  }
}

void _showFeedbackSheet(BuildContext context, bool esCorrecto) {
  showModalBottomSheet(
    context: context,
    isDismissible: false,
    backgroundColor: Colors.transparent,
    builder: (context) {
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
                  color: esCorrecto ? kColorVerdeNumi : kColorRojoNumi,
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
                  backgroundColor: esCorrecto ? kColorVerdeNumi : kColorRojoNumi,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  if (esCorrecto) {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                          builder: (_) => const QuienTieneMasview3()),
                    );
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