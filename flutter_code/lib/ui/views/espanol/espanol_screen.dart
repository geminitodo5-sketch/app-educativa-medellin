import 'package:flutter/material.dart';

class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Próximamente')),
      body: const Center(child: Text('Pantalla en construcción')),
    );
  }
}

class EspanolScreen extends StatelessWidget {
  const EspanolScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black, size: 30),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Stack(
        children: [
          // Fondo
          Positioned.fill(
            child: Image.asset(
              'assets/images/bienvenida/fondos (1).png',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                // Fallback a la ruta sin bienvenida si no la encuentra
                return Image.asset(
                  'assets/images/fondos (1).png',
                  fit: BoxFit.cover,
                );
              },
            ),
          ),
          
          // Pollito (flotando arriba a la izquierda del contenido)
          Positioned(
            top: 150,
            left: 20,
            child: Image.asset(
              'assets/images/bienvenida/pollo1.png',
              width: 80,
              errorBuilder: (context, error, stackTrace) {
                return Image.asset('assets/images/pollo1.png', width: 80);
              },
            ),
          ),
          
          // Monito (en la esquina inferior derecha, parcialmente recortado)
          Positioned(
            bottom: -20,
            right: -20,
            child: Image.asset(
              'assets/images/bienvenida/mono.png',
              width: 120,
              errorBuilder: (context, error, stackTrace) {
                return Image.asset('assets/images/mono.png', width: 120);
              },
            ),
          ),
          
          // Contenido principal
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  // Título Español
                  const Text(
                    'Español',
                    style: TextStyle(
                      fontFamily: 'Hiruko',
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 60),
                  
                  // Tarjetas tipo botón
                  _ActividadCard(
                    texto: 'Palabra loca',
                    imagenLeft: 'assets/images/areas/espanol/palabra_loca.png',
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const PlaceholderScreen()));
                    },
                  ),
                  const SizedBox(height: 20),
                  _ActividadCard(
                    texto: 'Arma la palabra',
                    imagenLeft: 'assets/images/areas/espanol/arma_palabra.png',
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const PlaceholderScreen()));
                    },
                  ),
                  const SizedBox(height: 20),
                  _ActividadCard(
                    texto: 'Oraciones',
                    imagenLeft: 'assets/images/areas/espanol/gato.png',
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const PlaceholderScreen()));
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActividadCard extends StatelessWidget {
  final String texto;
  final String imagenLeft;
  final VoidCallback onTap;

  const _ActividadCard({
    required this.texto,
    required this.imagenLeft,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 90,
        decoration: BoxDecoration(
          color: const Color(0xFFF65757),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            // Imagen a la izquierda (cuadrada con borde blanco)
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.asset(
                  imagenLeft,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    // Placeholder si la imagen no existe
                    return Icon(Icons.image, color: Colors.grey[400]);
                  },
                ),
              ),
            ),
            const SizedBox(width: 16),
            
            // Texto en blanco bold 24px
            Expanded(
              child: Text(
                texto,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            
            // Flecha -> a la derecha
            const Icon(
              Icons.arrow_forward,
              color: Colors.white,
              size: 32,
            ),
          ],
        ),
      ),
    );
  }
}
