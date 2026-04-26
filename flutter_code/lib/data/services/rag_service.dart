// ─────────────────────────────────────────────────────────────
//  lib/data/services/rag_service.dart
//  Motor RAG offline — BM25 + evaluador aritmético completo
//  Cubre: operadores símbolo, palabras (multiplicado por, entre…),
//  casos especiales (doble, mitad, triple, cuadrado, raíz).
// ─────────────────────────────────────────────────────────────

import 'dart:math';
import 'sqlite_service.dart';

class RagService {
  final SqliteService _db;
  RagService(this._db);

  // ─── BM25 hiperparámetros ─────────────────────────────────
  static const double _k1 = 1.5;
  static const double _b  = 0.75;
  static const double _minScore = 0.35;

  // ─── Stopwords normalizadas ───────────────────────────────
  // "mas" y "menos" NO están aquí porque son operadores matemáticos.
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

  // ─── Ejemplos por materia para el mensaje de fallback ────
  static const _ejemplos = {
    'matematicas': '¿Cuánto es 8 × 7?\n¿Qué es una fracción?\n¿Cómo calculo el área?',
    'ciencias':    '¿Qué es la fotosíntesis?\n¿Cómo funciona el sistema digestivo?\n¿Qué es un ecosistema?',
    'espanol':     '¿Qué es un sustantivo?\n¿Cómo se usa la coma?\n¿Qué es una metáfora?',
    'ingles':      '¿Qué significa "friend"?\n¿Cómo se usa "to be"?\n¿Qué son los verbos irregulares?',
    'sociales':    '¿Qué es la Constitución?\n¿Cuáles son los ríos de Colombia?\n¿Qué es la democracia?',
  };

  // ─── API pública ──────────────────────────────────────────

  Future<RagRespuesta> responder({
    required String pregunta,
    required String materia,
    required int grado,
  }) async {
    // 1. Evaluador aritmético (solo matemáticas — responde sin tocar la BD)
    if (materia == 'matematicas') {
      final calc = _calcularExpresion(pregunta);
      if (calc != null) return calc;
    }

    final tokens = _tokenizar(pregunta);

    if (tokens.isEmpty) {
      return RagRespuesta(
        texto: '¡Hola! Pregúntame algo sobre ${_nombreMateria(materia)}.\n'
               'Por ejemplo:\n${_ejemplos[materia] ?? '¿Qué es...?'}',
        encontrado: false, tema: '',
      );
    }

    // 2. Carga corpus completo de la materia (IDF preciso en BM25)
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

    // 3. BM25 con boost de grado
    final scored = _puntuarBM25(corpus, tokens, gradoPreferido: grado);
    final mejor = scored.first;

    if (mejor.puntaje < _minScore) {
      return RagRespuesta(
        texto: 'No encontré eso en ${_nombreMateria(materia)} para grado $grado.\n'
               'Intenta preguntar así:\n${_ejemplos[materia] ?? '¿Qué es...?'}',
        encontrado: false, tema: '',
      );
    }

    return RagRespuesta(
      texto: mejor.entrada['respuesta'] as String,
      encontrado: true,
      tema: mejor.entrada['tema'] as String,
    );
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
  //  EVALUADOR ARITMÉTICO COMPLETO
  // ═══════════════════════════════════════════════════════════
  //
  //  Maneja en orden:
  //    1. Casos especiales: el doble de N, la mitad de N, el triple de N,
  //       N al cuadrado, N al cubo, raíz cuadrada de N
  //    2. Frases compuestas: "multiplicado por", "dividido entre/por"
  //    3. Operadores en palabra: mas, menos, por, entre, veces, x
  //    4. Operadores símbolo: +, -, ×, *, ÷, /
  //    5. Expresión final: número op número

  static RagRespuesta? _calcularExpresion(String texto) {
    // Normaliza y limpia
    var t = _quitarAcentos(texto.toLowerCase())
        .replaceAll(RegExp(r'[?¿!¡]'), '')
        .trim();

    // Quita prefijos de pregunta comunes
    t = t
        .replaceAll(RegExp(r'^cu[aá]nto[s]?\s+(es|son|da|vale|valen|hay)\s+'), '')
        .replaceAll(RegExp(r'^cu[aá]l\s+es\s+(el\s+)?(resultado\s+de\s+)?'), '')
        .replaceAll(RegExp(r'^(calcula|resuelve|halla|encuentra|dime)\s+'), '')
        .replaceAll(RegExp(r'^(el\s+)?(resultado\s+de|resultado)\s+'), '')
        .replaceAll(RegExp(r'^que\s+(es|vale|da)\s+'), '')
        .trim();

    // ── Casos especiales ──────────────────────────────────────

    // "el doble de N"
    var m = RegExp(r'^(el\s+)?doble\s+de\s+(\d+(?:[.,]\d+)?)$').firstMatch(t);
    if (m != null) {
      final n = _parseNum(m.group(2)!);
      return _respEspecial('El doble de ${_fmt(n)}', n * 2, 'multiplicación',
          '${_fmt(n)} × 2 = ${_fmt(n * 2)}');
    }

    // "la mitad de N"
    m = RegExp(r'^(la\s+)?mitad\s+de\s+(\d+(?:[.,]\d+)?)$').firstMatch(t);
    if (m != null) {
      final n = _parseNum(m.group(2)!);
      return _respEspecial('La mitad de ${_fmt(n)}', n / 2, 'división',
          '${_fmt(n)} ÷ 2 = ${_fmt(n / 2)}');
    }

    // "el triple de N"
    m = RegExp(r'^(el\s+)?triple\s+de\s+(\d+(?:[.,]\d+)?)$').firstMatch(t);
    if (m != null) {
      final n = _parseNum(m.group(2)!);
      return _respEspecial('El triple de ${_fmt(n)}', n * 3, 'multiplicación',
          '${_fmt(n)} × 3 = ${_fmt(n * 3)}');
    }

    // "N al cuadrado" / "N elevado a 2" / "N^2"
    m = RegExp(r'^(\d+(?:[.,]\d+)?)\s*(al\s+cuadrado|\^2|elevado\s+a\s+(la\s+)?2)$')
        .firstMatch(t);
    if (m != null) {
      final n = _parseNum(m.group(1)!);
      final r = n * n;
      return RagRespuesta(
        texto: '${_fmt(n)}² = ${_fmt(r)}\n'
               '(${_fmt(n)} × ${_fmt(n)} = ${_fmt(r)})',
        encontrado: true, tema: 'potencias',
      );
    }

    // "N al cubo" / "N elevado a 3" / "N^3"
    m = RegExp(r'^(\d+(?:[.,]\d+)?)\s*(al\s+cubo|\^3|elevado\s+a\s+(la\s+)?3)$')
        .firstMatch(t);
    if (m != null) {
      final n = _parseNum(m.group(1)!);
      final r = n * n * n;
      return RagRespuesta(
        texto: '${_fmt(n)}³ = ${_fmt(r)}\n'
               '(${_fmt(n)} × ${_fmt(n)} × ${_fmt(n)} = ${_fmt(r)})',
        encontrado: true, tema: 'potencias',
      );
    }

    // "raíz (cuadrada) de N" / "√N"
    m = RegExp(r'^(ra[ií]z\s+(?:cuadrada\s+)?de\s+|√)(\d+(?:[.,]\d+)?)$')
        .firstMatch(t);
    if (m != null) {
      final n = _parseNum(m.group(2)!);
      final r = sqrt(n);
      return RagRespuesta(
        texto: '√${_fmt(n)} = ${_fmt(r)}\n'
               'La raíz cuadrada de ${_fmt(n)} es ${_fmt(r)}.',
        encontrado: true, tema: 'raíz cuadrada',
      );
    }

    // ── Normalización de operadores compuestos (orden: frases primero) ───

    // Frases multi-palabra ANTES que palabras sueltas
    t = t
        .replaceAll(RegExp(r'multiplicado\s+por'),  '*')
        .replaceAll(RegExp(r'multiplicado\s+x'),    '*')
        .replaceAll(RegExp(r'multiplicado\s+'),     '*')   // "multiplicado N" sin "por"
        .replaceAll(RegExp(r'dividido\s+entre'),    '/')
        .replaceAll(RegExp(r'dividido\s+por'),      '/')
        .replaceAll(RegExp(r'dividido\s+'),         '/')   // "dividido N" sin preposición
        .replaceAll(RegExp(r'sumado\s+[a-z]*\s*'), '+');

    // Palabras sueltas
    t = t
        .replaceAll(RegExp(r'\bmas\b'),         '+')
        .replaceAll(RegExp(r'\bmenos\b'),        '-')
        .replaceAll(RegExp(r'\bpor\b|\bveces\b'), '*')
        .replaceAll(RegExp(r'\bentre\b'),        '/')
        .replaceAll(RegExp(r'\bx\b'),            '*');   // "6 x 20"

    // Símbolos alternativos
    t = t
        .replaceAll('×', '*')
        .replaceAll('÷', '/')
        .replaceAll(',', '.');

    t = t.trim();

    // ── Expresión final: número op número ────────────────────
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
        resultado = a / b;
        operacion = 'división';
        simbolo   = '÷';
        break;
      default: return null;
    }

    return RagRespuesta(
      texto: '${_fmt(a)} $simbolo ${_fmt(b)} = ${_fmt(resultado)}\n\n'
             '¡Muy bien! La $operacion de ${_fmt(a)} y ${_fmt(b)} es ${_fmt(resultado)}.',
      encontrado: true,
      tema: operacion,
    );
  }

  // ─── Helpers del evaluador ────────────────────────────────

  static RagRespuesta _respEspecial(
      String enunciado, double resultado, String tema, String calculo) {
    return RagRespuesta(
      texto: '$enunciado = ${_fmt(resultado)}\n($calculo)',
      encontrado: true,
      tema: tema,
    );
  }

  static double _parseNum(String s) =>
      double.parse(s.replaceAll(',', '.'));

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
    // Extrae operadores símbolo como tokens especiales ANTES del filtro stopwords
    final mathTokens = <String>[];
    var t = texto.toLowerCase();

    t = t.replaceAllMapped(RegExp(r'[+]'),  (_) { mathTokens.add('suma');  return ' '; });
    t = t.replaceAllMapped(RegExp(r'[×*]'), (_) { mathTokens.add('multi'); return ' '; });
    t = t.replaceAllMapped(RegExp(r'[÷]'),  (_) { mathTokens.add('divid'); return ' '; });

    t = _normalizar(t).replaceAll(RegExp(r'[^a-z0-9\s]'), ' ');

    final regular = t.split(RegExp(r'\s+')).where((w) {
      if (w.isEmpty) return false;
      if (RegExp(r'^\d+$').hasMatch(w)) return true; // números siempre pasan
      return w.length >= 3 && !_stopwords.contains(w);
    }).toList();

    return [...regular, ...mathTokens];
  }

  // ─── Stemmer español ─────────────────────────────────────

  String _stem(String word) {
    final w = _normalizar(word);
    for (final sufijo in _sufijos) {
      if (w.endsWith(sufijo) && w.length - sufijo.length >= 3) {
        return w.substring(0, w.length - sufijo.length);
      }
    }
    return w;
  }

  // ─── Normalización (instancia) ────────────────────────────

  String _normalizar(String t) => _quitarAcentos(t).trim();

  // ─── Quitar acentos (estático, usado en evaluador también) ─

  static String _quitarAcentos(String t) => t
      .toLowerCase()
      .replaceAll(RegExp(r'[áàâä]'), 'a')
      .replaceAll(RegExp(r'[éèêë]'), 'e')
      .replaceAll(RegExp(r'[íìîï]'), 'i')
      .replaceAll(RegExp(r'[óòôö]'), 'o')
      .replaceAll(RegExp(r'[úùûü]'), 'u')
      .replaceAll('ñ', 'n');

  // ─── Nombre legible de materia ────────────────────────────

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
