import 'package:flutter/material.dart';
import 'materias_view.dart';

class MenuPrincipal extends StatelessWidget {
  const MenuPrincipal({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Fondo verde/azul cielo
          Positioned.fill(
            child: Image.asset(
              'assets/images/bienvenida/fondos (1).png',
              fit: BoxFit.cover,
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // ─── Encabezado ───
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20.0, vertical: 12.0),
                  child: Row(
                    children: [
                      // Saludo + nombre + nivel
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '¡Hola,',
                            style: TextStyle(
                              fontFamily: 'Hiruko',
                              fontSize: 18,
                              color: Colors.black87,
                            ),
                          ),
                          Row(
                            children: [
                              // Avatar pequeño (pollito)
                              Container(
                                width: 32,
                                height: 32,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFA855F7),
                                  shape: BoxShape.circle,
                                ),
                                child: ClipOval(
                                  child: Image.asset(
                                    'assets/images/bienvenida/pollo1.png',
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                'Camila',
                                style: TextStyle(
                                  fontFamily: 'Hiruko',
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF4ADE80),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Text(
                                  'Nivel 1',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // ─── Mascota (pollito grande) ───
                SizedBox(
                  height: 110,
                  child: Image.asset(
                    'assets/images/bienvenida/pollo1.png',
                    fit: BoxFit.contain,
                  ),
                ),

                const SizedBox(height: 10),

                // ─── Tarjeta blanca con las materias ───
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.92),
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 12,
                          offset: Offset(0, 6),
                        )
                      ],
                    ),
                    child: GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _MateriaCard(
                          label: 'Matemáticas',
                          color: const Color(0xFF3B82F6), // azul
                          icon: '🔢',
                          onTap: () => _irAMateria(context, 'Matemáticas'),
                        ),
                        _MateriaCard(
                          label: 'Sociales',
                          color: const Color(0xFFF97316), // naranja
                          icon: '🌍',
                          onTap: () => _irAMateria(context, 'Sociales'),
                        ),
                        _MateriaCard(
                          label: 'Español',
                          color: const Color(0xFFA855F7), // morado
                          icon: '🔤',
                          onTap: () => _irAMateria(context, 'Español'),
                        ),
                        _MateriaCard(
                          label: 'Ciencias\nNaturales',
                          color: const Color(0xFF22C55E), // verde
                          icon: '🌱',
                          onTap: () => _irAMateria(context, 'Ciencias Naturales'),
                        ),
                        // Botón centrado (Inglés)
                        Center(
                          child: _MateriaCard(
                            label: 'Inglés',
                            color: const Color(0xFFEF4444), // rojo
                            icon: '📚',
                            onTap: () => _irAMateria(context, 'Inglés'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),
              ],
            ),
          ),

          // ─── Bottom Navigation Bar ───
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              margin: const EdgeInsets.only(bottom: 16, left: 40, right: 40),
              padding:
                  const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.95),
                borderRadius: BorderRadius.circular(40),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  )
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    icon: const Icon(Icons.home_rounded,
                        color: Color(0xFF3B82F6), size: 28),
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: const Icon(Icons.check_box_outlined,
                        color: Colors.grey, size: 28),
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: const Icon(Icons.share_rounded,
                        color: Colors.grey, size: 28),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _irAMateria(BuildContext context, String materia) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MateriasView(materia: materia),
      ),
    );
  }
}

// ─── Widget reutilizable para cada materia ───
class _MateriaCard extends StatelessWidget {
  final String label;
  final Color color;
  final String icon;
  final VoidCallback onTap;

  const _MateriaCard({
    required this.label,
    required this.color,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.4),
              blurRadius: 8,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(icon, style: const TextStyle(fontSize: 38)),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Hiruko',
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
