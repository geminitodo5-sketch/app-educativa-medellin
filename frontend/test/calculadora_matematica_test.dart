import 'package:flutter_code/data/services/calculadora_matematica.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  ResultadoCalculo? r(String pregunta) => resolverExpresionMatematica(pregunta);

  group('el caso real reportado: no debe inventar la cuenta', () {
    test('raíz cuadrada de 48 (con artículo "la") se reconoce y no inventa',
        () {
      final resultado = r('Cuánto es la raíz cuadrada de 48');
      expect(resultado, isNotNull,
          reason: 'antes del fix caía en el LLM del servidor, que inventó '
              '"la raíz cuadrada de 48 es 6 porque 6×6=48"');
      // 6×6=36, no 48: la respuesta NUNCA debe afirmar eso.
      expect(resultado!.texto, isNot(contains('6×6=48')));
      expect(resultado.texto, isNot(contains('6 × 6 = 48')));
      // 48 no es un cuadrado perfecto: no debe decir "es 6" ni "es 7" como si
      // fuera exacto.
      expect(resultado.texto, isNot(matches(RegExp(r'es [67],'))));
      expect(resultado.texto, contains('no es un cuadrado perfecto'));
      expect(resultado.texto, contains('6.93'));
    });

    test('sin artículo también se reconoce (ya funcionaba antes)', () {
      final resultado = r('cuánto es raíz cuadrada de 48');
      expect(resultado, isNotNull);
      expect(resultado!.texto, contains('no es un cuadrado perfecto'));
    });
  });

  group('raíz cuadrada', () {
    test('cuadrado perfecto: afirma la raíz exacta y la cuenta correcta', () {
      final resultado = r('¿cuál es la raíz cuadrada de 49?')!;
      expect(resultado.texto, contains('7'));
      expect(resultado.texto, contains('7 × 7 = 49'));
      expect(resultado.texto, isNot(contains('no es un cuadrado perfecto')));
    });

    test('49 nunca puede confundirse con no-exacta', () {
      final resultado = r('raíz de 49')!;
      expect(resultado.texto, contains('= 7'));
    });

    test('0 y 1 (casos borde) no rompen nada', () {
      expect(r('raíz cuadrada de 0')!.texto, contains('0'));
      expect(r('raíz cuadrada de 1')!.texto, contains('1'));
    });

    test('con el símbolo √ pegado al número', () {
      final resultado = r('√81')!;
      expect(resultado.texto, contains('9'));
    });

    test('no perfecto ubica entre los dos cuadrados perfectos vecinos', () {
      final resultado = r('raíz cuadrada de 10')!;
      expect(resultado.texto, contains('3 × 3 = 9'));
      expect(resultado.texto, contains('4 × 4 = 16'));
    });
  });

  group('raíz cúbica', () {
    test('cubo perfecto', () {
      final resultado = r('raíz cúbica de 27')!;
      expect(resultado.texto, contains('3'));
      expect(resultado.texto, contains('3 × 3 × 3 = 27'));
    });

    test('no perfecto no inventa un entero exacto', () {
      final resultado = r('raíz cúbica de 30')!;
      expect(resultado.texto, contains('no es un cubo perfecto'));
      expect(resultado.texto, isNot(contains('= 3\n')));
    });
  });

  group('potencias', () {
    test('al cuadrado (forma pospuesta)', () {
      expect(r('5 al cuadrado')!.texto, contains('5² = 25'));
    });

    test('cuadrado de (forma antepuesta, con y sin artículo)', () {
      expect(r('cuadrado de 5')!.texto, contains('25'));
      expect(r('el cuadrado de 5')!.texto, contains('25'));
    });

    test('al cubo y cubo de', () {
      expect(r('3 al cubo')!.texto, contains('3³ = 27'));
      expect(r('cubo de 3')!.texto, contains('27'));
    });

    test('notación con caret', () {
      expect(r('4^2')!.texto, contains('16'));
    });
  });

  group('doble, mitad y triple', () {
    test('con y sin artículo dan el mismo resultado', () {
      expect(r('doble de 8')!.texto, contains('= 16'));
      expect(r('el doble de 8')!.texto, contains('= 16'));
      expect(r('mitad de 8')!.texto, contains('= 4'));
      expect(r('la mitad de 8')!.texto, contains('= 4'));
      expect(r('triple de 8')!.texto, contains('= 24'));
      expect(r('el triple de 8')!.texto, contains('= 24'));
    });
  });

  group('operaciones básicas', () {
    test('suma, resta, multiplicación, división', () {
      expect(r('cuánto es 5 + 3')!.texto, contains('= 8'));
      expect(r('cuánto es 10 - 4')!.texto, contains('= 6'));
      expect(r('7 por 6')!.texto, contains('= 42'));
      expect(r('20 dividido entre 4')!.texto, contains('= 5'));
    });

    test('división entre cero da un mensaje, no un crash', () {
      final resultado = r('10 dividido entre 0')!;
      expect(resultado.texto.toLowerCase(), contains('no se puede dividir'));
    });

    test('frases con "cuánto es", "cuál es el resultado de", etc.', () {
      expect(r('¿Cuánto es 5 más 3?')!.texto, contains('= 8'));
      expect(r('¿Cuál es el resultado de 9 menos 2?')!.texto, contains('= 7'));
      expect(r('calcula 6 por 7')!.texto, contains('= 42'));
    });
  });

  group('fracciones', () {
    test('suma de fracciones con pasos', () {
      final resultado = r('1/4 + 1/4')!; // 1/4 + 1/4 = 2/4 = 1/2
      expect(resultado.texto, contains('Resultado: 2/4'));
      expect(resultado.texto, contains('1/2 (simplificado)'));
    });

    test('multiplicación de fracciones', () {
      final resultado = r('1/2 por 2/3')!;
      expect(resultado.texto, contains('Resultado: 2/6'));
    });

    test('división entre cero en fracción no revienta', () {
      final resultado = r('1/2 dividido entre 0/3')!;
      expect(resultado.texto.toLowerCase(), contains('no se puede dividir'));
    });
  });

  group('preguntas que NO son matemáticas resolubles', () {
    test('devuelve null y no revienta con texto libre', () {
      expect(r('¿Qué es la fotosíntesis?'), isNull);
      expect(r('hola'), isNull);
      expect(r(''), isNull);
    });
  });
}
