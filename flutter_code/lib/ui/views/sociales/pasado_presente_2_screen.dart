import 'package:flutter/material.dart';
import 'pasado_presente_3_screen.dart';

void main() {
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: TelefonoGameScreen(),
    ),
  );
}

class TelefonoGameScreen extends StatefulWidget {
  const TelefonoGameScreen({super.key, this.onCompleted});
  final VoidCallback? onCompleted;

  @override
  State<TelefonoGameScreen> createState() => _TelefonoGameScreenState();
}

class _TelefonoGameScreenState extends State<TelefonoGameScreen> {
  final String targetWord = "TELÉFONO";

  // T E _ É _ O _ O
  List<String?> userSlots = ['T', 'E', null, 'É', null, 'O', null, 'O'];

  final List<Map<String, dynamic>> keyboardLetters = [
    {'letter': 'A', 'image': 'assets/images/actividades/sociales/Botón letra 9.png'},
    {'letter': 'U', 'image': 'assets/images/actividades/sociales/Botón letra 2.png'},
    {'letter': 'M', 'image': 'assets/images/actividades/sociales/letra m.png'},
    {'letter': 'E', 'image': 'assets/images/actividades/sociales/Botón letra 5.png'},
    {'letter': 'C', 'image': 'assets/images/actividades/sociales/Botón letra 4_1.png'},
    {'letter': 'L', 'image': 'assets/images/actividades/sociales/Botón letra 4.png'},
    {'letter': 'N', 'image': 'assets/images/actividades/sociales/Botón letra 6.png'},
    {'letter': 'T', 'image': 'assets/images/actividades/sociales/letra t.png'},
    {'letter': 'F', 'image': 'assets/images/actividades/sociales/Botón letra 1.png'},
  ];

  void _handleLetterTap(String letter) {
    setState(() {
      int emptyIndex = userSlots.indexOf(null);
      if (emptyIndex != -1) {
        userSlots[emptyIndex] = letter;
      }
    });

    if (!userSlots.contains(null) && userSlots.join('') == targetWord) {
      _showSuccessDialog();
    }
  }

  void _removeLetter(int index) {
    if (index == 2 || index == 4 || index == 6) {
      setState(() {
        userSlots[index] = null;
      });
    }
  }

  void _mostrarFeedback(bool esCorrecto, VoidCallback onAction) {
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
                    color: esCorrecto ? const Color(0xFF59E347) : const Color(0xFFF65757),
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
                    backgroundColor: esCorrecto ? const Color(0xFF59E347) : const Color(0xFFF65757),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    onAction();
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

  void _showSuccessDialog() {
    _mostrarFeedback(true, () {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => EscuchaYEligePage(onCompleted: widget.onCompleted),
        ),
      );
    });
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
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                    child: Column(
                      children: [
                        // Título
                        const Text(
                          '¿Cómo se llama?',
                          style: TextStyle(
                            fontFamily: 'Hiruko',
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF3D2B1F),
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Enunciado con fuente Hiruko bold igual que la imagen de referencia
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
                                  'Toca las letras que faltan para\ncompletar la palabra',
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
                        const SizedBox(height: 24),

                        // Imagen del teléfono
                        Image.asset(
                          'assets/images/actividades/sociales/telefono1.png',
                          height: 180,
                          errorBuilder: (c, e, s) =>
                              const Icon(Icons.image, size: 100),
                        ),

                        const SizedBox(height: 32),

                        // Slots de la palabra
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(userSlots.length, (index) {
                            return GestureDetector(
                              onTap: () => _removeLetter(index),
                              child: Container(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                decoration: const BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(
                                      width: 2,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                                width: 30,
                                height: 40,
                                child: Center(
                                  child: Text(
                                    userSlots[index] ?? "",
                                    style: const TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                        const SizedBox(height: 40),

                        // GridView de letras
                        SizedBox(
                          width: 280,
                          child: GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              mainAxisSpacing: 15,
                              crossAxisSpacing: 15,
                              childAspectRatio: 1.0,
                            ),
                            itemCount: keyboardLetters.length,
                            itemBuilder: (context, index) {
                              return LetterButton(
                                imagePath: keyboardLetters[index]['image'],
                                onTap: () => _handleLetterTap(
                                  keyboardLetters[index]['letter'],
                                ),
                              );
                            },
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

// Widget que muestra los PNGs de letras
class LetterButton extends StatelessWidget {
  final String imagePath;
  final VoidCallback onTap;

  const LetterButton({required this.imagePath, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Image.asset(
        imagePath,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => Container(
          color: Colors.grey.shade200,
          child: const Icon(Icons.broken_image),
        ),
      ),
    );
  }
}