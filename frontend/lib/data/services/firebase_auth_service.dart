import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  User? get usuarioActual => _auth.currentUser;

  Future<UserCredential> registrarConEmail(
    String email,
    String password,
  ) async {
    return await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<UserCredential> loginConEmail(
    String email,
    String password,
  ) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<UserCredential?> loginConGoogle() async {
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    if (googleUser == null) return null; // usuario canceló

    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;

    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    return await _auth.signInWithCredential(credential);
  }

  Future<void> enviarCorreoRecuperacion(String email) async {
    // Fuerza español para que el correo llegue en ese idioma
    await _auth.setLanguageCode('es');
    await _auth.sendPasswordResetEmail(email: email);
  }

  bool get estaVerificado => _auth.currentUser?.emailVerified ?? false;

  // reload() fuerza una consulta a Firebase; el caché local puede estar desactualizado
  Future<void> recargarUsuario() async {
    await _auth.currentUser?.reload();
  }

  Future<void> enviarVerificacionEmail() async {
    await _auth.setLanguageCode('es');
    await _auth.currentUser?.sendEmailVerification();
  }

  Future<void> cerrarSesion() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  static String mensajeDeError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'Ese email ya está registrado. ¡Inicia sesión!';
      case 'invalid-email':
        return 'El email no tiene un formato válido.';
      case 'weak-password':
        return 'La contraseña es muy débil. Mínimo 8 caracteres.';
      case 'user-not-found':
        return 'No existe una cuenta con ese email.';
      case 'wrong-password':
        return 'Contraseña incorrecta. Inténtalo de nuevo.';
      case 'invalid-credential':
        return 'Email o contraseña incorrectos.';
      case 'user-disabled':
        return 'Esta cuenta ha sido deshabilitada.';
      case 'too-many-requests':
        return 'Demasiados intentos fallidos. Espera un momento.';
      case 'network-request-failed':
        return 'Sin conexión a internet. Verifica tu red.';
      case 'account-exists-with-different-credential':
        return 'Ya existe una cuenta con ese email usando otro método de login.';
      default:
        return 'Error de autenticación: ${e.message ?? e.code}';
    }
  }
}
