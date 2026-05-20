import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/providers/database_provider.dart';
import '../../data/providers/app_state_provider.dart';

class ProgresoMateriaItem {
  final String materia;
  final String nombreMateria;
  final double porcentaje;
  final Color color;

  ProgresoMateriaItem({
    required this.materia,
    required this.nombreMateria,
    required this.porcentaje,
    required this.color,
  });
}

// Datos por materia: (color, totalActividades, nombreMostrar, nombreDB)
// nombreDB = nombre que acepta el CHECK constraint del SQLite
// La tabla usa 'español' con acento; el resto coincide con la clave interna.
const _materiasMeta = {
  'matematicas': (Color(0xFF3E7DFE), 3, 'Matemáticas', 'matematicas'),
  'ciencias':    (Color(0xFF3DCC52), 4, 'Ciencias',    'ciencias'),
  'espanol':     (Color(0xFFB83232), 3, 'Español',     'español'),
  'ingles':      (Color(0xFF8B5CF6), 3, 'Inglés',      'ingles'),
  'sociales':    (Color(0xFFF5A623), 3, 'Sociales',    'sociales'),
};

final progresoMateriaViewModelProvider =
    FutureProvider.autoDispose<List<ProgresoMateriaItem>>((ref) async {
  final estudiante = ref.watch(estudianteActivoProvider);
  if (estudiante == null || estudiante.id == null) return [];

  final repo  = ref.read(progresoRepositoryProvider);
  final items = <ProgresoMateriaItem>[];

  for (final entry in _materiasMeta.entries) {
    final materia = entry.key;
    final (color, totalAct, nombre, materiaDB) = entry.value;

    final pct = await repo.porcentajeMateria(
      estudianteId:       estudiante.id!,
      grado:              estudiante.grado,
      materia:            materiaDB,
      actividadesTotales: totalAct,
    );

    if (pct > 0) {
      items.add(ProgresoMateriaItem(
        materia:       materia,
        nombreMateria: nombre,
        porcentaje:    pct,
        color:         color,
      ));
    }
  }

  return items;
});
