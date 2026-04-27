// ─────────────────────────────────────────────────────────────
//  lib/ui/viewmodels/asistente_ia_view_model.dart
//  ViewModel para la pantalla del asistente RAG offline.
// ─────────────────────────────────────────────────────────────

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/providers/database_provider.dart';
import '../../data/services/rag_service.dart';
import '../../data/services/embedding_service.dart';
import '../../data/services/descarga_paquete_service.dart';

// ── Modelo de mensaje del chat ────────────────────────────────

enum RolMensaje { usuario, asistente }

class MensajeChat {
  final String texto;
  final RolMensaje rol;
  final bool esCargando;

  const MensajeChat({
    required this.texto,
    required this.rol,
    this.esCargando = false,
  });

  MensajeChat copyWith({String? texto, bool? esCargando}) => MensajeChat(
        texto: texto ?? this.texto,
        rol: rol,
        esCargando: esCargando ?? this.esCargando,
      );
}

// ── Estado ────────────────────────────────────────────────────

class AsistenteIaEstado {
  final List<MensajeChat> mensajes;
  final bool respondiendo;
  final Map<String, bool> descargado;
  final Map<String, double> progresosDescarga;
  final String materiaActual;
  final int gradoActual;

  const AsistenteIaEstado({
    this.mensajes = const [],
    this.respondiendo = false,
    this.descargado = const {},
    this.progresosDescarga = const {},
    this.materiaActual = 'matematicas',
    this.gradoActual = 1,
  });

  AsistenteIaEstado copyWith({
    List<MensajeChat>? mensajes,
    bool? respondiendo,
    Map<String, bool>? descargado,
    Map<String, double>? progresosDescarga,
    String? materiaActual,
    int? gradoActual,
  }) =>
      AsistenteIaEstado(
        mensajes: mensajes ?? this.mensajes,
        respondiendo: respondiendo ?? this.respondiendo,
        descargado: descargado ?? this.descargado,
        progresosDescarga: progresosDescarga ?? this.progresosDescarga,
        materiaActual: materiaActual ?? this.materiaActual,
        gradoActual: gradoActual ?? this.gradoActual,
      );

  bool get materiaDescargada => descargado[materiaActual] ?? false;
  double get progresoDescargaActual =>
      progresosDescarga[materiaActual] ?? 0.0;
}

// ── ViewModel ─────────────────────────────────────────────────

class AsistenteIaViewModel extends StateNotifier<AsistenteIaEstado> {
  final RagService _rag;
  final DescargaPaqueteService _descarga;

  static const _materias = [
    'matematicas', 'ciencias', 'espanol', 'ingles', 'sociales',
  ];

  AsistenteIaViewModel(this._rag, this._descarga)
      : super(const AsistenteIaEstado()) {
    _verificarDescargados();
  }

  // ── Inicialización ─────────────────────────────────────────

  Future<void> _verificarDescargados() async {
    final mapa = <String, bool>{};
    for (final m in _materias) {
      mapa[m] = await _descarga.estaDescargado(m);
    }
    state = state.copyWith(descargado: Map.unmodifiable(mapa));
  }

  Future<void> inicializar({required String materia, required int grado}) async {
    state = state.copyWith(
      materiaActual: materia,
      gradoActual: grado,
      mensajes: const [],
    );
    await _verificarDescargados();

    if (state.materiaDescargada) {
      final sugeridas = await _rag.preguntasSugeridas(
        materia: materia,
        grado: grado,
      );
      if (sugeridas.isNotEmpty) {
        final bienvenida = MensajeChat(
          texto: _mensajeBienvenida(materia, grado, sugeridas),
          rol: RolMensaje.asistente,
        );
        state = state.copyWith(mensajes: [bienvenida]);
      }
    }
  }

  // ── Cambio de materia / grado ──────────────────────────────

  void cambiarMateria(String materia) {
    state = state.copyWith(
      materiaActual: materia,
      mensajes: const [],
    );
    inicializar(materia: materia, grado: state.gradoActual);
  }

  void cambiarGrado(int grado) {
    state = state.copyWith(gradoActual: grado, mensajes: const []);
    inicializar(materia: state.materiaActual, grado: grado);
  }

  // ── Preguntar ──────────────────────────────────────────────

  Future<void> preguntar(String pregunta, {int? estudianteId}) async {
    if (pregunta.trim().isEmpty || state.respondiendo) return;

    final msgUsuario = MensajeChat(
      texto: pregunta.trim(),
      rol: RolMensaje.usuario,
    );
    final placeholder = const MensajeChat(
      texto: '...',
      rol: RolMensaje.asistente,
      esCargando: true,
    );

    state = state.copyWith(
      mensajes: [...state.mensajes, msgUsuario, placeholder],
      respondiendo: true,
    );

    try {
      final resultado = await _rag.responder(
        pregunta: pregunta,
        materia: state.materiaActual,
        grado: state.gradoActual,
      );

      if (estudianteId != null && resultado.encontrado) {
        await _rag.guardarHistorial(
          estudianteId: estudianteId,
          pregunta: pregunta,
          respuesta: resultado.texto,
          materia: state.materiaActual,
          grado: state.gradoActual,
        );
      }

      final respMsg = MensajeChat(
        texto: resultado.texto,
        rol: RolMensaje.asistente,
      );

      final msgs = List<MensajeChat>.from(state.mensajes)..removeLast();
      state = state.copyWith(
        mensajes: [...msgs, respMsg],
        respondiendo: false,
      );
    } catch (_) {
      final msgs = List<MensajeChat>.from(state.mensajes)..removeLast();
      state = state.copyWith(
        mensajes: [
          ...msgs,
          const MensajeChat(
            texto: 'Ocurrió un error al procesar tu pregunta. Intenta de nuevo.',
            rol: RolMensaje.asistente,
          ),
        ],
        respondiendo: false,
      );
    }
  }

  // ── Descarga ───────────────────────────────────────────────

  Future<void> descargarMateria(String materia) async {
    final nuevosProgresos =
        Map<String, double>.from(state.progresosDescarga);
    nuevosProgresos[materia] = 0.0;
    state = state.copyWith(progresosDescarga: nuevosProgresos);

    try {
      await _descarga.descargarPaquete(
        materia,
        onProgress: (p) {
          final progs = Map<String, double>.from(state.progresosDescarga);
          progs[materia] = p;
          state = state.copyWith(progresosDescarga: progs);
        },
      );

      final nuevo = Map<String, bool>.from(state.descargado);
      nuevo[materia] = true;
      final progs = Map<String, double>.from(state.progresosDescarga);
      progs.remove(materia);
      state = state.copyWith(descargado: nuevo, progresosDescarga: progs);

      // Si es la materia actual, lanza bienvenida
      if (materia == state.materiaActual) {
        await inicializar(
          materia: state.materiaActual,
          grado: state.gradoActual,
        );
      }
    } catch (e) {
      final progs = Map<String, double>.from(state.progresosDescarga);
      progs.remove(materia);
      state = state.copyWith(progresosDescarga: progs);
      rethrow;
    }
  }

  // ── Helpers ────────────────────────────────────────────────

  static String _mensajeBienvenida(String materia, int grado, List<String> sugeridas) {
    final nombre = _nombreMateria(materia);
    final temas = _temasPorMateria(materia, grado);
    final actividades = _actividadesPorMateria(materia);

    final buf = StringBuffer();
    buf.writeln('¡Bienvenido! Soy tu asistente de $nombre para grado $grado.');
    buf.writeln();
    buf.writeln('Puedo enseñarte temas como:');
    for (final t in temas) {
      buf.writeln('  • $t');
    }
    buf.writeln();
    buf.writeln('Por ejemplo, puedes preguntarme:');
    for (final s in sugeridas.take(3)) {
      buf.writeln('  • $s');
    }
    if (actividades.isNotEmpty) {
      buf.writeln();
      buf.write('Tambien tienes actividades interactivas disponibles: ${actividades.join(', ')}. ¡Explorelas en el menu de la materia!');
    }
    return buf.toString().trim();
  }

  static List<String> _temasPorMateria(String materia, int grado) {
    const mapa = <String, Map<int, List<String>>>{
      'matematicas': {
        3: ['Multiplicación y tablas', 'Fracciones', 'Figuras geométricas', 'Medidas y perímetro', 'Problemas de dos pasos'],
        4: ['División de varias cifras', 'Fracciones equivalentes', 'Ángulos y polígonos', 'Porcentajes', 'Ecuaciones simples'],
        5: ['Números enteros y negativos', 'Potencias y raíces', 'Fracciones y decimales', 'Álgebra básica', 'Estadística y probabilidad'],
      },
      'ciencias': {
        3: ['Ecosistemas y cadenas alimenticias', 'Los animales: vertebrados e invertebrados', 'Las plantas y la fotosíntesis', 'El agua y su ciclo', 'Mezclas y materiales'],
        4: ['El cuerpo humano y sus sistemas', 'Energía: tipos y transformaciones', 'El sistema solar', 'Cambios físicos y químicos', 'Biodiversidad de Colombia'],
        5: ['La célula y el ADN', 'Cambio climático y medio ambiente', 'Energías renovables', 'Microorganismos y biotecnología', 'Circuitos eléctricos'],
      },
      'espanol': {
        3: ['El cuento y sus partes', 'Sustantivos, adjetivos y verbos', 'Ortografía y acentuación', 'Textos descriptivos', 'Signos de puntuación'],
        4: ['Texto argumentativo', 'La noticia y el periódico', 'Conectores textuales', 'Sujeto y predicado', 'Resumen y mapa conceptual'],
        5: ['Figuras literarias', 'El ensayo', 'El debate', 'Coherencia y cohesión', 'Comunicación digital'],
      },
      'ingles': {
        3: ['Saludos y presentaciones', 'Animales y hábitats', 'Familia y emociones', 'Colores, formas y objetos', 'Verbos del presente simple'],
        4: ['Present y past continuous', 'Países y nacionalidades', 'Verbos modales (can, must, should)', 'Medio ambiente en inglés', 'Conectores del discurso'],
        5: ['Present perfect', 'Voz pasiva', 'Condicionales', 'Estilo indirecto', 'Escritura formal e informal'],
      },
      'sociales': {
        3: ['Regiones naturales de Colombia', 'Municipios y departamentos', 'Culturas afrocolombianas e indígenas', 'Gastronomía colombiana', 'Medio ambiente urbano'],
        4: ['Independencia de Colombia', 'El Congreso y la democracia', 'Pisos térmicos y geografía', 'Economía colombiana', 'Historia del siglo XX'],
        5: ['Historia de Colombia siglo XIX', 'Culturas precolombinas', 'Globalización y TLC', 'ODS y desarrollo sostenible', 'La Segunda Guerra Mundial'],
      },
    };
    return mapa[materia]?[grado] ?? mapa[materia]?[3] ?? [];
  }

  static List<String> _actividadesPorMateria(String materia) {
    const mapa = <String, List<String>>{
      'matematicas': ['Los números', 'Quien tiene más', 'Sumar'],
      'ciencias': ['Animales', 'Cuerpo humano', 'Las plantas', 'Vivo o no vivo'],
      'espanol': ['Arma la palabra', 'Oraciones', 'Palabra loca'],
      'ingles': ['Escucha y responde', 'Encuentra la pareja', 'Tarjetas de vocabulario'],
      'sociales': ['Detective de objetos', 'Heroes de la ciudad', 'Pasado y presente'],
    };
    return mapa[materia] ?? [];
  }

  static String _nombreMateria(String m) {
    const nombres = {
      'matematicas': 'Matemáticas',
      'ciencias': 'Ciencias',
      'espanol': 'Español',
      'ingles': 'Inglés',
      'sociales': 'Sociales',
    };
    return nombres[m] ?? m;
  }

  static String nombreMateria(String m) => _nombreMateria(m);
}

// ── Providers ─────────────────────────────────────────────────

// EmbeddingService se inicializa una vez; si el modelo TFLite no está en assets
// falla silenciosamente y RagService usa solo BM25 + expansión conceptual.
final embeddingServiceProvider = Provider<EmbeddingService>((ref) {
  final svc = EmbeddingService();
  svc.initialize(); // fire-and-forget; RagService lo usa solo cuando modelAvailable == true
  return svc;
});

final ragServiceProvider = Provider<RagService>((ref) {
  return RagService(
    ref.read(sqliteServiceProvider),
    embeddings: ref.read(embeddingServiceProvider),
  );
});

final descargaPaqueteServiceProvider = Provider<DescargaPaqueteService>((ref) {
  return DescargaPaqueteService(ref.read(sqliteServiceProvider));
});

final asistenteIaViewModelProvider =
    StateNotifierProvider<AsistenteIaViewModel, AsistenteIaEstado>((ref) {
  return AsistenteIaViewModel(
    ref.read(ragServiceProvider),
    ref.read(descargaPaqueteServiceProvider),
  );
});
