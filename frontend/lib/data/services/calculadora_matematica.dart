//  lib/data/services/calculadora_matematica.dart
//  Capa: Datos — Responsabilidad: Ingeniería
//
//  Resuelve con matemática exacta en Dart — nunca con un modelo de lenguaje —
//  las preguntas de aritmética que tienen una única respuesta verificable:
//  sumas, restas, multiplicaciones, divisiones, fracciones, dobles/mitades/
//  triples, potencias y raíces.
//
//  Por qué existe: un LLM (el Gemini del servidor o el Gemma del celular)
//  puede sonar seguro y decir una cuenta que no cuadra. Ejemplo real visto en
//  producción: "la raíz cuadrada de 48 es 6, porque 6×6=48" — 6×6 es 36, no
//  48, y además 48 no es un cuadrado perfecto. Toda expresión que esta
//  calculadora reconoce se resuelve aquí, así que ese tipo de invención deja
//  de ser posible para esas preguntas: nunca llegan a un LLM.
//
//  Archivo sin dependencias de Flutter (solo dart:math) para poder probarlo
//  con `dart test` sin necesitar el entorno gráfico de Flutter.
//  Pruebas: test/calculadora_matematica_test.dart.

import 'dart:math';

/// Resultado de una expresión matemática reconocida y resuelta con exactitud.
class ResultadoCalculo {
  final String texto;
  final String tema;
  const ResultadoCalculo({required this.texto, required this.tema});
}

/// Intenta resolver [pregunta] como una expresión aritmética en español.
/// Devuelve null si no la reconoce; el llamador sigue entonces con el
/// contenido descargado y, si hace falta, con la IA.
ResultadoCalculo? resolverExpresionMatematica(String pregunta) {
  var t = _quitarAcentos(pregunta.toLowerCase())
      .replaceAll(RegExp(r'[?¿!¡]'), '')
      .trim();

  t = t
      .replaceAll(RegExp(r'^cu[aá]nto[s]?\s+(es|son|da|vale|valen|hay)\s+'), '')
      .replaceAll(RegExp(r'^cu[aá]l\s+es\s+(el\s+)?(resultado\s+de\s+)?'), '')
      .replaceAll(RegExp(r'^(calcula|resuelve|halla|encuentra|dime)\s+'), '')
      .replaceAll(RegExp(r'^(el\s+)?(resultado\s+de|resultado)\s+'), '')
      .replaceAll(RegExp(r'^que\s+(es|vale|da)\s+'), '')
      .trim();

  final fraccion = _evaluarFraccion(t);
  if (fraccion != null) return fraccion;

  // Quita UN artículo inicial ("la"/"el") que antecede a la frase. Así "la
  // raíz cuadrada de 48" y "raíz cuadrada de 48" se reconocen igual — antes
  // solo se reconocía la segunda forma y la primera caía en la IA, que fue
  // justo el caso que inventó la cuenta equivocada de arriba.
  final s = t.replaceFirst(RegExp(r'^(el|la)\s+'), '');

  var m = RegExp(r'^doble\s+de\s+(\d+(?:[.,]\d+)?)$').firstMatch(s);
  if (m != null) {
    final n = _parseNum(m.group(1)!);
    return _especial('El doble de ${_fmt(n)}', n * 2, 'multiplicación',
        '${_fmt(n)} × 2 = ${_fmt(n * 2)}');
  }

  m = RegExp(r'^mitad\s+de\s+(\d+(?:[.,]\d+)?)$').firstMatch(s);
  if (m != null) {
    final n = _parseNum(m.group(1)!);
    return _especial('La mitad de ${_fmt(n)}', n / 2, 'división',
        '${_fmt(n)} ÷ 2 = ${_fmt(n / 2)}');
  }

  m = RegExp(r'^triple\s+de\s+(\d+(?:[.,]\d+)?)$').firstMatch(s);
  if (m != null) {
    final n = _parseNum(m.group(1)!);
    return _especial('El triple de ${_fmt(n)}', n * 3, 'multiplicación',
        '${_fmt(n)} × 3 = ${_fmt(n * 3)}');
  }

  // Potencia: forma pospuesta ("5 al cuadrado") o antepuesta ("cuadrado de 5").
  m = RegExp(r'^(\d+(?:[.,]\d+)?)\s*(al\s+cuadrado|\^2|elevado\s+a\s+(la\s+)?2)$')
          .firstMatch(s) ??
      RegExp(r'^cuadrado\s+de\s+(\d+(?:[.,]\d+)?)$').firstMatch(s);
  if (m != null) {
    final n = _parseNum(m.group(1)!);
    final r = n * n;
    return ResultadoCalculo(
      texto: '${_fmt(n)}² = ${_fmt(r)}\n(${_fmt(n)} × ${_fmt(n)} = ${_fmt(r)})',
      tema: 'potencias',
    );
  }

  m = RegExp(r'^(\d+(?:[.,]\d+)?)\s*(al\s+cubo|\^3|elevado\s+a\s+(la\s+)?3)$')
          .firstMatch(s) ??
      RegExp(r'^cubo\s+de\s+(\d+(?:[.,]\d+)?)$').firstMatch(s);
  if (m != null) {
    final n = _parseNum(m.group(1)!);
    final r = n * n * n;
    return ResultadoCalculo(
      texto: '${_fmt(n)}³ = ${_fmt(r)}\n'
             '(${_fmt(n)} × ${_fmt(n)} × ${_fmt(n)} = ${_fmt(r)})',
      tema: 'potencias',
    );
  }

  m = RegExp(r'^(?:ra[ií]z\s+(?:cuadrada\s+)?de\s+|√\s*)(\d+(?:[.,]\d+)?)$')
      .firstMatch(s);
  if (m != null) return _raizCuadrada(_parseNum(m.group(1)!));

  m = RegExp(r'^ra[ií]z\s+c[uú]bica\s+de\s+(\d+(?:[.,]\d+)?)$').firstMatch(s);
  if (m != null) return _raizCubica(_parseNum(m.group(1)!));

  // Normalización de operadores (frases multi-palabra primero)
  t = t
      .replaceAll(RegExp(r'multiplicado\s+por'), '*')
      .replaceAll(RegExp(r'multiplicado\s+x'), '*')
      .replaceAll(RegExp(r'multiplicado\s+'), '*')
      .replaceAll(RegExp(r'dividido\s+entre'), '/')
      .replaceAll(RegExp(r'dividido\s+por'), '/')
      .replaceAll(RegExp(r'dividido\s+'), '/')
      .replaceAll(RegExp(r'sumado\s+[a-z]*\s*'), '+');

  t = t
      .replaceAll(RegExp(r'\bmas\b'), '+')
      .replaceAll(RegExp(r'\bmenos\b'), '-')
      .replaceAll(RegExp(r'\bpor\b|\bveces\b'), '*')
      .replaceAll(RegExp(r'\bentre\b'), '/')
      .replaceAll(RegExp(r'\bx\b'), '*');

  t = t
      .replaceAll('×', '*')
      .replaceAll('÷', '/')
      .replaceAll(',', '.')
      .trim();

  final match = RegExp(r'^(\d+(?:\.\d+)?)\s*([+\-*/])\s*(\d+(?:\.\d+)?)$')
      .firstMatch(t);
  if (match == null) return null;

  final a = double.parse(match.group(1)!);
  final op = match.group(2)!;
  final b = double.parse(match.group(3)!);

  double resultado;
  String operacion;
  String simbolo;

  switch (op) {
    case '+':
      resultado = a + b;
      operacion = 'suma';
      simbolo = '+';
      break;
    case '-':
      resultado = a - b;
      operacion = 'resta';
      simbolo = '-';
      break;
    case '*':
      resultado = a * b;
      operacion = 'multiplicación';
      simbolo = '×';
      break;
    case '/':
      if (b == 0) {
        return const ResultadoCalculo(
          texto: '¡No se puede dividir entre cero!\n'
                 'El cero nunca puede ser divisor.',
          tema: 'división',
        );
      }
      resultado = a / b;
      operacion = 'división';
      simbolo = '÷';
      break;
    default:
      return null;
  }

  return ResultadoCalculo(
    texto: '${_fmt(a)} $simbolo ${_fmt(b)} = ${_fmt(resultado)}\n\n'
           '¡Muy bien! La $operacion de ${_fmt(a)} y ${_fmt(b)} es ${_fmt(resultado)}.',
    tema: operacion,
  );
}

// ── Raíces ────────────────────────────────────────────────────────────────
//
// Nunca se afirma una raíz exacta que no lo es: si el número no es un
// cuadrado (o cubo) perfecto, la respuesta lo dice explícitamente y da una
// aproximación, en vez de forzar un entero cercano como si fuera exacto.

ResultadoCalculo _raizCuadrada(double n) {
  final raizAprox = sqrt(n);
  final raizEntera = raizAprox.round();
  final esCuadradoPerfecto =
      n == n.roundToDouble() && raizEntera * raizEntera == n.round();

  if (esCuadradoPerfecto) {
    return ResultadoCalculo(
      texto: '√${_fmt(n)} = $raizEntera\n'
             'La raíz cuadrada de ${_fmt(n)} es $raizEntera, '
             'porque $raizEntera × $raizEntera = ${_fmt(n)}.',
      tema: 'raíz cuadrada',
    );
  }

  final piso = raizAprox.floor();
  final techo = piso + 1;
  final aprox = double.parse(raizAprox.toStringAsFixed(2));
  return ResultadoCalculo(
    texto: '√${_fmt(n)} ≈ ${_fmt(aprox)}\n'
           '${_fmt(n)} no es un cuadrado perfecto, así que su raíz no es un '
           'número exacto.\n'
           'Está entre $piso (porque $piso × $piso = ${piso * piso}) y '
           '$techo (porque $techo × $techo = ${techo * techo}).',
    tema: 'raíz cuadrada',
  );
}

ResultadoCalculo _raizCubica(double n) {
  final raizAprox = pow(n, 1 / 3).toDouble();
  final raizEntera = raizAprox.round();
  final esCuboPerfecto =
      n == n.roundToDouble() && raizEntera * raizEntera * raizEntera == n.round();

  if (esCuboPerfecto) {
    return ResultadoCalculo(
      texto: '∛${_fmt(n)} = $raizEntera\n'
             'La raíz cúbica de ${_fmt(n)} es $raizEntera, '
             'porque $raizEntera × $raizEntera × $raizEntera = ${_fmt(n)}.',
      tema: 'raíz cúbica',
    );
  }

  final aprox = double.parse(raizAprox.toStringAsFixed(2));
  return ResultadoCalculo(
    texto: '∛${_fmt(n)} ≈ ${_fmt(aprox)}\n'
           '${_fmt(n)} no es un cubo perfecto, así que su raíz no es un '
           'número exacto.',
    tema: 'raíz cúbica',
  );
}

// ── Fracciones ────────────────────────────────────────────────────────────
//
// Detecta el patrón "a/b [op] c/d" antes de que los operadores en palabra
// sean reemplazados por símbolos.
ResultadoCalculo? _evaluarFraccion(String t) {
  final tn = t
      .replaceAll(RegExp(r'multiplicado\s+(?:por|x)?\s*'), '×')
      .replaceAll(RegExp(r'dividido\s+(?:entre|por)?\s*'), '÷')
      .replaceAll(RegExp(r'\bpor\b|\bveces\b'), '×')
      .replaceAll(RegExp(r'\bentre\b'), '÷')
      .replaceAll(RegExp(r'\bmas\b'), '+')
      .replaceAll(RegExp(r'\bmenos\b'), '-')
      .trim();

  final m = RegExp(r'^(\d+)\s*/\s*(\d+)\s*([+\-×÷*])\s*(\d+)\s*/\s*(\d+)$')
      .firstMatch(tn);
  if (m == null) return null;

  final a = int.parse(m.group(1)!);
  final b = int.parse(m.group(2)!);
  final op = m.group(3)!;
  final c = int.parse(m.group(4)!);
  final d = int.parse(m.group(5)!);

  if (b == 0 || d == 0) {
    return const ResultadoCalculo(
      texto: '¡El denominador de una fracción no puede ser cero!',
      tema: 'fracciones',
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
  } else {
    // ÷
    if (c == 0) {
      return const ResultadoCalculo(
        texto: '¡No se puede dividir entre cero!',
        tema: 'fracciones',
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

  return ResultadoCalculo(texto: pasos, tema: 'fracciones');
}

// ── Utilidades ────────────────────────────────────────────────────────────

int _gcd(int a, int b) => b == 0 ? a.abs() : _gcd(b, a % b);

ResultadoCalculo _especial(
    String enunciado, double resultado, String tema, String calculo) {
  return ResultadoCalculo(
    texto: '$enunciado = ${_fmt(resultado)}\n($calculo)',
    tema: tema,
  );
}

double _parseNum(String s) => double.parse(s.replaceAll(',', '.'));

String _fmt(double n) {
  if (n == n.truncateToDouble()) return n.toInt().toString();
  final s = n.toStringAsFixed(4);
  return s.replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
}

String _quitarAcentos(String t) => t
    .toLowerCase()
    .replaceAll(RegExp(r'[áàâä]'), 'a')
    .replaceAll(RegExp(r'[éèêë]'), 'e')
    .replaceAll(RegExp(r'[íìîï]'), 'i')
    .replaceAll(RegExp(r'[óòôö]'), 'o')
    .replaceAll(RegExp(r'[úùûü]'), 'u')
    .replaceAll('ñ', 'n');
