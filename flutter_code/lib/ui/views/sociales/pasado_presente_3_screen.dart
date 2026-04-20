import 'package:flutter/material.dart';
import '../terminado.dart';

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: EscuchaYEligePage(),
  ));
}

class EscuchaYEligePage extends StatefulWidget {
  const EscuchaYEligePage({super.key, this.onCompleted});
  final VoidCallback? onCompleted;

  @override
  _EscuchaYEligePageState createState() => _EscuchaYEligePageState();
}

class _EscuchaYEligePageState extends State<EscuchaYEligePage> {
  final List<Map<String, dynamic>> animals = [
    {'image': 'assets/images/actividades/sociales/gato.png', 'color': const Color(0xFFA1E296), 'isCorrect': false},
    {'image': 'assets/images/actividades/sociales/Cocodrilo.png', 'color': const Color(0xFFFFE082), 'isCorrect': true},
    {'image': 'assets/images/actividades/sociales/pato.png', 'color': const Color(0xFFEF9A9A), 'isCorrect': false},
    {'image': 'assets/images/actividades/sociales/pollo.png', 'color': const Color(0xFFCE93D8), 'isCorrect': false},
  ];

  void _onPlayButtonPressed() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Reproduciendo sonido de Cocodrilo...'),
        duration: Duration(milliseconds: 800),
      ),
    );
  }

  void _onAnimalSelected(int index) {
    if (animals[index]['isCorrect']) {
      _showSuccessDialog();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Inténtalo de nuevo!'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("¡Excelente!", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text("¡Has encontrado al animal correcto!", textAlign: TextAlign.center),
        actions: [
          Center(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF39C12)),
              onPressed: () {
                widget.onCompleted?.call();
                Navigator.pop(context);
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (_) => const ActividadTerminadaScreen(),
                  ),
                );
              },
              child: const Text("Continuar", style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Fondo amarillo para que el header se integre sin costuras
      backgroundColor: const Color(0xFFF39C12),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildHeader(),
            // Bloque blanco con esquinas superiores redondeadas
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(28),
                    topRight: Radius.circular(28),
                  ),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
                  child: Column(
                    children: [
                      // Título
                      const Text(
                        'Escucha y elige',
                        style: TextStyle(
                          fontFamily: 'Hiruko',
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF3D2B1F),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Enunciado con fuente Hiruko bold
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF8EE),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: const Color(0xFFF5A623), width: 1.5),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Icon(Icons.volume_up_rounded,
                                color: Color(0xFFF5A623), size: 28),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Escucha y elige al animal\ncorrecto',
                                style: TextStyle(
                                  fontFamily: 'Hiruko',
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF3D2B1F),
                                  height: 1.55,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Cuadrícula de animales
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 20,
                          crossAxisSpacing: 20,
                          childAspectRatio: 1.0,
                        ),
                        itemCount: animals.length,
                        itemBuilder: (context, index) {
                          return AnimalCard(
                            imagePath: animals[index]['image'],
                            backgroundColor: animals[index]['color'],
                            onTap: () => _onAnimalSelected(index),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),

      // Botón verde de reproducir
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 10.0),
        child: GestureDetector(
          onTap: _onPlayButtonPressed,
          child: Image.asset(
            'assets/images/actividades/sociales/Botón.png',
            height: 90,
            width: 90,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      // Sin bordes redondeados — color plano amarillo
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      color: const Color(0xFFF39C12),
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Text(
            'Pasado y Presente',
            style: TextStyle(
              fontFamily: 'Hiruko',
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: () => Navigator.maybePop(context),
              child: Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                    color: Colors.white, shape: BoxShape.circle),
                child: const Icon(Icons.close,
                    size: 18, color: Color(0xFFF39C12)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AnimalCard extends StatelessWidget {
  final String imagePath;
  final Color backgroundColor;
  final VoidCallback onTap;

  const AnimalCard({
    Key? key,
    required this.imagePath,
    required this.backgroundColor,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(15.0),
          child: Image.asset(
            imagePath,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}