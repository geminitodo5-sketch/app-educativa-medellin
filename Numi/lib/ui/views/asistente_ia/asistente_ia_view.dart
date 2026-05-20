// ─────────────────────────────────────────────────────────────
//  lib/ui/views/asistente_ia/asistente_ia_view.dart
//  Pantalla del asistente de IA con RAG offline.
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../viewmodels/asistente_ia_view_model.dart';
import '../../../data/providers/app_state_provider.dart';
import '../../../data/providers/racha_provider.dart';
import 'rag_quiz_view.dart';

class AsistenteIaView extends ConsumerStatefulWidget {
  final String materiaInicial;
  final int gradoInicial;

  const AsistenteIaView({
    super.key,
    this.materiaInicial = 'matematicas',
    this.gradoInicial = 1,
  });

  @override
  ConsumerState<AsistenteIaView> createState() => _AsistenteIaViewState();
}

class _AsistenteIaViewState extends ConsumerState<AsistenteIaView> {
  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  static const _coloresMaterias = {
    'matematicas': Color(0xFF3E7DFE),
    'ciencias':    Color(0xFF3DCC52),
    'espanol':     Color(0xFFB83232),
    'ingles':      Color(0xFF8B5CF6),
    'sociales':    Color(0xFFF5A623),
  };

  static const _iconosMaterias = {
    'matematicas': Icons.calculate_rounded,
    'ciencias':    Icons.science_rounded,
    'espanol':     Icons.menu_book_rounded,
    'ingles':      Icons.language_rounded,
    'sociales':    Icons.public_rounded,
  };

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(asistenteIaViewModelProvider.notifier).inicializar(
            materia: widget.materiaInicial,
            grado: widget.gradoInicial,
          );
    });
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollAbajo() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _enviarMensaje(int? estudianteId) async {
    final pregunta = _inputCtrl.text.trim();
    if (pregunta.isEmpty) return;
    _inputCtrl.clear();
    ref.read(asistenteIaViewModelProvider.notifier)
        .preguntar(pregunta, estudianteId: estudianteId);
    if (estudianteId == null || !mounted) return;
    // Solo grados 3-5; el menú mostrará la pantalla al volver
    final grado = ref.read(estudianteActivoProvider)?.grado ?? 0;
    if (grado < 3) return;
    final svc = ref.read(rachaServiceProvider);
    final info = await svc.verificarRacha(estudianteId);
    if (info != null && mounted) {
      ref.read(rachaPendienteProvider.notifier).state = info;
    }
  }

  @override
  Widget build(BuildContext context) {
    final estado = ref.watch(asistenteIaViewModelProvider);
    final vm = ref.read(asistenteIaViewModelProvider.notifier);
    final estudiante = ref.watch(estudianteActivoProvider);

    final sw       = MediaQuery.of(context).size.width;
    final isTablet = sw >= 600;
    final color    = _coloresMaterias[estado.materiaActual] ?? const Color(0xFF3E7DFE);

    if (estado.mensajes.isNotEmpty) _scrollAbajo();

    final bodyContent = Column(
      children: [
        // ── Selector de materias ──────────────────────────────
        _SelectorMaterias(
          materiaActual: estado.materiaActual,
          descargado: estado.descargado,
          onMateriaSeleccionada: vm.cambiarMateria,
          colores: _coloresMaterias,
        ),
        // ── Chat ──────────────────────────────────────────────
        Expanded(
          child: estado.materiaDescargada
              ? _ChatArea(
                  mensajes: estado.mensajes,
                  scrollCtrl: _scrollCtrl,
                  color: color,
                  avatarEstudiante: estudiante?.personaje ?? 'pollito',
                )
              : _PantallaDescarga(
                  materia: estado.materiaActual,
                  progreso: estado.progresoDescargaActual,
                  descargando: estado.progresosDescarga
                      .containsKey(estado.materiaActual),
                  color: color,
                  onDescargar: () => _descargar(estado.materiaActual),
                ),
        ),
        // ── Input ──────────────────────────────────────────────
        if (estado.materiaDescargada)
          _InputBar(
            ctrl: _inputCtrl,
            respondiendo: estado.respondiendo,
            color: color,
            onEnviar: () => _enviarMensaje(estudiante?.id),
          ),
      ],
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      appBar: AppBar(
        backgroundColor: color,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            Icon(_iconosMaterias[estado.materiaActual],
                color: Colors.white, size: isTablet ? 24 : 22),
            const SizedBox(width: 8),
            Text(
              AsistenteIaViewModel.nombreMateria(estado.materiaActual),
              style: TextStyle(
                fontFamily: 'Hiruko',
                fontSize: isTablet ? 22.0 : 20.0,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        actions: [
          // Botón Quiz — solo para grados 3-5 con contenido descargado
          if (estado.gradoActual >= 3 && estado.materiaDescargada)
            IconButton(
              icon: const Icon(Icons.quiz_rounded, color: Colors.white),
              tooltip: 'Quiz',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => RagQuizView(
                    materia: estado.materiaActual,
                    grado: estado.gradoActual,
                  ),
                ),
              ),
            ),
          // Historial de conversaciones
          IconButton(
            icon: const Icon(Icons.history_rounded, color: Colors.white),
            tooltip: 'Historial',
            onPressed: () {
              final est = ref.read(estudianteActivoProvider);
              if (est == null || est.id == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Inicia sesión para ver tu historial.'),
                  ),
                );
                return;
              }
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => _HistorialSheet(
                  materia: estado.materiaActual,
                  estudianteId: est.id!,
                  color: color,
                ),
              );
            },
          ),
          // Indicador de grado (solo lectura)
          Container(
            margin: const EdgeInsets.only(right: 6),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'G${estado.gradoActual}',
              style: const TextStyle(
                fontFamily: 'Hiruko',
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: sw > 1024
          ? Center(child: SizedBox(width: 960, child: bodyContent))
          : bodyContent,
    );
  }

  Future<void> _descargar(String materia) async {
    try {
      await ref
          .read(asistenteIaViewModelProvider.notifier)
          .descargarMateria(materia);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al descargar: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

// ── Selector de materias ──────────────────────────────────────

class _SelectorMaterias extends StatefulWidget {
  final String materiaActual;
  final Map<String, bool> descargado;
  final void Function(String) onMateriaSeleccionada;
  final Map<String, Color> colores;

  static const _materias = [
    'matematicas', 'ciencias', 'espanol', 'ingles', 'sociales',
  ];
  static const _etiquetasLargas = {
    'matematicas': 'Matemáticas',
    'ciencias':    'Ciencias',
    'espanol':     'Español',
    'ingles':      'Inglés',
    'sociales':    'Sociales',
  };

  const _SelectorMaterias({
    required this.materiaActual,
    required this.descargado,
    required this.onMateriaSeleccionada,
    required this.colores,
  });

  @override
  State<_SelectorMaterias> createState() => _SelectorMateriasState();
}

class _SelectorMateriasState extends State<_SelectorMaterias> {
  final List<GlobalKey> _chipKeys =
      List.generate(5, (_) => GlobalKey());

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToActive());
  }

  @override
  void didUpdateWidget(_SelectorMaterias old) {
    super.didUpdateWidget(old);
    if (old.materiaActual != widget.materiaActual) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToActive());
    }
  }

  void _scrollToActive() {
    final idx = _SelectorMaterias._materias.indexOf(widget.materiaActual);
    if (idx < 0 || idx >= _chipKeys.length) return;
    final ctx = _chipKeys[idx].currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      alignment: 0.5,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final mq       = MediaQuery.of(context);
    final sw       = mq.size.width;
    final isTablet = sw >= 600;

    return LayoutBuilder(
      builder: (ctx, box) {
        return Container(
          color: Colors.white,
          padding: EdgeInsets.symmetric(vertical: isTablet ? 12.0 : 9.0),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            // ConstrainedBox con minWidth = ancho disponible:
            // · Si todos los chips caben → Row se estira al ancho completo
            //   y spaceEvenly los distribuye uniformemente.
            // · Si no caben → Row crece al ancho natural de los chips
            //   y el SingleChildScrollView permite deslizar.
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: box.maxWidth),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(
                  _SelectorMaterias._materias.length,
                  (i) {
                    final m      = _SelectorMaterias._materias[i];
                    final activa = m == widget.materiaActual;
                    final color  = widget.colores[m] ?? Colors.grey;
                    final ok     = widget.descargado[m] ?? false;
                    final label  = _SelectorMaterias._etiquetasLargas[m] ?? m;
                    return Padding(
                      key: _chipKeys[i],
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: GestureDetector(
                        onTap: () => widget.onMateriaSeleccionada(m),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: EdgeInsets.symmetric(
                            horizontal: isTablet ? 16.0 : 14.0,
                            vertical:   isTablet ? 10.0 :  8.0,
                          ),
                          decoration: BoxDecoration(
                            color: activa ? color : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: activa ? color : Colors.grey.shade300,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                label,
                                style: TextStyle(
                                  fontFamily: 'Hiruko',
                                  fontSize: isTablet ? 15.0 : 13.0,
                                  fontWeight: FontWeight.bold,
                                  color: activa
                                      ? Colors.white
                                      : Colors.grey.shade600,
                                ),
                              ),
                              if (ok) ...[
                                const SizedBox(width: 5),
                                Icon(
                                  Icons.check_circle_rounded,
                                  size: isTablet ? 14.0 : 12.0,
                                  color: activa ? Colors.white70 : color,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ── Pantalla cuando el paquete no está descargado ─────────────

class _PantallaDescarga extends StatelessWidget {
  final String materia;
  final double progreso;
  final bool descargando;
  final Color color;
  final VoidCallback onDescargar;

  const _PantallaDescarga({
    required this.materia,
    required this.progreso,
    required this.descargando,
    required this.color,
    required this.onDescargar,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (ctx, box) {
        final sw = box.maxWidth;
        final sh = box.maxHeight;
        final isTablet = sw >= 600;
        final iconSize = (sw * (isTablet ? 0.13 : 0.21)).clamp(60.0, 160.0);
        final titleFs  = (sw * (isTablet ? 0.034 : 0.056)).clamp(18.0, 32.0);
        final bodyFs   = (sw * (isTablet ? 0.022 : 0.036)).clamp(12.0, 18.0);
        final hPad     = (sw * 0.09).clamp(24.0, 96.0);
        final vGap     = (sh * 0.030).clamp(10.0, 32.0);

        return Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
                horizontal: hPad, vertical: vGap),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.download_for_offline_rounded,
                    size: iconSize, color: color),
                SizedBox(height: vGap),
                Text(
                  'Descarga el contenido',
                  style: TextStyle(
                    fontFamily: 'Hiruko',
                    fontSize: titleFs,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                SizedBox(height: vGap * 0.5),
                Text(
                  'Para usar el asistente de '
                  '${AsistenteIaViewModel.nombreMateria(materia)} '
                  'sin internet, descarga su base de conocimiento.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: bodyFs,
                    color: Colors.black54,
                  ),
                ),
                SizedBox(height: vGap * 1.5),
                if (descargando) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: progreso,
                      minHeight: isTablet ? 12.0 : 10.0,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  ),
                  SizedBox(height: vGap * 0.4),
                  Text(
                    '${(progreso * 100).toInt()}%',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: bodyFs,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ] else
                  ElevatedButton.icon(
                    onPressed: onDescargar,
                    icon: const Icon(Icons.download_rounded),
                    label: Text(
                      'Descargar ahora',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.bold,
                        fontSize: bodyFs,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        horizontal: isTablet ? 36.0 : 28.0,
                        vertical: isTablet ? 18.0 : 14.0,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Área de chat ──────────────────────────────────────────────

class _ChatArea extends StatelessWidget {
  final List<MensajeChat> mensajes;
  final ScrollController scrollCtrl;
  final Color color;
  final String avatarEstudiante;

  const _ChatArea({
    required this.mensajes,
    required this.scrollCtrl,
    required this.color,
    this.avatarEstudiante = 'pollito',
  });

  @override
  Widget build(BuildContext context) {
    if (mensajes.isEmpty) {
      return LayoutBuilder(
        builder: (ctx, constraints) {
          final sw = constraints.maxWidth;
          final sh = constraints.maxHeight;
          final isTablet = sw >= 600;
          // Rangos de clamp ampliados para aprovechar pantallas grandes
          final circleSize = (sw * 0.40).clamp(100.0, 260.0);
          final iconSize   = (sw * 0.23).clamp(60.0, 155.0);
          final titleFs = (sw * (isTablet ? 0.042 : 0.060)).clamp(22.0, 44.0);
          final bodyFs  = (sw * (isTablet ? 0.024 : 0.038)).clamp(13.0, 22.0);
          final hPad = (sw * 0.09).clamp(20.0, 120.0);
          final vPad = (sh * 0.05).clamp(16.0, 60.0);
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: sh),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: hPad,
                  vertical: vPad,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: circleSize,
                      height: circleSize,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.10),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.psychology_alt_rounded,
                        size: iconSize,
                        color: color.withValues(alpha: 0.70),
                      ),
                    ),
                    SizedBox(height: sh * 0.04),
                    Text(
                      '¡Hola! Soy Sabi 👋',
                      style: TextStyle(
                        fontFamily: 'Hiruko',
                        fontSize: titleFs,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: sh * 0.022),
                    Text(
                      'Tu compañero de aprendizaje inteligente.\n'
                      'Escribe una pregunta o elige un tema para comenzar.',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: bodyFs,
                        color: Colors.black54,
                        height: 1.6,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: sh * 0.045),
                    Wrap(
                      spacing: (sw * 0.025).clamp(8.0, 24.0),
                      runSpacing: (sh * 0.014).clamp(6.0, 18.0),
                      alignment: WrapAlignment.center,
                      children: const [
                        _ChipSugerencia('💡 Explícame un tema'),
                        _ChipSugerencia('📝 Ponme un ejemplo'),
                        _ChipSugerencia('❓ Tengo una duda'),
                        _ChipSugerencia('🔁 Repasa conmigo'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    }

    return LayoutBuilder(
      builder: (ctx, box) {
        final cw   = box.maxWidth;
        final hPad = cw >= 600 ? 16.0 : 12.0;
        return ListView.builder(
          controller: scrollCtrl,
          padding: EdgeInsets.fromLTRB(hPad, 8, hPad, 8),
          itemCount: mensajes.length,
          itemBuilder: (_, i) => _BurbujaMensaje(
            mensaje: mensajes[i],
            colorAsistente: color,
            avatarEstudiante: avatarEstudiante,
          ),
        );
      },
    );
  }
}

// ── Burbuja de mensaje ────────────────────────────────────────

class _BurbujaMensaje extends StatelessWidget {
  final MensajeChat mensaje;
  final Color colorAsistente;
  final String avatarEstudiante;

  const _BurbujaMensaje({
    required this.mensaje,
    required this.colorAsistente,
    this.avatarEstudiante = 'pollito',
  });

  @override
  Widget build(BuildContext context) {
    final esUsuario = mensaje.rol == RolMensaje.usuario;
    final sw        = MediaQuery.of(context).size.width;

    // Todas las dimensiones escalan proporcionalmente con el ancho de pantalla
    final avatarR  = (sw * 0.055).clamp(18.0, 32.0);
    final gap      = (sw * 0.018).clamp(6.0, 16.0);
    final fontSize = (sw * 0.040).clamp(14.0, 22.0);
    final hPadB    = (sw * 0.042).clamp(14.0, 28.0);
    final vPadB    = (sw * 0.028).clamp(10.0, 20.0);
    final vSpace   = (sw * 0.012).clamp(4.0, 12.0);

    final bubbleDecor = BoxDecoration(
      color: esUsuario ? colorAsistente : Colors.white,
      borderRadius: BorderRadius.only(
        topLeft: const Radius.circular(18),
        topRight: const Radius.circular(18),
        bottomLeft: Radius.circular(esUsuario ? 18 : 4),
        bottomRight: Radius.circular(esUsuario ? 4 : 18),
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.07),
          blurRadius: 6,
          offset: const Offset(0, 2),
        ),
      ],
    );

    final bubbleChild = mensaje.esCargando
        ? const _IndicadorEscribiendo()
        : Text(
            mensaje.texto,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: fontSize,
              color: esUsuario ? Colors.white : Colors.black87,
              height: 1.55,
            ),
          );

    final bubblePad = EdgeInsets.symmetric(
      horizontal: hPadB,
      vertical: vPadB,
    );

    return Padding(
      padding: EdgeInsets.symmetric(vertical: vSpace),
      child: Row(
        mainAxisAlignment:
            esUsuario ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: esUsuario
            // ── Usuario: burbuja con ancho proporcional grande + avatar ──
            ? [
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: (sw * 0.88).clamp(200.0, 750.0),
                  ),
                  child: Container(
                    padding: bubblePad,
                    decoration: bubbleDecor,
                    child: bubbleChild,
                  ),
                ),
                SizedBox(width: gap),
                CircleAvatar(
                  radius: avatarR,
                  backgroundImage: AssetImage(
                    'assets/images/avatares/avatar_${avatarEstudiante == 'pollito' ? 'pollo' : 'mono'}1.jpg',
                  ),
                ),
              ]
            // ── Asistente: Expanded → burbuja ocupa todo el ancho disponible ──
            : [
                CircleAvatar(
                  radius: avatarR,
                  backgroundImage: AssetImage(
                    'assets/images/avatares/avatar_${avatarEstudiante == 'pollito' ? 'mono' : 'pollo'}1.jpg',
                  ),
                ),
                SizedBox(width: gap),
                Expanded(
                  child: Container(
                    padding: bubblePad,
                    decoration: bubbleDecor,
                    child: bubbleChild,
                  ),
                ),
              ],
      ),
    );
  }
}

// ── Indicador "está escribiendo" ──────────────────────────────

class _IndicadorEscribiendo extends StatefulWidget {
  const _IndicadorEscribiendo();

  @override
  State<_IndicadorEscribiendo> createState() => _IndicadorEscribiendoState();
}

class _IndicadorEscribiendoState extends State<_IndicadorEscribiendo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final delay = i / 3;
            final t = (_ctrl.value - delay).clamp(0.0, 1.0);
            final opacity = (t < 0.5 ? t : 1.0 - t) * 2;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Opacity(
                opacity: opacity.clamp(0.2, 1.0),
                child: const CircleAvatar(
                  radius: 4,
                  backgroundColor: Colors.grey,
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

// ── Historial de conversaciones ───────────────────────────

class _HistorialSheet extends ConsumerWidget {
  final String materia;
  final int estudianteId;
  final Color color;

  const _HistorialSheet({
    required this.materia,
    required this.estudianteId,
    required this.color,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final histAsync = ref.watch(historialPorMateriaProvider(
      (estudianteId: estudianteId, materia: materia),
    ));

    return DraggableScrollableSheet(
      initialChildSize: 0.72,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      builder: (_, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 4),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Título
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
              child: Row(
                children: [
                  Icon(Icons.history_rounded, color: color, size: 22),
                  const SizedBox(width: 10),
                  Text(
                    'Historial — ${AsistenteIaViewModel.nombreMateria(materia)}',
                    style: TextStyle(
                      fontFamily: 'Hiruko',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: Colors.grey.shade100),
            // Contenido
            Expanded(
              child: histAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(
                  child: Text(
                    'No se pudo cargar el historial.',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ),
                data: (items) {
                  if (items.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.chat_bubble_outline_rounded,
                              size: 64, color: Colors.grey.shade200),
                          const SizedBox(height: 14),
                          Text(
                            'Aún no hay conversaciones\nguardadas en ${AsistenteIaViewModel.nombreMateria(materia)}.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 14,
                              color: Colors.grey.shade400,
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  return ListView.separated(
                    controller: scrollCtrl,
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, i) =>
                        _HistorialItem(item: items[i], color: color),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Ítem de historial ─────────────────────────────────────

class _HistorialItem extends StatelessWidget {
  final Map<String, dynamic> item;
  final Color color;

  const _HistorialItem({required this.item, required this.color});

  String _formatFecha(String? raw) {
    if (raw == null) return '';
    try {
      final dt = DateTime.parse(raw).toLocal();
      final h = dt.hour.toString().padLeft(2, '0');
      final m = dt.minute.toString().padLeft(2, '0');
      return '${dt.day}/${dt.month}/${dt.year}  $h:$m';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final pregunta = item['pregunta'] as String? ?? '';
    final respuesta = item['respuesta'] as String? ?? '';
    final fecha = _formatFecha(item['fecha'] as String?);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (fecha.isNotEmpty) ...[
            Text(
              fecha,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 11,
                color: Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 8),
          ],
          // Pregunta del usuario
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Tú',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  pregunta,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Respuesta del asistente
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Sabi',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.black54,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  respuesta,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    color: Colors.black87,
                    height: 1.4,
                  ),
                  maxLines: 6,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Barra de input ────────────────────────────────────────────

class _InputBar extends StatelessWidget {
  final TextEditingController ctrl;
  final bool respondiendo;
  final Color color;
  final VoidCallback onEnviar;

  const _InputBar({
    required this.ctrl,
    required this.respondiendo,
    required this.color,
    required this.onEnviar,
  });

  @override
  Widget build(BuildContext context) {
    final sw       = MediaQuery.of(context).size.width;
    final isTablet = sw >= 600;
    final hPad     = isTablet ? 16.0 : 12.0;
    final fontSize = (sw * (isTablet ? 0.026 : 0.038)).clamp(14.0, 18.0);
    final btnSize  = isTablet ? 52.0 : 48.0;

    return Container(
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(hPad, 8, hPad, 12),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F4FF),
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: TextField(
                  controller: ctrl,
                  enabled: !respondiendo,
                  maxLines: 3,
                  minLines: 1,
                  textCapitalization: TextCapitalization.sentences,
                  style: TextStyle(fontFamily: 'Poppins', fontSize: fontSize),
                  decoration: InputDecoration(
                    hintText: '¿Tienes alguna pregunta?',
                    hintStyle: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: fontSize,
                      color: Colors.black38,
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: isTablet ? 20.0 : 16.0,
                      vertical:   isTablet ? 14.0 : 10.0,
                    ),
                    border: InputBorder.none,
                  ),
                  onSubmitted: (_) => onEnviar(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: btnSize,
              height: btnSize,
              decoration: BoxDecoration(
                color: respondiendo ? Colors.grey.shade300 : color,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                onPressed: respondiendo ? null : onEnviar,
                icon: respondiendo
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : Icon(Icons.send_rounded,
                        color: Colors.white, size: isTablet ? 22 : 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Chip decorativo de sugerencia ────────────────────────────

class _ChipSugerencia extends StatelessWidget {
  final String texto;
  const _ChipSugerencia(this.texto);

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;
    final isTablet = sw >= 600;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: (sw * 0.042).clamp(12.0, 52.0),
        vertical: (sw * 0.022).clamp(8.0, 26.0),
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 4,
          ),
        ],
      ),
      child: Text(
        texto,
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: (sw * 0.034).clamp(11.0, isTablet ? 18.0 : 15.0),
          color: Colors.black54,
        ),
      ),
    );
  }
}
