import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/providers/app_state_provider.dart';
import '../../../../data/providers/database_provider.dart';
import '../../../../data/models/sync_queue_model.dart';
import '../../terminado.dart';
import 'animales.dart';
import 'animales_2.dart';
import 'animales_3.dart';

class AnimalesFlowScreen extends ConsumerStatefulWidget {
  const AnimalesFlowScreen({super.key});

  @override
  ConsumerState<AnimalesFlowScreen> createState() => _AnimalesFlowScreenState();
}

class _AnimalesFlowScreenState extends ConsumerState<AnimalesFlowScreen> {
  int _paso = 0;
  bool _navegandoATerminado = false;

  void _avanzar() => setState(() => _paso++);

  void _completar() {
    _guardarProgreso();
    _irATerminado();
  }

  Future<void> _guardarProgreso() async {
    final estudiante = ref.read(estudianteActivoProvider);
    if (estudiante == null || estudiante.id == null) return;
    final repo = ref.read(progresoRepositoryProvider);
    final queue = ref.read(syncQueueRepositoryProvider);
    await repo.registrarIntento(
      estudianteId: estudiante.id!,
      grado: estudiante.grado,
      materia: 'ciencias',
      actividad: 'Animales',
      porcentaje: 100.0,
    );
    await queue.encolar(SyncQueueModel(
      tipoAccion: 'progreso',
      payload: jsonEncode({
        'estudianteId': estudiante.id,
        'grado': estudiante.grado,
        'materia': 'ciencias',
        'actividad': 'Animales',
        'porcentaje': 100.0,
      }),
      fecha: DateTime.now().toIso8601String(),
    ));
  }

  void _irATerminado() {
    if (_navegandoATerminado || !mounted) return;
    _navegandoATerminado = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          // Sin onVolver — terminado.dart usa su propio contexto para hacer pop()
          builder: (_) => const ActividadTerminadaScreen(),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    switch (_paso) {
      case 0:
        return PantallaActividadAnimales(onCompletado: _avanzar, progress: 1 / 3);
      case 1:
        return PantallaClasificacionAnimales(onCompletado: _avanzar, progress: 2 / 3);
      default:
        return JuegoAnimalesScreen(onCompletado: _completar, progress: 1.0);
    }
  }
}