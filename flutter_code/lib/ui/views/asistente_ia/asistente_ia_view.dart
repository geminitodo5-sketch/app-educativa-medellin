// ─────────────────────────────────────────────────────────────
//  lib/ui/views/asistente_ia/asistente_ia_view.dart
//  Pantalla del asistente de IA con RAG offline.
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../viewmodels/asistente_ia_view_model.dart';
import '../../../data/providers/app_state_provider.dart';
import '../../../data/providers/racha_provider.dart';

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

    final color = _coloresMaterias[estado.materiaActual] ?? const Color(0xFF3E7DFE);

    if (estado.mensajes.isNotEmpty) _scrollAbajo();

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
            Icon(_iconosMaterias[estado.materiaActual], color: Colors.white, size: 22),
            const SizedBox(width: 8),
            Text(
              AsistenteIaViewModel.nombreMateria(estado.materiaActual),
              style: const TextStyle(
                fontFamily: 'Hiruko',
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        actions: [
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
          // Selector de grado
          PopupMenuButton<int>(
            icon: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${estado.gradoActual}°',
                style: const TextStyle(
                  fontFamily: 'Hiruko',
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            onSelected: vm.cambiarGrado,
            itemBuilder: (_) => List.generate(
              5,
              (i) => PopupMenuItem(
                value: i + 1,
                child: Text('Grado ${i + 1}',
                    style: const TextStyle(fontFamily: 'Poppins')),
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
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
      ),
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

class _SelectorMaterias extends StatelessWidget {
  final String materiaActual;
  final Map<String, bool> descargado;
  final void Function(String) onMateriaSeleccionada;
  final Map<String, Color> colores;

  static const _materias = [
    'matematicas', 'ciencias', 'espanol', 'ingles', 'sociales',
  ];
  static const _etiquetas = {
    'matematicas': 'Mat',
    'ciencias':    'Cie',
    'espanol':     'Esp',
    'ingles':      'Ing',
    'sociales':    'Soc',
  };

  const _SelectorMaterias({
    required this.materiaActual,
    required this.descargado,
    required this.onMateriaSeleccionada,
    required this.colores,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: _materias.map((m) {
          final activa = m == materiaActual;
          final color = colores[m] ?? Colors.grey;
          final ok = descargado[m] ?? false;
          return GestureDetector(
            onTap: () => onMateriaSeleccionada(m),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                    _etiquetas[m] ?? m,
                    style: TextStyle(
                      fontFamily: 'Hiruko',
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: activa ? Colors.white : Colors.grey.shade600,
                    ),
                  ),
                  if (ok) ...[
                    const SizedBox(width: 4),
                    Icon(
                      Icons.check_circle_rounded,
                      size: 12,
                      color: activa ? Colors.white70 : color,
                    ),
                  ],
                ],
              ),
            ),
          );
        }).toList(),
      ),
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.download_for_offline_rounded, size: 80, color: color),
            const SizedBox(height: 16),
            Text(
              'Descarga el contenido',
              style: TextStyle(
                fontFamily: 'Hiruko',
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Para usar el asistente de ${AsistenteIaViewModel.nombreMateria(materia)} sin internet, descarga su base de conocimiento.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 24),
            if (descargando) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progreso,
                  minHeight: 10,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '${(progreso * 100).toInt()}%',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ] else
              ElevatedButton.icon(
                onPressed: onDescargar,
                icon: const Icon(Icons.download_rounded),
                label: const Text(
                  'Descargar ahora',
                  style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Área de chat ──────────────────────────────────────────────

class _ChatArea extends StatelessWidget {
  final List<MensajeChat> mensajes;
  final ScrollController scrollCtrl;
  final Color color;

  const _ChatArea({
    required this.mensajes,
    required this.scrollCtrl,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    if (mensajes.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.chat_bubble_outline_rounded, size: 60, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(
              'Escribe una pregunta para empezar',
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

    return ListView.builder(
      controller: scrollCtrl,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: mensajes.length,
      itemBuilder: (_, i) => _BurbujaMensaje(
        mensaje: mensajes[i],
        colorAsistente: color,
      ),
    );
  }
}

// ── Burbuja de mensaje ────────────────────────────────────────

class _BurbujaMensaje extends StatelessWidget {
  final MensajeChat mensaje;
  final Color colorAsistente;

  const _BurbujaMensaje({
    required this.mensaje,
    required this.colorAsistente,
  });

  @override
  Widget build(BuildContext context) {
    final esUsuario = mensaje.rol == RolMensaje.usuario;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment:
            esUsuario ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!esUsuario) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: colorAsistente,
              child: const Icon(Icons.psychology_rounded,
                  color: Colors.white, size: 18),
            ),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
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
              ),
              child: mensaje.esCargando
                  ? const _IndicadorEscribiendo()
                  : Text(
                      mensaje.texto,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        color: esUsuario ? Colors.white : Colors.black87,
                        height: 1.4,
                      ),
                    ),
            ),
          ),
          if (esUsuario) const SizedBox(width: 6),
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
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
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
                  style: const TextStyle(fontFamily: 'Poppins', fontSize: 14),
                  decoration: const InputDecoration(
                    hintText: '¿Tienes alguna pregunta?',
                    hintStyle: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      color: Colors.black38,
                    ),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    border: InputBorder.none,
                  ),
                  onSubmitted: (_) => onEnviar(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 48,
              height: 48,
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
                    : const Icon(Icons.send_rounded,
                        color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
