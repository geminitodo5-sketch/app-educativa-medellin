// add_entries_2.js — Agrega entradas específicas: cielo azul, fracciones paso a paso
'use strict';
const fs = require('fs');
const path = require('path');
const KB = path.join(__dirname, 'knowledge_base');

function load(m) {
  return JSON.parse(fs.readFileSync(path.join(KB, m + '.json'), 'utf8'));
}
function save(m, data) {
  fs.writeFileSync(path.join(KB, m + '.json'), JSON.stringify(data, null, 2), 'utf8');
}

// ─── Ciencias: ¿Por qué el cielo es azul? ───────────────────────────────────
const ciencias = load('ciencias');
const nuevasCiencias = [
  {
    id: 'cie_g3_054',
    grado: 3,
    tema: 'por qué el cielo es azul',
    pregunta: '¿Por qué el cielo es azul?',
    respuesta: 'La luz del sol parece blanca, pero en realidad tiene todos los colores del arcoíris juntos: rojo, anaranjado, amarillo, verde, azul y violeta. Cuando esa luz viaja por el aire choca con partículas muy pequeñitas del aire. El color azul "rebota" (se dispersa) mucho más que los otros colores. Por eso cuando miramos el cielo vemos azul. Es como si el aire fuera un filtro gigante que deja pasar los otros colores pero "esparca" el azul en todas direcciones.',
    palabras_clave: ['cielo azul', 'luz solar', 'colores', 'dispersión', 'aire', 'arcoíris', 'partículas', 'luz blanca', 'óptica']
  },
  {
    id: 'cie_g4_053',
    grado: 4,
    tema: 'dispersión de la luz y el cielo azul',
    pregunta: '¿Por qué el cielo es azul? ¿Tiene que ver con la luz?',
    respuesta: 'Sí, tiene todo que ver con la luz. La luz solar es blanca porque contiene todos los colores del espectro (como un arcoíris). Cuando choca con las moléculas de nitrógeno y oxígeno del aire, ocurre algo llamado dispersión: los colores con ondas cortas (azul y violeta) se dispersan mucho más que los colores con ondas largas (rojo y amarillo). Nuestros ojos son más sensibles al azul que al violeta, por eso el cielo nos parece azul. Al amanecer y atardecer, la luz viaja más distancia por el aire, el azul se dispersa antes de llegar a ti y quedan los rojos y naranjas.',
    palabras_clave: ['cielo azul', 'dispersión de la luz', 'espectro', 'ondas', 'azul', 'violeta', 'rojo', 'atardecer', 'moléculas', 'óptica', 'luz solar']
  },
  {
    id: 'cie_g5_053',
    grado: 5,
    tema: 'dispersión de Rayleigh y color del cielo',
    pregunta: '¿Por qué el cielo es azul? ¿Qué es la dispersión de Rayleigh?',
    respuesta: 'El cielo es azul por un fenómeno llamado dispersión de Rayleigh, descubierto por el físico Lord Rayleigh en 1871. La luz solar blanca contiene todos los colores del espectro electromagnético. Cuando las ondas de luz chocan con moléculas del aire (N₂ y O₂), la intensidad de dispersión es inversamente proporcional a la cuarta potencia de la longitud de onda (I ∝ 1/λ⁴). Esto significa que el azul (λ ≈ 450 nm) se dispersa unas 5.5 veces más que el rojo (λ ≈ 700 nm). Durante el atardecer, la luz recorre más atmósfera; el azul se dispersa antes de llegar y predominan los rojos y naranjas.',
    palabras_clave: ['dispersión de Rayleigh', 'cielo azul', 'longitud de onda', 'espectro electromagnético', 'luz solar', 'moléculas', 'óptica', 'física', 'atardecer', 'azul']
  },
  {
    id: 'cie_g4_054',
    grado: 4,
    tema: 'colores del atardecer',
    pregunta: '¿Por qué el cielo se pone rojo y naranja al atardecer?',
    respuesta: 'Al amanecer y al atardecer, el sol está muy bajo en el horizonte y su luz debe atravesar una capa mucho más gruesa de atmósfera para llegar a tus ojos. Durante ese trayecto largo, la luz azul se dispersa completamente hacia los lados antes de llegar a ti. Solo los colores de onda larga (rojo, naranja, amarillo) llegan directamente a tus ojos. Por eso el cielo se ve de esos colores cálidos al atardecer. Es el mismo fenómeno del cielo azul, ¡pero al revés!',
    palabras_clave: ['atardecer', 'amanecer', 'rojo', 'naranja', 'dispersión', 'luz', 'atmósfera', 'horizonte', 'cielo', 'colores']
  },
  {
    id: 'cie_g3_055',
    grado: 3,
    tema: 'colores de la luz y arcoíris',
    pregunta: '¿Por qué el arcoíris tiene esos colores?',
    respuesta: 'El arcoíris aparece cuando hay gotitas de agua en el aire (como después de la lluvia) y el sol brilla. Cada gotita actúa como un pequeño prisma: separa la luz blanca del sol en todos sus colores. La luz entra a la gotita, rebota adentro y sale dividida en rojo, naranja, amarillo, verde, azul, índigo y violeta. Cada color sale en un ángulo diferente. Por eso vemos el arcoíris con colores bien separados. El rojo siempre va por fuera y el violeta por dentro.',
    palabras_clave: ['arcoíris', 'colores', 'luz blanca', 'prisma', 'gotas de agua', 'lluvia', 'sol', 'refracción', 'espectro', 'rojo verde azul']
  },
  {
    id: 'cie_g5_054',
    grado: 5,
    tema: 'espectro electromagnético',
    pregunta: '¿Qué es el espectro electromagnético?',
    respuesta: 'El espectro electromagnético es el conjunto de todas las ondas electromagnéticas ordenadas por su longitud de onda o frecuencia. De mayor a menor longitud de onda: ondas de radio (1m a 100km), microondas (1mm a 1m), infrarrojo (700nm a 1mm), luz visible (400-700nm), ultravioleta (10-400nm), rayos X (0.01-10nm) y rayos gamma (<0.01nm). La luz visible, que percibimos como colores, es solo una pequeña franja: el violeta tiene la longitud de onda más corta (~400nm) y el rojo la más larga (~700nm). La energía aumenta al disminuir la longitud de onda (E = hf = hc/λ).',
    palabras_clave: ['espectro electromagnético', 'ondas', 'longitud de onda', 'frecuencia', 'luz visible', 'ultravioleta', 'infrarrojo', 'rayos X', 'radio', 'microondas']
  }
];

ciencias.contenido.push(...nuevasCiencias);
save('ciencias', ciencias);
console.log('ciencias.json: +' + nuevasCiencias.length + ' entradas. Total:', ciencias.contenido.length);

// ─── Matemáticas: fracciones paso a paso (conceptual) ───────────────────────
const mat = load('matematicas');
const nuevasMat = [
  {
    id: 'mat_g3_083',
    grado: 3,
    tema: 'suma de fracciones igual denominador',
    pregunta: '¿Cómo sumo fracciones que tienen el mismo denominador?',
    respuesta: 'Para sumar fracciones con el mismo denominador es muy fácil: solo sumas los numeradores y el denominador queda igual. Ejemplo: 1/4 + 2/4. Paso 1: Los denominadores son iguales (ambos son 4). Paso 2: Suma los numeradores: 1 + 2 = 3. Paso 3: Pon el mismo denominador: resultado = 3/4. Es como partir una pizza en 4 trozos iguales y comer 1 trozo luego 2 trozos más: ¡comiste 3 trozos de 4!',
    palabras_clave: ['suma de fracciones', 'mismo denominador', 'numerador', 'fracciones', 'sumar', 'paso a paso', 'pizza', 'igual denominador']
  },
  {
    id: 'mat_g3_084',
    grado: 3,
    tema: 'numerador y denominador',
    pregunta: '¿Qué es el numerador y el denominador de una fracción?',
    respuesta: 'Una fracción tiene dos partes separadas por una línea: El DENOMINADOR (número de abajo) dice en cuántas partes iguales está dividido el todo. El NUMERADOR (número de arriba) dice cuántas partes tomamos. Ejemplo: En la fracción 3/8, el denominador 8 significa que algo está dividido en 8 partes iguales, y el numerador 3 significa que tomamos 3 de esas partes. Truco para recordar: el DENOMINADOR DENOMINA (nombra) el tipo de partes; el NUMERADOR NUMERA (cuenta) cuántas.',
    palabras_clave: ['numerador', 'denominador', 'fracción', 'partes iguales', 'fracción propia', 'significado', 'definición']
  },
  {
    id: 'mat_g4_077',
    grado: 4,
    tema: 'suma de fracciones diferente denominador',
    pregunta: '¿Cómo sumo fracciones con diferente denominador?',
    respuesta: 'Para sumar fracciones con diferente denominador necesitas encontrar el MCM (mínimo común múltiplo). Ejemplo: 1/2 + 1/3. Paso 1: Halla el MCM de 2 y 3. Múltiplos de 2: 2,4,6... Múltiplos de 3: 3,6... MCM = 6. Paso 2: Convierte cada fracción: 1/2 = 3/6 (multiplica arriba y abajo por 3); 1/3 = 2/6 (multiplica arriba y abajo por 2). Paso 3: Suma los numeradores: 3/6 + 2/6 = 5/6. Resultado: 1/2 + 1/3 = 5/6.',
    palabras_clave: ['suma fracciones', 'diferente denominador', 'MCM', 'mínimo común múltiplo', 'denominador común', 'paso a paso', 'convertir fracción']
  },
  {
    id: 'mat_g4_078',
    grado: 4,
    tema: 'resta de fracciones',
    pregunta: '¿Cómo resto fracciones paso a paso?',
    respuesta: 'Restar fracciones es igual que sumarlas pero con resta. Ejemplo: 3/4 - 1/3. Paso 1: Halla el MCM de 4 y 3. MCM = 12. Paso 2: Convierte: 3/4 = 9/12 (×3); 1/3 = 4/12 (×4). Paso 3: Resta los numeradores: 9/12 - 4/12 = 5/12. Resultado: 3/4 - 1/3 = 5/12. Si el denominador es igual, solo resta los numeradores y deja el denominador: 5/7 - 2/7 = 3/7.',
    palabras_clave: ['resta fracciones', 'restar', 'MCM', 'denominador común', 'paso a paso', 'fracciones', 'diferente denominador']
  },
  {
    id: 'mat_g5_081',
    grado: 5,
    tema: 'multiplicación de fracciones paso a paso',
    pregunta: '¿Cómo multiplico fracciones paso a paso?',
    respuesta: 'Multiplicar fracciones es la operación más sencilla. Ejemplo: 2/3 × 3/5. Paso 1: Multiplica los numeradores entre sí: 2 × 3 = 6. Paso 2: Multiplica los denominadores entre sí: 3 × 5 = 15. Resultado: 6/15. Paso 3: Simplifica dividiendo por el MCD. MCD(6,15) = 3. Resultado simplificado: 2/5. Atajo: Antes de multiplicar puedes simplificar en diagonal (simplificación cruzada): 2/3 × 3/5 → el 3 de arriba y el 3 de abajo se cancelan → 2/1 × 1/5 = 2/5.',
    palabras_clave: ['multiplicación fracciones', 'multiplicar', 'numerador', 'denominador', 'simplificar', 'MCD', 'simplificación cruzada', 'paso a paso']
  },
  {
    id: 'mat_g5_082',
    grado: 5,
    tema: 'división de fracciones paso a paso',
    pregunta: '¿Cómo divido fracciones? ¿Qué es invertir y multiplicar?',
    respuesta: 'Dividir fracciones usa la regla "invierte y multiplica". Ejemplo: 3/4 ÷ 2/5. Paso 1: Invierte la segunda fracción (el divisor): 2/5 se convierte en 5/2. Paso 2: Cambia la división por multiplicación: 3/4 × 5/2. Paso 3: Multiplica: numeradores 3×5=15; denominadores 4×2=8. Resultado: 15/8. Paso 4 (opcional): Convierte a número mixto: 15÷8 = 1 y 7/8. La regla funciona porque dividir por una fracción es lo mismo que multiplicar por su inverso (recíproco).',
    palabras_clave: ['división fracciones', 'dividir', 'invertir', 'multiplicar', 'recíproco', 'inverso multiplicativo', 'número mixto', 'paso a paso']
  },
  {
    id: 'mat_g5_083',
    grado: 5,
    tema: 'mínimo común múltiplo MCM',
    pregunta: '¿Qué es el mínimo común múltiplo (MCM) y cómo se calcula?',
    respuesta: 'El MCM de dos números es el número más pequeño que es múltiplo de ambos. Se usa mucho para sumar y restar fracciones. Método 1 - Lista de múltiplos: MCM(4,6): múltiplos de 4: 4,8,12,16... múltiplos de 6: 6,12,18... El primero en común es 12. MCM = 12. Método 2 - Descomposición en factores primos: 4 = 2² y 6 = 2×3. Toma cada factor con el mayor exponente: 2² × 3 = 12. MCM = 12. El MCD (máximo común divisor) es diferente: es el mayor divisor común. Para 12 y 8: MCD = 4.',
    palabras_clave: ['MCM', 'mínimo común múltiplo', 'múltiplos', 'factores primos', 'MCD', 'máximo común divisor', 'fracciones', 'denominador común']
  }
];

mat.contenido.push(...nuevasMat);
save('matematicas', mat);
console.log('matematicas.json: +' + nuevasMat.length + ' entradas. Total:', mat.contenido.length);

// ─── Verificación final ──────────────────────────────────────────────────────
console.log('\n=== Resumen final ===');
for (const m of ['matematicas', 'ciencias', 'espanol', 'ingles', 'sociales']) {
  const d = load(m);
  const byGrade = {};
  for (const e of d.contenido) byGrade[e.grado] = (byGrade[e.grado]||0)+1;
  console.log(m + ': total=' + d.contenido.length + ' ' + JSON.stringify(byGrade));
}
