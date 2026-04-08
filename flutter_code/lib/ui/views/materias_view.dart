import 'package:flutter/material.dart';

class MateriasView extends StatelessWidget {
  final String materia;

  const MateriasView({Key? key, required this.materia}) : super(key: key);

  // Configuración visual por materia
  static const Map<String, _MateriaConfig> _configs = {
    'Matemáticas': _MateriaConfig(
      color: Color(0xFF3B82F6),
      icon: '🔢',
      temas: [
        'Suma y resta',
        'Multiplicación',
        'División',
        'Fracciones',
        'Figuras geométricas',
      ],
    ),
    'Sociales': _MateriaConfig(
      color: Color(0xFFF97316),
      icon: '🌍',
      temas: [
        'Mi ciudad',
        'Colombia y sus regiones',
        'Historia patria',
        'Medioambiente',
        'Derechos y deberes',
      ],
    ),
    'Español': _MateriaConfig(
      color: Color(0xFFA855F7),
      icon: '🔤',
      temas: [
        'Lectura comprensiva',
        'Ortografía',
        'Gramática',
        'Escritura creativa',
        'Vocabulario',
      ],
    ),
    'Ciencias Naturales': _MateriaConfig(
      color: Color(0xFF22C55E),
      icon: '🌱',
      temas: [
        'Seres vivos',
        'El cuerpo humano',
        'Ecosistemas',
        'El sistema solar',
        'Experimentos',
      ],
    ),
    'Inglés': _MateriaConfig(
      color: Color(0xFFEF4444),
      icon: '📚',
      temas: [
        'Alphabet & numbers',
        'Colors & shapes',
        'Family & friends',
        'Animals',
        'Greetings',
      ],
    ),
  };

  @override
  Widget build(BuildContext context) {
    final config = _configs[materia] ??
        const _MateriaConfig(
          color: Color(0xFF3B82F6),
          icon: '📖',
          temas: [],
        );

    return Scaffold(
      body: Stack(
        children: [
          // Fondo degradado del color de la materia
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    config.color,
                    config.color.withOpacity(0.6),
                    const Color(0xFFE0F7FA),
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // ─── Header ───
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20.0, vertical: 16.0),
                  child: Row(
                    children: [
                      // Botón regresar
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.3),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.arrow_back_ios_new_rounded,
                              color: Colors.white, size: 18),
                        ),
                      ),
                      const Spacer(),
                      // Título materia
                      Text(
                        materia,
                        style: const TextStyle(
                          fontFamily: 'Hiruko',
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const Spacer(),
                      // Ícono grande
                      Text(config.icon, style: const TextStyle(fontSize: 32)),
                    ],
                  ),
                ),

                // ─── Mascota animada ───
                SizedBox(
                  height: 100,
                  child: Image.asset(
                    'assets/images/bienvenida/pollo1.png',
                    fit: BoxFit.contain,
                  ),
                ),

                const SizedBox(height: 8),

                // Texto motivador
                Text(
                  '¡Elige un tema para aprender!',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 15,
                    color: Colors.white.withOpacity(0.9),
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 16),

                // ─── Lista de temas ───
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.93),
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 12,
                          offset: Offset(0, 6),
                        )
                      ],
                    ),
                    child: ListView.separated(
                      itemCount: config.temas.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        return _TemaCard(
                          numero: index + 1,
                          titulo: config.temas[index],
                          color: config.color,
                          onTap: () {
                            // TODO: Navegar a la actividad del tema
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    '¡Próximamente: ${config.temas[index]}!'),
                                backgroundColor: config.color,
                                duration: const Duration(seconds: 1),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Widget para cada tema ───
class _TemaCard extends StatelessWidget {
  final int numero;
  final String titulo;
  final Color color;
  final VoidCallback onTap;

  const _TemaCard({
    required this.numero,
    required this.titulo,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.25), width: 1.5),
        ),
        child: Row(
          children: [
            // Número
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '$numero',
                  style: const TextStyle(
                    fontFamily: 'Hiruko',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            // Título del tema
            Expanded(
              child: Text(
                titulo,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: color.withOpacity(0.85),
                ),
              ),
            ),
            // Flecha
            Icon(Icons.arrow_forward_ios_rounded,
                size: 16, color: color.withOpacity(0.6)),
          ],
        ),
      ),
    );
  }
}

// ─── Clase de configuración por materia ───
class _MateriaConfig {
  final Color color;
  final String icon;
  final List<String> temas;

  const _MateriaConfig({
    required this.color,
    required this.icon,
    required this.temas,
  });
}
