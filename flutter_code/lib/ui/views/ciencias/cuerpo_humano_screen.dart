import 'dart:async';
import 'dart:convert';
import 'dart:math' show sin, pi;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/providers/app_state_provider.dart';
import '../../../data/providers/database_provider.dart';
import '../../../data/models/sync_queue_model.dart';
import '../terminado.dart';

const _p4 = 'assets/images/actividades/ciencias_naturales/pantalla 4/';
const _p5 = 'assets/images/actividades/ciencias_naturales/pantalla 5/';
const _p6 = 'assets/images/actividades/ciencias_naturales/pantalla 6/';

// ── Popup de retroalimentación ────────────────────────────────────────────
void _mostrarFeedback(BuildContext context, bool correcto) {
  final overlay = Overlay.of(context);
  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => Positioned(
      top: 0, left: 0, right: 0, bottom: 0,
      child: IgnorePointer(
        child: Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              decoration: BoxDecoration(
                color: correcto ? const Color(0xFF2E7D32) : const Color(0xFFB71C1C),
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 20, offset: Offset(0, 4))],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(correcto ? Icons.check_circle_rounded : Icons.cancel_rounded,
                      color: Colors.white, size: 30),
                  const SizedBox(width: 10),
                  Text(correcto ? '¡Correcto!' : '¡Incorrecto!',
                      style: const TextStyle(color: Colors.white, fontSize: 20,
                          fontWeight: FontWeight.bold, fontFamily: 'Hiruko')),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
  overlay.insert(entry);
  Future.delayed(const Duration(milliseconds: 1100), () {
    if (entry.mounted) entry.remove();
  });
}

// Pantalla principal que contiene las 3 actividades
class CuerpoHumanoScreen extends ConsumerStatefulWidget {
  const CuerpoHumanoScreen({super.key});

  @override
  ConsumerState<CuerpoHumanoScreen> createState() => _CuerpoHumanoScreenState();
}

class _CuerpoHumanoScreenState extends ConsumerState<CuerpoHumanoScreen> {
  final _ctrl = PageController();
  int _pagina = 0;
  bool _navegandoATerminado = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _siguiente() {
    if (_pagina < 2) {
      _ctrl.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _guardarProgreso() async {
    final estudiante = ref.read(estudianteActivoProvider);
    if (estudiante == null || estudiante.id == null) return;
    final repo = ref.read(progresoRepositoryProvider);
    final queue = ref.read(syncQueueRepositoryProvider);
    await repo.registrarIntento(
      estudianteId: estudiante.id!,
      grado: estudiante.grado,
      materia: 'ciencias',
      actividad: 'Cuerpo humano',
      porcentaje: 100.0,
    );
    await queue.encolar(SyncQueueModel(
      tipoAccion: 'progreso',
      payload: jsonEncode({
        'estudianteId': estudiante.id,
        'grado': estudiante.grado,
        'materia': 'ciencias',
        'actividad': 'Cuerpo humano',
        'porcentaje': 100.0,
      }),
      fecha: DateTime.now().toIso8601String(),
    ));
  }

  void _irATerminado() {
    if (_navegandoATerminado || !mounted) return;
    _navegandoATerminado = true;
    _guardarProgreso();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ActividadTerminadaScreen(
          onVolver: () {
            final nav = Navigator.of(context);
            nav.pop();
            nav.pop();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          PageView(
            controller: _ctrl,
            onPageChanged: (i) => setState(() => _pagina = i),
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _PageCard(
                title: 'Cuerpo humano',
                dots: _buildDots(),
                child: _Actividad1(onNext: _siguiente),
              ),
              _PageCard(
                title: 'Cuerpo humano',
                dots: _buildDots(),
                child: _Actividad2(onNext: _siguiente),
              ),
              _PageCard(
                title: 'Cuerpo humano',
                dots: _buildDots(),
                child: _Actividad3(onFinish: _irATerminado),
              ),
            ],
          ),
          // Botón X flotante sobre el header verde
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 12, right: 16),
                child: GestureDetector(
                  onTap: () => Navigator.of(context).maybePop(),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.35),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close, color: Colors.white, size: 20),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDots() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14, top: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(3, (i) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.symmetric(horizontal: 5),
            width: _pagina == i ? 14 : 10,
            height: 10,
            decoration: BoxDecoration(
              color: _pagina == i ? const Color(0xFF3DCC52) : const Color(0xFFCCCCCC),
              borderRadius: BorderRadius.circular(5),
            ),
          );
        }),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ACTIVIDAD 1
// ─────────────────────────────────────────────────────────────────────────────

class _Forma {
  final Offset centro;
  final double radio;
  const _Forma(this.centro, this.radio);
  bool contiene(Offset p) => (p - centro).distance <= radio;
}

class _ZonaCuerpo {
  final String nombre;
  final List<_Forma> formas;
  const _ZonaCuerpo(this.nombre, this.formas);
  bool contiene(Offset p) => formas.any((f) => f.contiene(p));
}

class _Actividad1 extends StatefulWidget {
  final VoidCallback onNext;
  const _Actividad1({required this.onNext});
  @override
  State<_Actividad1> createState() => _Actividad1State();
}

class _Actividad1State extends State<_Actividad1>
    with SingleTickerProviderStateMixin {
  static const _zonas = [
    _ZonaCuerpo('ojos', [
      _Forma(Offset(0.32, 0.40), 0.11),
      _Forma(Offset(0.73, 0.40), 0.11),
    ]),
    _ZonaCuerpo('manos', [
      _Forma(Offset(0.15, 0.77), 0.04),
      _Forma(Offset(0.88, 0.77), 0.04),
    ]),
    _ZonaCuerpo('piernas', [
      _Forma(Offset(0.42, 0.93), 0.08),
      _Forma(Offset(0.64, 0.93), 0.08),
      _Forma(Offset(0.44, 0.97), 0.048),
      _Forma(Offset(0.62, 0.97), 0.048),
    ]),
  ];

  static const _preguntas = ['ojos', 'manos', 'piernas'];

  int _ronda = 0;
  bool? _acierto;
  Size? _imageSize;
  Size _containerSize = Size.zero;

  late final AnimationController _shake = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 500),
  );

  @override
  void initState() {
    super.initState();
    _cargarTamanioImagen();
  }

  Future<void> _cargarTamanioImagen() async {
    final completer = Completer<ui.Image>();
    final stream =
        const AssetImage('${_p4}niño.png').resolve(const ImageConfiguration());
    late ImageStreamListener listener;
    listener = ImageStreamListener((info, _) {
      if (!completer.isCompleted) completer.complete(info.image);
      stream.removeListener(listener);
    });
    stream.addListener(listener);
    final img = await completer.future;
    if (mounted) {
      setState(
          () => _imageSize = Size(img.width.toDouble(), img.height.toDouble()));
    }
  }

  Offset _normalizarEnImagen(Offset local) {
    if (_imageSize == null) {
      return Offset(
          local.dx / _containerSize.width, local.dy / _containerSize.height);
    }
    final imgAspect = _imageSize!.width / _imageSize!.height;
    final ctnAspect = _containerSize.width / _containerSize.height;

    double imgLeft, imgTop, imgW, imgH;
    if (imgAspect > ctnAspect) {
      imgW = _containerSize.width;
      imgH = _containerSize.width / imgAspect;
      imgLeft = 0;
      imgTop = (_containerSize.height - imgH) / 2;
    } else {
      imgH = _containerSize.height;
      imgW = _containerSize.height * imgAspect;
      imgLeft = (_containerSize.width - imgW) / 2;
      imgTop = 0;
    }

    return Offset(
      ((local.dx - imgLeft) / imgW).clamp(0.0, 1.0),
      ((local.dy - imgTop) / imgH).clamp(0.0, 1.0),
    );
  }

  void _onTap(BuildContext context, Offset local) {
    if (_acierto != null) return;
    final normalizado = _normalizarEnImagen(local);
    final objetivo = _preguntas[_ronda];
    final zona = _zonas.firstWhere((z) => z.nombre == objetivo);
    final correcto = zona.contiene(normalizado);

    setState(() => _acierto = correcto);
    _mostrarFeedback(context, correcto);

    if (correcto) {
      Future.delayed(const Duration(milliseconds: 900), () {
        if (!mounted) return;
        setState(() {
          _acierto = null;
          _ronda++;
        });
        if (_ronda >= _preguntas.length) {
          Future.delayed(const Duration(milliseconds: 300), widget.onNext);
        }
      });
    } else {
      _shake.forward(from: 0);
      Future.delayed(const Duration(milliseconds: 1000), () {
        if (mounted) setState(() => _acierto = null);
      });
    }
  }

  @override
  void dispose() {
    _shake.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_ronda >= _preguntas.length) return const SizedBox();
    final objetivo = _preguntas[_ronda];

    return _Tarjeta(
      child: Column(
        children: [
          const _Instruccion('Toca la parte del cuerpo'),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: LayoutBuilder(
                builder: (ctx, constraints) {
                  _containerSize = constraints.biggest;
                  return GestureDetector(
                    onTapDown: (details) {
                      final box = ctx.findRenderObject() as RenderBox;
                      final local = box.globalToLocal(details.globalPosition);
                      _onTap(ctx, local);
                    },
                    child: AnimatedBuilder(
                      animation: _shake,
                      builder: (_, child) {
                        final dx = _acierto == false
                            ? 8.0 * sin(_shake.value * pi * 5)
                            : 0.0;
                        return Transform.translate(
                            offset: Offset(dx, 0), child: child);
                      },
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.asset('${_p4}niño.png', fit: BoxFit.contain, filterQuality: ui.FilterQuality.high),
                          if (_acierto != null)
                            Container(
                              decoration: BoxDecoration(
                                color: _acierto!
                                    ? const Color(0x3300CC44)
                                    : const Color(0x33FF3333),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Icon(
                                  _acierto!
                                      ? Icons.check_circle_rounded
                                      : Icons.cancel_rounded,
                                  color: _acierto!
                                      ? const Color(0xFF2E7D32)
                                      : const Color(0xFFB71C1C),
                                  size: 60,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Text(
              objetivo[0].toUpperCase() + objetivo.substring(1),
              style: const TextStyle(
                  fontFamily: 'Hiruko',
                  fontSize: 28,
                  fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Componentes visuales reutilizables
// ─────────────────────────────────────────────────────────────────────────────

class _Tarjeta extends StatelessWidget {
  final Widget child;
  const _Tarjeta({required this.child});
  @override
  Widget build(BuildContext context) => child;
}

class _PageCard extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget dots;
  const _PageCard({required this.title, required this.child, required this.dots});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Fondo verde que cubre la mitad superior
        Container(color: const Color(0xFF3DCC52)),
        Column(
          children: [
            // Bloque verde — título centrado, extenso
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 18, 52, 48),
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Hiruko',
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            // Bloque blanco con esquinas superiores redondeadas
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(32),
                    topRight: Radius.circular(32),
                  ),
                ),
                child: Column(
                  children: [
                    Expanded(child: child),
                    dots,
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Instruccion extends StatelessWidget {
  final String texto;
  const _Instruccion(this.texto);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.volume_up_rounded,
                color: Color(0xFF3DCC52), size: 22),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              texto,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                color: Color(0xFF424242),
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// ACTIVIDAD 2: Armar la niña (Libre posicionamiento)
//
// El niño arrastra cada pieza a cualquier parte del área de juego.
// Al presionar "Verificar", se evalúa si cada pieza está dentro de su
// zona correcta (toleranceRect). No hay silueta visible como guía.
// ═════════════════════════════════════════════════════════════════════════════

class _PiezaCuerpo {
  final String nombre;
  final String ruta;
  final Rect toleranceRect;
  // anchoFraccion: fracción del ANCHO del área. altoFraccion: fracción del ALTO.
  // Definir ambos por separado para respetar la proporción real de cada imagen.
  final double anchoFraccion;
  final double altoFraccion;
  const _PiezaCuerpo(
    this.nombre,
    this.ruta, {
    required this.toleranceRect,
    required this.anchoFraccion,
    required this.altoFraccion,
  });
}

// Posición de cada pieza en el área libre (fracción 0..1 relativa al área).
class _PiezaEstado {
  final String nombre;
  Offset posicion; // centro de la pieza (fracción del área)
  bool colocada;   // true = fue arrastrada al área de juego
  _PiezaEstado(this.nombre, {required this.posicion, this.colocada = false});
}

class _Actividad2 extends StatefulWidget {
  final VoidCallback onNext;
  const _Actividad2({required this.onNext});
  @override
  State<_Actividad2> createState() => _Actividad2State();
}

class _Actividad2State extends State<_Actividad2> {
  // toleranceRect: zona válida para verificación (fracción del área).
  // anchoFraccion / altoFraccion: se calculan en initState() a partir de
  // las dimensiones REALES de cada imagen para que sean siempre proporcionales.
  static const _piezasBase = [
    _PiezaCuerpo('piernas', '${_p5}piernas.png',
        toleranceRect: Rect.fromLTWH(0.00, 0.30, 1.00, 0.70),
        anchoFraccion: 0.55, altoFraccion: 0.35),
    _PiezaCuerpo('manos', '${_p5}manos.png',
        toleranceRect: Rect.fromLTWH(0.00, 0.10, 1.00, 0.80),
        anchoFraccion: 0.88, altoFraccion: 0.15),
    _PiezaCuerpo('camisa', '${_p5}camisa.png',
        toleranceRect: Rect.fromLTWH(0.05, 0.10, 0.90, 0.80),
        anchoFraccion: 0.65, altoFraccion: 0.28),
    _PiezaCuerpo('cabeza', '${_p5}cabeza.png',
        toleranceRect: Rect.fromLTWH(0.00, 0.00, 1.00, 0.60),
        anchoFraccion: 0.55, altoFraccion: 0.30),
    _PiezaCuerpo('cabello', '${_p5}cabello.png',
        toleranceRect: Rect.fromLTWH(0.00, 0.00, 1.00, 0.50),
        anchoFraccion: 0.62, altoFraccion: 0.22),
    _PiezaCuerpo('ojos', '${_p5}ojos.png',
        toleranceRect: Rect.fromLTWH(0.20, 0.05, 0.60, 0.30),
        anchoFraccion: 0.06, altoFraccion: 0.02),
    _PiezaCuerpo('boca', '${_p5}boca.png',
        toleranceRect: Rect.fromLTWH(0.20, 0.10, 0.60, 0.40),
        anchoFraccion: 0.08, altoFraccion: 0.03),
  ];

  static const _renderOrder = ['cabello', 'piernas', 'manos', 'camisa', 'cabeza', 'ojos', 'boca'];

  // Lista definitiva con fracciones recalculadas según dimensiones reales.
  List<_PiezaCuerpo> _piezas = List.of(_piezasBase);

  late List<_PiezaEstado> _estados;
  bool _verificado = false;
  bool _imagenesListas = false;

  final _areaKey = GlobalKey();
  final Map<String, Offset> _touchOffset = {};

  @override
  void initState() {
    super.initState();
    _inicializarEstados();
    _calcularFraccionesDesdeImagenes();
  }

  // Carga las dimensiones reales de cada imagen y recalcula anchoFraccion /
  // altoFraccion manteniendo la proporción original de cada asset.
  // La cabeza se toma como referencia con anchoFraccion = 0.50.
  Future<void> _calcularFraccionesDesdeImagenes() async {
    final Map<String, Size> sizes = {};

    for (final p in _piezasBase) {
      try {
        final completer = Completer<ui.Image>();
        final stream = AssetImage(p.ruta).resolve(const ImageConfiguration());
        late ImageStreamListener listener;
        listener = ImageStreamListener((info, _) {
          if (!completer.isCompleted) {
            completer.complete(info.image);
          }
          stream.removeListener(listener);
        });
        stream.addListener(listener);
        final img = await completer.future;
        sizes[p.nombre] = Size(img.width.toDouble(), img.height.toDouble());
      } catch (_) {
        // Si falla, usar fracciones base
        sizes[p.nombre] = const Size(100, 100);
      }
    }

    if (!mounted) return;

    // La cabeza es la referencia: anchoFraccion = 0.50
    // Todas las demás piezas se escalan proporcionalmente respecto a la cabeza.
    final cabezaSize = sizes['cabeza']!;
    const cabezaAncho = 0.50;

    final List<_PiezaCuerpo> nuevas = _piezasBase.map((p) {
      final imgSize = sizes[p.nombre]!;
      // Factor de escala = ancho de cabeza en px / ancho en fracción
      // → pixelesPorFraccion = cabezaSize.width / cabezaAncho
      // → anchoFrac_pieza = imgSize.width / pixelesPorFraccion
      final pixelesPorFraccion = cabezaSize.width / cabezaAncho;

      // Reducción general de tamaño para todas las piezas y ajustes específicos para encaje
      double escalaEspecial = 0.7; 
      if (p.nombre == 'ojos' || p.nombre == 'boca') {
        escalaEspecial = 0.25; // Ojos y boca muy pequeños para la cara
      } else if (p.nombre == 'camisa') {
        escalaEspecial = 0.60; // Camisa un poco más grande para el torso
      } else if (p.nombre == 'piernas') {
        escalaEspecial = 0.40; // Piernas ajustadas para proporcionalidad
      } else if (p.nombre == 'manos') {
        escalaEspecial = 0.60; // Brazos un poquito más grandes para mejor encaje
      } else if (p.nombre == 'cabello') {
        escalaEspecial = 0.85; // Cabello proporcional pero enviado al fondo
      }

      final anchoFrac = (imgSize.width  / pixelesPorFraccion * escalaEspecial).clamp(0.05, 0.95);
      final altoFrac  = (imgSize.height / pixelesPorFraccion * escalaEspecial).clamp(0.02, 0.50);

      return _PiezaCuerpo(
        p.nombre,
        p.ruta,
        toleranceRect: p.toleranceRect,
        anchoFraccion: anchoFrac,
        altoFraccion:  altoFrac,
      );
    }).toList();

    setState(() {
      _piezas = nuevas;
      _imagenesListas = true;
    });
  }

  void _inicializarEstados() {
    _estados = _piezasBase
        .map((p) => _PiezaEstado(p.nombre, posicion: const Offset(-999, -999)))
        .toList();
  }

  bool _estaEnArea(String nombre) =>
      _estados.firstWhere((e) => e.nombre == nombre).colocada;

  bool get _todoColocado => _estados.every((e) => e.colocada);

  bool _esCorrecto(String nombre) {
    final e = _estados.firstWhere((e) => e.nombre == nombre);
    final p = _piezas.firstWhere((p) => p.nombre == nombre);

    // 1. La Camisa es nuestro punto de referencia principal (ancla)
    if (nombre == 'camisa') return p.toleranceRect.contains(e.posicion);

    // 2. Partes que dependen de la Camisa (Cabeza, Manos, Piernas)
    if (nombre == 'cabeza' || nombre == 'manos' || nombre == 'piernas') {
      final eCamisa = _estados.firstWhere((est) => est.nombre == 'camisa');
      if (!eCamisa.colocada) return false;

      final diff = e.posicion - eCamisa.posicion;
      final distancia = diff.distance;
      
      if (nombre == 'cabeza') return distancia < 0.25 && diff.dy < -0.12 && diff.dx.abs() < 0.10;
      if (nombre == 'piernas') return distancia < 0.32 && diff.dy > 0.18 && diff.dx.abs() < 0.10;
      if (nombre == 'manos') return distancia < 0.25 && diff.dy.abs() < 0.12; 
    }

    // 3. Partes que dependen de la Cabeza (Ojos, Boca, Cabello)
    if (nombre == 'ojos' || nombre == 'boca' || nombre == 'cabello') {
      final eCabeza = _estados.firstWhere((estado) => estado.nombre == 'cabeza');
      if (!eCabeza.colocada) return false;
      
      final diff = e.posicion - eCabeza.posicion;
      final distancia = diff.distance;

      // Ojos y boca ahora exigen estar más al centro de la cara
      final margen = (nombre == 'cabello') ? 0.22 : 0.14;
      return distancia < margen && (nombre != 'cabello' || diff.dy < 0);
    }

    return p.toleranceRect.contains(e.posicion);
  }

  bool get _todoOk => _piezas.every((p) => _esCorrecto(p.nombre));

  Set<String> get _enBandeja =>
      _piezas.map((p) => p.nombre).where((n) => !_estaEnArea(n)).toSet();

  void _verificar(BuildContext context) {
    setState(() => _verificado = true);
    _mostrarFeedback(context, _todoOk);
    if (_todoOk) Future.delayed(const Duration(seconds: 1), widget.onNext);
  }

  void _reintentar() {
    setState(() {
      for (final e in _estados) {
        if (!_esCorrecto(e.nombre)) {
          e.colocada = false;
          e.posicion = const Offset(-999, -999);
        }
      }
      _verificado = false;
    });
  }

  void _colocarPieza(String nombre, Offset globalPointer, Offset touchOff) {
    final ro = _areaKey.currentContext?.findRenderObject() as RenderBox?;
    if (ro == null) return;

    final areaSize   = ro.size;
    final globalTopLeft = globalPointer - touchOff;
    final localTopLeft  = ro.globalToLocal(globalTopLeft);

    final p   = _piezas.firstWhere((p) => p.nombre == nombre);
    final pxW = areaSize.width  * p.anchoFraccion;
    final pxH = areaSize.height * p.altoFraccion;

    final centerX = localTopLeft.dx + pxW / 2;
    final centerY = localTopLeft.dy + pxH / 2;

    if (centerX < -pxW || centerX > areaSize.width  + pxW ||
        centerY < -pxH || centerY > areaSize.height + pxH) return;

    final fracX = (centerX / areaSize.width ).clamp(
        p.anchoFraccion / 2, 1.0 - p.anchoFraccion / 2);
    final fracY = (centerY / areaSize.height).clamp(
        p.altoFraccion  / 2, 1.0 - p.altoFraccion  / 2);

    setState(() {
      final e = _estados.firstWhere((e) => e.nombre == nombre);
      e.posicion = Offset(fracX, fracY);
      e.colocada = true;
      _verificado = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final enBandeja = _enBandeja;

    return _Tarjeta(
      child: Column(
        children: [
          const _Instruccion('¡Arma la niña! Arrastra cada parte a su lugar'),

          Expanded(
            flex: 5,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
              child: LayoutBuilder(builder: (_, constraints) {
                final areaW = constraints.maxWidth;
                final areaH = constraints.maxHeight;

                return Container(
                  key: _areaKey,
                  width: areaW,
                  height: areaH,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5FFF6),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFBBEEC4), width: 1.5),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: Stack(
                      clipBehavior: Clip.hardEdge,
                      children: [
                        if (_enBandeja.length == _piezas.length)
                          const Center(
                            child: Text('⬆ Arrastra las piezas aquí',
                                style: TextStyle(
                                    color: Color(0xFF9E9E9E),
                                    fontSize: 13,
                                    fontFamily: 'Poppins')),
                          ),

                        ..._renderOrder.map((nombre) {
                          final e = _estados.firstWhere((e) => e.nombre == nombre);
                          if (!e.colocada) return const SizedBox.shrink();
                          final p = _piezas.firstWhere((p) => p.nombre == nombre);

                          final pxW  = areaW * p.anchoFraccion;
                          final pxH  = areaH * p.altoFraccion;
                          final left = (e.posicion.dx * areaW - pxW / 2)
                              .clamp(0.0, (areaW - pxW).clamp(0.0, areaW));
                          final top  = (e.posicion.dy * areaH - pxH / 2)
                              .clamp(0.0, (areaH - pxH).clamp(0.0, areaH));
                          final correcto = _verificado ? _esCorrecto(nombre) : null;

                          return Positioned(
                            left: left, top: top, width: pxW, height: pxH,
                            child: Listener(
                              onPointerDown: (ev) {
                                _touchOffset[nombre] = ev.localPosition;
                              },
                              child: Draggable<String>(
                                data: nombre,
                                dragAnchorStrategy: pointerDragAnchorStrategy,
                                feedback: Material(
                                  color: Colors.transparent,
                                  child: Opacity(
                                    opacity: 0.9,
                                    child: SizedBox(
                                      width: pxW, height: pxH, 
                                      child: Image.asset(p.ruta, fit: BoxFit.contain, filterQuality: FilterQuality.high),
                                    ),
                                  ),
                                ),
                                childWhenDragging: Opacity(
                                  opacity: 0.25,
                                  child: SizedBox(
                                    width: pxW, height: pxH, 
                                    child: Image.asset(p.ruta, fit: BoxFit.contain, filterQuality: FilterQuality.high),
                                  ),
                                ),
                                onDragEnd: (details) {
                                  final touch = _touchOffset[nombre] ??
                                      Offset(pxW / 2, pxH / 2);
                                  _colocarPieza(nombre, details.offset, touch);
                                },
                                child: Stack(children: [
                                  SizedBox(
                                    width: pxW, height: pxH,
                                    child: Image.asset(p.ruta, fit: BoxFit.contain, filterQuality: FilterQuality.high),
                                  ),
                                  if (correcto != null)
                                    Positioned.fill(
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: correcto
                                              ? const Color(0x2200CC44)
                                              : const Color(0x44FF0000),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Center(
                                          child: Icon(
                                            correcto
                                                ? Icons.check_circle_rounded
                                                : Icons.cancel_rounded,
                                            color: correcto
                                                ? const Color(0xFF2E7D32)
                                                : const Color(0xFFB71C1C),
                                            size: 24,
                                          ),
                                        ),
                                      ),
                                    ),
                                ]),
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),

          if (_todoColocado && !_verificado)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: ElevatedButton.icon(
                onPressed: () => _verificar(context),
                icon: const Icon(Icons.check_rounded),
                label: const Text('Verificar',
                    style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3DCC52),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 3,
                ),
              ),
            )
          else if (_verificado && !_todoOk)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: ElevatedButton.icon(
                onPressed: _reintentar,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Reintentar',
                    style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE53935),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 3,
                ),
              ),
            ),

          if (enBandeja.isNotEmpty)
            SizedBox(
              height: 100,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.only(left: 6, right: 6, top: 4, bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: _piezas
                      .where((p) => enBandeja.contains(p.nombre))
                      .map((p) {
                        const thumbSize = 72.0;
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Listener(
                            onPointerDown: (ev) {
                              _touchOffset[p.nombre] = ev.localPosition;
                            },
                            child: Draggable<String>(
                              data: p.nombre,
                              dragAnchorStrategy: pointerDragAnchorStrategy,
                              feedback: Material(
                                color: Colors.transparent,
                                child: Opacity(
                                  opacity: 0.9,
                                  child: SizedBox(
                                      width: thumbSize, height: thumbSize, 
                                      child: Image.asset(p.ruta, fit: BoxFit.contain, filterQuality: FilterQuality.high),
                                  ),
                                ),
                              ),
                              childWhenDragging: Opacity(
                                opacity: 0.30,
                                child: _piezaEnBandeja(p.nombre, p.ruta),
                              ),
                              onDragEnd: (details) {
                                // Desde la bandeja: compensar el centro del thumbnail
                                const touch = Offset(thumbSize / 2, thumbSize / 2);
                                _colocarPieza(p.nombre, details.offset, touch);
                              },
                              child: _piezaEnBandeja(p.nombre, p.ruta),
                            ),
                          ),
                        );
                      })
                      .toList(),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _piezaEnBandeja(String nombre, String ruta) {
    final label = nombre[0].toUpperCase() + nombre.substring(1);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 72, height: 72,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF3DCC52), width: 1.5),
            boxShadow: const [
              BoxShadow(color: Color(0x22000000), blurRadius: 6, offset: Offset(0, 3))
            ],
          ),
          child: Image.asset(ruta, fit: BoxFit.contain, filterQuality: FilterQuality.high),
        ),
        const SizedBox(height: 2),
        Text(label,
            style: const TextStyle(
                fontSize: 10,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
                color: Color(0xFF444444))),
      ],
    );
  }
}


// Pintor de debug: muestra los hitRect de cada pieza sobre la silueta.
// Actívalo con _mostrarDebug = true para calibrar las zonas de drop.
class _DebugHitPainter extends CustomPainter {
  final List<_PiezaCuerpo> piezas;
  final Rect imgRect;

  const _DebugHitPainter({required this.piezas, required this.imgRect});

  static const _colores = [
    Color(0xFFE53935), // piernas  → rojo
    Color(0xFF1E88E5), // manos    → azul
    Color(0xFFFDD835), // camisa   → amarillo
    Color(0xFFFB8C00), // cabeza   → naranja
    Color(0xFF8E24AA), // ojos     → morado
    Color(0xFF00897B), // cabello  → verde azulado
  ];

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < piezas.length; i++) {
      final p = piezas[i];
      final color = _colores[i % _colores.length];

      final rect = Rect.fromLTWH(
        imgRect.left + p.toleranceRect.left * imgRect.width,
        imgRect.top + p.toleranceRect.top * imgRect.height,
        p.toleranceRect.width * imgRect.width,
        p.toleranceRect.height * imgRect.height,
      );

      canvas.drawRect(
          rect,
          Paint()
            ..color = color.withOpacity(0.15)
            ..style = PaintingStyle.fill);

      canvas.drawRect(
          rect,
          Paint()
            ..color = color
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5);

      final tp = TextPainter(
        text: TextSpan(
          text: p.nombre,
          style: TextStyle(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.bold,
            background: Paint()..color = Colors.white.withOpacity(0.7),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, rect.topLeft + const Offset(3, 3));
    }
  }

  @override
  bool shouldRepaint(covariant _DebugHitPainter old) =>
      old.imgRect != imgRect;
}

// ─────────────────────────────────────────────────────────────────────────────
// ACTIVIDAD 3: Sentidos y funciones
// ─────────────────────────────────────────────────────────────────────────────

class _Actividad3 extends StatefulWidget {
  final VoidCallback onFinish;
  const _Actividad3({required this.onFinish});
  @override
  State<_Actividad3> createState() => _Actividad3State();
}

class _Actividad3State extends State<_Actividad3> {
  final _preguntas = [
    {'txt': '¿Con qué parte del cuerpo puedo mirar el arcoíris?', 'ans': 'vista'},
    {'txt': '¿Con qué parte del cuerpo escucho música?', 'ans': 'oido'},
    {'txt': '¿Con qué parte del cuerpo siento si algo está caliente?', 'ans': 'tacto'},
    {'txt': '¿Con qué parte del cuerpo saboreo un helado?', 'ans': 'gusto'},
  ];

  final _botones = [
    {'id': 'vista', 'img': '${_p6}boton vista.png', 'c': const Color(0xFF1565C0)},
    {'id': 'oido',  'img': '${_p6}boton oido.png',  'c': const Color(0xFFE65100)},
    {'id': 'tacto', 'img': '${_p6}boton tacto.png', 'c': const Color(0xFF2E7D32)},
    {'id': 'gusto', 'img': '${_p6}boton gusto.png', 'c': const Color(0xFF6A1B9A)},
  ];

  int _ronda = 0;
  String? _seleccion;

  void _responder(BuildContext context, String id) {
    if (_seleccion != null) return;
    setState(() => _seleccion = id);
    final correcto = id == _preguntas[_ronda]['ans'];
    _mostrarFeedback(context, correcto);

    if (correcto) {
      Future.delayed(const Duration(milliseconds: 900), () {
        if (!mounted) return;
        if (_ronda < _preguntas.length - 1) {
          setState(() {
            _ronda++;
            _seleccion = null;
          });
        } else {
          widget.onFinish();
        }
      });
    } else {
      Future.delayed(const Duration(milliseconds: 900), () {
        if (mounted) setState(() => _seleccion = null);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return _Tarjeta(
      child: Column(
        children: [
          _Instruccion(_preguntas[_ronda]['txt']!),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  children: _botones.map((b) {
                    final esCorrecto = _seleccion == b['id'] &&
                        b['id'] == _preguntas[_ronda]['ans'];
                    final esError = _seleccion == b['id'] &&
                        b['id'] != _preguntas[_ronda]['ans'];
                    return GestureDetector(
                      onTap: () => _responder(context, b['id'] as String),
                      child: Container(
                    decoration: BoxDecoration(
                      color: b['c'] as Color,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: esCorrecto
                            ? Colors.greenAccent
                            : (esError ? Colors.red : Colors.transparent),
                        width: 4,
                      ),
                    ),
                        child: Image.asset(b['img'] as String, filterQuality: ui.FilterQuality.high),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}