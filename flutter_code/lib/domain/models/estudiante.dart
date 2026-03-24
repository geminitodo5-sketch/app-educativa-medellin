/// Modelo que representa a un estudiante en la aplicación.
/// Pertenece a la capa de DOMINIO.
class Estudiante {
  /// Identificador único en la base de datos local.
  /// Es nulo antes de insertarse en la BD.
  final int? id;

  /// Nombre o apodo del estudiante.
  final String nombre;

  /// Grado escolar (1 a 5).
  final int grado;

  /// Hash SHA-256 del PIN de acceso. NUNCA guardar en texto plano.
  final String pin;

  /// Identificador del avatar seleccionado (ej. 'avatar_oso', 'avatar_robot').
  final String avatar;

  /// Cantidad de monedas o puntos acumulados.
  final int monedas;

  Estudiante({
    this.id,
    required this.nombre,
    required this.grado,
    required this.pin,
    required this.avatar,
    this.monedas = 0,
  });

  /// Convierte un Map de SQLite a un objeto Estudiante.
  factory Estudiante.fromMap(Map<String, dynamic> map) {
    return Estudiante(
      id: map['id'] as int?,
      nombre: map['nombre'] as String,
      grado: map['grado'] as int,
      pin: map['pin'] as String,
      avatar: map['avatar'] as String,
      monedas: map['monedas'] as int? ?? 0,
    );
  }

  /// Convierte el objeto Estudiante a un Map para guardar en SQLite.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'grado': grado,
      'pin': pin,
      'avatar': avatar,
      'monedas': monedas,
    };
  }
}
