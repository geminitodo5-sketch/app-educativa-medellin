// ─────────────────────────────────────────────────────────────
//  lib/data/services/rag_service.dart  v3.0
//  Motor RAG offline — BM25 + expansión conceptual + reranking TFLite
//
//  Flujo de búsqueda:
//    1. Evaluador aritmético (solo matemáticas)
//    2. Tokenización + expansión de conceptos por materia
//    3. BM25 sobre corpus completo de la materia
//    4. Reranking semántico TFLite (si el modelo está disponible)
//    5. Decisión por umbral:
//         ≥ minScore  → respuesta directa + tema relacionado si aplica
//         ≥ softMin   → "¿quisiste preguntar sobre X?"
//         < softMin   → fallback con preguntas reales del grado del estudiante
// ─────────────────────────────────────────────────────────────

import 'dart:math';
import 'sqlite_service.dart';
import 'embedding_service.dart';

class RagService {
  final SqliteService _db;
  final EmbeddingService? _embeddings;

  // El parámetro embeddings es opcional: si se pasa un EmbeddingService con
  // el modelo TFLite cargado, se activa el reranking semántico automáticamente.
  RagService(this._db, {EmbeddingService? embeddings})
      : _embeddings = embeddings;

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
        texto: '¡Hola! Pregúntame algo sobre ${_nombreMateria(materia)}.\n'
               'Por ejemplo:\n${_ejemplos[materia] ?? '¿Qué es...?'}',
        encontrado: false, tema: '',
      );
    }

    // 3. Cargar corpus completo de la materia (IDF preciso en BM25)
    final corpus = await _db.consultar(
      'base_conocimiento',
      where: 'materia = ?',
      whereArgs: [materia],
    );
    if (corpus.isEmpty) {
      return RagRespuesta(
        texto: 'Aún no descargaste el contenido de ${_nombreMateria(materia)}. '
               'Toca "Descargar" en el menú para continuar.',
        encontrado: false, tema: '',
      );
    }

    // 4. BM25 con expansión conceptual
    //    Los tokens se expanden con sinónimos/conceptos relacionados
    //    para que el sistema entienda el mismo tema desde distintos ángulos.
    final tokensExpandidos = _expandirConceptos(tokens, materia);
    final scored = _puntuarBM25(corpus, tokensExpandidos, gradoPreferido: grado);

    // 5. Reranking semántico con TFLite (activo solo si el modelo está cargado)
    final reranked = await _rerancarConTFLite(scored, pregunta);

    final top = reranked.first;
    final top5 = reranked.take(5).toList();

    // 6. Decisión por umbral
    if (top.puntaje >= _minScore) {
      return _construirRespuesta(top, top5, materia, grado);
    }
    if (top.puntaje >= _softMin) {
      return _respuestaAproximada(top, materia, grado);
    }
    return _fallbackInteligente(corpus, materia, grado);
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
  //  CONSTRUCCIÓN DE RESPUESTAS
  // ═══════════════════════════════════════════════════════════

  // Respuesta directa (puntaje ≥ minScore)
  RagRespuesta _construirRespuesta(
    _EP top, List<_EP> candidatos, String materia, int grado,
  ) {
    final buffer = StringBuffer();
    buffer.write(top.entrada['respuesta'] as String);

    // Si hay un segundo resultado relevante con tema distinto, sugerirlo
    if (candidatos.length > 1) {
      final segundo   = candidatos[1];
      final temaTop   = (top.entrada['tema'] as String).toLowerCase();
      final temaSeg   = (segundo.entrada['tema'] as String).toLowerCase();
      final puntSeg   = segundo.puntaje;

      if (puntSeg >= _minScore * 0.72 && temaSeg != temaTop) {
        buffer.write('\n\n▸ También relacionado con tu pregunta: '
                     '${segundo.entrada['tema']}');
        buffer.write('\n  Puedes preguntar: "${segundo.entrada['pregunta']}"');
      }
    }

    return RagRespuesta(
      texto:      buffer.toString(),
      encontrado: true,
      tema:       top.entrada['tema'] as String,
    );
  }

  // Respuesta aproximada (softMin ≤ puntaje < minScore)
  RagRespuesta _respuestaAproximada(_EP top, String materia, int grado) {
    final tema     = top.entrada['tema'] as String;
    final pregSug  = top.entrada['pregunta'] as String;
    return RagRespuesta(
      texto: 'No encontré exactamente eso en ${_nombreMateria(materia)} '
             'para grado $grado, pero lo más cercano que tengo es sobre "$tema".\n\n'
             '¿Quisiste preguntar: "$pregSug"?\n\n'
             'Escríbela así y te respondo completo.',
      encontrado: false,
      tema: tema,
    );
  }

  // Fallback inteligente (puntaje < softMin)
  // Sugiere preguntas reales del grado del estudiante desde la KB.
  RagRespuesta _fallbackInteligente(
    List<Map<String, dynamic>> corpus, String materia, int grado,
  ) {
    // Filtrar entradas del grado del estudiante
    final delGrado = corpus
        .where((e) => e['grado'] == grado)
        .map((e) => e['pregunta'] as String)
        .toList()
      ..shuffle(Random());

    final sugeridas = delGrado.take(3).toList();

    final buffer = StringBuffer();
    buffer.write(
      'Hmm, no encontré información sobre ese tema en '
      '${_nombreMateria(materia)} para grado $grado. '
      'Es posible que ese contenido aún no esté disponible, '
      'pero seguiremos ampliando poco a poco.',
    );

    if (sugeridas.isNotEmpty) {
      buffer.write('\n\nSí sé responder cosas como estas (grado $grado):');
      for (final p in sugeridas) {
        buffer.write('\n• $p');
      }
    }

    return RagRespuesta(texto: buffer.toString(), encontrado: false, tema: '');
  }

  // ═══════════════════════════════════════════════════════════
  //  EVALUADOR ARITMÉTICO COMPLETO
  //  Maneja: casos especiales (doble/mitad/triple/cuadrado/raíz),
  //  frases compuestas, operadores en palabra, operadores símbolo.
  // ═══════════════════════════════════════════════════════════

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
