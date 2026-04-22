import 'dart:async';
import 'dart:convert';
import 'dart:math' show sin, pi, Random;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart'; // ✅ media_kit en lugar de just_audio
import '../../../data/providers/app_state_provider.dart';
import '../../../data/providers/database_provider.dart';
import '../../../data/models/sync_queue_model.dart';
import '../terminado.dart';

const _p4 = 'assets/images/actividades/ciencias_naturales/pantalla 4/';
const _p5 = 'assets/images/actividades/ciencias_naturales/pantalla 5/';
const _p6 = 'assets/images/actividades/ciencias_naturales/pantalla 6/';

// ── Rutas de audio ───────────────────────────────────────────────────────────
const _audio4 = 'assets/images/actividades/ciencias_naturales/audios/audio_naturales4_mezcla.mp3';
const _audio5 = 'assets/images/actividades/ciencias_naturales/audios/audio_naturales5_mezcla.mp3';
const _audio6 = 'assets/images/actividades/ciencias_naturales/audios/audio_naturales6_mezcla.mp3';

// Audios por parte del cuerpo (Actividad 1)
const _audioOjos    = 'assets/images/actividades/ciencias_naturales/audios/audio_naturales4_ojos_mezcla.mp3';
const _audioManos   = 'assets/images/actividades/ciencias_naturales/audios/audio_naturales4_manos_mezcla.mp3';
const _audioPiernas = 'assets/images/actividades/ciencias_naturales/audios/audio_naturales4_piernas_mezcla.mp3';

// Audios por pregunta (Actividad 3)
const _audioAct3Vista  = 'assets/images/actividades/ciencias_naturales/audios/audio_naturales6_arcoiris_mezcla.mp3';
const _audioAct3Oido   = 'assets/images/actividades/ciencias_naturales/audios/audio_naturales6_musica_mezcla.mp3';
const _audioAct3Tacto  = 'assets/images/actividades/ciencias_naturales/audios/audio_naturales6_objetos_mezcla.mp3';
const _audioAct3Gusto  = 'assets/images/actividades/ciencias_naturales/audios/audio_naturales6_alimentos_mezcla.mp3';

// ── Helper: reproduce un asset con media_kit ─────────────────────────────────
Future<void> _playAsset(Player player, String assetPath) async {
  try {
    await player.open(Media('asset:///$assetPath'));
  } catch (e) {
    debugPrint('Error al reproducir audio ($assetPath): $e');
  }
}

// ── Popup de retroalimentación ────────────────────────────────────────────
void _mostrarFeedback(BuildContext context, bool correcto, {VoidCallback? onAction}) {
  showModalBottomSheet(
    context: context,
    isDismissible: false,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return Container(
        padding: const EdgeInsets.all(30),
        decoration: BoxDecoration(
          color: correcto ? const Color(0xFFD7FFD3) : const Color(0xFFFFD3D3),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(
                  correcto ? Icons.check_circle : Icons.cancel,
                  color: correcto ? const Color(0xFF59E347) : const Color(0xFFF65757),
                  size: 40,
                ),
                const SizedBox(width: 15),
                Text(
                  correcto ? '¡Excelente trabajo!' : '¡Casi lo tienes!',
                  style: TextStyle(
                    fontFamily: 'Hiruko',
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: correcto ? Colors.green[900] : Colors.red[900],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: correcto ? const Color(0xFF59E347) : const Color(0xFFF65757),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  onAction?.call();
                },
                child: Text(
                  correcto ? 'Continuar' : 'Reintentar',
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Pantalla principal que contiene las 3 actividades
// ─────────────────────────────────────────────────────────────────────────────

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

  final Player _playerInstruccion = Player();
  final Player _playerParte       = Player();

  static const _audioPorParte = {
    'ojos':    _audioOjos,
    'manos':   _audioManos,
    'piernas': _audioPiernas,
  };

  late final AnimationController _shake = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 500),
  );

  Future<void> _playAudioParte(String parte) async {
    final assetPath = _audioPorParte[parte];
    if (assetPath == null) return;
    await _playAsset(_playerParte, assetPath);
  }

  @override
  void initState() {
    super.initState();
    _cargarTamanioImagen();

    // ✅ CORRECCIÓN: espera a que termine _audio4 antes de reproducir
    // el audio de la primera parte del cuerpo (ojos).
    Future.microtask(() async {
      if (!mounted) return;

      // 1. Reproduce la instrucción general
      await _playAsset(_playerInstruccion, _audio4);

      // 2. Espera a que el stream confirme que terminó de reproducirse
      await _playerInstruccion.stream.completed
          .firstWhere((done) => done);

      // 3. Solo entonces reproduce el audio de la primera parte
      if (mounted) await _playAudioParte(_preguntas[0]);
    });
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
    if (!correcto) _shake.forward(from: 0);

    _mostrarFeedback(context, correcto, onAction: () {
      if (correcto) {
        setState(() {
          _acierto = null;
          _ronda++;
        });
        if (_ronda >= _preguntas.length) {
          Future.delayed(const Duration(milliseconds: 300), widget.onNext);
        } else {
          _playAudioParte(_preguntas[_ronda]);
        }
      } else {
        setState(() => _acierto = null);
      }
    });
  }

  @override
  void dispose() {
    _shake.dispose();
    _playerInstruccion.dispose();
    _playerParte.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_ronda >= _preguntas.length) return const SizedBox();
    final objetivo = _preguntas[_ronda];

    return _Tarjeta(
      child: Column(
        children: [
          _Instruccion(
            'Toca la parte del cuerpo',
            player: _playerInstruccion,
            audioPath: _audio4,
          ),
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
        Container(color: const Color(0xFF3DCC52)),
        Column(
          children: [
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

class _Instruccion extends StatefulWidget {
  final String texto;
  final Player? player;
  final String? audioPath;
  const _Instruccion(this.texto, {this.player, this.audioPath});

  @override
  State<_Instruccion> createState() => _InstruccionState();
}

class _InstruccionState extends State<_Instruccion> {
  bool _reproduciendo = false;

  Future<void> _reproducir() async {
    if (widget.player == null || widget.audioPath == null) return;

    if (_reproduciendo) {
      await widget.player!.stop();
      if (mounted) setState(() => _reproduciendo = false);
      return;
    }

    if (mounted) setState(() => _reproduciendo = true);
    try {
      await widget.player!.open(Media('asset:///${widget.audioPath!}'));
      await widget.player!.stream.completed.firstWhere((done) => done);
    } catch (e) {
      debugPrint('Error reproduciendo audio: $e');
    } finally {
      if (mounted) setState(() => _reproduciendo = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: _reproducir,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _reproduciendo
                    ? const Color(0xFF3DCC52)
                    : const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.volume_up_rounded,
                color: _reproduciendo ? Colors.white : const Color(0xFF3DCC52),
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              widget.texto,
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
// ACTIVIDAD 2
// ═════════════════════════════════════════════════════════════════════════════

class _PiezaCuerpo {
  final String nombre;
  final String ruta;
  final Rect toleranceRect;
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

class _PiezaEstado {
  final String nombre;
  Offset posicion;
  bool colocada;
  _PiezaEstado(this.nombre, {required this.posicion, this.colocada = false});
}

class _Actividad2 extends StatefulWidget {
  final VoidCallback onNext;
  const _Actividad2({required this.onNext});
  @override
  State<_Actividad2> createState() => _Actividad2State();
}

class _Actividad2State extends State<_Actividad2> {
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

  List<_PiezaCuerpo> _piezas = List.of(_piezasBase);
  late List<_PiezaEstado> _estados;
  bool _verificado = false;
  bool _imagenesListas = false;

  final _areaKey = GlobalKey();
  final Map<String, Offset> _touchOffset = {};

  final Player _player = Player();

  Future<void> _playAudio() async {
    await _playAsset(_player, _audio5);
  }

  @override
  void initState() {
    super.initState();
    _inicializarEstados();
    _calcularFraccionesDesdeImagenes();
    Future.microtask(() {
      if (mounted) _playAudio();
    });
  }

  Future<void> _calcularFraccionesDesdeImagenes() async {
    final Map<String, Size> sizes = {};

    for (final p in _piezasBase) {
      try {
        final completer = Completer<ui.Image>();
        final stream = AssetImage(p.ruta).resolve(const ImageConfiguration());
        late ImageStreamListener listener;
        listener = ImageStreamListener((info, _) {
          if (!completer.isCompleted) completer.complete(info.image);
          stream.removeListener(listener);
        });
        stream.addListener(listener);
        final img = await completer.future;
        sizes[p.nombre] = Size(img.width.toDouble(), img.height.toDouble());
      } catch (_) {
        sizes[p.nombre] = const Size(100, 100);
      }
    }

    if (!mounted) return;

    final cabezaSize = sizes['cabeza']!;
    const cabezaAncho = 0.50;

    final List<_PiezaCuerpo> nuevas = _piezasBase.map((p) {
      final imgSize = sizes[p.nombre]!;
      final pixelesPorFraccion = cabezaSize.width / cabezaAncho;

      double escalaEspecial = 0.7;
      if (p.nombre == 'ojos' || p.nombre == 'boca') {
        escalaEspecial = 0.25;
      } else if (p.nombre == 'camisa') {
        escalaEspecial = 0.60;
      } else if (p.nombre == 'piernas') {
        escalaEspecial = 0.40;
      } else if (p.nombre == 'manos') {
        escalaEspecial = 0.60;
      } else if (p.nombre == 'cabello') {
        escalaEspecial = 0.85;
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

    if (nombre == 'camisa') {
      return e.posicion.dx >= 0.20 && e.posicion.dx <= 0.80 &&
             e.posicion.dy >= 0.25 && e.posicion.dy <= 0.75;
    }

    if (nombre == 'cabeza' || nombre == 'manos' || nombre == 'piernas') {
      final eCamisa = _estados.firstWhere((est) => est.nombre == 'camisa');
      if (!eCamisa.colocada) return p.toleranceRect.contains(e.posicion);
      final diff = e.posicion - eCamisa.posicion;
      if (nombre == 'cabeza') {
        return diff.dy < -0.08 && diff.dy > -0.45 && diff.dx.abs() < 0.28;
      }
      if (nombre == 'piernas') {
        return diff.dy > 0.10 && diff.dy < 0.55 && diff.dx.abs() < 0.28;
      }
      if (nombre == 'manos') {
        return diff.dy.abs() < 0.25 && diff.dx.abs() < 0.50;
      }
    }

    if (nombre == 'ojos' || nombre == 'boca' || nombre == 'cabello') {
      final eCabeza = _estados.firstWhere((estado) => estado.nombre == 'cabeza');
      if (!eCabeza.colocada) return p.toleranceRect.contains(e.posicion);
      final diff = e.posicion - eCabeza.posicion;
      final distancia = diff.distance;
      if (nombre == 'cabello') return distancia < 0.35 && diff.dy <= 0.05;
      if (nombre == 'ojos')    return distancia < 0.30;
      if (nombre == 'boca')    return distancia < 0.30;
    }

    return p.toleranceRect.contains(e.posicion);
  }

  bool get _todoOk => _piezas.every((p) => _esCorrecto(p.nombre));

  Set<String> get _enBandeja =>
      _piezas.map((p) => p.nombre).where((n) => !_estaEnArea(n)).toSet();

  void _verificar(BuildContext context) {
    setState(() => _verificado = true);
    _mostrarFeedback(context, _todoOk, onAction: () {
      if (_todoOk) widget.onNext();
      else _reintentar();
    });
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

    final areaSize      = ro.size;
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
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final enBandeja = _enBandeja;

    return _Tarjeta(
      child: Column(
        children: [
          _Instruccion(
            'Ayudame a armar la niña poniendo las partes en el lugar correcto',
            player: _player,
            audioPath: _audio5,
          ),
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

// ═════════════════════════════════════════════════════════════════════════════
// ACTIVIDAD 3: Sentidos y funciones
// ═════════════════════════════════════════════════════════════════════════════

class _Actividad3 extends StatefulWidget {
  final VoidCallback onFinish;
  const _Actividad3({required this.onFinish});
  @override
  State<_Actividad3> createState() => _Actividad3State();
}

class _Actividad3State extends State<_Actividad3> {
  static const _audioPorRespuesta = {
    'vista': _audioAct3Vista,
    'oido':  _audioAct3Oido,
    'tacto': _audioAct3Tacto,
    'gusto': _audioAct3Gusto,
  };

  late final List<Map<String, String>> _preguntas;

  final _botones = [
    {'id': 'vista', 'img': '${_p6}boton vista.png', 'c': const Color(0xFF1565C0)},
    {'id': 'oido',  'img': '${_p6}boton oido.png',  'c': const Color(0xFFE65100)},
    {'id': 'tacto', 'img': '${_p6}boton tacto.png', 'c': const Color(0xFF2E7D32)},
    {'id': 'gusto', 'img': '${_p6}boton gusto.png', 'c': const Color(0xFF6A1B9A)},
  ];

  int _ronda = 0;
  String? _seleccion;

  final Player _player = Player();

  String get _audioRondaActual =>
      _audioPorRespuesta[_preguntas[_ronda]['ans']]!;

  Future<void> _playAudioRonda() async {
    await _playAsset(_player, _audioRondaActual);
  }

  @override
  void initState() {
    super.initState();
    final lista = [
      {'txt': '¿Con qué parte del cuerpo puedo mirar los colores del arcoíris?', 'ans': 'vista'},
      {'txt': '¿Con qué parte del cuerpo escucho música?', 'ans': 'oido'},
      {'txt': '¿Con qué parte del cuerpo toco los objetos?', 'ans': 'tacto'},
      {'txt': '¿Con qué parte del cuerpo saboreo los alimentos?', 'ans': 'gusto'},
    ]..shuffle(Random());
    _preguntas = lista;
    Future.microtask(() {
      if (mounted) _playAudioRonda();
    });
  }

  void _responder(BuildContext context, String id) {
    if (_seleccion != null) return;
    setState(() => _seleccion = id);
    final correcto = id == _preguntas[_ronda]['ans'];
    _mostrarFeedback(context, correcto, onAction: () {
      if (correcto) {
        if (_ronda < _preguntas.length - 1) {
          setState(() {
            _ronda++;
            _seleccion = null;
          });
          _playAudioRonda();
        } else {
          widget.onFinish();
        }
      } else {
        setState(() => _seleccion = null);
      }
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _Tarjeta(
      child: Column(
        children: [
          _Instruccion(
            _preguntas[_ronda]['txt']!,
            player: _player,
            audioPath: _audioRondaActual,
          ),
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