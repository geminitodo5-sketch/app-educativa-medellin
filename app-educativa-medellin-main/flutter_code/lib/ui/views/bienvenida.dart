import 'package:flutter/material.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({Key? key}) : super(key: key);

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  // 0 = none, 1 = pollito, 2 = monito
  int selectedAvatarIndex = 0;

  @override
  Widget build(BuildContext context) {
    // Get screen dimensions
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: Image.asset(
              'assets/images/bienvenida/fondos (1).png',
              fit: BoxFit.cover,
            ),
          ),
          
          // Foreground Content
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                children: [
                  // Top spacing - approx 30% of screen height
                  SizedBox(height: screenSize.height * 0.30),
                  
                  // ¡Hola!
                  const Text(
                    '¡Hola!',
                    style: TextStyle(
                      fontFamily: 'Hiruko',
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),

                  // Bienvenido a numi
                  RichText(
                    text: const TextSpan(
                      style: TextStyle(
                        fontFamily: 'Hiruko',
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                      ),
                      children: [
                        TextSpan(
                          text: 'Bienvenido a ',
                          style: TextStyle(color: Colors.black),
                        ),
                        TextSpan(
                          text: 'numi',
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 30),

                  // Label: ¿Cuál es tu nombre?
                  const Text(
                    '¿Cuál es tu nombre?',
                    style: TextStyle(
                      fontFamily: 'Hiruko',
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  
                  const SizedBox(height: 12),

                  // Input box
                  Container(
                    width: 280, // Narrower width
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Nombre',
                        hintStyle: const TextStyle(
                          color: Colors.grey,
                          fontFamily: 'Poppins',
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20, 
                          vertical: 16,
                        ),
                      ),
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 18,
                        color: Colors.black,
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Label: Elige tu personaje
                  const Text(
                    'Elige tu personaje',
                    style: TextStyle(
                      fontFamily: 'Hiruko',
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Avatars
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Pollito Avatar
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedAvatarIndex = 1;
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeOut,
                          width: 100,
                          height: 100,
                          transform: selectedAvatarIndex == 1
                              ? (Matrix4.identity()..scale(1.1))
                              : Matrix4.identity(),
                          decoration: BoxDecoration(
                            color: const Color(0xFFA855F7), // Purple/Lilac
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: selectedAvatarIndex == 1 
                                  ? Colors.white 
                                  : Colors.transparent,
                              width: selectedAvatarIndex == 1 ? 4.0 : 0.0,
                            ),
                            boxShadow: selectedAvatarIndex == 1
                                ? [
                                    const BoxShadow(
                                      color: Colors.black26,
                                      blurRadius: 10,
                                      offset: Offset(0, 5),
                                    )
                                  ]
                                : [],
                          ),
                          child: ClipOval(
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Image.asset(
                                'assets/images/bienvenida/pollo1.png',
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 30),

                      // Monito Avatar
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedAvatarIndex = 2;
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeOut,
                          width: 100,
                          height: 100,
                          transform: selectedAvatarIndex == 2
                              ? (Matrix4.identity()..scale(1.1))
                              : Matrix4.identity(),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4ADE80), // Green
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: selectedAvatarIndex == 2 
                                  ? Colors.white 
                                  : Colors.transparent,
                              width: selectedAvatarIndex == 2 ? 4.0 : 0.0,
                            ),
                            boxShadow: selectedAvatarIndex == 2
                                ? [
                                    const BoxShadow(
                                      color: Colors.black26,
                                      blurRadius: 10,
                                      offset: Offset(0, 5),
                                    )
                                  ]
                                : [],
                          ),
                          child: ClipOval(
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Image.asset(
                                'assets/images/bienvenida/mono.png',
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 50), // bottom padding
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
