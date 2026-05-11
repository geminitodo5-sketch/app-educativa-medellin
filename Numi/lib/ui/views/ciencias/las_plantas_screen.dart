// lib/ui/views/ciencias/las_plantas_screen.dart

import 'dart:async';
import 'dart:convert';
import 'dart:math' show min;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart'; // ✅ media_kit reemplaza just_audio
import 'package:media_kit_video/media_kit_video.dart';
import '../../../data/services/feedback_sounds.dart';
import 'dart:ui' as ui;
import '../../../data/providers/app_state_provider.dart';
import '../../../data/providers/database_provider.dart';
import '../../../data/models/sync_queue_model.dart';
import '../terminado.dart';

// ✅ Eliminado: dart:io, package:just_audio, package:path_provider
// ✅ Eliminado: _resolverAudioPath — media_kit lee assets con Media('asset:///...') nativamente

const _audio10 = 'assets/images/actividades/ciencias_naturales/audios/audio_naturales10_mezcla.mp3';
const _audio11 = 'assets/images/actividades/ciencias_naturales/audios/audio_naturales11_mezcla.mp3';
const _audio12 = 'assets/images/actividades/ciencias_naturales/audios/audio_naturales12_mezcla.mp3';

const _p10 = 'assets/images/actividades/ciencias_naturales/pantalla 10/';
const _p11 = 'assets/images/actividades/ciencias_naturales/pantalla 11/';
const _p12 = 'assets/images/actividades/ciencias_naturales/pantalla 12/';

// ── Popup de retroalimentación ────────────────────────────────────────────
void _mostrarFeedback(BuildContext context, bool correcto, {VoidCallback? onAction}) {
  FeedbackSounds.instance.reproducir(correcto);
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
                  correcto ? '¡Excelente trabajo!' : '¡Inténtalo de nuevo!',
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

// ═══════════════════════════════════════════════════════════════════════════
class LasPlantasScreen extends ConsumerStatefulWidget {
  const LasPlantasScreen({super.key});
  @override
  ConsumerState<LasPlantasScreen> createState() => _LasPlantasScreenState();
}

class _LasPlantasScreenState extends ConsumerState<LasPlantasScreen> {
  final _ctrl = PageController();
  int _pagina = 0;
  bool _navegandoATerminado = false;

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  void _siguiente() => _ctrl.nextPage(
      duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);

  Future<void> _guardarProgreso() async {
    final estudiante = ref.read(estudianteActivoProvider);
    if (estudiante == null || estudiante.id == null) return;
    final repo = ref.read(progresoRepositoryProvider);
    final queue = ref.read(syncQueueRepositoryProvider);
    await repo.registrarIntento(
      estudianteId: estudiante.id!,
      grado: estudiante.grado,
      materia: 'ciencias',
      actividad: 'Las plantas',
      porcentaje: 100.0,
    );
    await queue.encolar(SyncQueueModel(
      tipoAccion: 'progreso',
      payload: jsonEncode({
        'estudianteId': estudiante.id,
        'grado': estudiante.grado,
        'materia': 'ciencias',
        'actividad': 'Las plantas',
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
                title: 'Las plantas',
                dots: _buildDots(),
                progress: 1 / 3,
                child: _Actividad1(onNext: _siguiente),
              ),
              _PageCard(
                title: 'Las plantas',
                dots: _buildDots(),
                progress: 2 / 3,
                child: _Actividad2(onNext: _siguiente),
              ),
              _PageCard(
                title: 'Las plantas',
                dots: _buildDots(),
                progress: 1.0,
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

// ── Componentes compartidos ───────────────────────────────────────────────
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
  final double progress;
  const _PageCard({required this.title, required this.child, required this.dots, required this.progress});

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;
    return Stack(
      children: [
        Container(color: const Color(0xFF3DCC52)),
        Column(
          children: [
            SafeArea(
              bottom: false,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 18, 52, 12),
                    child: Text(
                      title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'Hiruko',
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(sw * 0.08, 0, sw * 0.08, 14),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 8,
                        backgroundColor: Colors.white30,
                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF59E347)),
                      ),
                    ),
                  ),
                ],
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

// ── Fila de instrucción ───────────────────────────────────────────────────
class _Instruccion extends StatelessWidget {
  final String texto;
  final Player? player;
  final String? audioAsset;

  const _Instruccion(this.texto, {this.player, this.audioAsset});

  Future<void> _reproducir() async {
    if (player == null || audioAsset == null) return;
    try {
      await player!.open(Media('asset:///$audioAsset'));
      await player!.play();
    } catch (e) {
      debugPrint('Error al reproducir audio: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: _reproducir,
            child: Container(
              width: (sw * 0.13).clamp(44.0, 60.0),
              height: (sw * 0.13).clamp(44.0, 60.0),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                Icons.volume_up_rounded,
                color: const Color(0xFF3DCC52),
                size: (sw * 0.07).clamp(24.0, 34.0),
              ),
            ),
          ),
          SizedBox(width: sw * 0.03),
          Expanded(
            child: Text(
              texto,
              style: TextStyle(
                fontFamily: 'Hiruko',
                fontSize: (sw * 0.065).clamp(20.0, 46.0),
                fontWeight: FontWeight.bold,
                color: const Color(0xFF424242),
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// ACTIVIDAD 1
// ═══════════════════════════════════════════════════════════════════════════
class _Actividad1 extends StatefulWidget {
  final VoidCallback onNext;
  const _Actividad1({required this.onNext});
  @override State<_Actividad1> createState() => _Actividad1State();
}

class _Actividad1State extends State<_Actividad1> {
  static const _totalSlots = 5;
  static const _barajadas = [3, 1, 5, 2, 4];

  final Map<int, int> _colocadas = {};
  Player? _player;

  bool get _completo => _colocadas.length == _totalSlots;

  @override
  void initState() {
    super.initState();
    _player = Player();
    Future.microtask(() => _playAudio());
  }

  @override
  void dispose() {
    _player?.dispose();
    super.dispose();
  }

  Future<void> _playAudio() async {
    try {
      await _player?.open(Media('asset:///$_audio10'));
      await _player?.play();
    } catch (e) {
      debugPrint('Error playAudio actividad1: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final fasesSinColocar = _barajadas.where((f) => !_colocadas.values.contains(f)).toList();

    void onSlotAccepted(int slot, int fase) {
      setState(() => _colocadas[slot] = fase);
      if (_completo) {
        _mostrarFeedback(context, true, onAction: () {
          widget.onNext();
        });
      }
    }

    return _Tarjeta(
      child: Column(
        children: [
          _Instruccion(
            '¿Cómo crece una planta? Pon sus fases en el orden correcto',
            player: _player,
            audioAsset: _audio10,
          ),
          const SizedBox(height: 8),
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: LayoutBuilder(
                builder: (ctx, constraints) {
                  const arrowW = 28.0;
                  const slotMargin = 8.0; // 4px each side per empty slot
                  final byW = (constraints.maxWidth - 2 * arrowW - 3 * slotMargin) / 3;
                  final byH = (constraints.maxHeight - 24) / 2;
                  final slotSize = min(byW, byH).clamp(60.0, 120.0);
                  // spacerA positions the down-arrow under slot 3's center
                  final spacerA = 2 * (slotSize + slotMargin) + 2 * arrowW;
                  // spacerB aligns slot 4 directly below slot 3
                  final spacerB = slotSize + slotMargin + arrowW;
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [1, 2, 3].expand((slot) => [
                          _SlotDrop(
                            slot: slot,
                            colocada: _colocadas[slot],
                            onAccepted: (f) => onSlotAccepted(slot, f),
                            onRejected: () => _mostrarFeedback(context, false),
                            size: slotSize,
                          ),
                          if (slot < 3) const _FlechaEstilizada(),
                        ]).toList(),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(width: spacerA),
                          const _FlechaEstilizada(direccion: _DirFlecha.abajo),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(width: spacerB),
                          _SlotDrop(
                            slot: 5,
                            colocada: _colocadas[5],
                            onAccepted: (f) => onSlotAccepted(5, f),
                            onRejected: () => _mostrarFeedback(context, false),
                            size: slotSize,
                          ),
                          const _FlechaEstilizada(direccion: _DirFlecha.izquierda),
                          _SlotDrop(
                            slot: 4,
                            colocada: _colocadas[4],
                            onAccepted: (f) => onSlotAccepted(4, f),
                            onRejected: () => _mostrarFeedback(context, false),
                            size: slotSize,
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 14),
              child: LayoutBuilder(
                builder: (ctx, constraints) {
                  final chipSize = min(constraints.maxHeight * 0.65, (constraints.maxWidth - 24) / 5).clamp(44.0, 110.0);
                  return Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE0E0E0)),
                    ),
                    padding: const EdgeInsets.all(8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: fasesSinColocar.map((fase) => Draggable<int>(
                        data: fase,
                        onDraggableCanceled: (_, __) => _mostrarFeedback(context, false),
                        feedback: Material(
                          color: Colors.transparent,
                          child: _FaseChip(fase: fase, size: chipSize * 1.05),
                        ),
                        childWhenDragging: _FaseChip(fase: fase, size: chipSize, opacity: 0.35),
                        child: _FaseChip(fase: fase, size: chipSize),
                      )).toList(),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Flecha estilizada ─────────────────────────────────────────────────────
enum _DirFlecha { derecha, izquierda, abajo }

class _FlechaEstilizada extends StatelessWidget {
  final _DirFlecha direccion;
  const _FlechaEstilizada({this.direccion = _DirFlecha.derecha});

  @override
  Widget build(BuildContext context) {
    final esVertical = direccion == _DirFlecha.abajo;
    return SizedBox(
      width: esVertical ? 20 : 28,
      height: esVertical ? 28 : 20,
      child: CustomPaint(painter: _FlechaPainter(direccion)),
    );
  }
}

class _FlechaPainter extends CustomPainter {
  final _DirFlecha direccion;
  const _FlechaPainter(this.direccion);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black87
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.fill;

    final linePaint = Paint()
      ..color = Colors.black87
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    switch (direccion) {
      case _DirFlecha.derecha:
        canvas.drawLine(Offset(2, size.height / 2),
            Offset(size.width - 7, size.height / 2), linePaint);
        final path = Path()
          ..moveTo(size.width, size.height / 2)
          ..lineTo(size.width - 8, size.height / 2 - 5)
          ..lineTo(size.width - 8, size.height / 2 + 5)
          ..close();
        canvas.drawPath(path, paint);
        break;
      case _DirFlecha.izquierda:
        canvas.drawLine(Offset(7, size.height / 2),
            Offset(size.width - 2, size.height / 2), linePaint);
        final path = Path()
          ..moveTo(0, size.height / 2)
          ..lineTo(8, size.height / 2 - 5)
          ..lineTo(8, size.height / 2 + 5)
          ..close();
        canvas.drawPath(path, paint);
        break;
      case _DirFlecha.abajo:
        canvas.drawLine(Offset(size.width / 2, 2),
            Offset(size.width / 2, size.height - 7), linePaint);
        final path = Path()
          ..moveTo(size.width / 2, size.height)
          ..lineTo(size.width / 2 - 5, size.height - 8)
          ..lineTo(size.width / 2 + 5, size.height - 8)
          ..close();
        canvas.drawPath(path, paint);
        break;
    }
  }

  @override
  bool shouldRepaint(_FlechaPainter old) => old.direccion != direccion;
}

// ─────────────────────────────────────────────────────────────────────────────
class _SlotDrop extends StatelessWidget {
  final int slot;
  final int? colocada;
  final ValueChanged<int> onAccepted;
  final VoidCallback onRejected;
  final double size;
  const _SlotDrop({required this.slot, required this.colocada,
      required this.onAccepted, required this.onRejected, this.size = 72});

  @override
  Widget build(BuildContext context) {
    if (colocada != null) {
      return SizedBox(
        width: size, height: size,
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.asset('${_p10}cuadro verde.png',
                  fit: BoxFit.fill,
                  errorBuilder: (c, e, s) => Container(
                      decoration: BoxDecoration(
                          color: const Color(0xFF3DCC52),
                          borderRadius: BorderRadius.circular(12)))),
            ),
            Positioned.fill(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Image.asset('${_p10}fase$colocada.png',
                      fit: BoxFit.contain,
                      errorBuilder: (c, e, s) => Center(
                          child: Text('$colocada',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 22)))),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return DragTarget<int>(
      onWillAcceptWithDetails: (d) => d.data == slot,
      onAcceptWithDetails: (d) => onAccepted(d.data),
      builder: (ctx, candidates, rejected) {
        final hovering = candidates.isNotEmpty;
        final isRejected = rejected.isNotEmpty;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: size, height: size,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          child: Stack(
            children: [
              Positioned.fill(
                child: Opacity(
                  opacity: hovering ? 1.0 : isRejected ? 0.5 : 0.75,
                  child: Image.asset('${_p10}cuadro verde.png',
                      fit: BoxFit.fill,
                      errorBuilder: (c, e, s) => Container(
                          decoration: BoxDecoration(
                              color: hovering ? const Color(0xFF3DCC52)
                                  : isRejected ? const Color(0xFFB71C1C)
                                  : const Color(0xFFCCCCCC),
                              borderRadius: BorderRadius.circular(12)))),
                ),
              ),
              Center(
                child: Text('$slot',
                    style: TextStyle(
                      color: hovering ? Colors.white
                          : isRejected ? const Color(0xFFB71C1C)
                          : Colors.white70,
                      fontWeight: FontWeight.bold, fontSize: 26,
                      shadows: const [Shadow(color: Color(0x44000000), blurRadius: 2)],
                    )),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _FaseChip extends StatelessWidget {
  final int fase;
  final double size;
  final double opacity;
  const _FaseChip({required this.fase, required this.size, this.opacity = 1.0});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity,
      child: SizedBox(
        width: size, height: size,
        child: Image.asset('${_p10}fase$fase.png',
            fit: BoxFit.contain,
            alignment: Alignment.bottomCenter,
            errorBuilder: (c, e, s) => Center(child: Text('$fase',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)))),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// ACTIVIDAD 2
// ═══════════════════════════════════════════════════════════════════════════
class _PiezaPlanta {
  final String nombre;
  final String ruta;
  final String label;
  final Rect toleranceRect;
  final double anchoFraccion;
  final double altoFraccion;

  const _PiezaPlanta(
    this.nombre,
    this.ruta,
    this.label, {
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
    _PiezaPlanta('raices', '${_p11}raices.png', 'Raíces',
        toleranceRect: Rect.fromLTWH(0.00, 0.30, 1.00, 0.70),
        anchoFraccion: 0.35, altoFraccion: 0.18),
    _PiezaPlanta('tallo', '${_p11}tallo.png', 'Tallo',
        toleranceRect: Rect.fromLTWH(0.00, 0.00, 1.00, 1.00),
        anchoFraccion: 0.25, altoFraccion: 0.45),
    _PiezaPlanta('hojas', '${_p11}hojas.png', 'Hojas',
        toleranceRect: Rect.fromLTWH(0.00, 0.10, 1.00, 0.80),
        anchoFraccion: 0.60, altoFraccion: 0.35),
    _PiezaPlanta('flor', '${_p11}flor (2).png', 'Flor',
        toleranceRect: Rect.fromLTWH(0.00, 0.00, 1.00, 0.70),
        anchoFraccion: 0.45, altoFraccion: 0.35),
  ];

  static const _renderOrder = ['raices', 'tallo', 'hojas', 'flor'];

  List<_PiezaPlanta> _piezas = List.of(_piezasBase);
  late List<_PiezaEstado> _estados;
  bool _verificado = false;
  bool _imagenesListas = false;

  final _areaKey = GlobalKey();

  Player? _player;

  @override
  void initState() {
    super.initState();
    _player = Player();
    _estados = _piezasBase
        .map((p) => _PiezaEstado(p.nombre, posicion: const Offset(-999, -999)))
        .toList();
    _calcularFracciones();
    Future.microtask(() => _playAudio());
  }

  @override
  void dispose() {
    _player?.dispose();
    super.dispose();
  }

  Future<void> _playAudio() async {
    try {
      await _player?.open(Media('asset:///$_audio11'));
      await _player?.play();
    } catch (e) {
      debugPrint('Error playAudio actividad2: $e');
    }
  }

  Future<void> _calcularFracciones() async {
    final Map<String, Size> sizes = {};
    for (final p in _piezasBase) {
      try {
        final completer = Completer<ui.Image>();
        final stream = AssetImage(p.ruta).resolve(const ImageConfiguration());
        late ImageStreamListener listener;
        listener = ImageStreamListener(
          (info, _) {
            if (!completer.isCompleted) completer.complete(info.image);
            stream.removeListener(listener);
          },
          onError: (error, stack) {
            if (!completer.isCompleted) completer.completeError(error, stack);
            stream.removeListener(listener);
          },
        );
        stream.addListener(listener);
        final img = await completer.future;
        sizes[p.nombre] = Size(img.width.toDouble(), img.height.toDouble());
      } catch (_) {
        sizes[p.nombre] = const Size(100, 100);
      }
    }

    if (!mounted) return;

    final talloSize = sizes['tallo']!;
    const talloAnchoFrac = 0.22;
    final pxPorFraccion = talloSize.width / talloAnchoFrac;

    setState(() {
      _piezas = _piezasBase.map((p) {
        final imgSize = sizes[p.nombre]!;
        double wFinal = imgSize.width / pxPorFraccion;
        double hFinal = imgSize.height / pxPorFraccion;

        if (wFinal > 0.85) {
          hFinal = (0.85 / wFinal) * hFinal;
          wFinal = 0.85;
        }
        if (hFinal > 0.45) {
          wFinal = (0.45 / hFinal) * wFinal;
          hFinal = 0.45;
        }

        // ── Escala por pieza ─────────────────────────────────────────────
        // Cambia estos multiplicadores para ajustar el tamaño de cada pieza.
        // 0.50 = 50% del tamaño calculado, 1.0 = tamaño original.
        if (p.nombre == 'raices') {
          wFinal = wFinal * 0.45; // ← tamaño raíces (antes 0.65)
          hFinal = hFinal * 0.45;
        }
        if (p.nombre == 'flor') {
          wFinal = wFinal * 0.50; // ← tamaño girasol/flor
          hFinal = hFinal * 0.50;
        }

        return _PiezaPlanta(
          p.nombre, p.ruta, p.label,
          toleranceRect: p.toleranceRect,
          anchoFraccion: wFinal.clamp(0.1, 0.85),
          altoFraccion: hFinal.clamp(0.1, 0.45),
        );
      }).toList();
      _imagenesListas = true;
    });
  }

  // Igual que en cuerpo_humano: childDragAnchorStrategy hace que details.offset
  // en onAcceptWithDetails sea la esquina top-left del feedback. Sumamos la
  // mitad del tamaño de la pieza para obtener su centro.
  void _colocarPieza(String nombre, Offset globalTopLeft) {
    final ro = _areaKey.currentContext?.findRenderObject() as RenderBox?;
    if (ro == null) return;

    final areaSize = ro.size;
    final p = _piezas.firstWhere((p) => p.nombre == nombre);
    final pxW = areaSize.width  * p.anchoFraccion;
    final pxH = areaSize.height * p.altoFraccion;

    // Centro del feedback en coordenadas globales → locales del área
    final globalCenter = globalTopLeft + Offset(pxW / 2, pxH / 2);
    final localCenter  = ro.globalToLocal(globalCenter);

    // Descartar si quedó completamente fuera del área
    if (localCenter.dx < -pxW / 2 || localCenter.dx > areaSize.width  + pxW / 2 ||
        localCenter.dy < -pxH / 2 || localCenter.dy > areaSize.height + pxH / 2) return;

    setState(() {
      final e = _estados.firstWhere((e) => e.nombre == nombre);
      e.posicion = Offset(
        (localCenter.dx / areaSize.width ).clamp(p.anchoFraccion / 2, 1.0 - p.anchoFraccion / 2),
        (localCenter.dy / areaSize.height).clamp(p.altoFraccion  / 2, 1.0 - p.altoFraccion  / 2),
      );
      e.colocada  = true;
      _verificado = false;
    });
  }

  bool _esCorrecto(String nombre) {
    final e = _estados.firstWhere((e) => e.nombre == nombre);
    final p = _piezas.firstWhere((p) => p.nombre == nombre);

    if (nombre == 'tallo') {
      return e.posicion.dx >= 0.15 && e.posicion.dx <= 0.85 &&
             e.posicion.dy >= 0.15 && e.posicion.dy <= 0.85;
    }

    final eTallo = _estados.firstWhere((est) => est.nombre == 'tallo');
    if (!eTallo.colocada) return p.toleranceRect.contains(e.posicion);

    final diff = e.posicion - eTallo.posicion;
    final distancia = diff.distance;

    if (nombre == 'raices') {
      return diff.dy > 0.08 && diff.dy < 0.70 && diff.dx.abs() < 0.50;
    }
    if (nombre == 'flor') {
      return diff.dy < -0.08 && diff.dy > -0.65 && diff.dx.abs() < 0.40;
    }
    if (nombre == 'hojas') {
      return distancia < 0.55 && diff.dy.abs() < 0.45;
    }

    return p.toleranceRect.contains(e.posicion);
  }

  bool get _todoColocado => _estados.every((e) => e.colocada);
  bool get _todoOk => _piezas.every((p) => _esCorrecto(p.nombre));
  Set<String> get _enBandeja =>
      _piezas.map((p) => p.nombre).where((n) => !_estaEnArea(n)).toSet();

  bool _estaEnArea(String nombre) =>
      _estados.firstWhere((e) => e.nombre == nombre).colocada;

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

  @override
  Widget build(BuildContext context) {
    if (!_imagenesListas) return const Center(child: CircularProgressIndicator());

    final enBandeja = _enBandeja;
    final sh = MediaQuery.of(context).size.height;
    final bandejaH = (sh * 0.13).clamp(80.0, 150.0);
    final thumbSize = (bandejaH * 0.68).clamp(50.0, 100.0);

    return _Tarjeta(
      child: Column(
        children: [
          _Instruccion(
            'Arma  la planta con todos sus elementos, arrastralos al cuadro',
            player: _player,
            audioAsset: _audio11,
          ),
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(30, 8, 30, 4),
              child: LayoutBuilder(builder: (_, constraints) {
                final areaW = constraints.maxWidth;
                final areaH = constraints.maxHeight;

                return DragTarget<String>(
                  // ── El DragTarget cubre TODO el área ─────────────────────
                  // onAcceptWithDetails recibe details.offset = esquina top-left
                  // del feedback (gracias a childDragAnchorStrategy).
                  onAcceptWithDetails: (details) {
                    _colocarPieza(details.data, details.offset);
                  },
                  builder: (ctx, candidateData, rejectedData) {
                    return Container(
                      key: _areaKey,
                      width: areaW,
                      height: areaH,
                      decoration: BoxDecoration(
                        color: candidateData.isNotEmpty
                            ? const Color(0xFFE8F5E9)
                            : const Color(0xFFF9FBF9),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: candidateData.isNotEmpty
                              ? const Color(0xFF3DCC52)
                              : const Color(0xFFE0E0E0),
                          width: candidateData.isNotEmpty ? 2.5 : 1.5,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: Stack(
                          clipBehavior: Clip.hardEdge,
                          children: [
                            if (enBandeja.length == _piezas.length)
                              const Center(
                                child: Text('⬆ Arrastra  las piezas aquí',
                                    style: TextStyle(color: Colors.grey, fontSize: 12)),
                              ),

                            // ── Piezas ya colocadas ───────────────────────
                            ..._renderOrder.map((nombre) {
                              final e = _estados.firstWhere((st) => st.nombre == nombre);
                              if (!e.colocada) return const SizedBox.shrink();
                              final p = _piezas.firstWhere((pz) => pz.nombre == nombre);

                              final pxW  = areaW * p.anchoFraccion;
                              final pxH  = areaH * p.altoFraccion;
                              final left = (e.posicion.dx * areaW - pxW / 2)
                                  .clamp(0.0, (areaW - pxW).clamp(0.0, areaW));
                              final top  = (e.posicion.dy * areaH - pxH / 2)
                                  .clamp(0.0, (areaH - pxH).clamp(0.0, areaH));
                              final correcto = _verificado ? _esCorrecto(nombre) : null;

                              return Positioned(
                                left: left, top: top, width: pxW, height: pxH,
                                child: Draggable<String>(
                                  data: nombre,
                                  // ── childDragAnchorStrategy: igual que cuerpo humano ──
                                  // El feedback se ancla en la esquina top-left del widget.
                                  // details.offset en onDragEnd = esa esquina top-left global.
                                  dragAnchorStrategy: childDragAnchorStrategy,
                                  feedback: Material(
                                    color: Colors.transparent,
                                    child: Opacity(
                                      opacity: 0.88,
                                      child: SizedBox(width: pxW, height: pxH,
                                        child: Image.asset(p.ruta, fit: BoxFit.contain,
                                            filterQuality: ui.FilterQuality.high)),
                                    ),
                                  ),
                                  childWhenDragging: Opacity(
                                    opacity: 0.20,
                                    child: SizedBox(width: pxW, height: pxH,
                                      child: Image.asset(p.ruta, fit: BoxFit.contain,
                                          filterQuality: ui.FilterQuality.high)),
                                  ),
                                  // Solo manejamos el caso de soltar FUERA del área
                                  // (el DragTarget no lo acepta → wasAccepted=false)
                                  onDragEnd: (details) {
                                    if (!details.wasAccepted) {
                                      setState(() {
                                        final est = _estados.firstWhere(
                                            (est) => est.nombre == nombre);
                                        est.colocada = false;
                                        est.posicion = const Offset(-999, -999);
                                        _verificado  = false;
                                      });
                                    }
                                  },
                                  child: Stack(children: [
                                    SizedBox(width: pxW, height: pxH,
                                      child: Image.asset(p.ruta, fit: BoxFit.contain,
                                          filterQuality: ui.FilterQuality.high)),
                                    if (correcto != null)
                                      Positioned.fill(
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: correcto
                                                ? const Color(0x2200CC44)
                                                : const Color(0x33FF0000),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Center(
                                            child: Icon(
                                              correcto
                                                  ? Icons.check_circle_rounded
                                                  : Icons.cancel_rounded,
                                              color: correcto
                                                  ? const Color(0xFF2E7D32)
                                                  : const Color(0xFFB71C1C),
                                              size: 28,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ]),
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    );
                  },
                );
              }),
            ),
          ),

          if (_todoColocado && !_verificado)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: ElevatedButton.icon(
                onPressed: () => _verificar(context),
                icon: const Icon(Icons.check_rounded),
                label: const Text('Verificar',
                    style: TextStyle(fontFamily: 'Poppins', fontSize: 16,
                        fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3DCC52),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 3,
                ),
              ),
            )
          else if (_verificado && !_todoOk)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: ElevatedButton.icon(
                onPressed: _reintentar,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Reintentar',
                    style: TextStyle(fontFamily: 'Poppins', fontSize: 16,
                        fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE53935),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 3,
                ),
              ),
            ),

          // ── Bandeja de piezas ────────────────────────────────────────────
          if (enBandeja.isNotEmpty)
            SizedBox(
              height: bandejaH,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: _piezas
                      .where((p) => enBandeja.contains(p.nombre))
                      .map((p) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Draggable<String>(
                            data: p.nombre,
                            // ── childDragAnchorStrategy: igual que cuerpo humano ──
                            dragAnchorStrategy: childDragAnchorStrategy,
                            feedback: Material(
                              color: Colors.transparent,
                              child: Opacity(
                                opacity: 0.88,
                                child: SizedBox(
                                  width: thumbSize, height: thumbSize,
                                  child: Image.asset(p.ruta, fit: BoxFit.contain,
                                      filterQuality: ui.FilterQuality.high),
                                ),
                              ),
                            ),
                            childWhenDragging: Opacity(
                                opacity: 0.30, child: _chipBandeja(p, thumbSize)),
                            // La bandeja no maneja posicionamiento:
                            // el DragTarget del área lo hace en onAcceptWithDetails
                            child: _chipBandeja(p, thumbSize),
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

  Widget _chipBandeja(_PiezaPlanta p, double size) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: size, height: size,
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE0E0E0), width: 1.5),
          boxShadow: const [BoxShadow(color: Color(0x18000000), blurRadius: 4, offset: Offset(0, 2))],
        ),
        child: Image.asset(p.ruta, fit: BoxFit.contain, filterQuality: ui.FilterQuality.high,
            errorBuilder: (c, e, s) =>
                const Icon(Icons.image_not_supported, color: Colors.grey)),
      ),
      const SizedBox(height: 3),
      Text(p.label,
          style: const TextStyle(fontSize: 10, fontFamily: 'Poppins',
              color: Color(0xFF555555))),
    ],
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// ACTIVIDAD 3
// ═══════════════════════════════════════════════════════════════════════════
class _Actividad3 extends StatefulWidget {
  final VoidCallback onFinish;
  const _Actividad3({required this.onFinish});
  @override State<_Actividad3> createState() => _Actividad3State();
}

class _Actividad3State extends State<_Actividad3> {
  static const _opciones = [
    (id: 'sol',     ruta: '${_p12}sol.png',     correcto: true),
    (id: 'agua',    ruta: '${_p12}agua.png',    correcto: true),
    (id: 'tierra',  ruta: '${_p12}tierra.png',  correcto: true),
    (id: 'botella', ruta: '${_p12}botella.png', correcto: false),
  ];
  static const _meta = 3;

  final Set<String> _seleccionados = {};
  String? _error;

  Player? _player;
  Player? _videoPlayer;
  VideoController? _videoController;
  StreamSubscription<bool>? _videoSub;
  StreamSubscription<Duration>? _durationSub;
  StreamSubscription<Duration>? _positionSub;
  Duration _animDuration = Duration.zero;
  bool _animHandled = false;

  @override
  void initState() {
    super.initState();
    _player = Player();
    _videoPlayer = Player();
    _videoController = VideoController(_videoPlayer!);
    _durationSub = _videoPlayer!.stream.duration.listen((d) {
      if (d > Duration.zero) _animDuration = d;
    });
    Future.microtask(() => _playAudio());
    Future.microtask(() => _cargarVideoInicial());
  }

  @override
  void dispose() {
    _videoSub?.cancel();
    _durationSub?.cancel();
    _positionSub?.cancel();
    _player?.dispose();
    _videoPlayer?.dispose();
    super.dispose();
  }

  Future<void> _playAudio() async {
    try {
      await _player?.open(Media('asset:///$_audio12'));
      await _player?.play();
    } catch (e) {
      debugPrint('Error playAudio actividad3: $e');
    }
  }

  Future<void> _cargarVideoInicial() async {
    try {
      await _videoPlayer!.setPlaylistMode(PlaylistMode.none);
      await _videoPlayer!.open(
        Media('asset:///assets/animations/planta_creciendo.mp4'),
        play: false,
      );
    } catch (e) {
      debugPrint('Error cargando video planta: $e');
    }
  }

  void _finishVideo() {
    if (!mounted || _animHandled) return;
    _animHandled = true;
    _videoSub?.cancel();
    _positionSub?.cancel();
    _videoSub = null;
    _positionSub = null;
    final dur = _videoPlayer?.state.duration ?? Duration.zero;
    if (dur > Duration.zero) {
      _videoPlayer?.seek(dur - const Duration(milliseconds: 50));
    }
    _videoPlayer?.pause();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _mostrarFeedback(context, true, onAction: () => widget.onFinish());
    });
  }

  void _iniciarVideo() {
    _player?.stop();
    _videoSub?.cancel();
    _positionSub?.cancel();
    _animHandled = false;

    // Interceptar posición: cuando queden ≤200ms del total, pausar antes del loop
    _positionSub = _videoPlayer!.stream.position.listen((pos) {
      if (_animDuration > Duration.zero && !_animHandled) {
        final remaining = _animDuration.inMilliseconds - pos.inMilliseconds;
        if (pos.inMilliseconds > 800 && remaining >= 0 && remaining <= 200) {
          _finishVideo();
        }
      }
    });

    _videoPlayer!.seek(Duration.zero).then((_) => _videoPlayer!.play());

    // Respaldo absoluto si el listener de posición no dispara
    final duration = _animDuration > Duration.zero
        ? _animDuration
        : const Duration(seconds: 4);
    Future.delayed(duration + const Duration(milliseconds: 300), _finishVideo);
  }

  void _tocar(BuildContext context, String id, bool correcto) {
    if (_seleccionados.contains(id)) return;
    if (!correcto) {
      setState(() => _error = id);
      _mostrarFeedback(context, false, onAction: () {
        if (mounted) setState(() => _error = null);
      });
      return;
    }
    setState(() => _seleccionados.add(id));
    if (_seleccionados.length >= _meta) {
      _iniciarVideo();
    }
  }

  @override
  Widget build(BuildContext context) {
    return _Tarjeta(
      child: Column(
        children: [
          _Instruccion(
            'Necesito hacer crecer esta planta, elige  los elementos que le ayudarán a crecer',
            player: _player,
            audioAsset: _audio12,
          ),
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(40, 12, 40, 8),
              child: Video(
                controller: _videoController!,
                controls: NoVideoControls,
                fill: Colors.white,
                fit: BoxFit.contain,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
            child: LayoutBuilder(
              builder: (ctx, constraints) {
                final btnSide = ((constraints.maxWidth - 36) / 4).clamp(56.0, 150.0);
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: _opciones.map((op) {
                    final sel = _seleccionados.contains(op.id);
                    final err = _error == op.id;
                    return GestureDetector(
                      onTap: () => _tocar(context, op.id, op.correcto),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: btnSide, height: btnSide,
                        decoration: BoxDecoration(
                          color: sel ? const Color(0xFFE8F5E9)
                              : err ? const Color(0xFFFFEBEE)
                              : const Color(0xFFF5F5F5),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: sel ? const Color(0xFF3DCC52)
                                : err ? const Color(0xFFB71C1C)
                                : const Color(0xFFE0E0E0),
                            width: sel || err ? 3 : 1,
                          ),
                        ),
                        padding: const EdgeInsets.all(8),
                        child: Image.asset(op.ruta, fit: BoxFit.contain,
                            errorBuilder: (c, e, s) =>
                                const Icon(Icons.image_not_supported, color: Colors.grey)),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}