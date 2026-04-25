// ─────────────────────────────────────────────────────────────
//  lib/ui/views/registro_view.dart
//  Pantalla de registro: Edad, Género, Email, Contraseña
//  Aparece después de la animación de Numi y antes de Bienvenida
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/providers/database_provider.dart';
import 'bienvenida.dart';
import 'login_view.dart';

class RegistroView extends ConsumerStatefulWidget {
  const RegistroView({super.key});

  @override
  ConsumerState<RegistroView> createState() => _RegistroViewState();
}

class _RegistroViewState extends ConsumerState<RegistroView> {
  final _edadController      = TextEditingController();
  final _generoController    = TextEditingController();
  final _emailController     = TextEditingController();
  final _contrasenaController = TextEditingController();
  bool _mostrarContrasena = false;
  bool _cargando = false;

  @override
  void dispose() {
    _edadController.dispose();
    _generoController.dispose();
    _emailController.dispose();
    _contrasenaController.dispose();
    super.dispose();
  }

  Future<void> _continuar() async {
    final edad      = _edadController.text.trim();
    final genero    = _generoController.text.trim();
    final email     = _emailController.text.trim();
    final contrasena = _contrasenaController.text.trim();

    if (edad.isEmpty || genero.isEmpty || email.isEmpty || contrasena.isEmpty) {
      _mostrarError('¡Completa todos los campos!');
      return;
    }
    if (!email.contains('@')) {
      _mostrarError('Ingresa un email válido');
      return;
    }
    if (contrasena.length < 6) {
      _mostrarError('La contraseña debe tener al menos 6 caracteres');
      return;
    }

    setState(() => _cargando = true);

    try {
      // Verificar que el email no esté ya registrado
      final repo = ref.read(estudianteRepositoryProvider);
      final todos = await repo.listarTodos();
      final emailOcupado = todos.any((e) => e.email == email);

      if (!mounted) return;

      if (emailOcupado) {
        _mostrarError('Ese email ya está registrado. ¡Inicia sesión!');
        setState(() => _cargando = false);
        return;
      }

      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (ctx, a, _) => WelcomeScreen(
            email:      email,
            contrasena: contrasena,
            edad:       int.tryParse(edad),
            genero:     genero,
          ),
          transitionsBuilder: (ctx, anim, _, child) =>
              FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 400),
        ),
      );
    } catch (e) {
      if (mounted) _mostrarError('Error al registrar: $e');
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  void _mostrarError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontFamily: 'Poppins')),
        backgroundColor: const Color(0xFFEF5353),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

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

          // Contenido principal
          SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.zero,
              child: SizedBox(
                width: double.infinity,
                child: Column(
                  children: [
                    SizedBox(height: size.height * 0.06),

                    // Título
                    const Text(
                      'Regístrate',
                      style: TextStyle(
                        fontFamily: 'Hiruko',
                        fontSize: 38,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),

                    SizedBox(height: size.height * 0.04),

                    // Tarjeta del formulario
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 28),
                      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEEFF2),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Edad
                          _buildLabel('Edad'),
                          const SizedBox(height: 6),
                          _buildTextField(
                            controller: _edadController,
                            keyboardType: TextInputType.number,
                          ),
                          const SizedBox(height: 18),

                          // Género
                          _buildLabel('Género'),
                          const SizedBox(height: 6),
                          _buildTextField(controller: _generoController),
                          const SizedBox(height: 18),

                          // Email
                          _buildLabel('Email'),
                          const SizedBox(height: 6),
                          _buildTextField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 18),

                          // Contraseña
                          _buildLabel('Contraseña'),
                          const SizedBox(height: 6),
                          _buildPasswordField(),

                          const SizedBox(height: 28),

                          // Botón Continuar
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              onPressed: _cargando ? null : _continuar,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF4A8BF5),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                elevation: 0,
                              ),
                              child: _cargando
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2.5,
                                      ),
                                    )
                                  : const Text(
                                      'Continuar',
                                      style: TextStyle(
                                        fontFamily: 'Hiruko',
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),

                          const SizedBox(height: 18),

                          // ¿Ya tienes cuenta?
                          Center(
                            child: GestureDetector(
                              onTap: () {
                                Navigator.of(context).pushReplacement(
                                  PageRouteBuilder(
                                    pageBuilder: (ctx, a, _) =>
                                        const LoginView(),
                                    transitionsBuilder:
                                        (ctx, anim, _, child) =>
                                            FadeTransition(
                                                opacity: anim, child: child),
                                    transitionDuration:
                                        const Duration(milliseconds: 400),
                                  ),
                                );
                              },
                              child: RichText(
                                text: const TextSpan(
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 14,
                                    color: Colors.black54,
                                  ),
                                  children: [
                                    TextSpan(text: '¿Ya tienes cuenta? '),
                                    TextSpan(
                                      text: 'Inicia sesión',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: size.height * 0.18),
                  ],
                ),
              ),
            ),
          ),

          // Mono (Numi) en la esquina inferior derecha
          Positioned(
            bottom: 0,
            right: -10,
            child: IgnorePointer(
              child: Image.asset(
                'assets/images/bienvenida/mono.png',
                height: size.height * 0.22,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: 'Poppins',
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Color(0xFF555555),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(
        fontFamily: 'Poppins',
        fontSize: 15,
        color: Colors.black87,
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF4A8BF5), width: 1.5),
        ),
      ),
    );
  }

  Widget _buildPasswordField() {
    return TextField(
      controller: _contrasenaController,
      obscureText: !_mostrarContrasena,
      style: const TextStyle(
        fontFamily: 'Poppins',
        fontSize: 15,
        color: Colors.black87,
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF4A8BF5), width: 1.5),
        ),
        suffixIcon: GestureDetector(
          onTap: () =>
              setState(() => _mostrarContrasena = !_mostrarContrasena),
          child: Icon(
            _mostrarContrasena ? Icons.visibility : Icons.visibility_off,
            color: Colors.grey,
            size: 22,
          ),
        ),
      ),
    );
  }
}
