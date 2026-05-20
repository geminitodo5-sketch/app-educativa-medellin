import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/estudiante_model.dart';
import '../../data/providers/app_state_provider.dart';
import '../../data/providers/database_provider.dart';
import '../../data/providers/musica_provider.dart';
import 'bienvenida.dart';
import 'login_view.dart';
import 'menu_1_y_2_view.dart';
import 'menu_3_a_5_view.dart';

class RegistroView extends ConsumerStatefulWidget {
  const RegistroView({super.key});

  @override
  ConsumerState<RegistroView> createState() => _RegistroViewState();
}

class _RegistroViewState extends ConsumerState<RegistroView> {
  final _edadController = TextEditingController();
  final _emailController = TextEditingController();
  final _contrasenaController = TextEditingController();

  String? _generoSeleccionado;
  bool _mostrarContrasena = false;
  bool _cargando = false;

  // ── Errores inline ──────────────────────────────────────────
  String? _errorEdad;
  String? _errorGenero;
  String? _errorEmail;
  String? _errorContrasena;

  @override
  void initState() {
    super.initState();
    ref.read(musicaServiceProvider).entrar();
  }

  @override
  void dispose() {
    ref.read(musicaServiceProvider).salir();
    _edadController.dispose();
    _emailController.dispose();
    _contrasenaController.dispose();
    super.dispose();
  }

  // ── Validaciones individuales ────────────────────────────────

  String? _validarEdad(String valor) {
    if (valor.isEmpty) return 'La edad es obligatoria';
    final edad = int.tryParse(valor);
    if (edad == null || edad <= 0) return 'Ingresa una edad válida';
    if (edad > 99) return 'La edad no puede ser mayor a 99';
    return null;
  }

  String? _validarEmail(String email) {
    if (email.isEmpty) return 'El email es obligatorio';

    final regex = RegExp(r'^[a-zA-Z0-9._\-]+@gmail\.com$');
    if (!regex.hasMatch(email.toLowerCase())) {
      return 'Solo se permiten correos de Gmail (@gmail.com)';
    }

    final usuario = email.split('@')[0];
    if (usuario.length < 6) {
      return 'El nombre de usuario debe tener al menos 6 caracteres';
    }
    if (usuario.startsWith('.') || usuario.endsWith('.')) {
      return 'El email no puede empezar ni terminar con punto';
    }
    if (usuario.contains('..')) {
      return 'El email no puede tener puntos seguidos';
    }

    return null;
  }

  String? _validarContrasena(String contrasena) {
    if (contrasena.isEmpty) return 'La contraseña es obligatoria';
    if (contrasena.length < 8) return 'Mínimo 8 caracteres';
    if (!contrasena.contains(RegExp(r'[A-Z]'))) {
      return 'Debe contener al menos una mayúscula';
    }
    if (!contrasena.contains(RegExp(r'[0-9]'))) {
      return 'Debe contener al menos un número';
    }
    return null;
  }

  // ── Registro / login con Google ──────────────────────────────

  Future<void> _registrarConGoogle() async {
    setState(() => _cargando = true);
    try {
      final authService = ref.read(firebaseAuthServiceProvider);
      final credential  = await authService.loginConGoogle();

      if (credential == null) return; // usuario canceló el selector

      final uid   = credential.user!.uid;
      final email = credential.user?.email;

      if (!mounted) return;

      // Google ya verifica el correo → podemos entrar directamente
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(children: [
              const Icon(Icons.security_rounded, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Google envió una notificación de seguridad a ${email ?? 'tu Gmail'}',
                  style: const TextStyle(fontFamily: 'Poppins', fontSize: 13),
                ),
              ),
            ]),
            backgroundColor: const Color(0xFF1A73E8),
            duration: const Duration(seconds: 4),
          ),
        );
      }

      await _entrarConGoogle(uid, email);
    } on FirebaseAuthException catch (e) {
      if (mounted) _mostrarErrorSnack(_mensajeFirebaseGoogle(e));
    } catch (e) {
      if (mounted) _mostrarErrorSnack('Error con Google Sign-In: $e');
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _entrarConGoogle(String uid, String? email) async {
    final repo     = ref.read(estudianteRepositoryProvider);
    final syncCase = ref.read(sincronizarUseCaseProvider);

    // 1. Buscar perfil por firebase_uid
    var estudiante = await repo.buscarPorFirebaseUid(uid);

    // 2. Migración: buscar por email si no hay uid
    if (estudiante == null && email != null) {
      estudiante = await repo.buscarPorEmail(email);
      if (estudiante != null) {
        await repo.vincularFirebaseUid(estudiante.id!, uid);
        estudiante = estudiante.copyWith(firebaseUid: uid);
      }
    }

    if (!mounted) return;

    // 3. Sin perfil local → intentar restaurar desde Firestore
    if (estudiante == null) {
      final restored = await syncCase.sincronizarAlLogin(uid);
      if (!mounted) return;
      if (restored != null) {
        await repo.actualizarUltimaSesion(restored.id!);
        ref.read(estudianteActivoProvider.notifier).state = restored;
        if (!mounted) return;
        _navegarAlMenu(restored);
      } else {
        _navegarABienvenida(email: email, uid: uid);
      }
      return;
    }

    // 4. Perfil existente → entrar
    await repo.actualizarUltimaSesion(estudiante.id!);
    ref.read(estudianteActivoProvider.notifier).state = estudiante;
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
        ? Menu1Y2Screen(nombre: e.nombre, avatar: e.personaje, nivel: e.grado)
        : const Menu3A5Screen();
    Navigator.of(context).pushReplacement(PageRouteBuilder(
      pageBuilder: (ctx, a, _) => destino,
      transitionsBuilder: (ctx, anim, _, child) =>
          FadeTransition(opacity: anim, child: child),
      transitionDuration: const Duration(milliseconds: 400),
    ));
  }

  void _navegarABienvenida({String? email, required String uid}) {
    Navigator.of(context).pushReplacement(PageRouteBuilder(
      pageBuilder: (ctx, a, _) =>
          WelcomeScreen(email: email, firebaseUid: uid),
      transitionsBuilder: (ctx, anim, _, child) =>
          FadeTransition(opacity: anim, child: child),
      transitionDuration: const Duration(milliseconds: 400),
    ));
  }

  void _mostrarErrorSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontFamily: 'Poppins')),
      backgroundColor: const Color(0xFFEF5353),
    ));
  }

  String _mensajeFirebaseGoogle(FirebaseAuthException e) {
    switch (e.code) {
      case 'account-exists-with-different-credential':
        return 'Ya existe una cuenta con ese email usando otro método';
      case 'network-request-failed':
        return 'Sin conexión a internet';
      case 'too-many-requests':
        return 'Demasiados intentos. Espera un momento';
      default:
        return 'Error de Google: ${e.message ?? e.code}';
    }
  }

  // ── Acción principal ─────────────────────────────────────────

  Future<void> _continuar() async {
    final edad = _edadController.text.trim();
    final email = _emailController.text.trim();
    final contrasena = _contrasenaController.text.trim();

    setState(() {
      _errorEdad = _validarEdad(edad);
      _errorGenero = _generoSeleccionado == null ? 'Selecciona un género' : null;
      _errorEmail = _validarEmail(email);
      _errorContrasena = _validarContrasena(contrasena);
    });

    if (_errorEdad != null ||
        _errorGenero != null ||
        _errorEmail != null ||
        _errorContrasena != null) return;

    setState(() => _cargando = true);

    try {
      // 1. Crea la cuenta en Firebase Authentication
      final authService = ref.read(firebaseAuthServiceProvider);
      await authService.registrarConEmail(email, contrasena);

      // 2. Envía correo de verificación
      await authService.enviarVerificacionEmail();

      // 3. Cierra la sesión inmediatamente — el niño no puede entrar
      //    hasta que abra el correo y toque el enlace de activación.
      await authService.cerrarSesion();

      if (!mounted) return;

      // 4. Informa al usuario y lo manda a LoginView
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.mark_email_read_rounded,
                  color: Color(0xFF4A8BF5), size: 28),
              SizedBox(width: 10),
              Expanded(
                child: Text('¡Revisa tu Gmail!',
                    style: TextStyle(fontFamily: 'Hiruko', fontSize: 20)),
              ),
            ],
          ),
          content: Text(
            'Enviamos un correo de verificación a:\n$email\n\n'
            'Abre ese correo y toca el enlace de activación.\n'
            'Luego vuelve aquí e inicia sesión.\n\n'
            'Si no lo ves, revisa la carpeta Spam.',
            style: const TextStyle(
                fontFamily: 'Poppins', fontSize: 14, height: 1.55),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4A8BF5),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text('Ir a Iniciar Sesión',
                  style: TextStyle(fontFamily: 'Hiruko', fontSize: 16)),
            ),
          ],
        ),
      );

      if (!mounted) return;

      // 5. Navega a LoginView — el WelcomeScreen solo se abre tras
      //    verificar el correo e iniciar sesión correctamente.
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (ctx, a, _) => const LoginView(),
          transitionsBuilder: (ctx, anim, _, child) =>
              FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 400),
        ),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      String mensaje;
      if (e.code == 'email-already-in-use') {
        setState(() => _errorEmail = 'Ese email ya está registrado. ¡Inicia sesión!');
        setState(() => _cargando = false);
        return;
      } else if (e.code == 'invalid-email') {
        mensaje = 'El email no tiene un formato válido.';
      } else if (e.code == 'weak-password') {
        mensaje = 'La contraseña es muy débil.';
      } else if (e.code == 'network-request-failed') {
        mensaje = 'Sin conexión a internet. Verifica tu red.';
      } else {
        mensaje = 'Error al registrar: ${e.message ?? e.code}';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(mensaje, style: const TextStyle(fontFamily: 'Poppins')),
          backgroundColor: const Color(0xFFEF5353),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error al registrar: $e',
              style: const TextStyle(fontFamily: 'Poppins'),
            ),
            backgroundColor: const Color(0xFFEF5353),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  // ── Build ────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.shortestSide >= 600;
    final hMargin = isTablet ? size.width * 0.15 : 28.0;
    final titleSize = isTablet ? 48.0 : 38.0;
    final formPadH = isTablet ? 32.0 : 24.0;
    final formPadV = isTablet ? 36.0 : 28.0;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      // StackFit.expand hace que el Stack (y sus hijos no-Positioned) llenen
      // toda la pantalla, evitando el fondo blanco en tablets donde el
      // contenido es más corto que la pantalla.
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Gradiente de cielo (igual que MatematicasView) ─────────
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF1EB9D8), Color(0xFF59E347)],
              ),
            ),
          ),

          // ── Paisaje inferior (igual que MatematicasView) ───────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Image.asset(
              'assets/images/interfaz/fondos/fondo.jpg',
              fit: BoxFit.cover,
            ),
          ),

          // ── Contenido principal ────────────────────────────────────
          SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  SizedBox(height: size.height * 0.06),

                  Text(
                    'Regístrate',
                    style: TextStyle(
                      fontFamily: 'Hiruko',
                      fontSize: titleSize,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),

                  SizedBox(height: size.height * 0.04),

                  Container(
                    margin: EdgeInsets.symmetric(horizontal: hMargin),
                    padding: EdgeInsets.fromLTRB(formPadH, formPadV, formPadH, formPadV),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEEFF2),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Edad ──────────────────────────────
                        _buildLabel('Edad'),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _edadController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(2),
                          ],
                          onChanged: (val) => setState(
                            () => _errorEdad = _validarEdad(val.trim()),
                          ),
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: isTablet ? 16.0 : 15.0,
                            color: Colors.black87,
                          ),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: isTablet ? 16.0 : 14.0,
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
                              borderSide: const BorderSide(
                                color: Color(0xFF4A8BF5),
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                        _buildErrorText(_errorEdad),
                        const SizedBox(height: 18),

                        // ── Género ────────────────────────────
                        _buildLabel('Género'),
                        const SizedBox(height: 6),
                        _buildGeneroSelector(),
                        _buildErrorText(_errorGenero),
                        const SizedBox(height: 18),

                        // ── Email ─────────────────────────────
                        _buildLabel('Email'),
                        const SizedBox(height: 6),
                        _buildTextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          onChanged: (val) => setState(
                            () => _errorEmail = _validarEmail(val.trim()),
                          ),
                        ),
                        _buildErrorText(_errorEmail),
                        const SizedBox(height: 18),

                        // ── Contraseña ────────────────────────
                        _buildLabel('Contraseña'),
                        const SizedBox(height: 6),
                        _buildPasswordField(),
                        _buildErrorText(_errorContrasena),
                        if (_errorContrasena == null &&
                            _contrasenaController.text.isNotEmpty)
                          const Padding(
                            padding: EdgeInsets.only(top: 4),
                            child: Text(
                              '✓ Contraseña válida',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 12,
                                color: Color(0xFF34A853),
                              ),
                            ),
                          ),
                        if (_contrasenaController.text.isEmpty)
                          const Padding(
                            padding: EdgeInsets.only(top: 4),
                            child: Text(
                              'Mín. 8 caracteres, una mayúscula y un número',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 11,
                                color: Colors.black45,
                              ),
                            ),
                          ),

                        const SizedBox(height: 28),

                        // ── Botón Continuar ───────────────────
                        SizedBox(
                          width: double.infinity,
                          height: isTablet ? 64.0 : 52.0,
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
                                : Text(
                                    'Continuar',
                                    style: TextStyle(
                                      fontFamily: 'Hiruko',
                                      fontSize: isTablet ? 24.0 : 20.0,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),

                        const SizedBox(height: 14),

                        // ── Separador ─────────────────────────
                        Row(children: [
                          const Expanded(child: Divider(color: Colors.black26)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Text('o regístrate con',
                                style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: isTablet ? 13.0 : 12.0,
                                    color: Colors.black45)),
                          ),
                          const Expanded(child: Divider(color: Colors.black26)),
                        ]),

                        const SizedBox(height: 14),

                        // ── Botón Google ───────────────────────
                        SizedBox(
                          width: double.infinity,
                          height: isTablet ? 60.0 : 50.0,
                          child: OutlinedButton(
                            onPressed: _cargando ? null : _registrarConGoogle,
                            style: OutlinedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black87,
                              side: const BorderSide(
                                  color: Color(0xFFBBBBBB), width: 1.5),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                              elevation: 0,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text('Registrarse con Google ',
                                    style: TextStyle(
                                        fontFamily: 'Hiruko',
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87)),
                                _GoogleIcon(),
                              ],
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
                                  transitionsBuilder: (ctx, anim, _, child) =>
                                      FadeTransition(
                                        opacity: anim,
                                        child: child,
                                      ),
                                  transitionDuration: const Duration(
                                    milliseconds: 400,
                                  ),
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

                  // Espacio para que el fondo y el mono sean visibles debajo del formulario
                  SizedBox(height: size.height * (isTablet ? 0.25 : 0.22)),
                ],
              ),
            ),
          ),

          // ── Mono (Numi) ────────────────────────────────────────────
          Builder(
            builder: (context) {
              final bottomInset = MediaQuery.of(context).viewInsets.bottom;
              final monoHeight = size.height * (isTablet ? 0.22 : 0.22);
              final monoWidth = size.width * (isTablet ? 0.30 : 0.45);

              return AnimatedPositioned(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOut,
                bottom: bottomInset > 0 ? -(monoHeight * 0.6) : 0,
                right: -10,
                child: IgnorePointer(
                  child: Image.asset(
                    'assets/images/bienvenida/mono.png',
                    height: monoHeight,
                    width: monoWidth,
                    fit: BoxFit.contain,
                    alignment: Alignment.bottomRight,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ── Widgets helpers ──────────────────────────────────────────

  bool get _esTablet => MediaQuery.of(context).size.shortestSide >= 600;

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontFamily: 'Poppins',
        fontSize: _esTablet ? 16.0 : 14.0,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF555555),
      ),
    );
  }

  Widget _buildErrorText(String? error) {
    if (error == null) return const SizedBox(height: 4);
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        error,
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: _esTablet ? 13.0 : 12.0,
          color: const Color(0xFFEF5353),
        ),
      ),
    );
  }

  Widget _buildGeneroSelector() {
    const opciones = ['Masculino', 'Femenino'];
    final isTablet = _esTablet;
    return Row(
      children: opciones.map((opcion) {
        final seleccionado = _generoSeleccionado == opcion;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() {
              _generoSeleccionado = opcion;
              _errorGenero = null;
            }),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: EdgeInsets.only(right: opcion == 'Masculino' ? 8 : 0),
              padding: EdgeInsets.symmetric(vertical: isTablet ? 16.0 : 13.0),
              decoration: BoxDecoration(
                color: seleccionado ? const Color(0xFF4A8BF5) : Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  opcion,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: isTablet ? 15.0 : 14.0,
                    fontWeight: FontWeight.w600,
                    color: seleccionado ? Colors.white : Colors.black54,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    void Function(String)? onChanged,
  }) {
    final isTablet = _esTablet;
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      onChanged: onChanged,
      style: TextStyle(
        fontFamily: 'Poppins',
        fontSize: isTablet ? 16.0 : 15.0,
        color: Colors.black87,
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        contentPadding: EdgeInsets.symmetric(
          horizontal: 16,
          vertical: isTablet ? 16.0 : 14.0,
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
          borderSide: const BorderSide(color: Color(0xFF4A8BF5), width: 1.5),
        ),
      ),
    );
  }

  Widget _buildPasswordField() {
    final isTablet = _esTablet;
    return TextField(
      controller: _contrasenaController,
      obscureText: !_mostrarContrasena,
      onChanged: (val) =>
          setState(() => _errorContrasena = _validarContrasena(val.trim())),
      style: TextStyle(
        fontFamily: 'Poppins',
        fontSize: isTablet ? 16.0 : 15.0,
        color: Colors.black87,
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        contentPadding: EdgeInsets.symmetric(
          horizontal: 16,
          vertical: isTablet ? 16.0 : 14.0,
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
          borderSide: const BorderSide(color: Color(0xFF4A8BF5), width: 1.5),
        ),
        suffixIcon: GestureDetector(
          onTap: () => setState(() => _mostrarContrasena = !_mostrarContrasena),
          child: Icon(
            _mostrarContrasena ? Icons.visibility : Icons.visibility_off,
            color: Colors.grey,
            size: isTablet ? 26.0 : 22.0,
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
    final r  = size.width / 2;
    canvas.drawCircle(Offset(cx, cy), r, Paint()..color = Colors.white);
    final rect = Rect.fromCircle(center: Offset(cx, cy), radius: r);
    for (final seg in [
      (Colors.red,   -30.0, 90.0),
      (Colors.amber,  60.0, 90.0),
      (Colors.green, 150.0, 90.0),
      (Colors.blue,  240.0, 90.0),
    ]) {
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