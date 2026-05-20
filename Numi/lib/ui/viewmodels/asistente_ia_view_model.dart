import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/rag_repository.dart';
import '../../data/repositories/contenido_repository.dart';

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

class AsistenteIaEstado {
  final List<MensajeChat> mensajes;
  final bool respondiendo;
  final Map<String, bool> descargado;
  final Map<String, double> progresosDescarga;
  final String materiaActual;
  final int gradoActual;
  final List<String> opcionesDisplay; // texto visible de cada opción numerada
  final List<String> opcionesQuery;   // query enviado al RAG para cada opción
  final String avatarEstudiante;      // 'pollito' | 'mono'

  final String ultimoTema;
  final int nivelPista;    // 0 = sin pistas activas, 1-3 = nivel

  final bool isModelReady;
  final bool isModelDownloading;
  final double modelDownloadProgress; // 0.0–1.0
  final String? modelError;           // mensaje de error de descarga

  const AsistenteIaEstado({
    this.mensajes = const [],
    this.respondiendo = false,
    this.descargado = const {},
    this.progresosDescarga = const {},
    this.materiaActual = 'matematicas',
    this.gradoActual = 1,
    this.opcionesDisplay = const [],
    this.opcionesQuery = const [],
    this.avatarEstudiante = 'pollito',
    this.ultimoTema = '',
    this.nivelPista = 0,
    this.isModelReady = false,
    this.isModelDownloading = false,
    this.modelDownloadProgress = 0.0,
    this.modelError,
  });

  AsistenteIaEstado copyWith({
    List<MensajeChat>? mensajes,
    bool? respondiendo,
    Map<String, bool>? descargado,
    Map<String, double>? progresosDescarga,
    String? materiaActual,
    int? gradoActual,
    List<String>? opcionesDisplay,
    List<String>? opcionesQuery,
    String? avatarEstudiante,
    String? ultimoTema,
    int? nivelPista,
    bool? isModelReady,
    bool? isModelDownloading,
    double? modelDownloadProgress,
    Object? modelError = _sentinel,
  }) =>
      AsistenteIaEstado(
        mensajes: mensajes ?? this.mensajes,
        respondiendo: respondiendo ?? this.respondiendo,
        descargado: descargado ?? this.descargado,
        progresosDescarga: progresosDescarga ?? this.progresosDescarga,
        materiaActual: materiaActual ?? this.materiaActual,
        gradoActual: gradoActual ?? this.gradoActual,
        opcionesDisplay: opcionesDisplay ?? this.opcionesDisplay,
        opcionesQuery: opcionesQuery ?? this.opcionesQuery,
        avatarEstudiante: avatarEstudiante ?? this.avatarEstudiante,
        ultimoTema: ultimoTema ?? this.ultimoTema,
        nivelPista: nivelPista ?? this.nivelPista,
        isModelReady: isModelReady ?? this.isModelReady,
        isModelDownloading: isModelDownloading ?? this.isModelDownloading,
        modelDownloadProgress:
            modelDownloadProgress ?? this.modelDownloadProgress,
        modelError: modelError == _sentinel
            ? this.modelError
            : modelError as String?,
      );

  bool get materiaDescargada => descargado[materiaActual] ?? false;
  double get progresoDescargaActual =>
      progresosDescarga[materiaActual] ?? 0.0;
}

// Centinela para distinguir null explícito de "sin cambio" en copyWith.
const Object _sentinel = Object();

class AsistenteIaViewModel extends StateNotifier<AsistenteIaEstado> {
  final RagRepository _ragRepo;
  final ContenidoRepository _contenidoRepo;

  static const _materias = [
    'matematicas', 'ciencias', 'espanol', 'ingles', 'sociales',
  ];

  AsistenteIaViewModel(this._ragRepo, this._contenidoRepo)
      : super(const AsistenteIaEstado()) {
    _verificarDescargados();
    _inicializarModelo();
  }

  Future<void> _inicializarModelo() async {
    // 1. Activar el modelo si ya existe en el dispositivo.
    await _ragRepo.inicializarModeloSiExiste();

    if (_ragRepo.isModelReady) {
      if (mounted) state = state.copyWith(isModelReady: true);
      return;
    }

    // 2. Si no existe → descarga automática en background.
    //    El asistente usa RAG local como fallback mientras tanto.
    iniciarDescargaModelo();
  }

  Future<void> iniciarDescargaModelo() async {
    if (state.isModelDownloading || state.isModelReady) return;

    state = state.copyWith(
      isModelDownloading: true,
      modelDownloadProgress: 0.0,
      modelError: null,
    );

    try {
      await _ragRepo.descargarModelo(
        onProgress: (p) {
          if (mounted) {
            state = state.copyWith(modelDownloadProgress: p);
          }
        },
      );

      if (mounted) {
        state = state.copyWith(
          isModelReady: true,
          isModelDownloading: false,
          modelDownloadProgress: 1.0,
        );
      }
    } catch (e) {
      if (mounted) {
        state = state.copyWith(
          isModelDownloading: false,
          modelDownloadProgress: 0.0,
          modelError: 'Error al descargar el modelo: $e',
        );
      }
    }
  }

  Future<void> _verificarDescargados() async {
    final mapa = <String, bool>{};
    for (final m in _materias) {
      mapa[m] = await _contenidoRepo.estaDescargado(m);
    }
    state = state.copyWith(descargado: Map.unmodifiable(mapa));
  }

  Future<void> verificarDescargados() => _verificarDescargados();

  Future<void> inicializar({required String materia, required int grado}) async {
    state = state.copyWith(
      materiaActual: materia,
      gradoActual: grado,
      mensajes: const [],
      opcionesDisplay: const [],
      opcionesQuery: const [],
    );
    await _verificarDescargados();

    if (!state.materiaDescargada) return;

    final sugeridas = await _ragRepo.preguntasSugeridas(
      materia: materia,
      grado: grado,
      cantidad: 3,
    );

    // Construir opciones: temas del currículo + preguntas sugeridas del RAG
    final temas = _temasPorMateria(materia, grado);
    final display = <String>[];
    final query = <String>[];

    for (final tema in temas.take(5)) {
      display.add(tema);
      query.add('Explícame sobre $tema');
    }
    for (final q in sugeridas) {
      display.add(q);
      query.add(q);
    }

    // Mensaje 1: saludo breve
    final msg1 = MensajeChat(
      texto: '¡Hola! 😊 Soy Sabi, tu compañero de aprendizaje.\n\n'
             '¡Estoy aquí para ayudarte a brillar en ${_nombreMateria(materia)} de grado $grado! '
             '🌟 Puedes preguntarme lo que quieras, pedir que te explique algo paso a paso '
             'o explorar un tema nuevo juntos. ¡Tú puedes lograrlo! 💪',
      rol: RolMensaje.asistente,
    );

    // Mensaje 2: opciones numeradas
    final buf = StringBuffer('¿Qué quieres aprender hoy? Elige un número:\n');
    for (int i = 0; i < display.length; i++) {
      buf.writeln('${i + 1}. ${display[i]}');
    }
    buf.write('\nO escribe tu propia pregunta directamente.');

    final msg2 = MensajeChat(
      texto: buf.toString().trim(),
      rol: RolMensaje.asistente,
    );

    state = state.copyWith(
      mensajes: [msg1, msg2],
      opcionesDisplay: display,
      opcionesQuery: query,
    );
  }

  void cambiarMateria(String materia) {
    state = state.copyWith(
      materiaActual: materia,
      mensajes: const [],
      opcionesDisplay: const [],
      opcionesQuery: const [],
    );
    inicializar(materia: materia, grado: state.gradoActual);
  }

  void cambiarGrado(int grado) {
    state = state.copyWith(
      gradoActual: grado,
      mensajes: const [],
      opcionesDisplay: const [],
      opcionesQuery: const [],
    );
    inicializar(materia: state.materiaActual, grado: grado);
  }

  static const _frasesConfusion = [
    'no entiendo', 'no entendi', 'no entendí',
    'no comprendo', 'no comprendi', 'no comprendí',
    'no se', 'no sé', 'no lo se', 'no lo sé',
    'pista', 'dame una pista', 'ayuda', 'me ayudas',
    'explica mejor', 'explica mas', 'explica más',
    'no queda claro', 'no está claro', 'mas facil', 'más fácil',
    'no lo entiendo', 'repite', 'otra vez', 'como asi', 'cómo así',
  ];

  bool _esConfusion(String input) {
    final lower = input.toLowerCase().trim();
    return _frasesConfusion.any((f) => lower.contains(f));
  }

  String _queryPista(String tema, int nivel, int grado) {
    switch (nivel) {
      case 1: return 'Explica $tema de forma muy sencilla con palabras simples para grado $grado';
      case 2: return 'Dame un ejemplo práctico concreto de $tema para grado $grado';
      default: return 'Explica $tema paso a paso detallado para grado $grado';
    }
  }

  String _prefijoPista(int nivel) {
    switch (nivel) {
      case 1: return '😊 Te lo explico de otra manera:\n\n';
      case 2: return '💡 Mira este ejemplo concreto:\n\n';
      default: return '📝 Vamos paso a paso:\n\n';
    }
  }

  Future<void> preguntar(String input, {int? estudianteId}) async {
    final inputTrim = input.trim();
    if (inputTrim.isEmpty || state.respondiendo) return;

    // Si el usuario escribe un número, lo mapeamos a la opción correspondiente
    final numero = int.tryParse(inputTrim);
    final String queryRAG;
    final String textoVisible;
    int nuevoPista = 0;
    bool esPista = false;

    // T3.7: detectar confusión → pista progresiva
    if (_esConfusion(inputTrim) && state.ultimoTema.isNotEmpty) {
      nuevoPista = (state.nivelPista % 3) + 1;
      queryRAG = _queryPista(state.ultimoTema, nuevoPista, state.gradoActual);
      textoVisible = inputTrim;
      esPista = true;
    } else if (numero != null &&
        numero >= 1 &&
        numero <= state.opcionesDisplay.length) {
      textoVisible = '$numero. ${state.opcionesDisplay[numero - 1]}';
      queryRAG = state.opcionesQuery[numero - 1];
    } else {
      textoVisible = inputTrim;
      queryRAG = inputTrim;
      nuevoPista = 0; // reset al hacer una pregunta nueva
    }

    final msgUsuario = MensajeChat(texto: textoVisible, rol: RolMensaje.usuario);
    const placeholder = MensajeChat(
      texto: '...', rol: RolMensaje.asistente, esCargando: true,
    );

    state = state.copyWith(
      mensajes: [...state.mensajes, msgUsuario, placeholder],
      respondiendo: true,
      nivelPista: esPista ? nuevoPista : 0,
    );

    try {
      final resultado = await _ragRepo.responder(
        pregunta: queryRAG,
        materia: state.materiaActual,
        grado: state.gradoActual,
      );

      // Agregar prefijo de pista si corresponde
      final textoFinal = esPista
          ? '${_prefijoPista(nuevoPista)}${resultado.texto}'
          : resultado.texto;

      if (estudianteId != null && textoFinal.isNotEmpty) {
        await _ragRepo.guardarHistorial(
          estudianteId: estudianteId,
          pregunta: textoVisible,
          respuesta: textoFinal,
          materia: state.materiaActual,
          grado: state.gradoActual,
        );
      }

      final msgs = List<MensajeChat>.from(state.mensajes)..removeLast();
      state = state.copyWith(
        mensajes: [...msgs, MensajeChat(texto: textoFinal, rol: RolMensaje.asistente)],
        respondiendo: false,
        ultimoTema: resultado.tema.isNotEmpty ? resultado.tema : state.ultimoTema,
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

  Future<void> descargarMateria(String materia) async {
    final nuevosProgresos =
        Map<String, double>.from(state.progresosDescarga);
    nuevosProgresos[materia] = 0.0;
    state = state.copyWith(progresosDescarga: nuevosProgresos);

    try {
      await _contenidoRepo.descargarPaquete(
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

  Future<String?> getUltimaMateria(int estudianteId) =>
      _ragRepo.obtenerUltimaMateria(estudianteId);
}

// Se ejecuta una sola vez al arrancar la app (vía ProviderScope).
// Delega en el ViewModel para que TODO el estado del modelo (descargando,
// progreso, listo) fluya por asistenteIaViewModelProvider y la UI en
// configuracion_view vea el porcentaje real en tiempo real.
final gemmaStartupProvider = FutureProvider<void>((ref) async {
  // Crear el ViewModel si aún no existe; su constructor llama a
  // _inicializarModelo() → iniciarDescargaModelo(), que actualiza estado.
  ref.read(asistenteIaViewModelProvider);
});

final asistenteIaViewModelProvider =
    StateNotifierProvider<AsistenteIaViewModel, AsistenteIaEstado>((ref) {
  return AsistenteIaViewModel(
    ref.read(ragRepositoryProvider),
    ref.read(contenidoRepositoryProvider),
  );
});

final historialPorMateriaProvider = FutureProvider.family<
    List<Map<String, dynamic>>,
    ({int estudianteId, String materia})>((ref, params) async {
  final repo = ref.read(ragRepositoryProvider);
  return repo.obtenerHistorial(
    estudianteId: params.estudianteId,
    materia: params.materia,
  );
});
