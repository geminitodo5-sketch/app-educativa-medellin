import 'package:flutter/material.dart';
import 'quien_tiene_mas_3.dart';

class MenosFrutasview extends StatelessWidget {
  const MenosFrutasview({super.key});

  void _verificarRespuesta(BuildContext context, int seleccion) {
    final esCorrecto = seleccion == 1;
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: esCorrecto ? const Color(0xFFD7FFD3) : const Color(0xFFFFD3D3),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              esCorrecto ? Icons.check_circle_rounded : Icons.cancel_rounded,
              color: esCorrecto ? Colors.green[800] : Colors.red[800],
              size: 56,
            ),
            const SizedBox(height: 12),
            Text(
              esCorrecto ? '¡Excelente trabajo!' : '¡Casi lo tienes!',
              style: TextStyle(
                fontFamily: 'Hiruko',
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: esCorrecto ? Colors.green[900] : Colors.red[900],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: esCorrecto ? Colors.green[700] : Colors.red[700],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  if (esCorrecto) {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const QuienTieneMasview3()),
                    );
                  }
                },
                child: Text(
                  esCorrecto ? 'Continuar' : 'Reintentar',
                  style: const TextStyle(
                    fontFamily: 'Hiruko',
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF3475F7), // Azul oficial NUMI [cite: 64]
      body: Stack(
        children: [
          // 1. Título Superior - Tipografía Hiruko [cite: 70]
          const Positioned(
            top: 70,
            left: 0,
            right: 0,
            child: Text(
              'Quién tiene más',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontFamily: 'Hiruko',
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // 2. Panel Blanco Principal
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: MediaQuery.of(context).size.height * 0.82,
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(50),
                  topRight: Radius.circular(50),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 25,
                  vertical: 40,
                ),
                child: Column(
                  children: [
                    // Área de Árboles con números decorativos
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _buildTreeDisplay(
                          imagePath:
                              'assets/images/actividades/matematicas/arbol_manzana.png',
                          index: '1',
                          indexColor: const Color(
                            0xFFF65757,
                          ), // Rojo oficial [cite: 64]
                        ),
                        _buildTreeDisplay(
                          imagePath:
                              'assets/images/actividades/matematicas/arbol_naranjas.png',
                          index: '2',
                          indexColor: const Color(
                            0xFFEF9325,
                          ), // Naranja oficial [cite: 64]
                        ),
                      ],
                    ),

                    const Spacer(),

                    // Fila de Instrucción - Tipografía Poppins [cite: 71]
                    const Row(
                      children: [
                        Icon(
                          Icons.volume_up_outlined,
                          size: 60,
                          color: Colors.black87,
                        ),
                        SizedBox(width: 15),
                        Expanded(
                          child: Text(
                            '¿Cuál árbol tiene menos frutas?',
                            style: TextStyle(
                              fontSize: 22,
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w700,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 40),

                    // Botones de Opción con texto negro y Poppins
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildActionButton(
                          context,
                          label: 'Árbol 1',
                          color: const Color(0xFF3475F7),
                          onPressed: () => _verificarRespuesta(context, 1),
                        ),
                        _buildActionButton(
                          context,
                          label: 'Árbol 2',
                          color: const Color(0xFFC6D8FF),
                          onPressed: () => _verificarRespuesta(context, 2),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),

          // Botón de Cerrar
          Positioned(
            top: 35,
            right: 15,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 30),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ],
      ),
    );
  }

  // Widget para mostrar el árbol con el número (Behove) [cite: 65, 66]
  Widget _buildTreeDisplay({
    required String imagePath,
    required String index,
    required Color indexColor,
  }) {
    return Column(
      children: [
        Text(
          index,
          style: TextStyle(
            fontSize: 45,
            fontFamily: 'Behove',
            fontWeight: FontWeight.w900,
            color: indexColor,
          ),
        ),
        const SizedBox(height: 10),
        Image.asset(imagePath, height: 180, fit: BoxFit.contain),
      ],
    );
  }

  // Botones profesionales con texto color negro y Poppins
  Widget _buildActionButton(
    BuildContext context, {
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: 150,
      height: 55,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.black, // Texto color negro
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 18,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
