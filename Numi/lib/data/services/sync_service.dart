import 'package:connectivity_plus/connectivity_plus.dart';
import '../repositories/sync_queue_repository.dart';
import '../models/sync_queue_model.dart';

class SyncService {
  final SyncQueueRepository _repo;
  final Connectivity        _connectivity;

  /// Máximo de intentos antes de abandonar un registro.
  static const int _maxIntentos = 5;

  SyncService(this._repo, {Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity();

  // ── API pública ──────────────────────────────────────────────

  /// Intenta sincronizar todos los registros pendientes.
  /// Retorna cuántos se enviaron con éxito.
  Future<int> sincronizar() async {
    if (!await _hayInternet()) return 0;

    final pendientes = await _repo.pendientes();
    int enviados = 0;

    for (final item in pendientes) {
      if ((item.intentosSync) >= _maxIntentos) continue;

      final ok = await _enviarAlBackend(item);
      if (ok) {
        await _repo.marcarEnviado(item.id!);
        enviados++;
      } else {
        await _repo.registrarFallo(item.id!);
      }
    }

    return enviados;
  }

  /// Cuántos registros están esperando sincronización.
  Future<int> pendientesCount() => _repo.cantidadPendientes();

  /// Escucha cambios de conectividad y sincroniza automáticamente
  /// cada vez que el dispositivo recupera internet.
  /// Llama a [cancelar()] en el dispose del widget/provider.
  Stream<int> escucharYSincronizar() async* {
    await for (final result in _connectivity.onConnectivityChanged) {
      if (_esConexionValida(result)) {
        yield await sincronizar();
      }
    }
  }

  // ── Privados ────────────────────────────────────────────────

  Future<bool> _hayInternet() async {
    final result = await _connectivity.checkConnectivity();
    return _esConexionValida(result);
  }

  bool _esConexionValida(ConnectivityResult result) =>
      result == ConnectivityResult.mobile  ||
      result == ConnectivityResult.wifi    ||
      result == ConnectivityResult.ethernet;

  /// STUB — reemplazar con llamada HTTP real al backend cuando esté listo.
  /// Debe retornar true si el servidor confirmó la recepción (2xx).
  Future<bool> _enviarAlBackend(SyncQueueModel item) async {
    // TODO: reemplazar con:
    //   final response = await http.post(Uri.parse('https://api.numi.co/sync'),
    //       body: item.payload, headers: {'Content-Type': 'application/json'});
    //   return response.statusCode >= 200 && response.statusCode < 300;
    await Future.delayed(const Duration(milliseconds: 50)); // simula red
    return true; // optimista hasta tener backend
  }
}
