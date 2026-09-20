class SyncQueueModel {
  final int?   id;
  final String tipoAccion;   // 'progreso' | 'logro' | 'estudiante'
  final String payload;      // JSON serializado
  final String fecha;        // ISO-8601
  final bool   enviado;
  final int    intentosSync;

  const SyncQueueModel({
    this.id,
    required this.tipoAccion,
    required this.payload,
    required this.fecha,
    this.enviado      = false,
    this.intentosSync = 0,
  });

  factory SyncQueueModel.fromMap(Map<String, dynamic> map) {
    return SyncQueueModel(
      id:           map['id'] as int?,
      tipoAccion:   map['tipo_accion'] as String,
      payload:      map['payload'] as String,
      fecha:        map['fecha'] as String,
      enviado:      (map['enviado'] as int) == 1,
      intentosSync: map['intentos_sync'] as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'tipo_accion':   tipoAccion,
      'payload':       payload,
      'fecha':         fecha,
      'enviado':       enviado ? 1 : 0,
      'intentos_sync': intentosSync,
    };
  }

  SyncQueueModel copyWith({
    int?    id,
    String? tipoAccion,
    String? payload,
    String? fecha,
    bool?   enviado,
    int?    intentosSync,
  }) {
    return SyncQueueModel(
      id:           id           ?? this.id,
      tipoAccion:   tipoAccion   ?? this.tipoAccion,
      payload:      payload      ?? this.payload,
      fecha:        fecha        ?? this.fecha,
      enviado:      enviado      ?? this.enviado,
      intentosSync: intentosSync ?? this.intentosSync,
    );
  }
}
