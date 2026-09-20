import 'dart:math';
import 'sqlite_service.dart';
import 'rag_service.dart';

class BancoPreguntasService {
  final SqliteService _db;
  BancoPreguntasService(this._db);

  static const _tabla = 'preguntas_quiz';

  // Siembra las preguntas si la tabla está vacía.
  Future<void> inicializar() async {
    final filas = await _db.consultar(_tabla, limit: 1);
    if (filas.isNotEmpty) return;
    for (final p in _banco) {
      await _db.insertar(_tabla, {
        'materia':    p.m,
        'grado':      p.g,
        'tema':       p.t,
        'pregunta':   p.q,
        'opcion_a':   p.a,
        'opcion_b':   p.b,
        'opcion_c':   p.c,
        'opcion_d':   p.d,
        'correcta':   'a',   // opcion_a siempre es la correcta en storage
        'explicacion': p.e,
        'dificultad': p.dif,
      });
    }
  }

  Future<List<PreguntaQuiz>> obtenerPreguntas({
    required String materia,
    required int grado,
    int cantidad = 15,
  }) async {
    final filas = await _db.consultar(
      _tabla,
      where: 'materia = ? AND grado = ?',
      whereArgs: [materia, grado],
    );
    if (filas.isEmpty) return [];

    final rng = Random();
    final mezcladas = List<Map<String, dynamic>>.from(filas)..shuffle(rng);
    return mezcladas.take(cantidad).map((f) => _convertir(f, rng)).toList();
  }

  PreguntaQuiz _convertir(Map<String, dynamic> f, Random rng) {
    final clave = (f['correcta'] as String).toLowerCase(); // siempre 'a'
    final mapa = {
      'a': f['opcion_a'] as String,
      'b': f['opcion_b'] as String,
      'c': f['opcion_c'] as String,
      'd': f['opcion_d'] as String,
    };
    final letras = ['a', 'b', 'c', 'd']..shuffle(rng);
    return PreguntaQuiz(
      pregunta:       f['pregunta'] as String,
      opciones:       letras.map((l) => mapa[l]!).toList(),
      indiceCorrecto: letras.indexOf(clave),
      tema:           f['tema'] as String,
    );
  }
}

class _P {
  final String m, t, q, a, b, c, d, e;
  final int g, dif;
  const _P(this.m, this.g, this.t, this.q, this.a, this.b, this.c, this.d, this.e, {this.dif = 1});
}

// opcionA es siempre la correcta en _banco; el runtime baraja las posiciones.
const List<_P> _banco = [

  // MATEMÁTICAS GRADO 3
  _P('matematicas', 3, 'tablas de multiplicar',
     '¿Cuánto es 7 × 8?',
     '56', '48', '54', '63',
     '7 × 8 = 56. Truco: 7 × 8 = 7 × 7 + 7 = 49 + 7 = 56.'),

  _P('matematicas', 3, 'tablas de multiplicar',
     '¿Cuánto es 6 × 9?',
     '54', '48', '56', '63',
     '6 × 9 = 54. También: 6 × 10 − 6 = 60 − 6 = 54.'),

  _P('matematicas', 3, 'fracciones simples',
     '¿Cuál es la mitad de 36?',
     '18', '16', '20', '14',
     'La mitad = dividir entre 2. 36 ÷ 2 = 18.'),

  _P('matematicas', 3, 'figuras geométricas',
     '¿Cuántos lados tiene un pentágono?',
     '5', '4', '6', '3',
     'Penta- significa cinco. El pentágono tiene 5 lados y 5 ángulos.'),

  _P('matematicas', 3, 'medidas de longitud',
     '¿Cuántos centímetros hay en 1 metro?',
     '100', '10', '1000', '50',
     '1 m = 100 cm. El prefijo centi- significa centésima parte.'),

  _P('matematicas', 3, 'suma con llevadas',
     '¿Cuánto es 347 + 285?',
     '632', '622', '532', '612',
     '7+5=12 (llevo 1); 4+8+1=13 (llevo 1); 3+2+1=6. Total: 632.'),

  _P('matematicas', 3, 'resta con llevadas',
     '¿Cuánto es 500 − 263?',
     '237', '247', '253', '263',
     '500 − 263 = 237. Verificación: 237 + 263 = 500.'),

  _P('matematicas', 3, 'tablas de multiplicar',
     '¿Cuánto es 9 × 7?',
     '63', '56', '54', '72',
     '9 × 7 = 63. Truco: 10 × 7 − 7 = 70 − 7 = 63.'),

  _P('matematicas', 3, 'fracciones simples',
     '¿Qué fracción representa "una parte de cuatro iguales"?',
     '1/4', '1/3', '1/2', '2/4',
     '1/4 (un cuarto) es una sola parte cuando el todo se divide en 4 partes iguales.',
     dif: 2),

  _P('matematicas', 3, 'figuras geométricas',
     '¿Cuántos ángulos tiene un triángulo?',
     '3', '4', '2', '6',
     'El triángulo tiene 3 lados y 3 ángulos. La suma de sus ángulos siempre es 180°.'),

  // MATEMÁTICAS GRADO 4
  _P('matematicas', 4, 'división exacta',
     '¿Cuánto es 72 ÷ 8?',
     '9', '7', '8', '6',
     '72 ÷ 8 = 9. Verificación: 8 × 9 = 72.'),

  _P('matematicas', 4, 'fracciones equivalentes',
     '¿Cuál fracción es equivalente a 3/4?',
     '6/8', '4/6', '5/8', '2/3',
     '6/8 = 3/4 porque 6÷2=3 y 8÷2=4. Multiplicar/dividir ambos términos por el mismo número conserva el valor.',
     dif: 2),

  _P('matematicas', 4, 'perímetro y área',
     'Un rectángulo mide 5 cm de largo y 3 cm de ancho. ¿Cuál es su perímetro?',
     '16 cm', '15 cm', '8 cm', '18 cm',
     'Perímetro = 2 × (largo + ancho) = 2 × 8 = 16 cm. 15 cm² es el área, no el perímetro.'),

  _P('matematicas', 4, 'números decimales',
     '¿Cuánto es 4,5 + 2,3?',
     '6,8', '6,18', '7,8', '6,08',
     'Décimas: 5+3=8; enteros: 4+2=6. Resultado: 6,8. Nunca se suman los decimales como si fueran enteros.'),

  _P('matematicas', 4, 'múltiplos y divisores',
     '¿Cuál es el múltiplo de 6 más cercano a 40?',
     '42', '36', '40', '30',
     '6×6=36 (4 unidades lejos) y 6×7=42 (2 unidades lejos). El más cercano es 42.',
     dif: 2),

  _P('matematicas', 4, 'división exacta',
     '¿Cuánto es 84 ÷ 6?',
     '14', '12', '16', '13',
     '84 ÷ 6 = 14. Verificación: 6 × 14 = 84.'),

  _P('matematicas', 4, 'perímetro y área',
     '¿Cuál es el área de un cuadrado con lado de 7 cm?',
     '49 cm²', '28 cm²', '14 cm²', '42 cm²',
     'Área = lado × lado = 7 × 7 = 49 cm². 28 cm sería el perímetro (4 × 7).'),

  _P('matematicas', 4, 'números decimales',
     '¿Cuánto es 0,5 × 4?',
     '2', '0,20', '20', '4,5',
     '0,5 es la mitad de 1, por eso 0,5 × 4 = la mitad de 4 = 2.'),

  _P('matematicas', 4, 'múltiplos y divisores',
     '¿Cuántos divisores tiene el número 12?',
     '6', '4', '5', '8',
     'Divisores de 12: 1, 2, 3, 4, 6, 12. Son 6 en total.',
     dif: 2),

  _P('matematicas', 4, 'fracciones equivalentes',
     '¿Cuál fracción es equivalente a 2/3?',
     '4/6', '3/4', '4/5', '3/6',
     '4/6 = 2/3 (dividir por 2 ambos términos). 3/6 = 1/2, no 2/3.',
     dif: 2),

  // MATEMÁTICAS GRADO 5
  _P('matematicas', 5, 'potenciación',
     '¿Cuánto es 2³?',
     '8', '6', '9', '16',
     '2³ = 2×2×2 = 4×2 = 8. El exponente dice cuántas veces se multiplica la base.'),

  _P('matematicas', 5, 'radicación',
     '¿Cuál es la raíz cuadrada de 81?',
     '9', '8', '7', '10',
     '√81 = 9 porque 9 × 9 = 81.'),

  _P('matematicas', 5, 'fracciones mixtas',
     '¿Qué número mixto equivale a la fracción 11/4?',
     '2 y 3/4', '2 y 1/4', '3 y 1/4', '3 y 3/4',
     '11 ÷ 4 = 2 (cociente) con residuo 3. Entonces 11/4 = 2 y 3/4.',
     dif: 2),

  _P('matematicas', 5, 'volumen de sólidos',
     '¿Cuál es el volumen de un cubo con arista de 3 cm?',
     '27 cm³', '9 cm³', '18 cm³', '12 cm³',
     'Volumen del cubo = arista³ = 3×3×3 = 27 cm³.'),

  _P('matematicas', 5, 'estadística básica',
     'En el conjunto {3, 5, 7, 5, 2, 5}, ¿cuál es la moda?',
     '5', '3', '2', '7',
     'La moda es el valor que más se repite. El 5 aparece 3 veces.'),

  _P('matematicas', 5, 'estadística básica',
     '¿Cuál es la media de los números 4, 8 y 12?',
     '8', '6', '10', '12',
     'Media = suma ÷ cantidad = (4+8+12) ÷ 3 = 24 ÷ 3 = 8.'),

  _P('matematicas', 5, 'números enteros',
     '¿Cuánto es (−3) + (+7)?',
     '+4', '−4', '+10', '−10',
     'Prevalece el signo del mayor: 7−3=4, positivo. Resultado: +4.',
     dif: 2),

  _P('matematicas', 5, 'potenciación',
     '¿Cuánto es 3² + 2³?',
     '17', '10', '15', '13',
     '3²=9 y 2³=8. Entonces 9+8=17.',
     dif: 2),

  _P('matematicas', 5, 'volumen de sólidos',
     'Volumen de un prisma rectangular de 4 cm × 3 cm × 2 cm:',
     '24 cm³', '18 cm³', '14 cm³', '26 cm³',
     'Volumen = largo × ancho × alto = 4×3×2 = 24 cm³.'),

  _P('matematicas', 5, 'radicación',
     '¿Cuál es la raíz cuadrada de 64?',
     '8', '7', '9', '6',
     '√64 = 8 porque 8 × 8 = 64.'),

  // CIENCIAS NATURALES GRADO 3
  _P('ciencias', 3, 'seres vivos',
     '¿Cuál característica es exclusiva de los seres vivos?',
     'Reproducirse', 'Ocupar espacio', 'Tener peso', 'Cambiar de temperatura',
     'Reproducirse es exclusivo de los seres vivos. Las piedras ocupan espacio y tienen peso, pero no se reproducen.'),

  _P('ciencias', 3, 'cadenas alimenticias',
     'En la cadena pasto → conejo → zorro, ¿quién es el productor?',
     'El pasto', 'El conejo', 'El zorro', 'Todos por igual',
     'El productor fabrica su alimento con luz solar. Las plantas (pasto) son siempre los productores.'),

  _P('ciencias', 3, 'estados de la materia',
     '¿En qué estado las moléculas están más separadas?',
     'Gaseoso', 'Sólido', 'Líquido', 'Plasma',
     'En el gas las moléculas se mueven libremente y están muy separadas. En el sólido están muy unidas.'),

  _P('ciencias', 3, 'partes de la planta',
     '¿Cuál es la función principal de la raíz?',
     'Absorber agua y nutrientes del suelo', 'Hacer la fotosíntesis', 'Producir las flores', 'Transportar agua a las hojas',
     'La raíz ancla la planta y absorbe agua y minerales del suelo. La fotosíntesis ocurre en las hojas.'),

  _P('ciencias', 3, 'animales vertebrados',
     '¿Cuál de estos animales es vertebrado?',
     'El perro', 'La lombriz', 'El pulpo', 'La mariposa',
     'El perro tiene columna vertebral. La lombriz, el pulpo y la mariposa son invertebrados.'),

  _P('ciencias', 3, 'estados de la materia',
     '¿En qué estado se encuentra el hielo?',
     'Sólido', 'Líquido', 'Gaseoso', 'Plasma',
     'El hielo es agua en estado sólido: tiene forma y volumen fijos.'),

  _P('ciencias', 3, 'partes de la planta',
     '¿Qué parte de la planta produce las semillas?',
     'Las flores', 'Las hojas', 'El tallo', 'La raíz',
     'Tras la fecundación, el fruto se forma dentro de la flor y las semillas están en su interior.'),

  _P('ciencias', 3, 'animales invertebrados',
     '¿Cuál de estos animales es invertebrado?',
     'La araña', 'La rana', 'El pez', 'El pollo',
     'La araña no tiene columna vertebral. La rana, el pez y el pollo sí la tienen.'),

  _P('ciencias', 3, 'cadenas alimenticias',
     '¿Cuál es una cadena alimentaria correcta?',
     'Pasto → conejo → zorro', 'Zorro → conejo → pasto', 'Conejo → pasto → zorro', 'Conejo → zorro → pasto',
     'La cadena siempre va del productor (planta) al consumidor final. El pasto es comido por el conejo y este por el zorro.'),

  _P('ciencias', 3, 'estados de la materia',
     '¿Qué ocurre con el agua cuando se congela?',
     'Pasa de líquido a sólido', 'Pasa de gaseoso a sólido', 'Pasa de líquido a gaseoso', 'Pasa de sólido a líquido',
     'La congelación es el cambio de líquido a sólido. Ocurre a 0 °C.'),

  // CIENCIAS NATURALES GRADO 4
  _P('ciencias', 4, 'ecosistemas colombianos',
     '¿Cuál es el ecosistema más biodiverso de Colombia?',
     'La Amazonia colombiana', 'El desierto de La Tatacoa', 'La sabana llanera', 'El páramo andino',
     'La Amazonia alberga miles de especies únicas de plantas, animales e insectos.'),

  _P('ciencias', 4, 'ciclo del agua',
     '¿En qué fase del ciclo el calor del sol convierte el agua en vapor?',
     'Evaporación', 'Condensación', 'Precipitación', 'Infiltración',
     'La evaporación transforma el agua líquida en vapor que asciende a la atmósfera.'),

  _P('ciencias', 4, 'sistema digestivo',
     '¿Dónde se absorben principalmente los nutrientes?',
     'En el intestino delgado', 'En el estómago', 'En el intestino grueso', 'En el esófago',
     'El intestino delgado tiene vellosidades que absorben nutrientes hacia la sangre.'),

  _P('ciencias', 4, 'mezclas y soluciones',
     '¿Cuál de estas es una mezcla homogénea?',
     'Agua con azúcar', 'Ensalada de frutas', 'Agua con arena', 'Aceite con agua',
     'En el agua con azúcar el soluto se disuelve por completo y no se pueden distinguir las partes.'),

  _P('ciencias', 4, 'adaptaciones de animales',
     '¿Qué adaptación ayuda al cactus a sobrevivir en el desierto?',
     'Tallos carnosos que almacenan agua y espinas que reducen la transpiración', 'Hojas grandes para captar lluvia', 'Flores muy coloridas para atraer insectos', 'Tronco delgado para moverse con el viento',
     'Los cactus acumulan agua en el tallo y sus espinas reemplazan a las hojas reduciendo la pérdida de agua.',
     dif: 2),

  _P('ciencias', 4, 'sistema digestivo',
     '¿Dónde comienza la digestión mecánica?',
     'En la boca', 'En el estómago', 'En el intestino delgado', 'En el hígado',
     'En la boca los dientes trituran el alimento (digestión mecánica) y la saliva inicia la química.'),

  _P('ciencias', 4, 'mezclas y soluciones',
     '¿Cuál de estas es una mezcla heterogénea?',
     'Agua con aceite', 'Agua con sal', 'Jugo de naranja colado', 'Suero oral',
     'En el agua con aceite se distinguen las dos partes (heterogénea). Las otras son homogéneas.'),

  _P('ciencias', 4, 'ecosistemas colombianos',
     '¿Qué caracteriza el ecosistema de páramo en Colombia?',
     'Temperaturas bajas, niebla constante y frailejones', 'Temperaturas muy altas todo el año', 'Presencia de manglares', 'Grandes árboles de selva tropical',
     'El páramo (3.000-4.500 m) tiene clima frío, neblina frecuente y plantas típicas como los frailejones.'),

  _P('ciencias', 4, 'sistema digestivo',
     '¿Cuál es la función del esófago?',
     'Transportar el alimento de la boca al estómago', 'Absorber los nutrientes', 'Producir jugos digestivos', 'Almacenar los desechos',
     'El esófago es un tubo muscular que conecta la boca con el estómago mediante movimientos peristálticos.'),

  _P('ciencias', 4, 'mezclas y soluciones',
     '¿Qué técnica separa una mezcla de agua con arena?',
     'Filtración', 'Destilación', 'Evaporación', 'Imantación',
     'La filtración retiene la arena en el filtro y deja pasar el agua. Se usa cuando hay un sólido en un líquido.'),

  // CIENCIAS NATURALES GRADO 5
  _P('ciencias', 5, 'sistema solar',
     '¿Cuál es el planeta más grande del sistema solar?',
     'Júpiter', 'Saturno', 'Neptuno', 'Urano',
     'Júpiter es tan grande que todos los demás planetas cabrían dentro de él.'),

  _P('ciencias', 5, 'célula',
     '¿Qué parte de la célula controla todas sus funciones?',
     'El núcleo', 'La membrana celular', 'El citoplasma', 'La mitocondria',
     'El núcleo contiene el ADN, el "manual de instrucciones" que dirige todas las actividades celulares.'),

  _P('ciencias', 5, 'fuentes de energía',
     '¿Cuál es una fuente de energía renovable?',
     'La energía solar', 'El petróleo', 'El carbón mineral', 'El gas natural',
     'El sol seguirá brillando por miles de millones de años. El petróleo, carbón y gas se agotan.'),

  _P('ciencias', 5, 'fotosíntesis',
     '¿En qué organelo ocurre la fotosíntesis?',
     'El cloroplasto', 'La vacuola', 'La mitocondria', 'El retículo endoplasmático',
     'El cloroplasto tiene clorofila que capta la luz solar para producir glucosa y oxígeno.',
     dif: 2),

  _P('ciencias', 5, 'contaminación ambiental',
     '¿Cuál es la principal causa de contaminación del agua en Colombia?',
     'El vertimiento de residuos industriales y domésticos', 'El exceso de plantas acuáticas', 'Las lluvias ácidas de otros países', 'La presencia de muchos peces',
     'Las aguas residuales sin tratar y los desechos industriales contaminan ríos y fuentes de agua.'),

  _P('ciencias', 5, 'sistema solar',
     '¿Cuántos planetas tiene el sistema solar?',
     '8', '7', '9', '10',
     'Hay 8 planetas: Mercurio, Venus, Tierra, Marte, Júpiter, Saturno, Urano y Neptuno. Plutón es planeta enano.'),

  _P('ciencias', 5, 'célula',
     '¿Cuál es la función principal de la membrana celular?',
     'Controlar qué sustancias entran y salen de la célula', 'Producir energía', 'Guardar el material genético', 'Realizar la fotosíntesis',
     'La membrana es una barrera selectiva que protege la célula y regula el intercambio de sustancias.'),

  _P('ciencias', 5, 'fotosíntesis',
     '¿Cuáles son los ingredientes que la planta necesita para la fotosíntesis?',
     'Dióxido de carbono, agua y luz solar', 'Agua y nitrógeno del suelo', 'Oxígeno y glucosa del ambiente', 'Minerales del suelo y calor',
     'Ecuación básica: CO₂ + H₂O + luz → glucosa + O₂.'),

  _P('ciencias', 5, 'fuentes de energía',
     '¿Cuál es un ejemplo de energía no renovable?',
     'El carbón mineral', 'La energía eólica', 'La energía hidroeléctrica', 'La energía geotérmica',
     'El carbón tardó millones de años en formarse y se agotará. Las otras fuentes se reponen naturalmente.'),

  _P('ciencias', 5, 'sistema solar',
     '¿Qué planeta está más cerca del Sol?',
     'Mercurio', 'Venus', 'La Tierra', 'Marte',
     'Mercurio es el más cercano al Sol. Un año en Mercurio dura solo 88 días terrestres.'),

  // CIENCIAS SOCIALES GRADO 3
  _P('sociales', 3, 'mapas y puntos cardinales',
     '¿Cuáles son los cuatro puntos cardinales?',
     'Norte, Sur, Este, Oeste', 'Norte, Sur, Izquierda, Derecha', 'Arriba, Abajo, Derecha, Izquierda', 'Norte, Sur, Centro, Lateral',
     'Los puntos cardinales son: Norte (N), Sur (S), Este (E) y Oeste (O).'),

  _P('sociales', 3, 'regiones naturales de Colombia',
     '¿Cuántas regiones naturales tiene Colombia?',
     '6', '4', '5', '7',
     'Colombia tiene 6 regiones: Andina, Caribe, Pacífica, Orinoquía, Amazónica e Insular.'),

  _P('sociales', 3, 'comunidades y municipios',
     '¿Cuál es la capital de Colombia?',
     'Bogotá', 'Medellín', 'Cali', 'Barranquilla',
     'Bogotá D.C. es la capital y ciudad más grande de Colombia, sede del gobierno nacional.'),

  _P('sociales', 3, 'símbolos patrios',
     '¿Cuál símbolo patrio se entona en actos oficiales?',
     'El himno nacional', 'El escudo nacional', 'La bandera tricolor', 'El mapa de Colombia',
     'El himno nacional se entona en actos escolares, deportivos y oficiales en señal de respeto.'),

  _P('sociales', 3, 'regiones naturales de Colombia',
     '¿En qué región natural está el río Amazonas?',
     'En la región Amazónica', 'En la región Caribe', 'En la región Andina', 'En la región Pacífica',
     'El río Amazonas cruza el sur de Colombia en la región Amazónica (Amazonas, Putumayo).'),

  _P('sociales', 3, 'mapas y puntos cardinales',
     '¿Qué instrumento señala el Norte para orientarse?',
     'La brújula', 'El termómetro', 'El barómetro', 'El telescopio',
     'La brújula tiene una aguja imantada que siempre apunta al norte magnético.'),

  _P('sociales', 3, 'regiones naturales de Colombia',
     '¿Cuál región tiene las montañas más altas de Colombia?',
     'La región Andina', 'La región Caribe', 'La región Orinoquía', 'La región Pacífica',
     'La región Andina es atravesada por los Andes, con los nevados más altos del país.'),

  _P('sociales', 3, 'comunidades y municipios',
     '¿Qué es un municipio?',
     'División del territorio más pequeña que el departamento', 'Una ciudad muy grande e importante', 'Un país dentro del continente', 'Una región natural del país',
     'Colombia se divide en departamentos y cada departamento en municipios.'),

  _P('sociales', 3, 'símbolos patrios',
     '¿Cuál es la flor símbolo nacional de Colombia?',
     'La orquídea (Cattleya trianae)', 'La rosa', 'El girasol', 'El tulipán',
     'La orquídea Cattleya trianae, llamada "lirio de Navidad", fue declarada flor nacional en 1936.'),

  _P('sociales', 3, 'mapas y puntos cardinales',
     'En un mapa convencional, ¿hacia dónde apunta el Norte?',
     'Hacia arriba', 'Hacia abajo', 'Hacia la derecha', 'Hacia la izquierda',
     'Por convención cartográfica, el norte siempre se representa en la parte superior del mapa.'),

  // CIENCIAS SOCIALES GRADO 4
  _P('sociales', 4, 'historia precolombina',
     '¿Qué cultura construyó las estatuas de San Agustín?',
     'La cultura agustiniana', 'Los Muiscas', 'Los Taironas', 'Los Zenúes',
     'La cultura de San Agustín (Huila) es Patrimonio de la Humanidad por sus grandes estatuas de piedra.'),

  _P('sociales', 4, 'geografía física de Colombia',
     '¿Cuál es el río más largo de Colombia?',
     'El río Magdalena', 'El río Cauca', 'El río Orinoco', 'El río Atrato',
     'El Magdalena (~1.528 km) nace en el macizo colombiano y desemboca en el Caribe en Barranquilla.'),

  _P('sociales', 4, 'culturas indígenas',
     '¿Cuál cultura habitó la Sierra Nevada de Santa Marta?',
     'Los Taironas', 'Los Muiscas', 'Los Zenúes', 'Los Quimbayas',
     'Los Taironas construyeron la Ciudad Perdida (Teyuna), redescubierta en 1972.'),

  _P('sociales', 4, 'economía básica',
     '¿Cuál actividad pertenece al sector primario?',
     'Cultivar café en una finca', 'Fabricar ropa en una fábrica', 'Vender en un almacén', 'Trabajar en un banco',
     'El sector primario extrae recursos de la naturaleza: agricultura, ganadería, minería, pesca.'),

  _P('sociales', 4, 'geografía física de Colombia',
     '¿Cuál es la montaña más alta de Colombia?',
     'El Pico Cristóbal Colón (Sierra Nevada de Santa Marta)', 'El Nevado del Ruiz', 'El Nevado del Tolima', 'El Nevado del Huila',
     'El Pico Cristóbal Colón (5.775 m) en la Sierra Nevada de Santa Marta es el punto más alto del país.',
     dif: 2),

  _P('sociales', 4, 'historia precolombina',
     '¿Qué práctica de los Muiscas inspiró la leyenda de El Dorado?',
     'La ceremonia del Zipa cubriéndose de oro en la Laguna de Guatavita', 'Los sacrificios al dios Sol en Sogamoso', 'Las ofrendas en las estatuas de San Agustín', 'La adoración de la luna en cuevas',
     'El nuevo Zipa se cubría de polvo de oro y hacía ofrendas en la laguna, originando la leyenda.',
     dif: 2),

  _P('sociales', 4, 'geografía física de Colombia',
     '¿Cuál es el clima predominante en la región Caribe?',
     'Cálido con épocas secas y lluviosas', 'Frío y lluvioso todo el año', 'Templado con cuatro estaciones', 'Polar con nieves permanentes',
     'La región Caribe tiene clima tropical cálido (25-35 °C) con épocas seca y de lluvias.'),

  _P('sociales', 4, 'economía básica',
     '¿A qué sector pertenece fabricar zapatos en una fábrica?',
     'Sector secundario', 'Sector primario', 'Sector terciario', 'Sector cuaternario',
     'El sector secundario (industria) transforma materias primas en productos elaborados.'),

  _P('sociales', 4, 'culturas indígenas',
     '¿Cuál grupo indígena fue famoso por su orfebrería (trabajo en oro)?',
     'Los Quimbayas', 'Los Koguis', 'Los Nukak', 'Los Arhuacos',
     'Los Quimbayas del Eje Cafetero son reconocidos por sus extraordinarias piezas de oro, especialmente los "poporos".'),

  _P('sociales', 4, 'geografía física de Colombia',
     '¿En cuántos ramales se divide la Cordillera de los Andes en Colombia?',
     'Tres ramales', 'Dos ramales', 'Cuatro ramales', 'Un solo ramal',
     'Los Andes colombianos se dividen en: Cordillera Occidental, Central y Oriental.'),

  // CIENCIAS SOCIALES GRADO 5
  _P('sociales', 5, 'independencia de Colombia',
     '¿En qué año se dio el Grito de Independencia de Colombia?',
     '1810', '1819', '1800', '1821',
     'El 20 de julio de 1810 los criollos iniciaron el movimiento de independencia en Bogotá.'),

  _P('sociales', 5, 'instituciones del Estado colombiano',
     '¿Quién es el jefe de Estado y de Gobierno en Colombia?',
     'El Presidente de la República', 'El Congreso', 'El Fiscal General', 'El Gobernador',
     'El Presidente es elegido por voto popular para un período de 4 años.'),

  _P('sociales', 5, 'instituciones del Estado colombiano',
     '¿Cuántas ramas tiene el Poder Público en Colombia?',
     'Tres', 'Dos', 'Cuatro', 'Cinco',
     'Las tres ramas son: Legislativa (Congreso), Ejecutiva (Presidencia) y Judicial (Cortes).'),

  _P('sociales', 5, 'democracia y participación',
     '¿Qué es el sufragio?',
     'El derecho a votar en elecciones', 'El derecho a trabajar en el gobierno', 'La obligación de pagar impuestos', 'La participación en marchas',
     'El sufragio universal garantiza que todos los ciudadanos mayores de 18 años puedan votar.'),

  _P('sociales', 5, 'América Latina geografía',
     '¿Cuál es la capital de Brasil?',
     'Brasilia', 'São Paulo', 'Río de Janeiro', 'Buenos Aires',
     'Brasilia es la capital federal de Brasil desde 1960, construida especialmente para esa función.'),

  _P('sociales', 5, 'independencia de Colombia',
     '¿Quién lideró la campaña libertadora de Colombia y Venezuela?',
     'Simón Bolívar', 'Francisco de Paula Santander', 'Antonio Nariño', 'Camilo Torres',
     'Bolívar, "El Libertador", dirigió las campañas que liberaron Venezuela, Colombia, Ecuador, Perú y Bolivia.'),

  _P('sociales', 5, 'instituciones del Estado colombiano',
     '¿Qué órgano tiene la función de hacer las leyes en Colombia?',
     'El Congreso de la República', 'La Presidencia', 'La Corte Suprema de Justicia', 'Las Alcaldías',
     'El Congreso (Senado + Cámara de Representantes) crea, reforma y deroga leyes.'),

  _P('sociales', 5, 'América Latina geografía',
     '¿Cuál es el país más grande de América del Sur?',
     'Brasil', 'Argentina', 'Colombia', 'Perú',
     'Brasil (~8,5 millones de km²) ocupa casi la mitad del continente suramericano.'),

  _P('sociales', 5, 'independencia de Colombia',
     '¿Qué fecha se celebra como Día de la Independencia de Colombia?',
     '20 de julio', '7 de agosto', '11 de noviembre', '16 de julio',
     'El 20/07/1810 es el Grito de Independencia. El 7 de agosto conmemora la Batalla de Boyacá (1819).'),

  _P('sociales', 5, 'instituciones del Estado colombiano',
     '¿Cuál es la función del poder judicial?',
     'Impartir justicia e interpretar las leyes', 'Crear y aprobar las leyes', 'Ejecutar el plan de gobierno', 'Recaudar los impuestos',
     'El Poder Judicial administra justicia, resuelve conflictos y protege los derechos ciudadanos.'),

  // ESPAÑOL GRADO 3
  _P('espanol', 3, 'sinónimos y antónimos',
     '¿Cuál es sinónimo de "feliz"?',
     'Alegre', 'Triste', 'Enojado', 'Asustado',
     'Alegre y feliz tienen el mismo significado. Triste es el antónimo.'),

  _P('espanol', 3, 'sinónimos y antónimos',
     '¿Cuál es el antónimo de "rápido"?',
     'Lento', 'Veloz', 'Ligero', 'Ágil',
     'El antónimo es el opuesto. Rápido ↔ Lento. Veloz, ligero y ágil son sinónimos de rápido.'),

  _P('espanol', 3, 'tipos de oraciones',
     '¿Cuál de estas es una oración interrogativa?',
     '¿Dónde está tu casa?', 'Corre muy rápido.', '¡Qué día tan bonito!', 'El perro ladra fuerte.',
     'La oración interrogativa hace una pregunta y se escribe entre signos ¿?.'),

  _P('espanol', 3, 'uso de mayúsculas',
     '¿Cuál se escribe siempre con mayúscula?',
     'Colombia', 'niño', 'ciudad', 'árbol',
     'Los nombres propios (países, personas, ciudades) siempre se escriben con mayúscula.'),

  _P('espanol', 3, 'signos de puntuación',
     '¿Qué signo va al final de una oración que expresa emoción?',
     'El signo de exclamación (!)', 'El punto (.)', 'La coma (,)', 'Los puntos suspensivos (...)',
     'El signo de exclamación (¡ !) enmarca oraciones exclamativas que expresan emoción o sorpresa.'),

  _P('espanol', 3, 'tipos de palabras',
     '¿Qué es un sustantivo?',
     'Una palabra que nombra personas, animales, lugares o cosas', 'Una palabra que expresa una acción', 'Una palabra que describe cómo es algo', 'Una palabra que dice cómo se hace algo',
     'Los sustantivos son palabras que nombran seres, objetos, lugares o ideas: niño, perro, ciudad.'),

  _P('espanol', 3, 'tipos de oraciones',
     '¿Qué tipo de oración es "¡Qué lindo día hace hoy!"?',
     'Exclamativa', 'Interrogativa', 'Declarativa', 'Negativa',
     'La oración exclamativa expresa emociones fuertes y se escribe entre signos de exclamación (¡ !).'),

  _P('espanol', 3, 'sinónimos y antónimos',
     '¿Cuál es sinónimo de "grande"?',
     'Enorme', 'Pequeño', 'Largo', 'Nuevo',
     'Enorme significa muy grande. Pequeño es el antónimo de grande.'),

  _P('espanol', 3, 'comprensión lectora',
     'El sujeto de una oración es la parte que...',
     'Nombra al ser del que se habla o que realiza la acción', 'Expresa la acción que se realiza', 'Dice dónde ocurre la acción', 'Indica el tiempo de la acción',
     'El sujeto es de quien se habla. En "Los niños juegan", el sujeto es "Los niños".'),

  _P('espanol', 3, 'ortografía',
     '¿Cuál de estas palabras lleva tilde?',
     'Árbol', 'Mesa', 'Casa', 'Gato',
     '"Árbol" es esdrújula (ÁR-bol) y todas las palabras esdrújulas llevan tilde obligatoriamente.'),

  // ESPAÑOL GRADO 4
  _P('espanol', 4, 'sujeto y predicado',
     'En "Los niños juegan en el parque", ¿cuál es el sujeto?',
     'Los niños', 'Juegan', 'En el parque', 'Juegan en el parque',
     'El sujeto es "Los niños" porque es quien realiza la acción. El predicado es "juegan en el parque".'),

  _P('espanol', 4, 'uso de b/v y h',
     '¿Cuál de estas palabras se escribe con "V"?',
     'Viento', 'Burro', 'Beso', 'Blanco',
     '"Viento" se escribe con V. Regla: verbos terminados en -aba y palabras con BL/BR usan B.'),

  _P('espanol', 4, 'adjetivos y sustantivos',
     '¿Cuál de estas palabras es un adjetivo?',
     'Hermoso', 'Correr', 'Casa', 'Rápidamente',
     '"Hermoso" describe o califica al sustantivo. "Correr" es verbo, "casa" es sustantivo, "rápidamente" es adverbio.'),

  _P('espanol', 4, 'tipos de texto',
     '¿Cuál texto narra una historia con personajes y una trama?',
     'Texto narrativo', 'Texto informativo', 'Texto descriptivo', 'Texto argumentativo',
     'El texto narrativo cuenta hechos (reales o ficticios) con personajes, narrador e inicio-nudo-desenlace.'),

  _P('espanol', 4, 'sujeto y predicado',
     'En "El pájaro canta", ¿cuál es el predicado?',
     'Canta', 'El pájaro', 'El pájaro canta', 'Solo el verbo lo tiene',
     'El predicado dice qué hace el sujeto. "Canta" es el predicado de "El pájaro canta".'),

  _P('espanol', 4, 'uso de b/v y h',
     '¿Cuál de estas palabras se escribe con "H"?',
     'Hora', 'Ola (del mar)', 'Ala', 'Ira',
     '"Hora" lleva H muda. La H no suena en español pero se escribe en muchas palabras.'),

  _P('espanol', 4, 'comprensión de textos',
     '¿Qué es la idea principal de un texto?',
     'La oración que expresa el tema más importante', 'Siempre el primer párrafo', 'Siempre el título', 'Siempre la última oración',
     'La idea principal es el mensaje central del texto. Puede estar al inicio, en medio o al final.'),

  _P('espanol', 4, 'adjetivos y sustantivos',
     '¿Cuál es el sustantivo en "La mariposa vuela alto"?',
     'Mariposa', 'Vuela', 'Alto', 'La',
     '"Mariposa" nombra un ser (sustantivo). "Vuela" es verbo, "alto" es adjetivo/adverbio, "la" es artículo.'),

  _P('espanol', 4, 'morfología',
     '¿Cuál palabra tiene un prefijo que significa "no" o "sin"?',
     'Infeliz', 'Precaución', 'Subtítulo', 'Bicicleta',
     'El prefijo "in-" significa "no": infeliz = no feliz. Pre- = antes, sub- = bajo, bi- = dos.'),

  _P('espanol', 4, 'tipos de texto',
     '¿Para qué sirve el texto descriptivo?',
     'Explicar las características de un ser, objeto o lugar', 'Narrar sucesos en orden cronológico', 'Convencer al lector de una opinión', 'Dar instrucciones paso a paso',
     'El texto descriptivo "pinta con palabras": usa adjetivos para que el lector imagine lo descrito.'),

  // ESPAÑOL GRADO 5
  _P('espanol', 5, 'verbos en tiempos compuestos',
     '¿Cuál verbo está en pretérito perfecto compuesto?',
     'He comido', 'Comí', 'Comeré', 'Como',
     'Pretérito perfecto compuesto = "haber" + participio: he comido. "Comí" es pretérito simple.'),

  _P('espanol', 5, 'conectores textuales',
     '¿Cuál conector indica consecuencia?',
     'Por lo tanto', 'Sin embargo', 'Aunque', 'Mientras que',
     '"Por lo tanto" introduce una consecuencia lógica. "Sin embargo" indica contraste.'),

  _P('espanol', 5, 'figuras literarias',
     '¿Qué figura usa la frase "Sus ojos son dos estrellas"?',
     'Metáfora', 'Símil', 'Hipérbole', 'Personificación',
     'La metáfora identifica directamente: "ojos son estrellas". El símil diría "como estrellas".'),

  _P('espanol', 5, 'uso de g/j y r/rr',
     '¿Cuál palabra se escribe con "RR"?',
     'Carro', 'Arena', 'Caro', 'Pero',
     '"Carro" lleva RR. Regla: RR entre vocales con sonido fuerte. Al inicio de palabra: solo R (rosa, río).'),

  _P('espanol', 5, 'texto argumentativo',
     '¿Cuál es un ejemplo de texto argumentativo?',
     'Una carta de opinión en un periódico', 'Una receta de cocina', 'Un cuento de hadas', 'Un mapa conceptual',
     'El texto argumentativo convierte usando razones y datos. Las cartas de opinión y ensayos son argumentativos.'),

  _P('espanol', 5, 'figuras literarias',
     '¿Cuál es la diferencia entre símil y metáfora?',
     'El símil usa "como" o "parece"; la metáfora identifica directamente', 'Son exactamente la misma figura', 'La metáfora usa "como"', 'El símil es más literario',
     'Símil: "Corre como el viento". Metáfora: "Es un rayo". La metáfora es más directa e impactante.',
     dif: 2),

  _P('espanol', 5, 'verbos en tiempos compuestos',
     '¿Cuál verbo está en pasado simple (pretérito indefinido)?',
     'Canté', 'Canto', 'Cantaré', 'Cantaba',
     '"Canté" es pretérito indefinido: acción concluida. "Cantaba" es imperfecto; "canto" es presente.'),

  _P('espanol', 5, 'conectores textuales',
     '¿Cuál conector introduce una idea contraria?',
     'Sin embargo', 'Por lo tanto', 'Además', 'Por ejemplo',
     '"Sin embargo" y "pero" contrastan ideas. "Por lo tanto" indica consecuencia, "además" agrega.'),

  _P('espanol', 5, 'figuras literarias',
     '¿Cuál es un ejemplo de hipérbole?',
     '"Tengo un hambre que me comería un elefante"', '"El cielo es azul como el mar"', '"El viento susurra canciones"', '"Sus ojos son dos luceros"',
     'La hipérbole exagera con fines expresivos. "Hambre de un elefante" exagera para enfatizar la magnitud.'),

  _P('espanol', 5, 'uso de g/j y r/rr',
     '¿Cuál palabra se escribe con "G" aunque suene parecido a "J"?',
     'Genio', 'Jabón', 'Jirafa', 'Jamón',
     '"Genio" lleva G. Regla: "ge" y "gi" suenan como J pero se escriben con G: general, girasol, genio.'),

  // INGLÉS GRADO 3
  _P('ingles', 3, 'colores',
     'How do you say "rojo" in English?',
     'Red', 'Blue', 'Green', 'Yellow',
     'Red = rojo. Blue = azul, Green = verde, Yellow = amarillo.'),

  _P('ingles', 3, 'números 1-100',
     'What does "fifty" mean in Spanish?',
     '50', '15', '5', '500',
     'Fifty = 50. Fifteen = 15, Five = 5, Five hundred = 500.'),

  _P('ingles', 3, 'presente simple to be',
     'Which form of "to be" goes with "I"?',
     'I am', 'He is', 'She is', 'I is',
     'Conjugación: I am / you are / he, she, it is / we, they are.'),

  _P('ingles', 3, 'partes del cuerpo',
     'How do you say "cabeza" in English?',
     'Head', 'Hand', 'Foot', 'Arm',
     'Head = cabeza. Hand = mano, Foot = pie, Arm = brazo.'),

  _P('ingles', 3, 'saludos y despedidas',
     'How do you say "buenos días" in English?',
     'Good morning', 'Good night', 'Good afternoon', 'Goodbye',
     'Good morning se usa hasta el mediodía. Good afternoon = buenas tardes, Good night = buenas noches.'),

  _P('ingles', 3, 'números 1-100',
     'What is the number 90 in English?',
     'Ninety', 'Nineteen', 'Nine', 'Ninth',
     'Ninety = 90. Nineteen = 19, Nine = 9, Ninth = noveno (ordinal).'),

  _P('ingles', 3, 'colores',
     'How do you say "verde" in English?',
     'Green', 'Yellow', 'Blue', 'Purple',
     'Green = verde. Yellow = amarillo, Blue = azul, Purple = morado.'),

  _P('ingles', 3, 'presente simple to be',
     'Which form of "to be" goes with "She"?',
     'She is', 'She am', 'She are', 'She be',
     'Con he/she/it siempre se usa "is": she is, he is, it is.'),

  _P('ingles', 3, 'partes del cuerpo',
     'How do you say "mano" in English?',
     'Hand', 'Foot', 'Arm', 'Knee',
     'Hand = mano. Foot = pie, Arm = brazo, Knee = rodilla.'),

  _P('ingles', 3, 'saludos y despedidas',
     'What do you say when saying goodbye?',
     'Goodbye', 'Hello', 'Hi', 'How are you?',
     'Goodbye (o Bye) se usa para despedirse. Hello y Hi son saludos de bienvenida.'),

  // INGLÉS GRADO 4
  _P('ingles', 4, 'presente simple verbos de acción',
     'Which sentence is correct in simple present with "she"?',
     'She reads books every day', 'She read books every day', 'She reading books every day', 'She is read books every day',
     'Con he/she/it el verbo añade -s o -es: she reads. Con I/you/we/they no se agrega -s.'),

  _P('ingles', 4, 'días meses estaciones',
     'How do you say "enero" in English?',
     'January', 'June', 'February', 'March',
     'January = enero. June = junio, February = febrero, March = marzo.'),

  _P('ingles', 4, 'adjetivos comparativos',
     'What is the comparative form of "big"?',
     'Bigger', 'More big', 'Biggest', 'Most big',
     'Adjetivos cortos (1-2 sílabas): agregan -er. Big→bigger. "Biggest" es superlativo.'),

  _P('ingles', 4, 'vocabulario del hogar y escuela',
     'How do you say "cocina" in English?',
     'Kitchen', 'Bedroom', 'Bathroom', 'Living room',
     'Kitchen = cocina. Bedroom = habitación, Bathroom = baño, Living room = sala.'),

  _P('ingles', 4, 'presente simple verbos de acción',
     'Which form is correct with "Does" + she?',
     'Does she go to school?', 'Does she goes to school?', 'Do she go to school?', 'Is she go to school?',
     'Con "does" el verbo principal va en forma base (sin -s): Does she go? (no "goes").'),

  _P('ingles', 4, 'días meses estaciones',
     'Which season comes after summer?',
     'Fall (Autumn)', 'Spring', 'Winter', 'Summer again',
     'Orden: Spring → Summer → Fall/Autumn → Winter. Después del verano viene el otoño.'),

  _P('ingles', 4, 'adjetivos comparativos',
     'What is the comparative form of "tall"?',
     'Taller', 'More tall', 'Tallest', 'Most tall',
     'Tall→Taller (comparativo). Tallest = superlativo (el más alto).'),

  _P('ingles', 4, 'vocabulario del hogar y escuela',
     'How do you say "sala de estar" in English?',
     'Living room', 'Kitchen', 'Bathroom', 'Bedroom',
     'Living room = sala de estar. Kitchen = cocina, Bathroom = baño, Bedroom = habitación.'),

  _P('ingles', 4, 'presente simple verbos de acción',
     'Which is correct with "they" in simple present?',
     'They go to the park', 'They goes to the park', 'They is going to the park', 'They gos to the park',
     'Con they (y I/you/we) el verbo no lleva -s: they go. Solo con he/she/it: he goes.'),

  _P('ingles', 4, 'días meses estaciones',
     'How do you say "invierno" in English?',
     'Winter', 'Summer', 'Spring', 'Autumn',
     'Winter = invierno. Summer = verano, Spring = primavera, Autumn/Fall = otoño.'),

  // INGLÉS GRADO 5
  _P('ingles', 5, 'presente continuo',
     'Which sentence is in the present continuous?',
     'She is singing right now.', 'She sings every day.', 'She sang yesterday.', 'She will sing tomorrow.',
     'Presente continuo = to be + verbo-ing: is singing. Indica acción en progreso ahora mismo.'),

  _P('ingles', 5, 'pasado simple verbos regulares',
     'What is the simple past of "to walk"?',
     'Walked', 'Walks', 'Walking', 'Walk',
     'Verbos regulares forman el pasado con -ed: walk→walked, play→played, watch→watched.'),

  _P('ingles', 5, 'preposiciones de lugar',
     'Which preposition means "encima de" (touching the surface)?',
     'On', 'Under', 'In', 'Behind',
     '"On" = sobre una superficie en contacto: The book is on the table. Under = debajo, In = dentro.'),

  _P('ingles', 5, 'vocabulario de profesiones',
     'How do you say "médico" in English?',
     'Doctor', 'Teacher', 'Lawyer', 'Engineer',
     'Doctor = médico. Teacher = maestro, Lawyer = abogado, Engineer = ingeniero.'),

  _P('ingles', 5, 'pasado simple verbos regulares',
     'Which sentence is in the simple past?',
     'I played soccer yesterday.', 'I play soccer every day.', 'I am playing soccer.', 'I will play soccer.',
     '"I played soccer yesterday" usa pasado simple (played = past of play). "Yesterday" confirma la acción concluida.'),

  _P('ingles', 5, 'preposiciones de lugar',
     'Which preposition means "debajo de"?',
     'Under', 'On', 'Above', 'Between',
     'Under = debajo de: The cat is under the table. On = sobre, Above = por encima sin contacto.'),

  _P('ingles', 5, 'pasado simple verbos irregulares',
     'What is the simple past of the irregular verb "to go"?',
     'Went', 'Goed', 'Gone', 'Going',
     '"Went" es el pasado irregular de "go". Otros irregulares: see→saw, eat→ate, have→had.',
     dif: 2),

  _P('ingles', 5, 'vocabulario de profesiones',
     'How do you say "enfermero/a" in English?',
     'Nurse', 'Teacher', 'Lawyer', 'Waiter',
     'Nurse = enfermero/a. Teacher = maestro, Lawyer = abogado, Waiter = mesero.'),

  _P('ingles', 5, 'presente continuo',
     'Which is the correct present continuous with "we"?',
     'We are playing', 'We is playing', 'We am playing', 'We playing',
     '"We are playing" es correcto. Presente continuo: I am / he,she,it is / we,you,they are + verbo-ing.'),

  _P('ingles', 5, 'comprensión de textos cortos',
     'What does "The cat is on the table" mean?',
     'El gato está encima de la mesa', 'El gato está debajo de la mesa', 'El gato está detrás de la mesa', 'El gato está al lado de la mesa',
     '"On" = encima (en contacto). Under = debajo, Behind = detrás, Next to = al lado.'),
];
