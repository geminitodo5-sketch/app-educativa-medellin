import 'package:flutter/material.dart';

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
  
  // Lista de animales con sus colores y la validación de victoria
  final List<Map<String, dynamic>> animals = [
    {'image': 'assets/images/actividades/sociales/gato.png', 'color': const Color(0xFFA1E296), 'isCorrect': false},
    {'image': 'assets/images/actividades/sociales/Cocodrilo.png', 'color': const Color(0xFFFFE082), 'isCorrect': true}, // CORRECTO
    {'image': 'assets/images/actividades/sociales/pato.png', 'color': const Color(0xFFEF9A9A), 'isCorrect': false},
    {'image': 'assets/images/actividades/sociales/pollo.png', 'color': const Color(0xFFCE93D8), 'isCorrect': false},
  ];

  void _onPlayButtonPressed() {
    // Aquí puedes añadir la lógica de audio más tarde
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
                Navigator.maybePop(context);
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
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // --- ENCABEZADO NARANJA ---
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              decoration: const BoxDecoration(
                color: Color(0xFFF39C12),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 30),
                  const Text(
                    'Pasado y Presente',
                    style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.maybePop(context),
                    child: const Icon(Icons.close, color: Colors.white, size: 30),
                  ),
                ],
              ),
            ),
            
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 25.0, vertical: 30.0),
                child: Column(
                  children: [
                    const Text(
                      'Escucha y elige',
                      style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.black87),
                    ),
                    const SizedBox(height: 20),
                    
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.volume_up_rounded, size: 35, color: Colors.black87),
                        SizedBox(width: 15),
                        Expanded(
                          child: Text(
                            'Escucha y elige al animal\ncorrecto',
                            style: TextStyle(fontSize: 16, color: Colors.black54, height: 1.3),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),
                    
                    // --- CUADRÍCULA DE ANIMALES ---
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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
                    const SizedBox(height: 100), // Espacio para que el botón no tape el grid
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      
      // --- BOTÓN VERDE DE REPRODUCIR ---
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 10.0),
        child: GestureDetector(
          onTap: _onPlayButtonPressed,
          child: Image.asset(
            'assets/images/actividades/sociales/Botón.png', // Tu imagen del botón verde
            height: 90,
            width: 90,
            fit: BoxFit.contain,
          ),
        ),
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