// ─────────────────────────────────────────────────────────────
//  lib/ui/views/registro_view.dart
//  Pantalla de registro: Edad, Género, Email, Contraseña
//  Aparece después de la animación de Numi y antes de Bienvenida
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  void dispose() {
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

    final formatoBasico = RegExp(
      r'^[a-zA-Z0-9._\-]+@[a-zA-Z0-9\-]+\.[a-zA-Z]{2,}$',
    );
    if (!formatoBasico.hasMatch(email)) {
      return 'Ingresa un email válido (sin caracteres especiales)';
    }

    const dominiosPermitidos = [
      'gmail.com',
      'hotmail.com',
      'hotmail.es',
      'outlook.com',
      'outlook.es',
      'yahoo.com',
      'yahoo.es',
      'icloud.com',
      'live.com',
      'live.es',
      'protonmail.com',
      'proton.me',
      'unal.edu.co',
      'udea.edu.co',
      'uniandes.edu.co',
      'javeriana.edu.co',
      'urosario.edu.co',
      'eafit.edu.co',
      'uninorte.edu.co',
      'icesi.edu.co',
    ];

    const extensionesValidas = [
      '.com',
      '.co',
      '.es',
      '.org',
      '.net',
      '.edu',
      '.edu.co',
      '.gov',
      '.gov.co',
      '.io',
      '.me',
      '.info',
    ];

    final partes = email.split('@');
    final dominio = partes[1].toLowerCase();

    final dominioExactoValido = dominiosPermitidos.contains(dominio);
    final extensionValida = extensionesValidas.any(
      (ext) => dominio.endsWith(ext),
    );

    if (!dominioExactoValido && !extensionValida) {
      return 'Usa un correo de Gmail, Hotmail, Outlook u otro proveedor válido';
    }

    final usuario = partes[0];
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

  // ── Acción principal ─────────────────────────────────────────

  Future<void> _continuar() async {
    final edad = _edadController.text.trim();
    final email = _emailController.text.trim();
    final contrasena = _contrasenaController.text.trim();

    setState(() {
      _errorEdad = _validarEdad(edad);
      _errorGenero = _generoSeleccionado == null
          ? 'Selecciona un género'
          : null;
      _errorEmail = _validarEmail(email);
      _errorContrasena = _validarContrasena(contrasena);
    });

    if (_errorEdad != null ||
        _errorGenero != null ||
        _errorEmail != null ||
        _errorContrasena != null)
      return;

    setState(() => _cargando = true);

    try {
      final repo = ref.read(estudianteRepositoryProvider);
      final todos = await repo.listarTodos();
      final emailOcupado = todos.any((e) => e.email == email);

      if (!mounted) return;

      if (emailOcupado) {
        setState(
          () => _errorEmail = 'Ese email ya está registrado. ¡Inicia sesión!',
        );
        setState(() => _cargando = false);
        return;
      }

      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (ctx, a, _) => WelcomeScreen(
            email: email,
            contrasena: contrasena,
            edad: int.tryParse(edad),
            genero: _generoSeleccionado!,
          ),
          transitionsBuilder: (ctx, anim, _, child) =>
              FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 400),
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
                          // ── Edad ──────────────────────────────
                          _buildLabel('Edad'),
                          const SizedBox(height: 6),
                          TextField(
                            controller: _edadController,
                            keyboardType: TextInputType.number,
                            // Solo dígitos, máximo 2 caracteres (bloquea el 3er dígito)
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(2),
                            ],
                            onChanged: (val) => setState(
                              () => _errorEdad = _validarEdad(val.trim()),
                            ),
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

                    SizedBox(height: size.height * 0.18),
                  ],
                ),
              ),
            ),
          ),

          // Mono (Numi) — responsive y reactivo al teclado
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
                    width: size.width * 0.45,
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

  Widget _buildErrorText(String? error) {
    if (error == null) return const SizedBox(height: 4);
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        error,
        style: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 12,
          color: Color(0xFFEF5353),
        ),
      ),
    );
  }

  Widget _buildGeneroSelector() {
    const opciones = ['Masculino', 'Femenino'];
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
              padding: const EdgeInsets.symmetric(vertical: 13),
              decoration: BoxDecoration(
                color: seleccionado ? const Color(0xFF4A8BF5) : Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  opcion,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
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
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      onChanged: onChanged,
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
          borderSide: const BorderSide(color: Color(0xFF4A8BF5), width: 1.5),
        ),
      ),
    );
  }

  Widget _buildPasswordField() {
    return TextField(
      controller: _contrasenaController,
      obscureText: !_mostrarContrasena,
      onChanged: (val) =>
          setState(() => _errorContrasena = _validarContrasena(val.trim())),
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
          borderSide: const BorderSide(color: Color(0xFF4A8BF5), width: 1.5),
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