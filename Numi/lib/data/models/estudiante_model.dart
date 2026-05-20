class EstudianteModel {
  final int?    id;
  final String  nombre;
  final int     grado;
  final String  personaje;       // 'pollito' | 'mono'
  final String  fechaRegistro;   // ISO-8601
  final String? ultimaSesion;    // ISO-8601, nullable
  final String? email;
  final String? contrasena;
  final int?    edad;
  final String? genero;
  final String? firebaseUid;     // UID de Firebase Auth

  const EstudianteModel({
    this.id,
    required this.nombre,
    required this.grado,
    required this.personaje,
    required this.fechaRegistro,
    this.ultimaSesion,
    this.email,
    this.contrasena,
    this.edad,
    this.genero,
    this.firebaseUid,
  });

  factory EstudianteModel.fromMap(Map<String, dynamic> map) {
    return EstudianteModel(
      id:            map['id'] as int?,
      nombre:        map['nombre'] as String,
      grado:         map['grado'] as int,
      personaje:     map['personaje'] as String,
      fechaRegistro: map['fecha_registro'] as String,
      ultimaSesion:  map['ultima_sesion'] as String?,
      email:         map['email'] as String?,
      contrasena:    map['contrasena'] as String?,
      edad:          map['edad'] as int?,
      genero:        map['genero'] as String?,
      firebaseUid:   map['firebase_uid'] as String?,
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
      'email':          email,
      'contrasena':     contrasena,
      'edad':           edad,
      'genero':         genero,
      'firebase_uid':   firebaseUid,
    };
  }

  EstudianteModel copyWith({
    int?    id,
    String? nombre,
    int?    grado,
    String? personaje,
    String? fechaRegistro,
    String? ultimaSesion,
    String? email,
    String? contrasena,
    int?    edad,
    String? genero,
    String? firebaseUid,
  }) {
    return EstudianteModel(
      id:            id            ?? this.id,
      nombre:        nombre        ?? this.nombre,
      grado:         grado         ?? this.grado,
      personaje:     personaje     ?? this.personaje,
      fechaRegistro: fechaRegistro ?? this.fechaRegistro,
      ultimaSesion:  ultimaSesion  ?? this.ultimaSesion,
      email:         email         ?? this.email,
      contrasena:    contrasena    ?? this.contrasena,
      edad:          edad          ?? this.edad,
      genero:        genero        ?? this.genero,
      firebaseUid:   firebaseUid   ?? this.firebaseUid,
    );
  }
}
