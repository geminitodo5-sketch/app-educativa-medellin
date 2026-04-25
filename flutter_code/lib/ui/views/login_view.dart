// ─────────────────────────────────────────────────────────────
//  lib/ui/views/login_view.dart
//  Pantalla de inicio de sesión: Email + Contraseña + Google
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/providers/database_provider.dart';
import '../../data/providers/app_state_provider.dart';
import 'menu_1_y_2_view.dart';
import 'bienvenida.dart';

class LoginView extends ConsumerStatefulWidget {
  const LoginView({super.key});

  @override
  ConsumerState<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends ConsumerState<LoginView> {
  final _emailController      = TextEditingController();
  final _contrasenaController = TextEditingController();
  bool _mostrarContrasena = false;
  bool _cargando = false;

  @override
  void dispose() {
    _emailController.dispose();
    _contrasenaController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final email      = _emailController.text.trim();
    final contrasena = _contrasenaController.text.trim();

    if (email.isEmpty || contrasena.isEmpty) {
      _mostrarError('¡Completa todos los campos!');
      return;
    }

    setState(() => _cargando = true);

    try {
      final repo       = ref.read(estudianteRepositoryProvider);
      final estudiante = await repo.buscarPorEmailYContrasena(email, contrasena);

      if (!mounted) return;

      if (estudiante == null) {
        _mostrarError('Email o contraseña incorrectos');
        setState(() => _cargando = false);
        return;
      }

      await repo.actualizarUltimaSesion(estudiante.id!);
      ref.read(estudianteActivoProvider.notifier).state = estudiante;

      if (!mounted) return;

      // Si aún no tiene nombre/avatar, completar registro
      if (estudiante.nombre.isEmpty || estudiante.personaje.isEmpty) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (ctx, a, _) => const WelcomeScreen(),
            transitionsBuilder: (ctx, anim, _, child) =>
                FadeTransition(opacity: anim, child: child),
            transitionDuration: const Duration(milliseconds: 400),
          ),
        );
        return;
      }

      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (ctx, a, _) => Menu1Y2Screen(
            nombre: estudiante.nombre,
            avatar: estudiante.personaje,
            nivel:  estudiante.grado,
          ),
          transitionsBuilder: (ctx, anim, _, child) =>
              FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 400),
        ),
      );
    } catch (e) {
      if (mounted) _mostrarError('Error al iniciar sesión: $e');
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _loginConGoogle() async {}

  void _mostrarError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg,
            style: const TextStyle(
              fontFamily: 'Hiruko',
              fontSize: 16,
              fontWeight: FontWeight.bold,
            )),
        backgroundColor: const Color(0xFFEF5353),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SizedBox.expand(
        child: Stack(
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
                      SizedBox(height: size.height * 0.09),

                      // Título
                      const Text(
                        'Inicia Sesión',
                        style: TextStyle(
                          fontFamily: 'Hiruko',
                          fontSize: 38,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),

                      SizedBox(height: size.height * 0.05),

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

                            const SizedBox(height: 24),

                            // Botón Login (verde)
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: ElevatedButton(
                                onPressed: _cargando ? null : _login,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF4DC63D),
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
                                        'Login',
                                        style: TextStyle(
                                          fontFamily: 'Hiruko',
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                              ),
                            ),

                            const SizedBox(height: 12),

                            // Botón Entra con Google (blanco)
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: OutlinedButton(
                                onPressed: _loginConGoogle,
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: Colors.black87,
                                  side: const BorderSide(
                                    color: Color(0xFFBBBBBB),
                                    width: 1.5,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  elevation: 0,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text(
                                      'Entra con Google ',
                                      style: TextStyle(
                                        fontFamily: 'Hiruko',
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    _GoogleIcon(),
                                  ],
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

            // Pollito (esquina inferior izquierda)
            Positioned(
              bottom: 0,
              left: -8,
              child: IgnorePointer(
                child: Image.asset(
                  'assets/images/bienvenida/pollo1.png',
                  height: size.height * 0.20,
                  fit: BoxFit.contain,
                ),
              ),
            ),

            // Mono (esquina inferior derecha)
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
          borderSide: const BorderSide(color: Color(0xFF4DC63D), width: 1.5),
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
          borderSide: const BorderSide(color: Color(0xFF4DC63D), width: 1.5),
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

// ─── Ícono de Google dibujado con CustomPaint ─────────────────
class _GoogleIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 22,
      height: 22,
      child: CustomPaint(painter: _GoogleLogoPainter()),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r  = size.width / 2;

    canvas.drawCircle(Offset(cx, cy), r, Paint()..color = Colors.white);

    final rect = Rect.fromCircle(center: Offset(cx, cy), radius: r);
    final segments = [
      (Colors.red,   -30.0, 90.0),
      (Colors.amber,  60.0, 90.0),
      (Colors.green, 150.0, 90.0),
      (Colors.blue,  240.0, 90.0),
    ];
    for (final seg in segments) {
      canvas.drawArc(
        rect.deflate(size.width * 0.11),
        seg.$2 * 3.14159265 / 180,
        seg.$3 * 3.14159265 / 180,
        false,
        Paint()
          ..color = seg.$1
          ..style = PaintingStyle.stroke
          ..strokeWidth = size.width * 0.22,
      );
    }

    canvas.drawRect(
      Rect.fromLTWH(cx, cy - r * 0.35, r, r * 0.7),
      Paint()..color = Colors.white,
    );
    canvas.drawRect(
      Rect.fromLTWH(cx, cy - r * 0.13, r * 0.85, r * 0.27),
      Paint()..color = Colors.blue,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
