import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'quien_tiene_mas_31.dart';

// --- Paleta de Colores NUMI (según página 9 del manual) ---
const Color kColorAzulNumi = Color(0xFF3475F7); // HEX 3475f7 [cite: 64]
const Color kColorRojoNumi = Color(0xFFF65757); // HEX f65757 [cite: 64]
const Color kColorNaranjaNumi = Color(0xFFEF9325); // HEX ef9325 [cite: 64]
const Color kColorVerdeNumi = Color(0xFF59E347);
const Color kColorAzulClaro = Color(0xFFC7D7FD);

class PantallaSumaUvas extends ConsumerWidget {
  const PantallaSumaUvas({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: kColorAzulNumi,
      body: SafeArea(
        child: Column(
          children: [
            // Encabezado con el botón en la esquina superior derecha
            const _HeaderSuma(),

            // Cuerpo Blanco Redondeado
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
                      // Instrucción con tipografía Hiruko
                      const _InstruccionAudio(),
                      const Spacer(),
                      // Cajas de Frutas con colores oficiales [cite: 64]
                      const _SeccionCajas(),
                      const Spacer(),
                      // Ecuación con Hiruko
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
                      // Opciones con Poppins
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
  const _HeaderSuma({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100, // Espacio para el título y botón
      width: double.infinity,
      child: Stack(
        children: [
          // Título central con Hiruko (Tipografía principal según manual)
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
          // Botón X posicionado manualmente en la esquina
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
  const _InstruccionAudio({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.volume_up_outlined, size: 50, color: Colors.black87),
        const SizedBox(width: 15),
        const Expanded(
          child: Text(
            "Suma las uvas de las dos cajas",
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
  const _SeccionCajas({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
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

  const _CajaFruta({super.key, required this.color, required this.cantidad});

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
          // Número en Poppins
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
  const _OpcionesRespuesta({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _BotonOpcion(
          numero: "6",
          seleccionado: false,
          onTap: () => _showFeedbackSheet(context, false),
        ),
        _BotonOpcion(
          numero: "8",
          seleccionado: false,
          onTap: () => _showFeedbackSheet(context, false),
        ),
        _BotonOpcion(
          numero: "7",
          seleccionado: true,
          onTap: () => _showFeedbackSheet(context, true),
        ),
      ],
    );
  }
}

class _BotonOpcion extends StatelessWidget {
  final String numero;
  final bool seleccionado;
  final VoidCallback onTap;

  const _BotonOpcion({
    super.key,
    required this.numero,
    required this.seleccionado,
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
          color: seleccionado ? kColorAzulNumi : kColorAzulClaro,
          borderRadius: BorderRadius.circular(15),
        ),
        alignment: Alignment.center,
        child: Text(
          numero,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black,
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
                  backgroundColor: esCorrecto
                      ? kColorVerdeNumi
                      : kColorRojoNumi,
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
