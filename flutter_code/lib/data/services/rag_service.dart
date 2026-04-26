// ─────────────────────────────────────────────────────────────
//  lib/data/services/rag_service.dart
//  Motor RAG offline con stemming español, búsqueda multi-grado
//  y conversión de operadores matemáticos a palabras.
// ─────────────────────────────────────────────────────────────

import 'sqlite_service.dart';

class RagService {
  final SqliteService _db;
  RagService(this._db);

  // ─── Stopwords normalizadas (sin tildes) ──────────────────
  static const _stopwords = {
    'el','la','los','las','un','una','unos','unas','de','del','al','a','en',
    'y','o','pero','que','es','son','ser','fue','era','si','no','se',
    'me','te','le','nos','con','para','su','sus','mi','mis','tu','tus',
    'este','esta','estos','estas','ese','esa','esos','esas','lo','hay','mas',
    'muy','bien','ya','tambien','porque','cuando','donde','quien',
    'cual','cuales','cuanto','cuantos','sobre','entre','hasta','desde',
    'hacia','durante','sin','ante','bajo','puedo','puede','puedes',
    'quiero','quisiera','dime','como','favor','porfavor',
    'forma','manera','modo','simple','facil','ayuda',
    'quiere','hacer','hago','haces',
  };

  // ─── Sufijos para stemming español ───────────────────────
  // Se prueban de mayor a menor longitud; raíz mínima = 3 chars.
  static const _sufijos = [
    'aciones','amiento','amiento','imientos','imientos',
    'acion','iones','iendo','mente','ando',
    'ados','idas','idos','adas',
    'ado','ida','ido','ada',
    'ares','eres','ires',
    'amos','emos','imos',
    'cion','ncia','nces',
    'ar','er','ir',
    'es','as',
  ];

  // ─── API pública ──────────────────────────────────────────

  Future<RagRespuesta> responder({
    required String pregunta,
    required String materia,
    required int grado,
  }) async {
    final tokens = _tokenizar(pregunta);

    if (tokens.isEmpty) {
      return RagRespuesta(
        texto: 'Escribe una pregunta sobre $materia y te ayudo.',
        encontrado: false, tema: '',
      );
    }

    // 1. Busca en el grado exacto
    var entradas = await _db.consultar(
      'base_conocimiento',
      where: 'materia = ? AND grado = ?',
      whereArgs: [materia, grado],
    );

    if (entradas.isEmpty) {
      return RagRespuesta(
        texto: 'Aún no descargaste el contenido de $materia. '
               'Toca "Descargar" en el menú para continuar.',
        encontrado: false, tema: '',
      );
    }

    var scored = _puntuar(entradas, tokens);
    final mejorExacto = scored.first;

    // 2. Si el puntaje en el grado exacto es bajo, busca en otros grados
    if (mejorExacto.puntaje < 0.4) {
      final todasEntradas = await _db.consultar(
        'base_conocimiento',
        where: 'materia = ?',
        whereArgs: [materia],
      );
      final scoredTodas = _puntuar(todasEntradas, tokens);
      if (scoredTodas.first.puntaje > mejorExacto.puntaje) {
        scored = scoredTodas;
      }
    }

    final mejor = scored.first;

    if (mejor.puntaje < 0.1) {
      return RagRespuesta(
        texto: 'No encontré eso en $materia para grado $grado. '
               'Intenta preguntar con otras palabras, por ejemplo: '
               '"¿Qué es la multiplicación?" o "¿Cómo se divide?"',
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
      limit: cantidad * 2,
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
      'pregunta': pregunta,
      'respuesta': respuesta,
      'materia': mapaMateria[materia] ?? materia,
      'grado': grado,
      'fecha': DateTime.now().toIso8601String(),
    });
  }

  // ─── Scoring ──────────────────────────────────────────────

  List<_EP> _puntuar(List<Map<String, dynamic>> entradas, List<String> tokens) {
    final stems = tokens.map(_stem).toList();

    final lista = entradas.map((e) {
      double score = 0;

      final claves = (e['palabras_clave'] as String)
          .split(',')
          .map((w) => _stem(_normalizar(w.trim())))
          .toSet();

      final pregTokens = _tokenizar(e['pregunta'] as String)
          .map(_stem)
          .toSet();
      final respTokens = _tokenizar(e['respuesta'] as String)
          .map(_stem)
          .toSet();

      for (final stem in stems) {
        // Coincidencia exacta de stem en palabras clave → mayor peso
        if (claves.contains(stem)) {
          score += 2.0;
        } else {
          // Coincidencia parcial: el stem es prefijo de una clave o viceversa
          for (final c in claves) {
            if (c.startsWith(stem) || stem.startsWith(c)) {
              score += 0.8;
              break;
            }
          }
        }

        if (pregTokens.contains(stem)) score += 1.2;
        if (respTokens.contains(stem)) score += 0.4;
      }

      // Bonus si varios tokens coinciden (relevancia concentrada)
      final coincidencias = stems.where(claves.contains).length;
      if (coincidencias >= 2) score += coincidencias * 0.5;

      return _EP(entrada: e, puntaje: stems.isEmpty ? 0 : score / stems.length);
    }).toList()
      ..sort((a, b) => b.puntaje.compareTo(a.puntaje));

    return lista;
  }

  // ─── Tokenizador ──────────────────────────────────────────

  List<String> _tokenizar(String texto) {
    // Convierte operadores a palabras antes de tokenizar
    var t = texto
        .toLowerCase()
        .replaceAll('+', ' mas ')
        .replaceAll('×', ' por ')
        .replaceAll('*', ' por ')
        .replaceAll('÷', ' entre ')
        .replaceAll('/', ' entre ')
        .replaceAll('-', ' menos ');

    t = _normalizar(t)
        .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ');

    return t.split(RegExp(r'\s+')).where((w) {
      if (w.isEmpty) return false;
      // Siempre conserva números, aunque sean de 1 dígito
      if (RegExp(r'^\d+$').hasMatch(w)) return true;
      // Texto: mínimo 3 chars y no stopword
      return w.length >= 3 && !_stopwords.contains(w);
    }).toList();
  }

  // ─── Stemmer (sufijos en español normalizados) ────────────

  String _stem(String word) {
    final w = _normalizar(word);
    for (final sufijo in _sufijos) {
      if (w.endsWith(sufijo) && w.length - sufijo.length >= 3) {
        return w.substring(0, w.length - sufijo.length);
      }
    }
    return w;
  }

  // ─── Normalización de acentos ─────────────────────────────

  String _normalizar(String t) {
    return t
        .toLowerCase()
        .replaceAll(RegExp(r'[áàâä]'), 'a')
        .replaceAll(RegExp(r'[éèêë]'), 'e')
        .replaceAll(RegExp(r'[íìîï]'), 'i')
        .replaceAll(RegExp(r'[óòôö]'), 'o')
        .replaceAll(RegExp(r'[úùûü]'), 'u')
        .replaceAll('ñ', 'n')
        .trim();
  }
}

class _EP {
  final Map<String, dynamic> entrada;
  final double puntaje;
  _EP({required this.entrada, required this.puntaje});
}

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
