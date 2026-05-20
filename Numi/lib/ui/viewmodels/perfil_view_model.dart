import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/estudiante_model.dart';
import '../../data/providers/database_provider.dart';

final perfilViewModelProvider =
    ChangeNotifierProvider<PerfilViewModel>((ref) {
  return PerfilViewModel(ref);
});

class PerfilViewModel extends ChangeNotifier {
  final Ref _ref;

  PerfilViewModel(this._ref);

  // ── Estado ──────────────────────────────────────────────────
  bool              _ocupado    = false;
  EstudianteModel?  _estudiante;
  String?           _error;

  bool             get ocupado    => _ocupado;
  EstudianteModel? get estudiante => _estudiante;
  String?          get error      => _error;

  // ── Comandos ────────────────────────────────────────────────

  /// Carga (o crea) el estudiante activo y actualiza su última sesión.
  Future<void> commandCargarDatos() async {
    if (_ocupado) return;

    _ocupado = true;
    _error   = null;
    notifyListeners();

    try {
      final repo = _ref.read(estudianteRepositoryProvider);
      _estudiante = await repo.obtenerOCrearPorDefecto();
      await repo.actualizarUltimaSesion(_estudiante!.id!);
      // Refresca el objeto con la sesión actualizada
      _estudiante = await repo.obtenerPorId(_estudiante!.id!);
    } catch (e) {
      _error = 'Error al cargar el perfil: $e';
      debugPrint(_error);
    } finally {
      _ocupado = false;
      notifyListeners();
    }
  }

  /// Actualiza el nombre del estudiante en la BD.
  Future<void> commandActualizarNombre(String nuevoNombre) async {
    if (_estudiante == null) return;

    final actualizado = _estudiante!.copyWith(nombre: nuevoNombre);
    try {
      final repo = _ref.read(estudianteRepositoryProvider);
      await repo.actualizar(actualizado);
      _estudiante = actualizado;
      notifyListeners();
    } catch (e) {
      _error = 'Error al actualizar nombre: $e';
      debugPrint(_error);
      notifyListeners();
    }
  }
}
