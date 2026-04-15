// ─────────────────────────────────────────────────────────────
//  lib/data/models/estudiante_model.dart
//  Capa: Datos — Responsabilidad: Ingeniería
// ─────────────────────────────────────────────────────────────

class EstudianteModel {
  final int?   id;
  final String nombre;
  final int    grado;
  final String personaje;       // 'pollito' | 'mono'
  final String fechaRegistro;   // ISO-8601
  final String? ultimaSesion;   // ISO-8601, nullable

  const EstudianteModel({
    this.id,
    required this.nombre,
    required this.grado,
    required this.personaje,
    required this.fechaRegistro,
    this.ultimaSesion,
  });

  factory EstudianteModel.fromMap(Map<String, dynamic> map) {
    return EstudianteModel(
      id:             map['id'] as int?,
      nombre:         map['nombre'] as String,
      grado:          map['grado'] as int,
      personaje:      map['personaje'] as String,
      fechaRegistro:  map['fecha_registro'] as String,
      ultimaSesion:   map['ultima_sesion'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'nombre':         nombre,
      'grado':          grado,
      'personaje':      personaje,
      'fecha_registro': fechaRegistro,
      'ultima_sesion':  ultimaSesion,
    };
  }

  EstudianteModel copyWith({
    int?    id,
    String? nombre,
    int?    grado,
    String? personaje,
    String? fechaRegistro,
    String? ultimaSesion,
  }) {
    return EstudianteModel(
      id:            id            ?? this.id,
      nombre:        nombre        ?? this.nombre,
      grado:         grado         ?? this.grado,
      personaje:     personaje     ?? this.personaje,
      fechaRegistro: fechaRegistro ?? this.fechaRegistro,
      ultimaSesion:  ultimaSesion  ?? this.ultimaSesion,
    );
  }
}
