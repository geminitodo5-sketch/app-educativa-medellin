import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'sumar_2.dart';

// Proveedor para manejar el estado de la respuesta
final respuestaSumarProvider = StateProvider<bool?>((ref) => null);

class SumarPatronview extends ConsumerWidget {
  const SumarPatronview({super.key});

  // Colores del Manual de Marca 
  static const Color azulPrincipal = Color(0xFF3475F7);
  static const Color azulBoton = Color(0xFF3878FA);
  static const Color azulBotonClaro = Color(0xFFC4D7FF);
  static const Color rojoNumi = Color(0xFFF65757);
  static const Color naranjaNumi = Color(0xFFEF9325);
  static const Color verdeNumi = Color(0xFF59E347);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: azulPrincipal,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildTopBar(context, ref),
            const SizedBox(height: 10),
            Expanded(
              child: _buildMainContent(context, ref),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        Align(
          alignment: Alignment.topRight,
          child: IconButton(
            icon: const Icon(Icons.close, color: Colors.white, size: 30),
            onPressed: () {
              ref.read(respuestaSumarProvider.notifier).state = null;
              Navigator.of(context).pop();
            },
          ),
        ),
        const Text(
          'Sumar',
          style: TextStyle(
            color: Colors.white,
            fontSize: 34,
            fontFamily: 'Hiruko', // Tipografía principal 
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildMainContent(BuildContext context, WidgetRef ref) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(40),
          topRight: Radius.circular(40),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 25.0, vertical: 40.0),
        child: Column(
          children: [
            _buildInstruction(),
            const SizedBox(height: 40),
            _buildPatternTable(),
            const Spacer(),
            // Opción Correcta: 4+1 = 5
            _buildOptionButton(context, ref, '4+1', azulBoton, Colors.white, true),
            const SizedBox(height: 15),
            // Opción Incorrecta: 4+2 = 6
            _buildOptionButton(context, ref, '4+2', azulBoton, Colors.white, false),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildInstruction() {
    return Row(
      children: [
        const Icon(Icons.volume_up_rounded, size: 50, color: Colors.black87),
        const SizedBox(width: 15),
        const Text(
          'Continua el patrón',
          style: TextStyle(
            fontSize: 20,
            fontFamily: 'Poppins', // Tipografía secundaria 
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _buildPatternTable() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: azulBoton, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Column(
          children: [
            _buildTableRow('3', '2+1', rojoNumi),
            _buildTableRow('4', '3+1', naranjaNumi),
            _buildTableRow('5', '???', verdeNumi),
          ],
        ),
      ),
    );
  }

  Widget _buildTableRow(String num, String suma, Color bgColor) {
    return Container(
      height: 65,
      decoration: BoxDecoration(
        color: bgColor,
        border: const Border(bottom: BorderSide(color: azulBoton, width: 1)),
      ),
      child: Row(
        children: [
          Expanded(child: _tableText(num)),
          const VerticalDivider(color: azulBoton, thickness: 2, width: 0),
          Expanded(child: _tableText(suma)),
        ],
      ),
    );
  }

  Widget _tableText(String text) {
    return Center(
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 28,
          fontFamily: 'Hiruko',
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  // Lógica del botón con pestaña inferior (Bottom Sheet)
  Widget _buildOptionButton(BuildContext context, WidgetRef ref, String text, Color bgColor, Color textColor, bool esCorrecto) {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        ),
        onPressed: () {
          ref.read(respuestaSumarProvider.notifier).state = esCorrecto;
          _showFeedbackSheet(context, esCorrecto);
        },
        child: Text(
          text,
          style: TextStyle(
            color: textColor,
            fontSize: 22,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    if (esCorrecto) {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                            builder: (_) => const PantallaSumaUvas()),
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
}