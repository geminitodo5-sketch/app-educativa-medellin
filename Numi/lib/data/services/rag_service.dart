// ─────────────────────────────────────────────────────────────
//  lib/data/services/rag_service.dart  v4.0
//  Motor RAG — FAISS (servidor) + BM25 offline + TFLite reranking
//
//  Flujo de búsqueda:
//    1. Evaluador aritmético (solo matemáticas)
//    2. Intenta búsqueda semántica FAISS en el servidor (si hay red)
//    3. Si no hay red: BM25 local + expansión de conceptos
//    4. Reranking semántico TFLite (siempre activo)
//    5. Decisión por umbral:
//         ≥ minScore → respuesta interpretada y adaptada al grado
//         ≥ softMin  → sugerencia amigable de tema relacionado
//         < softMin  → fallback con preguntas reales del grado
//
//  Respuestas: se interpretan y formatean por grado (3, 4, 5).
//  Nunca se devuelve un copy-paste del campo `respuesta` de la KB.
// ─────────────────────────────────────────────────────────────

import 'dart:math';
import 'package:dio/dio.dart';
import 'sqlite_service.dart';
import 'embedding_service.dart';
import 'local_llm_service.dart';

class RagService {
  final SqliteService _db;
  final EmbeddingService? _embeddings;
  final LocalLlmService? _localLlm;

  // [embeddings] activa el reranking semántico TFLite (opcional).
  // [localLlm]  activa la generación local con Gemma (opcional).
  RagService(this._db, {EmbeddingService? embeddings, LocalLlmService? localLlm})
      : _embeddings = embeddings,
        _localLlm = localLlm;

  // ─── BM25 hiperparámetros ─────────────────────────────────
  static const double _k1      = 1.5;
  static const double _b       = 0.75;
  static const double _minScore  = 0.35; // respuesta directa
  static const double _softMin   = 0.18; // respuesta aproximada

  // ─── Stopwords normalizadas ───────────────────────────────
  // "mas" y "menos" NO están aquí (son operadores matemáticos).
  static const _stopwords = {
    'el','la','los','las','un','una','unos','unas','de','del','al','a','en',
    'y','o','pero','que','es','son','ser','fue','era','si','no','se',
    'me','te','le','nos','con','para','su','sus','mi','mis','tu','tus',
    'este','esta','estos','estas','ese','esa','esos','esas','lo','hay',
    'muy','bien','ya','tambien','porque','cuando','donde','quien',
    'cual','cuales','cuanto','cuantos','sobre','hasta','desde',
    'hacia','durante','sin','ante','bajo','puedo','puede','puedes',
    'quiero','quisiera','dime','como','favor','porfavor',
    'forma','manera','modo','simple','facil','ayuda',
    'quiere','hacer','hago','haces',
  };

  // ─── Sufijos para stemming español ───────────────────────
  static const _sufijos = [
    'aciones','amiento','imientos',
    'acion','iones','iendo','mente','ando',
    'ados','idas','idos','adas',
    'ado','ida','ido','ada',
    'ares','eres','ires',
    'amos','emos','imos',
    'cion','ncia','nces',
    'ar','er','ir',
    'es','as',
  ];

  // ═══════════════════════════════════════════════════════════
  //  MAPAS DE EXPANSIÓN CONCEPTUAL
  //  Permiten que el sistema entienda el mismo tema desde
  //  distintos ángulos: "¿cómo respiran los peces?" encuentra
  //  la entrada sobre sistema respiratorio aunque use palabras
  //  diferentes. La key es el inicio de stem del término del
  //  usuario; los valores son términos de la KB relacionados.
  // ═══════════════════════════════════════════════════════════
  static const Map<String, Map<String, List<String>>> _expansion = {

    // ── MATEMÁTICAS ──────────────────────────────────────────
    'matematicas': {
      'tabla':      ['multiplicacion', 'multiplicar', 'producto', 'factor'],
      'multiplic':  ['tabla', 'producto', 'factor', 'veces'],
      'sum':        ['adicion', 'agregar', 'total', 'resultado', 'mas'],
      'rest':       ['sustraccion', 'quitar', 'diferencia', 'menos'],
      'divis':      ['cociente', 'repartir', 'dividendo', 'divisor'],
      'fracc':      ['numerador', 'denominador', 'quebrado', 'mitad', 'tercio'],
      'decimal':    ['coma', 'decimas', 'centesimas', 'millesimas'],
      'porcent':    ['tanto por ciento', 'descuento', 'proporcion'],
      'figur':      ['geometria', 'poligono', 'triangulo', 'cuadrado', 'rectangulo', 'circulo'],
      'geometr':    ['figura', 'forma', 'plano', 'solido', 'lados', 'poligono'],
      'area':       ['superficie', 'medir', 'm2', 'centimetro cuadrado'],
      'perimetr':   ['contorno', 'borde', 'lados', 'longitud'],
      'angul':      ['grado', 'recto', 'agudo', 'obtuso', 'triangulo'],
      'medid':      ['metro', 'centimetro', 'kilogramo', 'litro', 'unidad'],
      'patron':     ['secuencia', 'serie', 'sigue', 'siguiente numero'],
      'estadistic': ['grafico', 'tabla', 'datos', 'barras', 'promedio'],
      'multipl':    ['multiplo', 'divisor', 'factor', 'divisible', 'comun'],
      'promedi':    ['media aritmetica', 'dato', 'estadistica'],
      'ecuaci':     ['variable', 'despejar', 'resolver', 'incognita'],
      'raiz':       ['cuadrada', 'radical', 'sqrt'],
      'potenci':    ['cuadrado', 'cubo', 'exponente'],
      'proporci':   ['razon', 'escala', 'porcentaje', 'proporcionalidad'],
      'problem':    ['plantear', 'resolver', 'situacion', 'enunciado'],
      'volum':      ['capacidad', 'litro', 'centimetro cubico', 'solido'],
      'coordenada': ['plano cartesiano', 'eje x', 'eje y', 'punto', 'graficar'],
      'plano':      ['coordenadas', 'eje', 'cartesiano', 'cuadrante'],
    },

    // ── CIENCIAS NATURALES ────────────────────────────────────
    'ciencias': {
      'respir':     ['pulmones', 'oxigeno', 'alveolos', 'sistema respiratorio', 'CO2'],
      'digest':     ['estomago', 'intestino', 'nutricion', 'alimentos', 'sistema digestivo'],
      'sangre':     ['circulacion', 'corazon', 'arterias', 'venas', 'sistema circulatorio'],
      'comer':      ['nutricion', 'alimento', 'digestion', 'nutriente', 'vitamina'],
      'hues':       ['esqueleto', 'oseo', 'columna', 'articulacion', 'sistema oseo'],
      'muscul':     ['contraccion', 'movimiento', 'fibra', 'sistema muscular'],
      'cerebr':     ['nervioso', 'neurona', 'impulso', 'sistema nervioso'],
      'planta':     ['fotosintesis', 'clorofila', 'hoja', 'tallo', 'raiz'],
      'fotosint':   ['clorofila', 'luz solar', 'glucosa', 'CO2', 'oxigeno'],
      'animal':     ['vertebrado', 'invertebrado', 'clasificacion', 'reino animal'],
      'celul':      ['nucleo', 'membrana', 'citoplasma', 'ADN', 'organulo'],
      'fuerz':      ['newton', 'empuje', 'movimiento', 'velocidad', 'masa'],
      'movimient':  ['fuerza', 'velocidad', 'aceleracion', 'newton', 'desplazamiento'],
      'energ':      ['transformacion', 'calor', 'luz', 'renovable', 'termica', 'electrica'],
      'mezcl':      ['solucion', 'homogenea', 'heterogenea', 'separacion', 'filtracion'],
      'ecosistem':  ['cadena alimenticia', 'habitat', 'biodiversidad', 'especie', 'productor'],
      'contamin':   ['medio ambiente', 'residuos', 'poluccion', 'basura', 'deforestacion'],
      'mater':      ['solido', 'liquido', 'gaseoso', 'estado', 'cambio de estado'],
      'electric':   ['circuito', 'corriente', 'conductor', 'pila', 'serie', 'paralelo'],
      'magnetis':   ['iman', 'polo norte', 'campo magnetico', 'brujula', 'electroiman'],
      'sonid':      ['onda', 'frecuencia', 'vibracion', 'decibel'],
      'luz':        ['reflexion', 'refraccion', 'espectro', 'optica', 'ojo'],
      'agalla':     ['respiracion', 'peces', 'branquia', 'agua', 'oxigeno'],
      'maquina':    ['palanca', 'polea', 'plano inclinado', 'rueda', 'cuña'],
      'clim':       ['temperatura', 'ecosistema', 'calentamiento', 'cambio climatico'],
      'evoluc':     ['darwin', 'seleccion natural', 'adaptacion', 'especie', 'fosil'],
      'vitamin':    ['nutricion', 'salud', 'alimento', 'mineral', 'hierro'],
      'vacun':      ['inmune', 'enfermedad', 'prevencion', 'anticuerpo', 'virus'],
      'herenci':    ['gen', 'ADN', 'cromosoma', 'rasgo', 'hereditario'],
      'reproduc':   ['celula sexual', 'ovulo', 'espermatozoide', 'fecundacion'],
      'organism':   ['clasificacion', 'ser vivo', 'reino', 'taxonomia'],
      'mineral':    ['roca', 'suelo', 'geologico', 'cristal', 'dureza'],
    },

    // ── ESPAÑOL / LENGUAJE ────────────────────────────────────
    'espanol': {
      'punt':       ['signos de puntuacion', 'coma', 'punto y coma', 'exclamacion'],
      'sign':       ['puntuacion', 'coma', 'punto', 'interrogacion', 'exclamacion'],
      'letr':       ['ortografia', 'alfabeto', 'consonante', 'vocal', 'tilde'],
      'cuent':      ['narrativo', 'ficcion', 'personaje', 'trama', 'texto'],
      'poem':       ['poesia', 'verso', 'estrofa', 'rima', 'metafora'],
      'sustantiv':  ['nombre comun', 'nombre propio', 'genero', 'numero gramatical'],
      'verb':       ['accion', 'conjugacion', 'tiempo verbal', 'infinitivo', 'modo'],
      'adjetiv':    ['calificativo', 'comparativo', 'superlativo', 'descriptor'],
      'parraf':     ['texto', 'oracion', 'idea principal', 'coherencia', 'cohesion'],
      'sinonim':    ['parecido', 'equivalente', 'mismo significado', 'campo semantico'],
      'antonim':    ['contrario', 'opuesto', 'significado contrario'],
      'silab':      ['division silabica', 'tonica', 'atona', 'diptongo', 'hiato'],
      'acent':      ['tilde', 'prosodico', 'ortografico', 'aguda', 'grave', 'esdrujula'],
      'argum':      ['argumentacion', 'opinion', 'tesis', 'evidencia', 'debate'],
      'leer':       ['comprension lectora', 'inferencia', 'interpretar', 'analisis'],
      'escrib':     ['produccion', 'redaccion', 'composicion', 'texto escrito'],
      'conect':     ['enlace', 'conjuncion', 'transicion', 'cohesion', 'pero aunque'],
      'resum':      ['sintetizar', 'compendio', 'ideas principales', 'mapa conceptual'],
      'expos':      ['oral', 'discurso', 'presentacion', 'hablar', 'exposicion'],
      'narrativ':   ['cuento', 'historia', 'personaje', 'narrador', 'ficcion'],
      'descripti':  ['descripcion', 'caracteristica', 'como es', 'adjetivo'],
      'informativ': ['informacion', 'noticia', 'enciclopedia', 'datos', 'expositivo'],
      'inferenci':  ['conclusion', 'deducir', 'implica', 'entre lineas', 'deduccion'],
      'produc':     ['texto escrito', 'redaccion', 'estructura', 'parrafo'],
      'ortograf':   ['tilde', 'letra', 'mayuscula', 'regla ortografica'],
      'lectur':     ['texto', 'comprension', 'leer', 'interpretar', 'critica'],
    },

    // ── INGLÉS ────────────────────────────────────────────────
    'ingles': {
      'verb':       ['action word', 'to be', 'to have', 'conjugate', 'irregular'],
      'present':    ['simple present', 'tense', 'now', 'habitual', 'frequency'],
      'past':       ['simple past', 'yesterday', 'irregular verb', 'preterite', 'ago'],
      'futur':      ['future', 'will', 'going to', 'tomorrow', 'prediction'],
      'vocabul':    ['word', 'meaning', 'translation', 'vocabulary', 'dictionary'],
      'preposici':  ['preposition', 'in', 'on', 'at', 'by', 'with', 'location'],
      'articul':    ['article', 'the', 'a', 'an', 'determiner'],
      'adjetiv':    ['adjective', 'describe', 'color', 'size', 'big', 'small'],
      'sustantiv':  ['noun', 'person', 'place', 'thing', 'plural'],
      'pronunciar': ['pronunciation', 'phonics', 'sound', 'speak', 'how to say'],
      'salud':      ['greeting', 'hello', 'hi', 'how are you', 'nice to meet'],
      'famili':     ['family', 'mom', 'dad', 'brother', 'sister', 'cousin', 'relative'],
      'comid':      ['food', 'eat', 'fruit', 'vegetable', 'meal', 'drink', 'healthy'],
      'cuerp':      ['body', 'head', 'arm', 'leg', 'eye', 'health', 'parts'],
      'color':      ['colour', 'red', 'blue', 'green', 'yellow', 'purple'],
      'numer':      ['numbers', 'count', 'how many', 'cardinal', 'ordinal'],
      'rutin':      ['routine', 'daily habits', 'wake up', 'school', 'schedule'],
      'animal':     ['animals', 'pet', 'wild', 'farm', 'zoo', 'nature'],
      'tiemp':      ['weather', 'rainy', 'sunny', 'cold', 'hot', 'temperature'],
      'rop':        ['clothes', 'wear', 'shirt', 'pants', 'dress', 'fashion'],
      'objetos':    ['object', 'thing', 'item', 'technology', 'tool', 'use'],
      'opinion':    ['opinion', 'think', 'believe', 'like', 'prefer', 'agree'],
      'emocion':    ['feelings', 'happy', 'sad', 'angry', 'scared', 'excited'],
      'salon':      ['classroom', 'school', 'teacher', 'student', 'learn'],
      'habitos':    ['habits', 'healthy', 'routine', 'do every day', 'lifestyle'],
      'medios':     ['media', 'tv', 'internet', 'social media', 'communication'],
    },

    // ── CIENCIAS SOCIALES ─────────────────────────────────────
    'sociales': {
      'rio':        ['hidrografia', 'cuenca', 'Magdalena', 'Cauca', 'corriente', 'agua'],
      'montan':     ['cordillera', 'andina', 'sierra', 'nevado', 'pico', 'altura'],
      'ocean':      ['mar', 'Caribe', 'Pacifico', 'Atlantico', 'costa', 'isla'],
      'mar':        ['oceano', 'Caribe', 'costa', 'litoral', 'isla', 'agua'],
      'map':        ['cartografia', 'coordenadas', 'escala', 'brujula', 'orientacion'],
      'region':     ['zona', 'territorio', 'departamento', 'municipio', 'area', 'Andina', 'Caribe', 'Pacifica', 'Orinoquia', 'Amazonica'],
      'gobier':     ['gobernador', 'alcalde', 'presidente', 'instituciones', 'estado'],
      'constituc':  ['ley', 'norma', 'derechos', 'carta magna', '1991', 'colombia'],
      'derecho':    ['deber', 'ciudadano', 'constitucional', 'humanos', 'libertad'],
      'democraci':  ['voto', 'elecciones', 'participacion', 'ciudadania', 'gobierno'],
      'colon':      ['virreinato', 'conquistadores', 'espana', 'colonial', '1492'],
      'independ':   ['libertad', '20 julio', 'bolivar', 'republica', '1819', '1810'],
      'indigen':    ['precolombino', 'Muisca', 'Tayrona', 'aborigen', 'nativo', 'cultura'],
      'econom':     ['produccion', 'comercio', 'exportaciones', 'trabajo', 'industria'],
      'clim':       ['temperatura', 'lluvia', 'piso termico', 'tropical', 'ambiente'],
      'cultur':     ['patrimonio', 'tradicion', 'costumbre', 'fiesta', 'identidad'],
      'fronter':    ['limite', 'Venezuela', 'Ecuador', 'Brasil', 'Panama', 'limitar'],
      'piso':       ['termico', 'temperatura', 'altura', 'paramo', 'frio', 'calido'],
      'recurs':     ['natural', 'renovable', 'petroleo', 'agua', 'bosque', 'suelo'],
      'comunid':    ['barrio', 'vecindad', 'organizacion', 'social', 'junta', 'familia'],
      'precolomb':  ['Muisca', 'Tayrona', 'Quimbaya', 'indigena', 'cultura', 'San Agustin'],
      'bolivar':    ['independencia', 'Boyaca', '1819', 'libertador', 'Gran Colombia'],
      'histori':    ['precolombino', 'colonia', 'independencia', 'republica', 'pasado'],
      'geografi':   ['mapa', 'region', 'cordillera', 'relieve', 'ubicacion', 'cartografia'],
      'departamen': ['gobernador', 'municipio', 'alcalde', 'territorio', 'colombia'],
      'ambient':    ['contaminacion', 'deforestacion', 'problema', 'recurso natural'],
    },
  };

  // ─── Ejemplos por materia para el fallback ────────────────
  static const _ejemplos = {
    'matematicas': '¿Cuánto es 8 × 7?\n¿Qué es una fracción?\n¿Cómo calculo el área de un rectángulo?',
    'ciencias':    '¿Qué es la fotosíntesis?\n¿Cómo funciona el sistema digestivo?\n¿Qué es un ecosistema?',
    'espanol':     '¿Qué es un sustantivo?\n¿Cómo se usa la coma?\n¿Qué es una metáfora?',
    'ingles':      '¿Qué significa "friend"?\n¿Cómo se usa "to be"?\n¿Cuáles son los verbos irregulares?',
    'sociales':    '¿Qué es la Constitución de Colombia?\n¿Cuáles son las regiones de Colombia?\n¿Qué es la democracia?',
  };

  // ─── URL del servidor RAG ─────────────────────────────────
  static const String _apiBase =
      'https://app-educativa-medellin-production.up.railway.app';

  // ─── LLM endpoint (Gemini en servidor) ───────────────────
  // Timeout mayor que FAISS porque Gemini necesita tiempo de inferencia.
  // Devuelve null ante cualquier fallo → flujo BM25/FAISS continúa.
  Future<RagRespuesta?> _preguntarConLLM(
    String pregunta, String materia, int grado,
  ) async {
    try {
      final dio = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 8),
        receiveTimeout: const Duration(seconds: 18),
      ));
      final resp = await dio.post(
        '$_apiBase/api/preguntar',
        data: {'pregunta': pregunta, 'materia': materia, 'grado': grado},
      );
      if (resp.statusCode != 200) return null;
      final data      = resp.data as Map<String, dynamic>?;
      if (data == null) return null;
      final encontrado = data['encontrado'] as bool? ?? false;
      final texto      = data['texto']     as String? ?? '';
      final tema       = data['tema']      as String? ?? '';
      if (!encontrado || texto.isEmpty) return null;
      return RagRespuesta(texto: texto, encontrado: true, tema: tema);
    } catch (_) {
      return null; // Sin internet o Gemini no configurado → BM25/FAISS local
    }
  }

  // ═══════════════════════════════════════════════════════════
  //  API PÚBLICA
  // ═══════════════════════════════════════════════════════════

  Future<RagRespuesta> responder({
    required String pregunta,
    required String materia,
    required int grado,
  }) async {
    // 1. Evaluador aritmético (solo matemáticas — sin tocar la BD)
    if (materia == 'matematicas') {
      final calc = _calcularExpresion(pregunta);
      if (calc != null) return calc;
    }

    // 2. Tokenizar
    final tokens = _tokenizar(pregunta);
    if (tokens.isEmpty) {
      return RagRespuesta(
        texto: grado == 3
            ? '¡Hola! Hazme una pregunta sobre ${_nombreMateria(materia)} 😊\n'
              'Por ejemplo:\n${_ejemplos[materia] ?? '¿Qué es...?'}'
            : 'Hazme una pregunta sobre ${_nombreMateria(materia)}.\n'
              'Por ejemplo:\n${_ejemplos[materia] ?? '¿Qué es...?'}',
        encontrado: false, tema: '',
      );
    }

    // 3. Cargar corpus local (siempre necesario para el fallback)
    final corpus = await _db.consultar(
      'base_conocimiento',
      where: 'materia = ?',
      whereArgs: [materia],
    );
    if (corpus.isEmpty) {
      return RagRespuesta(
        texto: grado == 3
            ? '¡Primero hay que descargar el contenido! 📥\n'
              'Toca el botón "Descargar" para continuar.'
            : 'Aún no descargaste el contenido de ${_nombreMateria(materia)}.\n'
              'Toca "Descargar" en el menú para continuar.',
        encontrado: false, tema: '',
      );
    }

    // 4. LLM endpoint: Gemini + FAISS en servidor → respuesta generativa.
    //    Si el servidor no tiene Gemini configurado, devuelve RAG puro (también útil).
    //    Si falla la conexión, continúa silenciosamente con BM25/FAISS local.
    final llmResp = await _preguntarConLLM(pregunta, materia, grado);
    if (llmResp != null) return llmResp;

    // 5. Búsqueda FAISS en servidor (semántica, si hay internet)
    //    Si el servidor no responde, se usa BM25 local automáticamente.
    List<_EP> scored;
    final faissResult = await _buscarConFAISS(pregunta, materia, grado);
    if (faissResult != null && faissResult.isNotEmpty) {
      scored = faissResult;
    } else {
      // BM25 local + expansión conceptual (offline)
      final tokensExpandidos = _expandirConceptos(tokens, materia);
      scored = _puntuarBM25(corpus, tokensExpandidos, gradoPreferido: grado);
    }

    // 6. Reranking semántico TFLite (siempre activo)
    final reranked = await _rerancarConTFLite(scored, pregunta);

    final top  = reranked.first;
    final top5 = reranked.take(5).toList();

    // 7. Decisión por umbral
    if (top.puntaje >= _minScore) {
      return await _construirRespuesta(top, top5, pregunta, materia, grado);
    }
    if (top.puntaje >= _softMin) {
      return _respuestaAproximada(top, materia, grado);
    }
    return _fallbackInteligente(corpus, materia, grado);
  }

  // ─── Búsqueda semántica FAISS en el servidor ──────────────
  // Timeout corto: si el servidor tarda, cae silenciosamente al BM25 local.
  Future<List<_EP>?> _buscarConFAISS(
    String pregunta, String materia, int grado,
  ) async {
    try {
      final dio = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 6),
        receiveTimeout: const Duration(seconds: 8),
      ));
      final resp = await dio.post(
        '$_apiBase/api/buscar_semantico',
        data: {'pregunta': pregunta, 'materia': materia, 'grado': grado, 'top_k': 5},
      );
      if (resp.statusCode != 200) return null;
      final lista = (resp.data['resultados'] as List<dynamic>?) ?? [];
      if (lista.isEmpty) return null;

      return lista
          .whereType<Map>()
          .map((r) {
            final m = Map<String, dynamic>.from(r);
            // Normalizar palabras_clave: el servidor devuelve List, SQLite String
            final kw = m['palabras_clave'];
            if (kw is List) m['palabras_clave'] = kw.join(', ');
            return _EP(
              entrada: m,
              puntaje: (m['similitud'] as num?)?.toDouble() ?? 0.0,
            );
          })
          .toList();
    } catch (_) {
      return null; // Sin internet → BM25 local
    }
  }

  Future<List<String>> preguntasSugeridas({
    required String materia,
    required int grado,
    int cantidad = 4,
  }) async {
    final entradas = await _db.consultar(
      'base_conocimiento',
      where: 'materia = ? AND grado = ?',
      whereArgs: [materia, grado],
      limit: cantidad * 3,
    );
    final lista = entradas.map((e) => e['pregunta'] as String).toList();
    lista.shuffle();
    return lista.take(cantidad).toList();
  }

  Future<void> guardarHistorial({
    required int estudianteId,
    required String pregunta,
    required String respuesta,
    required String materia,
    required int grado,
  }) async {
    if (grado < 3) return;
    const mapaMateria = {'espanol': 'español'};
    await _db.insertar('historial_rag', {
      'estudiante_id': estudianteId,
      'pregunta':      pregunta,
      'respuesta':     respuesta,
      'materia':       mapaMateria[materia] ?? materia,
      'grado':         grado,
      'fecha':         DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> obtenerHistorial({
    required int estudianteId,
    required String materia,
    int limite = 60,
  }) async {
    const mapaMateria = {'espanol': 'español'};
    final materiaDB = mapaMateria[materia] ?? materia;
    return _db.consultar(
      'historial_rag',
      where: 'estudiante_id = ? AND materia = ?',
      whereArgs: [estudianteId, materiaDB],
      orderBy: 'fecha DESC',
      limit: limite,
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  EXPANSIÓN CONCEPTUAL
  //  Transforma los tokens del usuario en un conjunto expandido
  //  que incluye conceptos relacionados de la KB.
  //  Ejemplo: tokens = ['respiramos'] → stem 'respir' →
  //           expandido += ['pulmones','oxigeno','alveolos',...]
  // ═══════════════════════════════════════════════════════════

  List<String> _expandirConceptos(List<String> tokens, String materia) {
    final mapa = _expansion[materia];
    if (mapa == null) return tokens;

    final expanded = <String>[...tokens];
    for (final token in tokens) {
      final s = _stem(token);
      if (s.length < 3) continue;
      for (final entry in mapa.entries) {
        final key = entry.key;
        // Coincidencia si uno empieza por el otro (stem overlap)
        if (s.startsWith(key) || key.startsWith(s) || s == key) {
          for (final related in entry.value) {
            expanded.addAll(_tokenizar(related));
          }
          break; // una sola key por token para evitar explosión
        }
      }
    }
    return expanded;
  }

  // ═══════════════════════════════════════════════════════════
  //  RERANKING SEMÁNTICO CON TFLITE
  //  Si EmbeddingService tiene un modelo TFLite cargado,
  //  combina el score BM25 con la similitud coseno del embedding.
  //  Si no hay modelo, devuelve los resultados BM25 sin cambios.
  // ═══════════════════════════════════════════════════════════

  Future<List<_EP>> _rerancarConTFLite(List<_EP> scored, String query) async {
    final emb = _embeddings;
    if (emb == null || !emb.modelAvailable) return scored;

    final queryEmb = await emb.encodeLocal(query);
    if (queryEmb == null) return scored;

    // Solo rerankeamos los top-10 por eficiencia en dispositivo móvil
    final top10 = scored.take(10).toList();
    final rest  = scored.skip(10).toList();
    final maxBm25 = top10.first.puntaje + 0.001;

    final reranked = <_EP>[];
    for (final ep in top10) {
      final docText = '${ep.entrada['pregunta']} ${ep.entrada['respuesta']}';
      final docEmb  = await emb.encodeLocal(docText);
      if (docEmb == null) {
        reranked.add(ep);
        continue;
      }
      final cosine   = EmbeddingService.cosineSimilarity(queryEmb, docEmb);
      final bm25Norm = ep.puntaje / maxBm25;
      // coseno de [-1,1] → [0,1]; peso 60% BM25 + 40% semántico
      final combined = bm25Norm * 0.6 + ((cosine + 1) / 2) * 0.4;
      reranked.add(_EP(entrada: ep.entrada, puntaje: combined));
    }

    reranked.sort((a, b) => b.puntaje.compareTo(a.puntaje));
    return [...reranked, ...rest];
  }

  // ═══════════════════════════════════════════════════════════
  //  CONSTRUCCIÓN DE RESPUESTAS — interpretadas por grado
  // ═══════════════════════════════════════════════════════════

  // Respuesta directa (puntaje ≥ minScore)
  // Usa Gemma local si está listo; si no, cae al formateador por grado.
  Future<RagRespuesta> _construirRespuesta(
    _EP top, List<_EP> candidatos, String pregunta, String materia, int grado,
  ) async {
    final tema    = (top.entrada['tema'] as String?)?.trim() ?? '';
    final respRaw = (top.entrada['respuesta'] as String?)?.trim() ?? '';

    String texto;
    final llm = _localLlm;
    if (llm != null && llm.isReady) {
      final buf = StringBuffer();
      try {
        await for (final token in llm.generarRespuesta(
          contexto: respRaw,
          pregunta: pregunta,
          grado: grado,
          materia: materia,
        )) {
          buf.write(token);
        }
        texto = buf.toString().trim();
        if (texto.isEmpty) texto = _interpretarParaNino(respRaw, tema, grado);
      } catch (_) {
        texto = _interpretarParaNino(respRaw, tema, grado);
      }
    } else {
      texto = _interpretarParaNino(respRaw, tema, grado);
    }

    final buffer = StringBuffer(texto);

    // Sugerir tema relacionado si es relevante y diferente
    if (candidatos.length > 1) {
      final seg     = candidatos[1];
      final temaTop = tema.toLowerCase();
      final temaSeg = ((seg.entrada['tema'] as String?)?.toLowerCase() ?? '');
      if (seg.puntaje >= _minScore * 0.72 &&
          temaSeg != temaTop &&
          temaSeg.isNotEmpty) {
        buffer.write(
          grado == 3
              ? '\n\n💡 ¿También quieres que te explique sobre: $temaSeg?'
              : '\n\n💡 También puedo explicarte sobre: $temaSeg.',
        );
      }
    }

    return RagRespuesta(
      texto: buffer.toString().trim(), encontrado: true, tema: tema,
    );
  }

  // ── Formateador inteligente ────────────────────────────────
  // Divide la respuesta en ideas clave y las presenta de forma
  // estructurada y adaptada al grado (3, 4 o 5).
  String _interpretarParaNino(String respRaw, String tema, int grado) {
    final ideas   = _extraerIdeas(respRaw);
    final ejemplo = _extraerEjemplo(respRaw);
    final sb      = StringBuffer();

    // Apertura adaptada al grado
    sb.writeln(_apertura(tema, grado));
    sb.writeln();

    // Ideas principales como bullet points
    if (ideas.length == 1) {
      sb.writeln(ideas.first);
    } else {
      final maxIdeas = grado == 3 ? 3 : grado == 4 ? 4 : 5;
      for (final idea in ideas.take(maxIdeas)) {
        sb.writeln('• $idea');
      }
    }

    // Ejemplo destacado (si la KB lo incluye)
    if (ejemplo != null) {
      sb.writeln();
      sb.writeln(grado == 3
          ? 'Mira este ejemplo: $ejemplo'
          : 'Ejemplo: $ejemplo');
    }

    // Cierre motivador adaptado al grado
    sb.writeln();
    sb.write(_cierre(grado));

    return sb.toString().trim();
  }

  // Divide el texto en ideas/oraciones individuales para los bullet points
  List<String> _extraerIdeas(String texto) {
    // Quitar sección de ejemplo explícito (se maneja aparte)
    final sinEjemplo = texto
        .replaceAll(RegExp(r'[Ee]jemplo:.*', dotAll: true), '')
        .replaceAll(RegExp(r'[Pp]or ejemplo[,:].*', dotAll: true), '')
        .trim();

    // Intentar split por punto seguido de mayúscula (oraciones completas)
    var partes = sinEjemplo
        .split(RegExp(r'(?<=[.!?])\s+(?=[A-ZÁÉÍÓÚÑ¿¡"«0-9])'))
        .map((s) => s.trim().replaceAll(RegExp(r'\s+'), ' '))
        .where((s) => s.length > 8)
        .toList();

    if (partes.isEmpty) {
      // Fallback: split por salto de línea o punto y coma
      partes = sinEjemplo
          .split(RegExp(r'[\n;]'))
          .map((s) => s.trim())
          .where((s) => s.length > 8)
          .toList();
    }

    if (partes.isEmpty) return [sinEjemplo.trim()];
    return partes.take(5).toList();
  }

  // Extrae el ejemplo explícito del texto si existe
  String? _extraerEjemplo(String texto) {
    final m1 = RegExp(r'[Ee]jemplo:?\s*(.+?)(?:\.|$)').firstMatch(texto);
    if (m1 != null) return m1.group(1)?.trim();
    final m2 = RegExp(r'[Pp]or ejemplo[,:]?\s*(.+?)(?:\.|$)').firstMatch(texto);
    if (m2 != null) return m2.group(1)?.trim();
    return null;
  }

  // ── Textos de apertura por grado ──────────────────────────
  String _apertura(String tema, int grado) {
    final t = tema.isNotEmpty ? tema.toLowerCase() : 'este tema';
    switch (grado) {
      case 3:  return '¡Buenísima pregunta! Te cuento sobre $t de forma muy sencilla:';
      case 4:  return 'Muy bien. Aquí va la explicación sobre $t:';
      default: return 'Excelente. Analicemos el tema de $t:';
    }
  }

  // ── Textos de cierre por grado (variados para no repetirse) ─
  static const _cierres3 = [
    '¿Lo entendiste? 😊 ¡Sigue así, eres muy inteligente!',
    '¡Lo estás haciendo genial! ¿Tienes más preguntas? 🌟',
    '¡Eso es! Aprender es divertido. ¿Quieres saber más? 🐒',
  ];
  static const _cierres4 = [
    '¿Quedó claro? ¡No dudes en preguntar más!',
    '¡Excelente curiosidad! ¿Hay algo más sobre este tema?',
    'Si tienes más dudas, ¡aquí estoy para ayudarte!',
  ];
  static const _cierres5 = [
    '¿Quieres que profundicemos más en algún punto?',
    '¿Hay algún aspecto que quieras explorar con más detalle?',
    '¿Tienes más preguntas sobre este tema u otros relacionados?',
  ];

  String _cierre(int grado) {
    final list = grado == 3 ? _cierres3 : grado == 4 ? _cierres4 : _cierres5;
    return list[Random().nextInt(list.length)];
  }

  // ── Respuesta aproximada (softMin ≤ puntaje < minScore) ───
  RagRespuesta _respuestaAproximada(_EP top, String materia, int grado) {
    final tema    = (top.entrada['tema'] as String?)?.trim() ?? '';
    final pregSug = (top.entrada['pregunta'] as String?)?.trim() ?? '';

    final String texto;
    switch (grado) {
      case 3:
        texto = 'Hmm, no tengo exactamente eso 🤔\n\n'
                'Pero sé algo muy parecido sobre:\n'
                '👉 "$tema"\n\n'
                '¿Puedo responderte esta pregunta?\n'
                '"$pregSug"\n\n'
                '¡Escríbela así y te ayudo! 😊';
        break;
      case 4:
        texto = 'No encontré exactamente eso en ${_nombreMateria(materia)} '
                'para grado $grado.\n\n'
                'Lo más parecido que tengo es sobre "$tema".\n\n'
                '¿Quisiste preguntar:\n"$pregSug"?\n\n'
                'Escríbela así y te respondo completo.';
        break;
      default:
        texto = 'No encontré una respuesta exacta para esa pregunta en '
                '${_nombreMateria(materia)} (grado $grado).\n\n'
                'El tema más relacionado es: "$tema".\n\n'
                'Intenta con esta pregunta:\n"$pregSug"';
    }

    return RagRespuesta(texto: texto, encontrado: false, tema: tema);
  }

  // ── Fallback inteligente (puntaje < softMin) ───────────────
  // Sugiere preguntas reales del grado del estudiante desde la KB.
  RagRespuesta _fallbackInteligente(
    List<Map<String, dynamic>> corpus, String materia, int grado,
  ) {
    final delGrado = corpus
        .where((e) => e['grado'] == grado)
        .map((e) => e['pregunta'] as String)
        .toList()
      ..shuffle(Random());

    final sugeridas = delGrado.take(3).toList();

    final String intro;
    switch (grado) {
      case 3:
        intro = '¡Ups! Todavía no tengo esa información 😅\n\n'
                'Pero sí puedo ayudarte con cosas como estas:';
        break;
      case 4:
        intro = 'Ese tema aún no está disponible en ${_nombreMateria(materia)} '
                'para grado $grado.\n\nSí puedo responder preguntas como:';
        break;
      default:
        intro = 'No encontré información sobre ese tema en '
                '${_nombreMateria(materia)} para grado $grado.\n\n'
                'Estas son algunas preguntas que sí puedo responder:';
    }

    final buffer = StringBuffer(intro);
    for (final p in sugeridas) {
      buffer.write('\n• $p');
    }
    if (grado == 3) buffer.write('\n\n¡Anímate y pregunta! 🌟');

    return RagRespuesta(texto: buffer.toString(), encontrado: false, tema: '');
  }

  // ═══════════════════════════════════════════════════════════
  //  EVALUADOR ARITMÉTICO COMPLETO
  //  Maneja: fracciones paso a paso, casos especiales
  //  (doble/mitad/triple/cuadrado/raíz), frases compuestas,
  //  operadores en palabra, operadores símbolo.
  // ═══════════════════════════════════════════════════════════

  // ── GCD auxiliar para simplificar fracciones ──────────────
  static int _gcd(int a, int b) => b == 0 ? a.abs() : _gcd(b, a % b);

  // ── Evaluador de operaciones entre fracciones ─────────────
  // Detecta el patrón "a/b [op] c/d" antes de que los operadores
  // en palabra sean reemplazados por símbolos.
  static RagRespuesta? _evaluarFraccion(String t) {
    // Normalizar operadores en palabra a símbolos provisionales
    final tn = t
        .replaceAll(RegExp(r'multiplicado\s+(?:por|x)?\s*'), '×')
        .replaceAll(RegExp(r'dividido\s+(?:entre|por)?\s*'), '÷')
        .replaceAll(RegExp(r'\bpor\b|\bveces\b'), '×')
        .replaceAll(RegExp(r'\bentre\b'), '÷')
        .replaceAll(RegExp(r'\bmas\b'), '+')
        .replaceAll(RegExp(r'\bmenos\b'), '-')
        .replaceAll('×', '×') // idempotente
        .trim();

    // Patrón: entero/entero operador entero/entero
    final m = RegExp(
      r'^(\d+)\s*/\s*(\d+)\s*([+\-×÷*])\s*(\d+)\s*/\s*(\d+)$',
    ).firstMatch(tn);
    if (m == null) return null;

    final a = int.parse(m.group(1)!);
    final b = int.parse(m.group(2)!);
    final op = m.group(3)!;
    final c = int.parse(m.group(4)!);
    final d = int.parse(m.group(5)!);

    if (b == 0 || d == 0) {
      return const RagRespuesta(
        texto: '¡El denominador de una fracción no puede ser cero!',
        encontrado: true, tema: 'fracciones',
      );
    }

    int numR, denR;
    String pasos;

    if (op == '+') {
      final g = _gcd(b, d);
      final mcm = (b * d) ~/ g;
      final na = a * (mcm ~/ b);
      final nc = c * (mcm ~/ d);
      numR = na + nc;
      denR = mcm;
      pasos = 'Suma de fracciones: $a/$b + $c/$d\n\n'
              'Paso 1: Denominador común (MCM de $b y $d) = $mcm\n'
              'Paso 2: Convierte cada fracción:\n'
              '  • $a/$b = $na/$mcm\n'
              '  • $c/$d = $nc/$mcm\n'
              'Paso 3: Suma los numeradores: $na + $nc = $numR\n\n'
              'Resultado: $numR/$denR';
    } else if (op == '-') {
      final g = _gcd(b, d);
      final mcm = (b * d) ~/ g;
      final na = a * (mcm ~/ b);
      final nc = c * (mcm ~/ d);
      numR = na - nc;
      denR = mcm;
      pasos = 'Resta de fracciones: $a/$b - $c/$d\n\n'
              'Paso 1: Denominador común (MCM de $b y $d) = $mcm\n'
              'Paso 2: Convierte cada fracción:\n'
              '  • $a/$b = $na/$mcm\n'
              '  • $c/$d = $nc/$mcm\n'
              'Paso 3: Resta los numeradores: $na - $nc = $numR\n\n'
              'Resultado: $numR/$denR';
    } else if (op == '×' || op == '*') {
      numR = a * c;
      denR = b * d;
      pasos = 'Multiplicación de fracciones: $a/$b × $c/$d\n\n'
              'Paso 1: Multiplica los numeradores: $a × $c = $numR\n'
              'Paso 2: Multiplica los denominadores: $b × $d = $denR\n\n'
              'Resultado: $numR/$denR';
    } else { // ÷
      if (c == 0) {
        return const RagRespuesta(
          texto: '¡No se puede dividir entre cero!',
          encontrado: true, tema: 'fracciones',
        );
      }
      numR = a * d;
      denR = b * c;
      pasos = 'División de fracciones: $a/$b ÷ $c/$d\n\n'
              'Paso 1: Invierte la segunda fracción: $c/$d → $d/$c\n'
              'Paso 2: Ahora multiplica: $a/$b × $d/$c\n'
              'Paso 3: Numeradores: $a × $d = $numR\n'
              'Paso 4: Denominadores: $b × $c = $denR\n\n'
              'Resultado: $numR/$denR';
    }

    // Simplificar resultado
    if (denR != 0) {
      final g = _gcd(numR.abs(), denR.abs());
      if (g > 1) {
        final sN = numR ~/ g;
        final sD = denR ~/ g;
        pasos += sD == 1 ? ' = $sN (número entero)' : ' = $sN/$sD (simplificado)';
      } else if (numR > 0 && denR > 0 && numR > denR) {
        final ent = numR ~/ denR;
        final rem = numR % denR;
        if (rem != 0) pasos += ' → número mixto: $ent y $rem/$denR';
      }
    }

    return RagRespuesta(texto: pasos, encontrado: true, tema: 'fracciones');
  }

  static RagRespuesta? _calcularExpresion(String texto) {
    var t = _quitarAcentos(texto.toLowerCase())
        .replaceAll(RegExp(r'[?¿!¡]'), '')
        .trim();

    t = t
        .replaceAll(RegExp(r'^cu[aá]nto[s]?\s+(es|son|da|vale|valen|hay)\s+'), '')
        .replaceAll(RegExp(r'^cu[aá]l\s+es\s+(el\s+)?(resultado\s+de\s+)?'), '')
        .replaceAll(RegExp(r'^(calcula|resuelve|halla|encuentra|dime)\s+'), '')
        .replaceAll(RegExp(r'^(el\s+)?(resultado\s+de|resultado)\s+'), '')
        .replaceAll(RegExp(r'^que\s+(es|vale|da)\s+'), '')
        .trim();

    // Detectar operaciones entre fracciones antes de normalizar operadores
    final fracResult = _evaluarFraccion(t);
    if (fracResult != null) return fracResult;

    // Casos especiales
    var m = RegExp(r'^(el\s+)?doble\s+de\s+(\d+(?:[.,]\d+)?)$').firstMatch(t);
    if (m != null) {
      final n = _parseNum(m.group(2)!);
      return _respEspecial('El doble de ${_fmt(n)}', n * 2, 'multiplicación',
          '${_fmt(n)} × 2 = ${_fmt(n * 2)}');
    }

    m = RegExp(r'^(la\s+)?mitad\s+de\s+(\d+(?:[.,]\d+)?)$').firstMatch(t);
    if (m != null) {
      final n = _parseNum(m.group(2)!);
      return _respEspecial('La mitad de ${_fmt(n)}', n / 2, 'división',
          '${_fmt(n)} ÷ 2 = ${_fmt(n / 2)}');
    }

    m = RegExp(r'^(el\s+)?triple\s+de\s+(\d+(?:[.,]\d+)?)$').firstMatch(t);
    if (m != null) {
      final n = _parseNum(m.group(2)!);
      return _respEspecial('El triple de ${_fmt(n)}', n * 3, 'multiplicación',
          '${_fmt(n)} × 3 = ${_fmt(n * 3)}');
    }

    m = RegExp(r'^(\d+(?:[.,]\d+)?)\s*(al\s+cuadrado|\^2|elevado\s+a\s+(la\s+)?2)$')
        .firstMatch(t);
    if (m != null) {
      final n = _parseNum(m.group(1)!);
      final r = n * n;
      return RagRespuesta(
        texto: '${_fmt(n)}² = ${_fmt(r)}\n(${_fmt(n)} × ${_fmt(n)} = ${_fmt(r)})',
        encontrado: true, tema: 'potencias',
      );
    }

    m = RegExp(r'^(\d+(?:[.,]\d+)?)\s*(al\s+cubo|\^3|elevado\s+a\s+(la\s+)?3)$')
        .firstMatch(t);
    if (m != null) {
      final n = _parseNum(m.group(1)!);
      final r = n * n * n;
      return RagRespuesta(
        texto: '${_fmt(n)}³ = ${_fmt(r)}\n(${_fmt(n)} × ${_fmt(n)} × ${_fmt(n)} = ${_fmt(r)})',
        encontrado: true, tema: 'potencias',
      );
    }

    m = RegExp(r'^(ra[ií]z\s+(?:cuadrada\s+)?de\s+|√)(\d+(?:[.,]\d+)?)$').firstMatch(t);
    if (m != null) {
      final n = _parseNum(m.group(2)!);
      final r = sqrt(n);
      return RagRespuesta(
        texto: '√${_fmt(n)} = ${_fmt(r)}\n'
               'La raíz cuadrada de ${_fmt(n)} es ${_fmt(r)}.',
        encontrado: true, tema: 'raíz cuadrada',
      );
    }

    // Normalización de operadores (frases multi-palabra primero)
    t = t
        .replaceAll(RegExp(r'multiplicado\s+por'), '*')
        .replaceAll(RegExp(r'multiplicado\s+x'),   '*')
        .replaceAll(RegExp(r'multiplicado\s+'),    '*')
        .replaceAll(RegExp(r'dividido\s+entre'),   '/')
        .replaceAll(RegExp(r'dividido\s+por'),     '/')
        .replaceAll(RegExp(r'dividido\s+'),        '/')
        .replaceAll(RegExp(r'sumado\s+[a-z]*\s*'), '+');

    t = t
        .replaceAll(RegExp(r'\bmas\b'),          '+')
        .replaceAll(RegExp(r'\bmenos\b'),         '-')
        .replaceAll(RegExp(r'\bpor\b|\bveces\b'), '*')
        .replaceAll(RegExp(r'\bentre\b'),         '/')
        .replaceAll(RegExp(r'\bx\b'),             '*');

    t = t
        .replaceAll('×', '*')
        .replaceAll('÷', '/')
        .replaceAll(',', '.')
        .trim();

    final match = RegExp(
      r'^(\d+(?:\.\d+)?)\s*([+\-*/])\s*(\d+(?:\.\d+)?)$',
    ).firstMatch(t);
    if (match == null) return null;

    final a  = double.parse(match.group(1)!);
    final op = match.group(2)!;
    final b  = double.parse(match.group(3)!);

    double resultado;
    String operacion;
    String simbolo;

    switch (op) {
      case '+': resultado = a + b; operacion = 'suma';           simbolo = '+'; break;
      case '-': resultado = a - b; operacion = 'resta';          simbolo = '-'; break;
      case '*': resultado = a * b; operacion = 'multiplicación'; simbolo = '×'; break;
      case '/':
        if (b == 0) {
          return const RagRespuesta(
            texto: '¡No se puede dividir entre cero!\n'
                   'El cero nunca puede ser divisor.',
            encontrado: true, tema: 'división',
          );
        }
        resultado = a / b; operacion = 'división'; simbolo = '÷'; break;
      default: return null;
    }

    return RagRespuesta(
      texto: '${_fmt(a)} $simbolo ${_fmt(b)} = ${_fmt(resultado)}\n\n'
             '¡Muy bien! La $operacion de ${_fmt(a)} y ${_fmt(b)} es ${_fmt(resultado)}.',
      encontrado: true,
      tema: operacion,
    );
  }

  static RagRespuesta _respEspecial(
      String enunciado, double resultado, String tema, String calculo) {
    return RagRespuesta(
      texto: '$enunciado = ${_fmt(resultado)}\n($calculo)',
      encontrado: true,
      tema: tema,
    );
  }

  static double _parseNum(String s) => double.parse(s.replaceAll(',', '.'));

  static String _fmt(double n) {
    if (n == n.truncateToDouble()) return n.toInt().toString();
    final s = n.toStringAsFixed(4);
    return s.replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
  }

  // ═══════════════════════════════════════════════════════════
  //  BM25
  // ═══════════════════════════════════════════════════════════

  List<_EP> _puntuarBM25(
    List<Map<String, dynamic>> corpus,
    List<String> tokens, {
    int? gradoPreferido,
  }) {
    final stems = tokens.map(_stem).toSet().toList();
    if (stems.isEmpty || corpus.isEmpty) {
      return corpus.map((e) => _EP(entrada: e, puntaje: 0)).toList();
    }

    final N = corpus.length.toDouble();

    // palabras_clave ×3, pregunta ×2, respuesta ×1
    final docTerms = corpus.map((e) {
      final kw = (e['palabras_clave'] as String)
          .split(',')
          .map((w) => _stem(_normalizar(w.trim())))
          .toList();
      final pq = _tokenizar(e['pregunta'] as String).map(_stem).toList();
      final rs = _tokenizar(e['respuesta'] as String).map(_stem).toList();
      return [...kw, ...kw, ...kw, ...pq, ...pq, ...rs];
    }).toList();

    final totalLen = docTerms.fold<int>(0, (s, d) => s + d.length);
    final avgDl    = totalLen / N;

    final idf = <String, double>{};
    for (final stem in stems) {
      final df = docTerms.where((d) => d.contains(stem)).length.toDouble();
      idf[stem] = log((N - df + 0.5) / (df + 0.5) + 1);
    }

    final result = List<_EP>.generate(corpus.length, (i) {
      final doc = docTerms[i];
      final dl  = doc.length.toDouble();
      double score = 0;

      for (final stem in stems) {
        final tf = doc.where((t) => t == stem).length.toDouble();
        if (tf == 0) continue;
        score += idf[stem]! *
            (tf * (_k1 + 1)) /
            (tf + _k1 * (1 - _b + _b * dl / avgDl));
      }

      // Boost 30 % para el grado exacto del estudiante
      if (gradoPreferido != null && corpus[i]['grado'] == gradoPreferido) {
        score *= 1.3;
      }

      return _EP(entrada: corpus[i], puntaje: score);
    });

    result.sort((a, b) => b.puntaje.compareTo(a.puntaje));
    return result;
  }

  // ═══════════════════════════════════════════════════════════
  //  TOKENIZADOR
  // ═══════════════════════════════════════════════════════════

  List<String> _tokenizar(String texto) {
    final mathTokens = <String>[];
    var t = texto.toLowerCase();

    t = t.replaceAllMapped(RegExp(r'[+]'),  (_) { mathTokens.add('suma');  return ' '; });
    t = t.replaceAllMapped(RegExp(r'[×*]'), (_) { mathTokens.add('multi'); return ' '; });
    t = t.replaceAllMapped(RegExp(r'[÷]'),  (_) { mathTokens.add('divid'); return ' '; });

    t = _normalizar(t).replaceAll(RegExp(r'[^a-z0-9\s]'), ' ');

    final regular = t.split(RegExp(r'\s+')).where((w) {
      if (w.isEmpty) return false;
      if (RegExp(r'^\d+$').hasMatch(w)) return true;
      return w.length >= 3 && !_stopwords.contains(w);
    }).toList();

    return [...regular, ...mathTokens];
  }

  // ─── Stemmer español ──────────────────────────────────────

  String _stem(String word) {
    final w = _normalizar(word);
    for (final sufijo in _sufijos) {
      if (w.endsWith(sufijo) && w.length - sufijo.length >= 3) {
        return w.substring(0, w.length - sufijo.length);
      }
    }
    return w;
  }

  String _normalizar(String t) => _quitarAcentos(t).trim();

  static String _quitarAcentos(String t) => t
      .toLowerCase()
      .replaceAll(RegExp(r'[áàâä]'), 'a')
      .replaceAll(RegExp(r'[éèêë]'), 'e')
      .replaceAll(RegExp(r'[íìîï]'), 'i')
      .replaceAll(RegExp(r'[óòôö]'), 'o')
      .replaceAll(RegExp(r'[úùûü]'), 'u')
      .replaceAll('ñ', 'n');

  static String _nombreMateria(String m) => const {
    'matematicas': 'Matemáticas',
    'ciencias':    'Ciencias',
    'espanol':     'Español',
    'ingles':      'Inglés',
    'sociales':    'Sociales',
  }[m] ?? m;

  // ─── Generador de preguntas de selección múltiple ────────────

  Future<List<PreguntaQuiz>> generarPreguntasMCQ({
    required String materia,
    required int grado,
    int cantidad = 10,
  }) async {
    final corpus = await _db.consultar(
      'base_conocimiento',
      where: 'materia = ? AND grado = ?',
      whereArgs: [materia, grado],
    );

    if (corpus.length < 4) return [];

    final rng = Random();
    final entradas = List<Map<String, dynamic>>.from(corpus)..shuffle(rng);
    final resultado = <PreguntaQuiz>[];

    for (final correcta in entradas.take(cantidad)) {
      final temaCorrect = correcta['tema'] as String? ?? '';
      final respCorrecta =
          _extractarRespuestaCorta(correcta['respuesta'] as String);

      // Candidatos ordenados: mismo tema primero, otros temas como fallback.
      // Así todas las opciones hablan del mismo tema siempre que el corpus
      // tenga suficientes entradas; solo se mezclan temas si no hay de sobra.
      final mismoTema = corpus
          .where((e) =>
              e != correcta &&
              (e['tema'] as String? ?? '') == temaCorrect)
          .toList()
        ..shuffle(rng);

      final otrosTemas = corpus
          .where((e) =>
              e != correcta &&
              (e['tema'] as String? ?? '') != temaCorrect)
          .toList()
        ..shuffle(rng);

      // Elegir 3 distractores comprobando el texto extraído antes de usarlos,
      // para garantizar que ningún par de opciones sea idéntico o casi idéntico.
      final clavesUsadas = {_claveDistractor(respCorrecta)};
      final distractoresTextos = <String>[];

      for (final pool in [mismoTema, otrosTemas]) {
        for (final e in pool) {
          if (distractoresTextos.length >= 3) break;
          final texto = _extractarRespuestaCorta(e['respuesta'] as String);
          final clave = _claveDistractor(texto);
          if (texto.length >= 8 && !clavesUsadas.contains(clave)) {
            clavesUsadas.add(clave);
            distractoresTextos.add(texto);
          }
        }
        if (distractoresTextos.length >= 3) break;
      }

      if (distractoresTextos.length < 3) continue;

      final opciones = [respCorrecta, ...distractoresTextos];
      final lista = List.generate(4, (i) => (i == 0, opciones[i]));
      lista.shuffle(rng);

      resultado.add(PreguntaQuiz(
        pregunta: _reformularPregunta(correcta['pregunta'] as String),
        opciones: lista.map((e) => e.$2).toList(),
        indiceCorrecto: lista.indexWhere((e) => e.$1),
        tema: temaCorrect,
      ));
    }

    return resultado;
  }

  // Hace la pregunta concisa y muy fácil de leer para niños de 3°-5°.
  String _reformularPregunta(String pregunta) {
    var q = pregunta.trim();

    // Arreglar palabras pegadas del corpus
    q = q.replaceAllMapped(
      RegExp(
        r'\b(es|son|fue|era|están|y)(la|el|los|las|un|una|unos|unas)\b',
        caseSensitive: false,
      ),
      (m) => '${m.group(1)} ${m.group(2)}',
    );

    // Normalizar espacios dobles
    q = q.replaceAll(RegExp(r'\s{2,}'), ' ').trim();

    // Quitar punto final; las preguntas terminan en '?'
    q = q.replaceAll(RegExp(r'[.:]$'), '').trim();
    if (!q.endsWith('?')) q = '$q?';

    // Simplificar arranques académicos → lenguaje infantil
    q = q
        .replaceFirst(RegExp(r'^¿En qué consiste\s+',                   caseSensitive: false), '¿Qué es ')
        .replaceFirst(RegExp(r'^¿Cuál es la definición de\s+',          caseSensitive: false), '¿Qué es ')
        .replaceFirst(RegExp(r'^¿Cuál es el concepto de\s+',            caseSensitive: false), '¿Qué es ')
        .replaceFirst(RegExp(r'^¿A qué se denomina\s+',                 caseSensitive: false), '¿Cómo se llama ')
        .replaceFirst(RegExp(r'^¿Cómo se denomina\s+',                  caseSensitive: false), '¿Cómo se llama ')
        .replaceFirst(RegExp(r'^¿Cuál de los siguientes\s+',            caseSensitive: false), '¿Cuál ')
        .replaceFirst(RegExp(r'^¿Cuáles son las características de\s+', caseSensitive: false), '¿Cómo es ')
        .replaceFirst(RegExp(r'^¿Cuál es la función de\s+',             caseSensitive: false), '¿Para qué sirve ')
        .replaceFirst(RegExp(r'^¿Cuál es la importancia de\s+',         caseSensitive: false), '¿Por qué es importante ')
        .replaceFirst(RegExp(r'^¿Qué elementos conforman\s+',           caseSensitive: false), '¿Qué tiene ')
        .replaceFirst(RegExp(r'^¿Cómo se clasifican\s+',                caseSensitive: false), '¿En qué grupos se dividen ')
        .replaceFirst(RegExp(r'^¿Cómo se lleva a cabo\s+',              caseSensitive: false), '¿Cómo ocurre ')
        .replaceFirst(RegExp(r'^¿Cuál es el proceso de\s+',             caseSensitive: false), '¿Cómo funciona ')
        .replaceFirst(RegExp(r'^¿Cuáles son los tipos de\s+',           caseSensitive: false), '¿Qué tipos de ')
        .replaceFirst(RegExp(r'^¿Qué factores\s+',                      caseSensitive: false), '¿Qué cosas ')
        .replaceFirst(RegExp(r'^¿De qué manera\s+',                     caseSensitive: false), '¿Cómo ')
        .replaceFirst(RegExp(r'^¿De qué forma\s+',                      caseSensitive: false), '¿Cómo ')
        .replaceFirst(RegExp(r'^¿Mediante qué\s+',                      caseSensitive: false), '¿Con qué ')
        .replaceFirst(RegExp(r'^¿Cuál es la principal\s+',              caseSensitive: false), '¿Cuál es la ');

    // Limite de 70 chars para que sea fácil de leer de un vistazo
    if (q.length > 70) {
      final cortes = [q.indexOf(', '), q.indexOf(': ')];
      final primero = cortes
          .where((i) => i > 20 && i < 62)
          .fold<int>(-1, (best, i) => best == -1 ? i : (i < best ? i : best));
      if (primero > 0) {
        q = '${q.substring(0, primero).trim()}?';
      } else {
        final sub = q.substring(0, 65);
        final espacio = sub.lastIndexOf(' ');
        q = '${sub.substring(0, espacio > 0 ? espacio : 65).replaceAll(RegExp(r'[?,]$'), '')}?';
      }
    }

    // Capitalizar letra después de '¿'
    if (q.length > 2 && q[0] == '¿') {
      q = '¿${q[1].toUpperCase()}${q.substring(2)}';
    }

    return q;
  }

  // Devuelve la primera idea corta de la respuesta (máx 90 chars).
  // Las opciones deben ser fáciles de leer de un vistazo para niños.
  String _extractarRespuestaCorta(String respuesta) {
    var s = respuesta.trim();

    // Quitar prefijos académicos tipo "R:" o "Respuesta:"
    s = s.replaceFirst(RegExp(r'^[Rr]espuesta\s*[:\-]\s*'), '');
    s = s.replaceFirst(RegExp(r'^[Rr]\.\s*'), '');
    s = s.replaceAll(RegExp(r'\s{2,}'), ' ').trim();

    // Paso 1 — primera oración completa (hasta 90 chars)
    final matchOracion = RegExp(r'[.!](?:\s|$)').firstMatch(s);
    if (matchOracion != null) {
      final primera = s.substring(0, matchOracion.start + 1).trim();
      if (primera.length >= 8 && primera.length <= 90) {
        return _limpiarOpcion(primera);
      }
    }

    // Paso 2 — texto corto: devolver completo
    if (s.length <= 90) return _limpiarOpcion(s);

    // Paso 3 — punto y coma como separador fuerte
    final semiIdx = s.indexOf('; ');
    if (semiIdx >= 15 && semiIdx <= 85) {
      return _limpiarOpcion(s.substring(0, semiIdx));
    }

    // Paso 4 — coma como separador (mínimo 30 chars para que tenga sentido)
    final commaIdx = s.indexOf(', ');
    if (commaIdx >= 30 && commaIdx <= 85) {
      return _limpiarOpcion(s.substring(0, commaIdx));
    }

    // Paso 5 — corte en palabra completa sin artículos/preposiciones al final
    final sub = s.substring(0, 85);
    final palabras = sub.split(' ')..removeLast();
    const _debiles = {
      'el', 'la', 'los', 'las', 'un', 'una', 'unos', 'unas',
      'de', 'del', 'en', 'que', 'al', 'con', 'por', 'para',
      'es', 'son', 'fue', 'su', 'sus', 'a', 'y', 'o', 'como', 'se',
    };
    while (palabras.isNotEmpty &&
        _debiles.contains(palabras.last.toLowerCase())) {
      palabras.removeLast();
    }
    return _limpiarOpcion(palabras.join(' '));
  }

  String _limpiarOpcion(String s) {
    s = s.replaceAll(RegExp(r'[,;:]$'), '').trim();
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }

  // Clave normalizada para detectar opciones duplicadas o casi idénticas.
  // Compara los primeros 45 caracteres alfanuméricos sin acentos.
  String _claveDistractor(String texto) {
    final norm = _normalizar(texto).replaceAll(RegExp(r'[^a-z0-9]'), '');
    return norm.substring(0, norm.length.clamp(0, 45));
  }
}

// ─── Tipos internos ───────────────────────────────────────────

class _EP {
  final Map<String, dynamic> entrada;
  final double puntaje;
  _EP({required this.entrada, required this.puntaje});
}

// ─── Respuesta pública ────────────────────────────────────────

class RagRespuesta {
  final String texto;
  final bool encontrado;
  final String tema;
  const RagRespuesta({
    required this.texto,
    required this.encontrado,
    required this.tema,
  });
}

// ─── Pregunta de selección múltiple ──────────────────────────

class PreguntaQuiz {
  final String pregunta;
  final List<String> opciones;   // siempre 4 elementos
  final int indiceCorrecto;      // 0–3
  final String tema;

  const PreguntaQuiz({
    required this.pregunta,
    required this.opciones,
    required this.indiceCorrecto,
    required this.tema,
  });
}
