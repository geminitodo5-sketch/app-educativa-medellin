// ─────────────────────────────────────────────────────────────
//  lib/ui/views/bienvenida.dart
//  Registro del estudiante: nombre + avatar → guarda en BD
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/estudiante_model.dart';
import '../../data/providers/database_provider.dart';
import '../../data/providers/app_state_provider.dart';
import 'seleccion_grado_view.dart';

class WelcomeScreen extends ConsumerStatefulWidget {
  final String? email;
  final String? contrasena;
  final int?    edad;
  final String? genero;

  const WelcomeScreen({
    super.key,
    this.email,
    this.contrasena,
    this.edad,
    this.genero,
  });

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  // 0 = ninguno, 1 = pollito, 2 = monito
  int _avatarSeleccionado = 0;
  final _nombreController = TextEditingController();
  bool _guardando = false;

  @override
  void dispose() {
    _nombreController.dispose();
    super.dispose();
  }

  Future<void> _continuar() async {
    final nombre = _nombreController.text.trim();
    if (nombre.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Escribe tu nombre primero!',
              style: TextStyle(fontFamily: 'Poppins')),
          backgroundColor: Color(0xFFEF5353),
        ),
      );
      return;
    }
    if (_avatarSeleccionado == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Elige tu personaje!',
              style: TextStyle(fontFamily: 'Poppins')),
          backgroundColor: Color(0xFFEF5353),
        ),
      );
      return;
    }

    setState(() => _guardando = true);

    try {
      final repo = ref.read(estudianteRepositoryProvider);
      final personaje = _avatarSeleccionado == 1 ? 'pollito' : 'mono';

      final estudiante = EstudianteModel(
        nombre: nombre,
        grado: 1, // grado temporal, se actualiza en selección de grado
        personaje: personaje,
        fechaRegistro: DateTime.now().toIso8601String(),
        email:     widget.email,
        contrasena: widget.contrasena,
        edad:      widget.edad,
        genero:    widget.genero,
      );

      final id = await repo.crear(estudiante);
      final estudianteGuardado = estudiante.copyWith(id: id);

      // Establece el estudiante activo en el estado global
      ref.read(estudianteActivoProvider.notifier).state = estudianteGuardado;

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (ctx, a, _) => const SeleccionGradoView(),
          transitionsBuilder: (ctx, anim, _, child) =>
              FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 400),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al guardar: $e',
              style: const TextStyle(fontFamily: 'Poppins')),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.shortestSide >= 600;

    // Escalas responsivas
    final double titleFontSize    = isTablet ? 56.0  : 40.0;
    final double subtitleFontSize = isTablet ? 50.0  : 36.0;
    final double labelFontSize    = isTablet ? 32.0  : 24.0;
    final double inputFontSize    = isTablet ? 22.0  : 18.0;
    final double buttonFontSize   = isTablet ? 28.0  : 22.0;
    final double avatarSize       = isTablet ? 140.0 : 100.0;
    final double inputWidth       = isTablet ? 400.0 : 280.0;
    final double buttonWidth      = isTablet ? 300.0 : 220.0;
    final double buttonHeight     = isTablet ? 70.0  : 56.0;
    final double avatarSpacing    = isTablet ? 48.0  : 30.0;
    final double topSpacingFactor = isTablet ? 0.08  : 0.05;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Fondo
          Container(
            decoration: const BoxDecoration(
              color: Color(0xFF7BD0E8),
              image: DecorationImage(
                image: AssetImage('assets/images/interfaz/fondos/fondo.jpg'),
                fit: BoxFit.cover,
                alignment: Alignment.bottomCenter,
              ),
            ),
          ),

          // Contenido
          SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isTablet ? 48.0 : 24.0,
              ),
              child: Column(
                children: [
                  SizedBox(height: screenSize.height * topSpacingFactor),

                  // ¡Hola!
                  Text(
                    '¡Hola!',
                    style: TextStyle(
                      fontFamily: 'Hiruko',
                      fontSize: titleFontSize,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),

                  // Bienvenido a numi
                  RichText(
                    text: TextSpan(
                      style: TextStyle(
                        fontFamily: 'Hiruko',
                        fontSize: subtitleFontSize,
                        fontWeight: FontWeight.bold,
                      ),
                      children: const [
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

                  // ¿Cuál es tu nombre?
                  Text(
                    '¿Cuál es tu nombre?',
                    style: TextStyle(
                      fontFamily: 'Hiruko',
                      fontSize: labelFontSize,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Campo de nombre
                  Container(
                    width: inputWidth,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      controller: _nombreController,
                      textCapitalization: TextCapitalization.words,
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
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: isTablet ? 28.0 : 20.0,
                          vertical:   isTablet ? 20.0 : 16.0,
                        ),
                      ),
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: inputFontSize,
                        color: Colors.black,
                      ),
                    ),
                  ),

                  const SizedBox(height: 36),

                  // Elige tu personaje
                  Text(
                    'Elige tu personaje',
                    style: TextStyle(
                      fontFamily: 'Hiruko',
                      fontSize: labelFontSize,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Avatares
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _AvatarOpcion(
                        index: 1,
                        seleccionado: _avatarSeleccionado == 1,
                        color: const Color(0xFFA855F7),
                        imagen: 'assets/images/bienvenida/pollo feliz 2 (2).png',
                        size: avatarSize,
                        onTap: () => setState(() => _avatarSeleccionado = 1),
                      ),
                      SizedBox(width: avatarSpacing),
                      _AvatarOpcion(
                        index: 2,
                        seleccionado: _avatarSeleccionado == 2,
                        color: const Color(0xFF4ADE80),
                        imagen: 'assets/images/bienvenida/mono.png',
                        size: avatarSize,
                        onTap: () => setState(() => _avatarSeleccionado = 2),
                      ),
                    ],
                  ),

                  const SizedBox(height: 40),

                  // Botón continuar
                  SizedBox(
                    width: buttonWidth,
                    height: buttonHeight,
                    child: ElevatedButton(
                      onPressed: _guardando ? null : _continuar,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3475F7),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                        elevation: 4,
                        shadowColor: const Color(0xFF1A4BBF),
                      ),
                      child: _guardando
                          ? SizedBox(
                              width: isTablet ? 32.0 : 24.0,
                              height: isTablet ? 32.0 : 24.0,
                              child: const CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : Text(
                              '¡Continuar!',
                              style: TextStyle(
                                fontFamily: 'Hiruko',
                                fontSize: buttonFontSize,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 50),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Widget de opción de avatar ───────────────────────────────
class _AvatarOpcion extends StatelessWidget {
  final int index;
  final bool seleccionado;
  final Color color;
  final String imagen;
  final double size;
  final VoidCallback onTap;

  const _AvatarOpcion({
    required this.index,
    required this.seleccionado,
    required this.color,
    required this.imagen,
    required this.size,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        width: size,
        height: size,
        transform: seleccionado
            ? Matrix4.diagonal3Values(1.1, 1.1, 1.0)
            : Matrix4.identity(),
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: seleccionado ? Colors.white : Colors.transparent,
            width: seleccionado ? 4.0 : 0.0,
          ),
          boxShadow: seleccionado
              ? [
                  const BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  ),
                ]
              : [],
        ),
        child: ClipOval(
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Image.asset(imagen, fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }
}