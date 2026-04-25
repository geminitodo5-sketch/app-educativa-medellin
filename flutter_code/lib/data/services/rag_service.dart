// ─────────────────────────────────────────────────────────────
//  lib/data/services/rag_service.dart
//  Motor RAG 100% offline: recupera la respuesta más relevante
//  de base_conocimiento usando coincidencia de palabras clave.
// ─────────────────────────────────────────────────────────────

import 'sqlite_service.dart';

class RagService {
  final SqliteService _db;

  RagService(this._db);

  // ── Stopwords en español (palabras que no aportan al índice) ──
  static const _stopwords = {
    'el','la','los','las','un','una','unos','unas','de','del','al','a','en',
    'y','o','pero','que','como','es','son','ser','fue','era','si','no','se',
    'me','te','le','nos','con','por','para','su','sus','mi','mis','tu','tus',
    'este','esta','estos','estas','ese','esa','esos','esas','lo','hay','mas',
    'muy','bien','ya','tambien','porque','cuando','donde','quien','que','como',
    'cual','cuales','cuando','donde','quien','cuanto','cuantos',
    'sobre','entre','hasta','desde','hacia','durante','sin','ante','bajo',
  };

  // ── API pública ───────────────────────────────────────────────

  /// Busca la mejor respuesta offline para [pregunta] dentro de
  /// [materia] y [grado]. Devuelve texto formateado listo para
  /// mostrar al estudiante.
  Future<RagRespuesta> responder({
    required String pregunta,
    required String materia,
    required int grado,
  }) async {
    final tokens = _tokenizar(pregunta);

    if (tokens.isEmpty) {
      return RagRespuesta(
        texto: 'Por favor escribe una pregunta sobre $materia.',
        encontrado: false,
        tema: '',
      );
    }

    // Carga entradas de la BD para esta materia y grado
    final entradas = await _db.consultar(
      'base_conocimiento',
      where: 'materia = ? AND grado = ?',
      whereArgs: [materia, grado],
    );

    if (entradas.isEmpty) {
      return RagRespuesta(
        texto: 'Aún no has descargado el contenido de $materia. '
               'Ve a la sección de descarga para obtenerlo.',
        encontrado: false,
        tema: '',
      );
    }

    // Puntúa cada entrada
    final scored = entradas.map((e) {
      return _EntradaPuntuada(
        entrada: e,
        puntaje: _puntuar(e, tokens),
      );
    }).toList()
      ..sort((a, b) => b.puntaje.compareTo(a.puntaje));

    final mejor = scored.first;

    // Umbral mínimo: al menos 1 coincidencia
    if (mejor.puntaje < 0.05) {
      return RagRespuesta(
        texto: 'No encontré información exacta sobre eso en $materia '
               '(grado $grado). Intenta reformular tu pregunta usando '
               'palabras clave del tema.',
        encontrado: false,
        tema: '',
      );
    }

    final respuesta = mejor.entrada['respuesta'] as String;
    final tema      = mejor.entrada['tema'] as String;

    return RagRespuesta(
      texto: respuesta,
      encontrado: true,
      tema: tema,
    );
  }

  /// Devuelve las preguntas sugeridas para [materia] y [grado].
  Future<List<String>> preguntasSugeridas({
    required String materia,
    required int grado,
    int cantidad = 4,
  }) async {
    final entradas = await _db.consultar(
      'base_conocimiento',
      where: 'materia = ? AND grado = ?',
      whereArgs: [materia, grado],
      limit: cantidad,
    );
    return entradas.map((e) => e['pregunta'] as String).toList();
  }

  /// Guarda en historial_rag (solo grados 3-5).
  /// historial_rag usa 'español' con acento; mapeamos 'espanol' → 'español'.
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

  // ── Privado ───────────────────────────────────────────────────

  List<String> _tokenizar(String texto) {
    return texto
        .toLowerCase()
        .replaceAll(RegExp(r'[áàä]'), 'a')
        .replaceAll(RegExp(r'[éèë]'), 'e')
        .replaceAll(RegExp(r'[íìï]'), 'i')
        .replaceAll(RegExp(r'[óòö]'), 'o')
        .replaceAll(RegExp(r'[úùü]'), 'u')
        .replaceAll(RegExp(r'[ñ]'), 'n')
        .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
        .split(RegExp(r'\s+'))
        .where((w) => w.length > 2 && !_stopwords.contains(w))
        .toList();
  }

  double _puntuar(Map<String, dynamic> entrada, List<String> tokens) {
    if (tokens.isEmpty) return 0;

    final claves = (entrada['palabras_clave'] as String)
        .split(',')
        .map(_normalizarToken)
        .toSet();

    final preguntaTokens = _tokenizar(entrada['pregunta'] as String).toSet();
    final respuestaTokens = _tokenizar(entrada['respuesta'] as String).toSet();

    double score = 0;
    for (final t in tokens) {
      final norm = _normalizarToken(t);
      if (claves.contains(norm)) score += 1.0;
      if (preguntaTokens.contains(norm)) score += 0.8;
      if (respuestaTokens.contains(norm)) score += 0.3;
    }

    // Normaliza por longitud de la consulta
    return score / tokens.length;
  }

  String _normalizarToken(String t) {
    return t
        .toLowerCase()
        .replaceAll(RegExp(r'[áàä]'), 'a')
        .replaceAll(RegExp(r'[éèë]'), 'e')
        .replaceAll(RegExp(r'[íìï]'), 'i')
        .replaceAll(RegExp(r'[óòö]'), 'o')
        .replaceAll(RegExp(r'[úùü]'), 'u')
        .replaceAll(RegExp(r'[ñ]'), 'n')
        .trim();
  }
}

class _EntradaPuntuada {
  final Map<String, dynamic> entrada;
  final double puntaje;
  _EntradaPuntuada({required this.entrada, required this.puntaje});
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
