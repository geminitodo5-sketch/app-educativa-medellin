import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/musica_service.dart';

final musicaServiceProvider = Provider<MusicaService>((ref) {
  final service = MusicaService();
  ref.onDispose(service.cerrar);
  return service;
});
