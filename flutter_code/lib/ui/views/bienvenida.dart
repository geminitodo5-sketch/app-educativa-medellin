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

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // Fondo
          Positioned.fill(
            child: Image.asset(
              'assets/images/bienvenida/fondos (1).png',
              fit: BoxFit.cover,
            ),
          ),

          // Contenido
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                children: [
                  SizedBox(height: screenSize.height * 0.28),

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

                  // ¿Cuál es tu nombre?
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

                  // Campo de nombre
                  Container(
                    width: 280,
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

                  const SizedBox(height: 36),

                  // Elige tu personaje
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

                  // Avatares
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _AvatarOpcion(
                        index: 1,
                        seleccionado: _avatarSeleccionado == 1,
                        color: const Color(0xFFA855F7),
                        imagen: 'assets/images/bienvenida/pollo feliz 2 (2).png',
                        onTap: () => setState(() => _avatarSeleccionado = 1),
                      ),
                      const SizedBox(width: 30),
                      _AvatarOpcion(
                        index: 2,
                        seleccionado: _avatarSeleccionado == 2,
                        color: const Color(0xFF4ADE80),
                        imagen: 'assets/images/bienvenida/mono.png',
                        onTap: () => setState(() => _avatarSeleccionado = 2),
                      ),
                    ],
                  ),

                  const SizedBox(height: 40),

                  // Botón continuar
                  SizedBox(
                    width: 220,
                    height: 56,
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
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : const Text(
                              '¡Continuar!',
                              style: TextStyle(
                                fontFamily: 'Hiruko',
                                fontSize: 22,
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
  final VoidCallback onTap;

  const _AvatarOpcion({
    required this.index,
    required this.seleccionado,
    required this.color,
    required this.imagen,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        width: 100,
        height: 100,
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
