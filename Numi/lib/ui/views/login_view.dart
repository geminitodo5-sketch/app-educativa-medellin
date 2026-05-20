import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/providers/database_provider.dart';
import '../../data/services/firebase_auth_service.dart';
import '../../data/providers/app_state_provider.dart';
import '../../data/providers/musica_provider.dart';
import '../../data/models/estudiante_model.dart';
import 'menu_1_y_2_view.dart';
import 'menu_3_a_5_view.dart';
import 'bienvenida.dart';
import 'registro_view.dart';

class LoginView extends ConsumerStatefulWidget {
  const LoginView({super.key});

  @override
  ConsumerState<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends ConsumerState<LoginView> {
  final _emailController = TextEditingController();
  final _contrasenaController = TextEditingController();
  bool _mostrarContrasena = false;
  bool _cargando = false;

  @override
  void initState() {
    super.initState();
    ref.read(musicaServiceProvider).entrar();
  }

  @override
  void dispose() {
    ref.read(musicaServiceProvider).salir();
    _emailController.dispose();
    _contrasenaController.dispose();
    super.dispose();
  }

  // ── Login con email y contraseña via Firebase ────────────────
  Future<void> _login() async {
    final email = _emailController.text.trim();
    final contrasena = _contrasenaController.text.trim();

    if (email.isEmpty || contrasena.isEmpty) {
      _mostrarError('¡Completa todos los campos!');
      return;
    }

    setState(() => _cargando = true);

    try {
      final authService = ref.read(firebaseAuthServiceProvider);
      final credential = await authService.loginConEmail(email, contrasena);

      // Recarga para obtener el estado real de verificación desde el servidor
      await authService.recargarUsuario();

      if (!authService.estaVerificado) {
        // El usuario está autenticado temporalmente → aprovechar para el reenvío
        if (mounted) await _mostrarDialogoNoVerificado(email, authService);
        await authService.cerrarSesion();
        return;
      }

      final uid = credential.user!.uid;
      if (!mounted) return;
      await _entrarConFirebaseUid(uid, email: email);
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        _mostrarError(
          e.code == 'invalid-credential' || e.code == 'user-not-found'
              ? 'Email o contraseña incorrectos'
              : _mensajeFirebase(e),
        );
      }
    } catch (e) {
      if (mounted) _mostrarError('Error al iniciar sesión: $e');
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  // ── Diálogo de correo sin verificar ──────────────────────────
  Future<void> _mostrarDialogoNoVerificado(
      String email, FirebaseAuthService authService) async {
    bool enviando = false;
    bool reenviado = false;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (_, setDS) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.mark_email_unread_rounded,
                  color: Color(0xFF4A8BF5), size: 26),
              SizedBox(width: 10),
              Expanded(
                child: Text('Verifica tu Gmail',
                    style: TextStyle(fontFamily: 'Hiruko', fontSize: 20)),
              ),
            ],
          ),
          content: Text(
            'Tu cuenta aún no está verificada.\n\n'
            'Revisa tu Gmail ($email) y toca el enlace de activación. '
            'Luego vuelve a iniciar sesión.\n\n'
            'Si no lo ves, revisa la carpeta Spam.',
            style: const TextStyle(
                fontFamily: 'Poppins', fontSize: 13.5, height: 1.55),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Entendido',
                  style: TextStyle(
                      fontFamily: 'Poppins', color: Colors.grey)),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4A8BF5),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              icon: enviando
                  ? const SizedBox(
                      width: 15,
                      height: 15,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : Icon(reenviado ? Icons.check_rounded : Icons.send_rounded,
                      size: 16),
              label: Text(
                reenviado ? '¡Enviado!' : 'Reenviar correo',
                style: const TextStyle(fontFamily: 'Hiruko', fontSize: 15),
              ),
              onPressed: enviando || reenviado
                  ? null
                  : () async {
                      setDS(() => enviando = true);
                      try {
                        await authService.enviarVerificacionEmail();
                        setDS(() {
                          enviando = false;
                          reenviado = true;
                        });
                      } catch (_) {
                        setDS(() => enviando = false);
                      }
                    },
            ),
          ],
        ),
      ),
    );
  }

  // ── Recuperar contraseña ──────────────────────────────────────
  Future<void> _olvideMiContrasena() async {
    final controller =
        TextEditingController(text: _emailController.text.trim());

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.lock_reset_rounded, color: Color(0xFF4DC63D), size: 26),
            SizedBox(width: 10),
            Text('Recuperar contraseña',
                style: TextStyle(fontFamily: 'Hiruko', fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Escribe tu correo Gmail. Te enviaremos un enlace para crear una nueva contraseña.',
              style: TextStyle(
                  fontFamily: 'Poppins', fontSize: 13, height: 1.5),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: controller,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(fontFamily: 'Poppins', fontSize: 14),
              decoration: InputDecoration(
                hintText: 'tucorreo@gmail.com',
                hintStyle: const TextStyle(
                    fontFamily: 'Poppins', color: Colors.grey),
                filled: true,
                fillColor: const Color(0xFFF5F5F5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                      color: Color(0xFF4DC63D), width: 1.5),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar',
                style: TextStyle(fontFamily: 'Poppins', color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4DC63D),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              final email = controller.text.trim();
              if (email.isEmpty) return;
              Navigator.pop(ctx);
              try {
                final authService = ref.read(firebaseAuthServiceProvider);
                await authService.enviarCorreoRecuperacion(email);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Correo enviado a $email',
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            '📌 Si no lo ves, revisa la carpeta SPAM o Correo no deseado',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      backgroundColor: const Color(0xFF4DC63D),
                      duration: const Duration(seconds: 7),
                    ),
                  );
                }
              } on FirebaseAuthException catch (e) {
                if (mounted) {
                  _mostrarError(
                    e.code == 'user-not-found'
                        ? 'No hay una cuenta registrada con ese correo'
                        : 'Error al enviar: ${e.message ?? e.code}',
                  );
                }
              } catch (e) {
                if (mounted) {
                  _mostrarError('Error inesperado: $e');
                }
              }
            },
            child: const Text('Enviar correo',
                style: TextStyle(
                    fontFamily: 'Hiruko',
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // ── Login con Google ──────────────────────────────────────────
  Future<void> _loginConGoogle() async {
    setState(() => _cargando = true);
    try {
      final authService = ref.read(firebaseAuthServiceProvider);
      final credential = await authService.loginConGoogle();

      if (credential == null) {
        // El usuario canceló el selector de cuenta
        setState(() => _cargando = false);
        return;
      }

      final uid = credential.user!.uid;
      final email = credential.user?.email;

      if (!mounted) return;

      // Google envía automáticamente una notificación de seguridad al Gmail
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.security_rounded, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Google envió una notificación de seguridad a ${email ?? 'tu Gmail'}',
                  style: const TextStyle(
                      fontFamily: 'Poppins', fontSize: 13),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF1A73E8),
          duration: const Duration(seconds: 4),
        ),
      );

      await _entrarConFirebaseUid(uid, email: email);
    } on FirebaseAuthException catch (e) {
      if (mounted) _mostrarError(_mensajeFirebase(e));
    } catch (e) {
      if (mounted) _mostrarError('Error con Google Sign-In: $e');
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  // ── Lógica común: busca perfil local y navega ─────────────────
  Future<void> _entrarConFirebaseUid(String uid, {String? email}) async {
    final repo     = ref.read(estudianteRepositoryProvider);
    final syncCase = ref.read(sincronizarUseCaseProvider);

    // 1. Buscar por firebase_uid
    var estudiante = await repo.buscarPorFirebaseUid(uid);

    // 2. Si no existe, buscar por email (migración de cuentas legacy)
    if (estudiante == null && email != null) {
      estudiante = await repo.buscarPorEmail(email);
      if (estudiante != null) {
        await repo.vincularFirebaseUid(estudiante.id!, uid);
        estudiante = estudiante.copyWith(firebaseUid: uid);
      }
    }

    if (!mounted) return;

    // 3. Sin perfil local → intentar restaurar desde Firestore (nuevo dispositivo)
    if (estudiante == null) {
      final restored = await syncCase.sincronizarAlLogin(uid);

      if (!mounted) return;

      if (restored != null) {
        // Perfil restaurado desde la nube → entrar directamente
        await repo.actualizarUltimaSesion(restored.id!);
        ref.read(estudianteActivoProvider.notifier).state = restored;
        if (!mounted) return;
        _navegarAlMenu(restored);
      } else {
        // Usuario completamente nuevo → crear perfil
        _navegarABienvenida(email: email, uid: uid);
      }
      return;
    }

    // 4. Perfil local encontrado → actualizar sesión, entrar y sincronizar
    await repo.actualizarUltimaSesion(estudiante.id!);
    ref.read(estudianteActivoProvider.notifier).state = estudiante;

    // Sync en background: sube avances locales y descarga los del otro dispositivo
    syncCase.ejecutar(estudiante.id!).ignore();

    if (!mounted) return;

    if (estudiante.nombre.isEmpty || estudiante.personaje.isEmpty) {
      _navegarABienvenida(email: email, uid: uid);
      return;
    }

    _navegarAlMenu(estudiante);
  }

  void _navegarAlMenu(EstudianteModel e) {
    final Widget destino = e.grado <= 2
        ? Menu1Y2Screen(
            nombre: e.nombre,
            avatar: e.personaje,
            nivel: e.grado,
          )
        : const Menu3A5Screen();

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (ctx, a, _) => destino,
        transitionsBuilder: (ctx, anim, _, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  void _navegarABienvenida({String? email, required String uid}) {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (ctx, a, _) => WelcomeScreen(
          email:       email,
          firebaseUid: uid,
        ),
        transitionsBuilder: (ctx, anim, _, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────
  String _mensajeFirebase(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Email o contraseña incorrectos';
      case 'user-disabled':
        return 'Esta cuenta ha sido deshabilitada';
      case 'too-many-requests':
        return 'Demasiados intentos. Espera un momento';
      case 'network-request-failed':
        return 'Sin conexión a internet';
      case 'account-exists-with-different-credential':
        return 'Ya existe una cuenta con ese email usando otro método';
      default:
        return 'Error: ${e.message ?? e.code}';
    }
  }

  void _mostrarError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: const TextStyle(
            fontFamily: 'Hiruko',
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFFEF5353),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SizedBox.expand(
        child: Stack(
          children: [
            // ── Fondo ─────────────────────────────────────────
            Positioned.fill(
              child: Image.asset(
                'assets/images/bienvenida/fondos (1).png',
                fit: BoxFit.cover,
              ),
            ),

            // ── Contenido principal ───────────────────────────
            SafeArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.zero,
                child: SizedBox(
                  width: double.infinity,
                  child: Column(
                    children: [
                      SizedBox(height: size.height * 0.04),

                      // ── Botón volver ───────────────────────
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 16),
                          child: GestureDetector(
                            onTap: () => Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                builder: (_) => const RegistroView(),
                              ),
                            ),
                            child: Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.08),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.arrow_back_ios_new_rounded,
                                size: 18,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: size.height * 0.04),

                      // ── Título ─────────────────────────────
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

                      // ── Tarjeta del formulario ─────────────
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

                            const SizedBox(height: 8),

                            // ¿Olvidaste tu contraseña?
                            Align(
                              alignment: Alignment.centerRight,
                              child: GestureDetector(
                                onTap: _olvideMiContrasena,
                                child: const Text(
                                  '¿Olvidaste tu contraseña?',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF4DC63D),
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 16),

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
                                onPressed: _cargando ? null : _loginConGoogle,
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

            // ── Pollito — responsive y reactivo al teclado ────
            Builder(
              builder: (context) {
                final bottomInset = MediaQuery.of(context).viewInsets.bottom;
                final pollitoHeight = size.height * 0.17;

                return AnimatedPositioned(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOut,
                  bottom: bottomInset > 0 ? -(pollitoHeight * 0.6) : 0,
                  left: -8,
                  child: IgnorePointer(
                    child: Image.asset(
                      'assets/images/bienvenida/pollo1.png',
                      height: pollitoHeight,
                      width: size.width * 0.35,
                      fit: BoxFit.contain,
                      alignment: Alignment.bottomLeft,
                    ),
                  ),
                );
              },
            ),

            // ── Mono — responsive y reactivo al teclado ───────
            Builder(
              builder: (context) {
                final bottomInset = MediaQuery.of(context).viewInsets.bottom;
                final monoHeight = size.height * 0.22;

                return AnimatedPositioned(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOut,
                  bottom: bottomInset > 0 ? -(monoHeight * 0.6) : 0,
                  right: -10,
                  child: IgnorePointer(
                    child: Image.asset(
                      'assets/images/bienvenida/mono.png',
                      height: monoHeight,
                      width: size.width * 0.38,
                      fit: BoxFit.contain,
                      alignment: Alignment.bottomRight,
                    ),
                  ),
                );
              },
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
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
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
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
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
          onTap: () => setState(() => _mostrarContrasena = !_mostrarContrasena),
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
    final r = size.width / 2;

    canvas.drawCircle(Offset(cx, cy), r, Paint()..color = Colors.white);

    final rect = Rect.fromCircle(center: Offset(cx, cy), radius: r);
    final segments = [
      (Colors.red, -30.0, 90.0),
      (Colors.amber, 60.0, 90.0),
      (Colors.green, 150.0, 90.0),
      (Colors.blue, 240.0, 90.0),
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
