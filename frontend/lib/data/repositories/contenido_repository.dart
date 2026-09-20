import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/database_provider.dart';
import '../services/descarga_paquete_service.dart';

class ContenidoRepository {
  final DescargaPaqueteService _descarga;

  ContenidoRepository(this._descarga);

  Future<bool> estaDescargado(String materia) =>
      _descarga.estaDescargado(materia);

  Future<void> descargarPaquete(
    String materia, {
    void Function(double)? onProgress,
  }) =>
      _descarga.descargarPaquete(materia, onProgress: onProgress);
}

final descargaPaqueteServiceProvider = Provider<DescargaPaqueteService>((ref) {
  return DescargaPaqueteService(ref.read(sqliteServiceProvider));
});

final contenidoRepositoryProvider = Provider<ContenidoRepository>((ref) {
  return ContenidoRepository(ref.read(descargaPaqueteServiceProvider));
});
