// lib/ui/views/ciencias/vivo_no_vivo_screen.dart

import 'dart:convert';
import 'dart:math' show sin, pi;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/providers/app_state_provider.dart';
import '../../../data/providers/database_provider.dart';
import '../../../data/models/sync_queue_model.dart';
import '../terminado.dart';

const _p1 = 'assets/images/actividades/ciencias_naturales/pantalla 1/';
const _p2 = 'assets/images/actividades/ciencias_naturales/pantalla 2/';
const _p3 = 'assets/images/actividades/ciencias_naturales/pantalla 3/';

// ── Popup de retroalimentación ────────────────────────────────────────────
void _mostrarFeedback(BuildContext context, bool esCorrecto, VoidCallback onAction) {
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
                  esCorrecto ? '¡Excelente trabajo!' : '¡Casi lo tienes!',
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
          // PageView ocupa toda la pantalla
          PageView(
            controller: _ctrl,
            onPageChanged: (i) => setState(() => _pagina = i),
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _PageCard(
                title: '¿Vivo o no Vivo?',
                dots: _buildDots(),
                child: _Actividad1(onNext: _siguiente),
              ),
              _PageCard(
                title: '¿Vivo o no Vivo?',
                dots: _buildDots(),
                child: _Actividad2(onNext: _siguiente),
              ),
              _PageCard(
                title: '¿Vivo o no Vivo?',
                dots: _buildDots(),
                child: _Actividad3(onFinish: _irATerminado),
              ),
            ],
          ),
          // Botón X flotante sobre todo, en la esquina superior derecha
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

// ── Tarjeta (passthrough — el estilo lo provee _PageCard) ────────────────
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
  const _PageCard({required this.title, required this.child, required this.dots});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Fondo verde que cubre la mitad superior
        Container(color: const Color(0xFF3DCC52)),
        // Columna principal
        Column(
          children: [
            // Bloque verde — título centrado, más alto
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

// ── Fila de instrucción ───────────────────────────────────────────────────
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

// ═══════════════════════════════════════════════════════════════════════════
//  ACTIVIDAD 1 — Clasificar el cocodrilo: ¿vivo o no vivo?
// ═══════════════════════════════════════════════════════════════════════════
class _Actividad1 extends StatefulWidget {
  final VoidCallback onNext;
  const _Actividad1({required this.onNext});

  @override
  State<_Actividad1> createState() => _Actividad1State();
}

class _Actividad1State extends State<_Actividad1>
    with SingleTickerProviderStateMixin {
  String? _seleccion;
  late final AnimationController _shake = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 500),
  );

  @override
  void dispose() {
    _shake.dispose();
    super.dispose();
  }

  void _responder(BuildContext context, String opcion) {
    if (_seleccion != null) return;
    setState(() => _seleccion = opcion);
    final correcto = opcion == 'vivo';
    if (!correcto) _shake.forward(from: 0);
    _mostrarFeedback(context, correcto, () {
      if (correcto) {
        widget.onNext();
      } else {
        setState(() => _seleccion = null);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return _Tarjeta(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Instruccion(
              'Ayúdame a decidir si estos son seres vivos o no vivos'),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Image.asset(
                '${_p1}cocodrilo.png',
                fit: BoxFit.contain,
                errorBuilder: (ctx, e, s) => const Icon(
                    Icons.image_not_supported,
                    size: 80,
                    color: Colors.grey),
              ),
            ),
          ),
          AnimatedBuilder(
            animation: _shake,
            builder: (_, child) {
              final dx = _seleccion == 'no_vivo'
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
              color: color.withOpacity(0.5),
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
  const _Actividad2({required this.onNext});

  @override
  State<_Actividad2> createState() => _Actividad2State();
}

class _Actividad2State extends State<_Actividad2> {
  // índice 0 = pato (correcto)
  static const _nombres = ['pato', 'roca', 'libro', 'globo'];
  static const _rutas = [
    '${_p2}pato.png',
    '${_p2}roca.png',
    '${_p2}libro.png',
    '${_p2}globo.png',
  ];
  static const _indexCorrecto = 0;

  int? _seleccionado;

  void _seleccionar(BuildContext context, int idx) {
    if (_seleccionado != null) return;
    setState(() => _seleccionado = idx);
    final correcto = idx == _indexCorrecto;
    _mostrarFeedback(context, correcto, () {
      if (correcto) {
        widget.onNext();
      } else {
        setState(() => _seleccionado = null);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return _Tarjeta(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Instrucción al tope del bloque blanco
          const SizedBox(height: 20),
          _Instruccion('Elige el ser vivo entre los no vivos'),
          // Grid centrado en el espacio restante
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
                              color: Colors.black.withOpacity(0.06),
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
  const _Actividad3({required this.onFinish});

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

  final Set<String> _colocados = {};
  bool _hovering = false;

  bool get _completado => _colocados.length >= _meta;

  void _onDrop(BuildContext context, String nombre) {
    final item = _items.firstWhere((i) => i.nombre == nombre);
    if (_colocados.contains(nombre)) return;
    if (!item.esVida) {
      _mostrarFeedback(context, false, () {});
      return;
    }
    setState(() => _colocados.add(nombre));
    _mostrarFeedback(context, true, () {
      if (_completado) widget.onFinish();
    });
  }

  @override
  Widget build(BuildContext context) {
    return _Tarjeta(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Instrucción al tope del bloque blanco
          const SizedBox(height: 20),
          _Instruccion(
              'Arrastra dentro del cuadro los elementos más importantes para vivir'),
          // Contenido centrado en el espacio restante
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Zona de drop — ancho completo, más alta
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
                    child: AspectRatio(
                      aspectRatio: 1.1,
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
                                    final it = _items
                                        .firstWhere((i) => i.nombre == n);
                                    return Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: const Color(0xCCFFFFFF),
                                        borderRadius:
                                            BorderRadius.circular(8),
                                      ),
                                      padding: const EdgeInsets.all(4),
                                      child: Image.asset(it.ruta,
                                          fit: BoxFit.contain),
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
          ),
                  // Bandeja de elementos arrastrables
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
                    child: Container(
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
                                width: 50,
                                height: 50,
                                child: Image.asset(item.ruta,
                                    fit: BoxFit.contain,
                                    errorBuilder: (ctx, e, s) => const Icon(
                                        Icons.image,
                                        size: 40,
                                        color: Colors.grey)),
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