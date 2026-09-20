import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/racha_service.dart';
import 'database_provider.dart';

final rachaServiceProvider = Provider<RachaService>(
  (ref) => RachaService(ref.read(sqliteServiceProvider)));

/// Racha calculada hoy que aún no se ha mostrado en pantalla.
/// Los menús la leen, la muestran y la limpian (null).
final rachaPendienteProvider = StateProvider<RachaInfo?>((ref) => null);
