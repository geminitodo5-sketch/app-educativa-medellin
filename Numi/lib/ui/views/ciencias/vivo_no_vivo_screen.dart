// lib/ui/views/ciencias/vivo_no_vivo_screen.dart

import 'dart:convert';
import 'dart:math' show sin, pi;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart'; // ✅ media_kit reemplaza just_audio
import '../../../data/providers/app_state_provider.dart';
import '../../../data/providers/database_provider.dart';
import '../../../data/services/feedback_sounds.dart';
import '../../../data/models/sync_queue_model.dart';
import '../terminado.dart';

// ── Eliminado: _resolverAudioPath ya no es necesario.
// media_kit lee assets directamente con Media('asset:///...') en todas las plataformas.

const _p1 = 'assets/images/actividades/ciencias_naturales/pantalla 1/';
const _p2 = 'assets/images/actividades/ciencias_naturales/pantalla 2/';
const _p3 = 'assets/images/actividades/ciencias_naturales/pantalla 3/';

// ── Popup de retroalimentación ────────────────────────────────────────────
void _mostrarFeedback(BuildContext context, bool esCorrecto, VoidCallback onAction) {
  FeedbackSounds.instance.reproducir(esCorrecto);
  showModalBottomSheet(
    context: context,
    isDismissible: false,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return Container(
        padding: const EdgeInsets.all(30),
        decoration: BoxDecoration(
          color: esCorrecto ? const Color(0xFFD7FFD3) : const Color(0xFFFFD3D3),
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
                  esCorrecto ? Icons.check_circle : Icons.cancel,
                  color: esCorrecto ? const Color(0xFF59E347) : const Color(0xFFF65757),
                  size: 40,
                ),
                const SizedBox(width: 15),
                Text(
                  esCorrecto ? '¡Excelente trabajo!' : '¡Inténtalo de nuevo!',
                  style: TextStyle(
                    fontFamily: 'Hiruko',
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: esCorrecto ? Colors.green[900] : Colors.red[900],
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
                  backgroundColor: esCorrecto ? const Color(0xFF59E347) : const Color(0xFFF65757),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  onAction();
                },
                child: Text(
                  esCorrecto ? 'Continuar' : 'Reintentar',
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

class _Item {
  final String nombre;
  final String ruta;
  final bool esVida;
  const _Item(this.nombre, this.ruta, this.esVida);
}

// ═══════════════════════════════════════════════════════════════════════════
//  Pantalla principal — 3 actividades en PageView
// ═══════════════════════════════════════════════════════════════════════════
class VivoNoVivoScreen extends ConsumerStatefulWidget {
  const VivoNoVivoScreen({super.key});

  @override
  ConsumerState<VivoNoVivoScreen> createState() => _VivoNoVivoScreenState();
}

class _VivoNoVivoScreenState extends ConsumerState<VivoNoVivoScreen> {
  final _ctrl = PageController();
  int _pagina = 0;
  bool _navegandoATerminado = false;

  final _key1 = GlobalKey<_Actividad1State>();
  final _key2 = GlobalKey<_Actividad2State>();
  final _key3 = GlobalKey<_Actividad3State>();

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
      actividad: '¿Vivo o no Vivo?',
      porcentaje: 100.0,
    );
    await queue.encolar(SyncQueueModel(
      tipoAccion: 'progreso',
      payload: jsonEncode({
        'estudianteId': estudiante.id,
        'grado': estudiante.grado,
        'materia': 'ciencias',
        'actividad': '¿Vivo o no Vivo?',
        'porcentaje': 100.0,
      }),
      fecha: DateTime.now().toIso8601String(),
    ));
  }

  void _irATerminado() {
    if (_navegandoATerminado || !mounted) return;
    _navegandoATerminado = true;
    _guardarProgreso();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (newContext) => ActividadTerminadaScreen(
          onVolver: () => Navigator.of(newContext).popUntil((route) => route.isFirst),
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
            onPageChanged: (i) {
              // ✅ Detener audios previos para que no se traslapen
              _key1.currentState?.stopAudio();
              _key2.currentState?.stopAudio();
              _key3.currentState?.stopAudio();

              setState(() => _pagina = i);

              if (i == 0) {
                _key1.currentState?.playAudio();
              } else if (i == 1) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _key2.currentState?.playAudio();
                });
              } else if (i == 2) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _key3.currentState?.playAudio();
                });
              }
            },
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _PageCard(
                title: '¿Vivo o no Vivo?',
                dots: _buildDots(),
                progress: 1 / 3,
                child: _Actividad1(key: _key1, onNext: _siguiente),
              ),
              _PageCard(
                title: '¿Vivo o no Vivo?',
                dots: _buildDots(),
                progress: 2 / 3,
                child: _Actividad2(key: _key2, onNext: _siguiente),
              ),
              _PageCard(
                title: '¿Vivo o no Vivo?',
                dots: _buildDots(),
                progress: 1.0,
                child: _Actividad3(key: _key3, onFinish: _irATerminado),
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
              color: _pagina == i
                  ? const Color(0xFF3DCC52)
                  : const Color(0xFFCCCCCC),
              borderRadius: BorderRadius.circular(5),
            ),
          );
        }),
      ),
    );
  }
}

// ── Tarjeta (passthrough) ─────────────────────────────────────────────────
class _Tarjeta extends StatelessWidget {
  final Widget child;
  const _Tarjeta({required this.child});

  @override
  Widget build(BuildContext context) => child;
}

// ── Tarjeta con header verde + cuerpo blanco ──────────────────────────────
class _PageCard extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget dots;
  final double progress;
  const _PageCard({
    required this.title,
    required this.child,
    required this.dots,
    required this.progress,
  });

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
                        valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFF59E347)),
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
// ✅ Ahora recibe Player? en lugar de AudioPlayer?
// ✅ El path del asset usa el formato 'asset:///...' que media_kit entiende nativamente
class _Instruccion extends StatelessWidget {
  final String texto;
  final Player? player;       // ✅ media_kit Player
  final String? audioAsset;   // ✅ path del asset, ej: 'assets/audio/xxx.mp3'

  const _Instruccion(
    this.texto, {
    this.player,
    this.audioAsset,
  });

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
//  ACTIVIDAD 1 — Clasificar el cocodrilo: ¿vivo o no vivo?
// ═══════════════════════════════════════════════════════════════════════════
class _Actividad1 extends StatefulWidget {
  final VoidCallback onNext;
  const _Actividad1({super.key, required this.onNext});

  @override
  State<_Actividad1> createState() => _Actividad1State();
}

class _ItemClasifica {
  final String ruta;
  final bool esVivo;
  final double escala;
  const _ItemClasifica(this.ruta, this.esVivo, {this.escala = 1.0});
}

class _Actividad1State extends State<_Actividad1>
    with SingleTickerProviderStateMixin {

  static const _items = [
    _ItemClasifica('${_p1}elefante.png', true),
    _ItemClasifica('${_p1}gato.png',     true),
    _ItemClasifica('${_p1}mono.png',     true),
    _ItemClasifica('${_p1}Roca.png',     false, escala: 0.55),
    _ItemClasifica('${_p1}arbol.png',    true,  escala: 0.72),
  ];

  int _ronda = 0;
  String? _seleccion;

  late final AnimationController _shake = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 500),
  );

  // ✅ Player de media_kit — mismo patrón que el código de referencia
  Player? _player;

  static const _audioAsset =
      'assets/images/actividades/ciencias_naturales/audios/audio_naturales1_mezcla.mp3';

  @override
  void initState() {
    super.initState();
    _player = Player(); // ✅ Inicializar igual que en el código de referencia
    // ✅ Reproducción automática al entrar, igual que en el código de referencia
    Future.microtask(() => playAudio());
  }

  @override
  void dispose() {
    _shake.dispose();
    _player?.dispose(); // ✅ Liberar memoria
    super.dispose();
  }

  Future<void> playAudio() async {
    try {
      await _player?.open(Media('asset:///$_audioAsset'));
      await _player?.play();
    } catch (e) {
      debugPrint('Error playAudio actividad1: $e');
    }
  }

  Future<void> stopAudio() async {
    await _player?.stop(); // ✅ media_kit usa stop()
  }

  void _responder(BuildContext context, String opcion) {
    if (_seleccion != null) return;
    setState(() => _seleccion = opcion);
    final item = _items[_ronda];
    final correcto = (opcion == 'vivo') == item.esVivo;

    if (!correcto) {
      _shake.forward(from: 0);
      _mostrarFeedback(context, false, () {
        setState(() => _seleccion = null);
      });
      return;
    }

    final siguiente = _ronda + 1;
    if (siguiente >= _items.length) {
      widget.onNext();
    } else {
      setState(() {
        _ronda = siguiente;
        _seleccion = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = _items[_ronda];
    return _Tarjeta(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ✅ Se pasa _player y _audioAsset a _Instruccion
          _Instruccion(
            'Ayúdame a decidir si estos son seres vivos o no vivos',
            player: _player,
            audioAsset: _audioAsset,
          ),
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_items.length, (i) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _ronda == i ? 12 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: i < _ronda
                        ? const Color(0xFF3DCC52)
                        : (_ronda == i
                            ? const Color(0xFF2E7D32)
                            : const Color(0xFFCCCCCC)),
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Align(
                  key: ValueKey(item.ruta),
                  alignment: Alignment.center,
                  child: FractionallySizedBox(
                    widthFactor: item.escala,
                    heightFactor: item.escala,
                    child: Image.asset(
                      item.ruta,
                      fit: BoxFit.contain,
                      errorBuilder: (ctx, e, s) => const Icon(
                          Icons.image_not_supported, size: 80, color: Colors.grey),
                    ),
                  ),
                ),
              ),
            ),
          ),
          AnimatedBuilder(
            animation: _shake,
            builder: (_, child) {
              final esRespuestaIncorrecta = _seleccion != null &&
                  ((_seleccion == 'vivo') != item.esVivo);
              final dx = esRespuestaIncorrecta
                  ? 8.0 * sin(_shake.value * pi * 5)
                  : 0.0;
              return Transform.translate(offset: Offset(dx, 0), child: child);
            },
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: Row(
                children: [
                  Expanded(
                    child: _BtnClasifica(
                      texto: 'vivo',
                      color: _seleccion == 'vivo'
                          ? const Color(0xFF2E7D32)
                          : const Color(0xFF3DCC52),
                      onTap: () => _responder(context, 'vivo'),
                      icono: _seleccion == 'vivo'
                          ? Icons.check_circle_rounded
                          : null,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _BtnClasifica(
                      texto: 'no\nvivo',
                      color: _seleccion == 'no_vivo'
                          ? const Color(0xFFB71C1C)
                          : const Color(0xFFE53935),
                      onTap: () => _responder(context, 'no_vivo'),
                      icono: _seleccion == 'no_vivo'
                          ? Icons.close_rounded
                          : null,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BtnClasifica extends StatelessWidget {
  final String texto;
  final Color color;
  final VoidCallback onTap;
  final IconData? icono;

  const _BtnClasifica({
    required this.texto,
    required this.color,
    required this.onTap,
    this.icono,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 68,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.5),
              blurRadius: 0,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Center(
          child: icono != null
              ? Icon(icono, color: Colors.white, size: 30)
              : Text(
                  texto,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Hiruko',
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                    height: 1.1,
                  ),
                ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  ACTIVIDAD 2 — Elige el ser vivo entre los no vivos (grid 2×2)
// ═══════════════════════════════════════════════════════════════════════════
class _Actividad2 extends StatefulWidget {
  final VoidCallback onNext;
  const _Actividad2({super.key, required this.onNext});

  @override
  State<_Actividad2> createState() => _Actividad2State();
}

class _Actividad2State extends State<_Actividad2> {
  static const _nombres = ['pato', 'roca', 'libro', 'globo'];
  static const _rutas = [
    '${_p2}pato.png',
    '${_p2}roca.png',
    '${_p2}libro.png',
    '${_p2}globo.png',
  ];
  static const _indexCorrecto = 0;

  static const _audioAsset =
      'assets/images/actividades/ciencias_naturales/audios/audio_naturales2_mezcla.mp3';

  int? _seleccionado;

  // ✅ Player de media_kit
  Player? _player;

  @override
  void initState() {
    super.initState();
    _player = Player(); // ✅ Inicializar igual que en el código de referencia
  }

  @override
  void dispose() {
    _player?.dispose(); // ✅ Liberar memoria
    super.dispose();
  }

  Future<void> playAudio() async {
    try {
      await _player?.open(Media('asset:///$_audioAsset'));
      await _player?.play();
    } catch (e) {
      debugPrint('Error playAudio actividad2: $e');
    }
  }

  Future<void> stopAudio() async {
    await _player?.stop();
  }

  void _seleccionar(BuildContext context, int idx) {
    if (_seleccionado != null) return;
    setState(() => _seleccionado = idx);
    final correcto = idx == _indexCorrecto;
    if (!correcto) {
      _mostrarFeedback(context, false, () {
        setState(() => _seleccionado = null);
      });
      return;
    }
    widget.onNext();
  }

  @override
  Widget build(BuildContext context) {
    return _Tarjeta(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 20),
          // ✅ Se pasa _player y _audioAsset
          _Instruccion(
            'Elige el ser vivo entre  los no vivos',
            player: _player,
            audioAsset: _audioAsset,
          ),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: GridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: List.generate(_nombres.length, (idx) {
                    final sel = _seleccionado == idx;
                    final correcto = idx == _indexCorrecto;
                    final borderColor = sel
                        ? (correcto
                            ? const Color(0xFF3DCC52)
                            : const Color(0xFFE53935))
                        : const Color(0xFFE0E0E0);
                    final bg = sel
                        ? (correcto
                            ? const Color(0xFFE8F5E9)
                            : const Color(0xFFFFEBEE))
                        : Colors.white;

                    return GestureDetector(
                      onTap: () => _seleccionar(context, idx),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        decoration: BoxDecoration(
                          color: bg,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: borderColor, width: 2.5),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.06),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Image.asset(
                          _rutas[idx],
                          fit: BoxFit.contain,
                          errorBuilder: (ctx, e, s) => const Icon(
                              Icons.image_not_supported,
                              size: 50,
                              color: Colors.grey),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  ACTIVIDAD 3 — Arrastra al cuadro los elementos necesarios para vivir
// ═══════════════════════════════════════════════════════════════════════════
class _Actividad3 extends StatefulWidget {
  final VoidCallback onFinish;
  const _Actividad3({super.key, required this.onFinish});

  @override
  State<_Actividad3> createState() => _Actividad3State();
}

class _Actividad3State extends State<_Actividad3> {
  static const _items = [
    _Item('sol',     '${_p3}sol.png',     true),
    _Item('agua',    '${_p3}agua.png',    true),
    _Item('arbol',   '${_p3}arbol.png',   true),
    _Item('manzana', '${_p3}manzana.png', true),
    _Item('banano',  '${_p3}banano.png',  true),
    _Item('roca',    '${_p3}roca.png',    false),
    _Item('carro',   '${_p3}carro.png',   false),
    _Item('viento',  '${_p3}viento.png',  false),
    _Item('botella', '${_p3}botella.png', false),
  ];

  static const int _meta = 5;

  static const _audioAsset =
      'assets/images/actividades/ciencias_naturales/audios/audio_naturales3_mezcla.mp3';

  // ✅ Player de media_kit
  Player? _player;

  final Set<String> _colocados = {};
  bool _hovering = false;

  bool get _completado => _colocados.length >= _meta;

  @override
  void initState() {
    super.initState();
    _player = Player(); // ✅ Inicializar igual que en el código de referencia
  }

  @override
  void dispose() {
    _player?.dispose(); // ✅ Liberar memoria
    super.dispose();
  }

  Future<void> playAudio() async {
    try {
      await _player?.open(Media('asset:///$_audioAsset'));
      await _player?.play();
    } catch (e) {
      debugPrint('Error playAudio actividad3: $e');
    }
  }

  Future<void> stopAudio() async {
    await _player?.stop();
  }

  void _onDrop(BuildContext context, String nombre) {
    final item = _items.firstWhere((i) => i.nombre == nombre);
    if (_colocados.contains(nombre)) return;
    if (!item.esVida) {
      _mostrarFeedback(context, false, () {});
      return;
    }
    setState(() => _colocados.add(nombre));
    if (_completado) widget.onFinish();
  }

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;
    final hPad = (sw * 0.035).clamp(10.0, 20.0);

    return _Tarjeta(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Instruccion(
            'Arrastra dentro del cuadro  los elementos más importantes para vivir',
            player: _player,
            audioAsset: _audioAsset,
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.fromLTRB(hPad, 8, hPad, 8),
              child: Column(
                children: [
                  Expanded(
                    child: DragTarget<String>(
                      onWillAcceptWithDetails: (_) {
                        setState(() => _hovering = true);
                        return true;
                      },
                      onLeave: (_) => setState(() => _hovering = false),
                      onAcceptWithDetails: (d) {
                        setState(() => _hovering = false);
                        _onDrop(context, d.data);
                      },
                      builder: (ctx, candidates, rejected) {
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: _hovering
                                  ? const Color(0xFF3DCC52)
                                  : const Color(0xFFBDBDBD),
                              width: _hovering ? 3 : 1.5,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Image.asset(
                                  '${_p3}cuadro.png',
                                  fit: BoxFit.cover,
                                  alignment: Alignment.center,
                                  errorBuilder: (ctx, e, s) =>
                                      Container(color: const Color(0xFFE3F2FD)),
                                ),
                                if (_colocados.isNotEmpty)
                                  Align(
                                    alignment: Alignment.topLeft,
                                    child: Padding(
                                      padding: const EdgeInsets.all(8),
                                      child: Wrap(
                                        spacing: 4,
                                        runSpacing: 4,
                                        children: _colocados.map((n) {
                                          final it = _items.firstWhere((i) => i.nombre == n);
                                          final iconSz = (sw * 0.10).clamp(36.0, 60.0);
                                          return Container(
                                            width: iconSz,
                                            height: iconSz,
                                            decoration: BoxDecoration(
                                              color: const Color(0xCCFFFFFF),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            padding: const EdgeInsets.all(4),
                                            child: Image.asset(it.ruta, fit: BoxFit.contain),
                                          );
                                        }).toList(),
                                      ),
                                    ),
                                  ),
                                if (_completado)
                                  Container(
                                    color: const Color(0x554CAF50),
                                    child: const Center(
                                      child: Icon(Icons.check_circle_rounded,
                                          color: Colors.white, size: 56),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE0E0E0)),
                    ),
                    padding: const EdgeInsets.all(8),
                    child: GridView.count(
                      crossAxisCount: 5,
                      mainAxisSpacing: 6,
                      crossAxisSpacing: 6,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      children: _items.map((item) {
                        if (_colocados.contains(item.nombre)) {
                          return Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFEEEEEE),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          );
                        }
                        return Draggable<String>(
                          data: item.nombre,
                          feedback: Material(
                            color: Colors.transparent,
                            child: SizedBox(
                              width: (sw * 0.13).clamp(44.0, 70.0),
                              height: (sw * 0.13).clamp(44.0, 70.0),
                              child: Image.asset(item.ruta,
                                  fit: BoxFit.contain,
                                  errorBuilder: (ctx, e, s) => const Icon(
                                      Icons.image, size: 40, color: Colors.grey)),
                            ),
                          ),
                          childWhenDragging: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFEEEEEE),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0F0F0),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFDDDDDD)),
                            ),
                            padding: const EdgeInsets.all(6),
                            child: Image.asset(
                              item.ruta,
                              fit: BoxFit.contain,
                              errorBuilder: (ctx, e, s) => const Icon(
                                  Icons.image_not_supported,
                                  size: 28,
                                  color: Colors.grey),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}