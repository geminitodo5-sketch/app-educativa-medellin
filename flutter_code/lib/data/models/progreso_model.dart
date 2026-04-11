// ─────────────────────────────────────────────────────────────
//  lib/data/models/progreso_model.dart
//  Capa: Datos — Responsabilidad: Ingeniería
// ─────────────────────────────────────────────────────────────

class ProgresoModel {
  final int?   id;
  final int    estudianteId;
  final int    grado;
  final String materia;      // 'matematicas' | 'ingles' | 'español' | 'ciencias' | 'sociales'
  final String actividad;
  final double porcentaje;   // 0.0 – 100.0
  final int    intentos;
  final String? ultimaVez;  // ISO-8601, nullable
  final bool   sincronizado;

  const ProgresoModel({
    this.id,
    required this.estudianteId,
    required this.grado,
    required this.materia,
    required this.actividad,
    this.porcentaje   = 0.0,
    this.intentos     = 0,
    this.ultimaVez,
    this.sincronizado = false,
  });

  factory ProgresoModel.fromMap(Map<String, dynamic> map) {
    return ProgresoModel(
      id:           map['id'] as int?,
      estudianteId: map['estudiante_id'] as int,
      grado:        map['grado'] as int,
      materia:      map['materia'] as String,
      actividad:    map['actividad'] as String,
      porcentaje:   (map['porcentaje'] as num).toDouble(),
      intentos:     map['intentos'] as int,
      ultimaVez:    map['ultima_vez'] as String?,
      sincronizado: (map['sincronizado'] as int) == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'estudiante_id': estudianteId,
      'grado':         grado,
      'materia':       materia,
      'actividad':     actividad,
      'porcentaje':    porcentaje,
      'intentos':      intentos,
      'ultima_vez':    ultimaVez,
      'sincronizado':  sincronizado ? 1 : 0,
    };
  }

  ProgresoModel copyWith({
    int?    id,
    int?    estudianteId,
    int?    grado,
    String? materia,
    String? actividad,
    double? porcentaje,
    int?    intentos,
    String? ultimaVez,
    bool?   sincronizado,
  }) {
    return ProgresoModel(
      id:           id           ?? this.id,
      estudianteId: estudianteId ?? this.estudianteId,
      grado:        grado        ?? this.grado,
      materia:      materia      ?? this.materia,
      actividad:    actividad    ?? this.actividad,
      porcentaje:   porcentaje   ?? this.porcentaje,
      intentos:     intentos     ?? this.intentos,
      ultimaVez:    ultimaVez    ?? this.ultimaVez,
      sincronizado: sincronizado ?? this.sincronizado,
    );
  }
}
