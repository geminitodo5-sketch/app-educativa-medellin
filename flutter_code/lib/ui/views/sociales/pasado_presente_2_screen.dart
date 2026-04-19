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

  // 1. MODIFICACIÓN: Lista con tus rutas de imágenes
  final List<Map<String, dynamic>> keyboardLetters = [
    {'letter': 'A', 'image': 'assets/images/actividades/sociales/Botón letra 9.png'},
    {'letter': 'U', 'image': 'assets/images/actividades/sociales/Botón letra 2.png'},
    {'letter': 'M', 'image': 'assets/images/actividades/sociales/letra m.png'},
     
    {'letter': 'E', 'image': 'assets/images/actividades/sociales/Botón letra 5.png', },
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

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("¡Muy bien!"),
        content: const Text("Completaste la palabra."),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (_) => EscuchaYEligePage(onCompleted: widget.onCompleted),
                ),
              );
            },
            child: const Text("Siguiente"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF39C12),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 30),
                  const Text(
                    'Pasado y Presente',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.maybePop(context),
                    child: const Icon(Icons.close, color: Colors.white, size: 30),
                  ),
                ],
              ),
            ),

            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(40),
                    topRight: Radius.circular(40),
                  ),
                ),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(25.0),
                    child: Column(
                      children: [
                        const Text(
                          '¿Cómo se  llama?',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            const Icon(Icons.volume_up_rounded, size: 40),
                            const SizedBox(width: 10),
                            const Text(
                              'Toca  las  letras que faltan para\ncompletar  la  palabra',
                              style: TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                        const SizedBox(height: 30),

                        // Imagen del teléfono
                        Image.asset(
                          'assets/images/actividades/sociales/telefono1.png',
                          height: 180,
                          errorBuilder: (c, e, s) =>
                              const Icon(Icons.image, size: 100),
                        ),

                        const SizedBox(height: 40),

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
                        const SizedBox(height: 50),

                        // 2. MODIFICACIÓN: GridView usando las imágenes
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
}

// 3. MODIFICACIÓN: Widget que muestra tus PNGs
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
