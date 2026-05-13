// ─────────────────────────────────────────────────────────────
//  lib/ui/views/asistente_ia/rag_quiz_view.dart
//  Pantalla de quiz MCQ generado por RAG — T3.10
//  Grados 3-5: 5 correctas → FelicitacionesModal con video.
//  Estilo de feedback tomado de descubre_numeros_view.dart.
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../viewmodels/rag_quiz_view_model.dart';
import '../../viewmodels/asistente_ia_view_model.dart';
import '../../widgets/felicitaciones_modal.dart';
import '../../../data/providers/app_state_provider.dart';
import '../../../data/providers/database_provider.dart';
import '../../../data/providers/racha_provider.dart';
import '../../../data/services/feedback_sounds.dart';

class RagQuizView extends ConsumerStatefulWidget {
  final String materia;
  final int grado;

  const RagQuizView({
    super.key,
    required this.materia,
    required this.grado,
  });

  @override
  ConsumerState<RagQuizView> createState() => _RagQuizViewState();
}

class _RagQuizViewState extends ConsumerState<RagQuizView> {
  static const Color _verdeNumi = Color(0xFF59E347);
  static const Color _rojoNumi  = Color(0xFFF65757);

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

  static const _letrasOpciones = ['A', 'B', 'C', 'D'];

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(ragQuizViewModelProvider.notifier)
          .inicializar(widget.materia, widget.grado);
    });
  }

  Color get _colorMateria =>
      _coloresMaterias[widget.materia] ?? const Color(0xFF3E7DFE);

  @override
  Widget build(BuildContext context) {
    final estado     = ref.watch(ragQuizViewModelProvider);
    final estudiante = ref.watch(estudianteActivoProvider);
    final avatar     = estudiante?.personaje ?? 'pollito';

    return Scaffold(
      backgroundColor: _colorMateria,
      body: Column(
        children: [
          // ── Header ─────────────────────────────────────────────
          _QuizHeader(
            materia: widget.materia,
            colorMateria: _colorMateria,
            icono: _iconosMaterias[widget.materia] ?? Icons.quiz_rounded,
            correctas: estado.correctas,
            meta: RagQuizEstado.metaCorrectas,
            onClose: () => Navigator.of(context).pop(),
          ),

          // ── Cuerpo ─────────────────────────────────────────────
          Expanded(
            child: Container(
              width: double.infinity,
              clipBehavior: Clip.hardEdge,
              decoration: const BoxDecoration(
                color: Color(0xFFF0F4FF),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(36),
                  topRight: Radius.circular(36),
                ),
              ),
              child: SafeArea(
                top: false,
                child: _buildCuerpo(estado, avatar),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCuerpo(RagQuizEstado estado, String avatar) {
    if (estado.cargando) {
      return const Center(child: CircularProgressIndicator());
    }

    if (estado.sinContenido) {
      return _SinContenido(materia: widget.materia, color: _colorMateria);
    }

    final pregunta = estado.preguntaActual;
    if (pregunta == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;

    return Column(
      children: [
        SizedBox(height: h * 0.025),

        // ── Tarjeta de pregunta ───────────────────────────────
        Padding(
          padding: EdgeInsets.symmetric(horizontal: w * 0.053),
          child: _TarjetaPregunta(
            texto: pregunta.pregunta,
            tema: pregunta.tema,
            avatar: avatar,
            colorMateria: _colorMateria,
          ),
        ),

        SizedBox(height: h * 0.02),

        // ── Opciones — cada botón expande para llenar el espacio ──
        Expanded(
          child: Padding(
            padding: EdgeInsets.fromLTRB(w * 0.053, 0, w * 0.053, h * 0.02),
            child: Column(
              children: List.generate(pregunta.opciones.length, (i) {
                final isLast = i == pregunta.opciones.length - 1;
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      bottom: isLast ? 0 : h * 0.018,
                    ),
                    child: _BotonOpcion(
                      letra: _letrasOpciones[i],
                      texto: pregunta.opciones[i],
                      estado: _estadoBoton(estado, i, pregunta.indiceCorrecto),
                      colorMateria: _colorMateria,
                      onTap: estado.ultimaRespuestaCorrecta == null
                          ? () => _onResponder(i)
                          : null,
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ],
    );
  }

  _EstadoBoton _estadoBoton(
      RagQuizEstado estado, int indice, int indiceCorrecto) {
    if (estado.ultimaRespuestaCorrecta == null) return _EstadoBoton.normal;
    if (indice == indiceCorrecto) return _EstadoBoton.correcto;
    return _EstadoBoton.normal;
  }

  // Número de actividades por materia (para registrar progreso al 100%)
  static const _actividadesQuiz = {
    'matematicas': 3,
    'ciencias':    4,
    'espanol':     3,
    'ingles':      3,
    'sociales':    3,
  };

  // Mapeo al nombre que acepta el CHECK constraint del DB
  // La tabla SQLite requiere 'español' (con acento)
  static const _materiaDB = {
    'espanol': 'español',
  };

  // Registra progreso al 100% y verifica la racha al completar el quiz.
  Future<void> _onQuizCompletado() async {
    final estudiante = ref.read(estudianteActivoProvider);
    if (estudiante == null || estudiante.id == null) return;

    final repo      = ref.read(progresoRepositoryProvider);
    final total     = _actividadesQuiz[widget.materia] ?? 3;
    final materiaDB = _materiaDB[widget.materia] ?? widget.materia;
    // Usa el grado registrado del estudiante para que menuProgresoProvider
    // pueda encontrar los datos (siempre consulta con estudiante.grado).
    final grado     = estudiante.grado;

    // Registra N actividades al 100% para que porcentajeMateria() devuelva 100%
    for (int i = 1; i <= total; i++) {
      await repo.registrarIntento(
        estudianteId: estudiante.id!,
        grado:        grado,
        materia:      materiaDB,
        actividad:    'quiz_rag_$i',
        porcentaje:   100.0,
      );
    }

    // Verificar racha (grados 3-5)
    if (!mounted) return;
    final svc  = ref.read(rachaServiceProvider);
    final info = await svc.verificarRacha(estudiante.id!);
    if (info != null && mounted) {
      ref.read(rachaPendienteProvider.notifier).state = info;
    }
  }

  void _onResponder(int opcion) {
    final vm = ref.read(ragQuizViewModelProvider.notifier);
    vm.responder(opcion);

    final estado     = ref.read(ragQuizViewModelProvider);
    final esCorrecto = estado.ultimaRespuestaCorrecta == true;

    _mostrarFeedback(esCorrecto, estado.quizCompletado);
  }

  void _mostrarFeedback(bool esCorrecto, bool quizCompletado) {
    FeedbackSounds.instance.reproducir(esCorrecto);
    final mq       = MediaQuery.of(context);
    final sw       = mq.size.width;
    final isTablet = sw >= 600;

    showModalBottomSheet(
      context: context,
      isDismissible: false,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: mq.viewInsets.bottom),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: (sw * (isTablet ? 0.08 : 0.06)).clamp(20.0, 60.0),
            vertical: 26,
          ),
          decoration: BoxDecoration(
            color: esCorrecto
                ? const Color(0xFFD7FFD3)
                : const Color(0xFFFFD3D3),
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
                    color: esCorrecto ? _verdeNumi : _rojoNumi,
                    size: isTablet ? 52 : 42,
                  ),
                  SizedBox(width: isTablet ? 20 : 14),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          esCorrecto ? '¡Correcto!' : '¡Incorrecto!',
                          style: TextStyle(
                            fontFamily: 'Hiruko',
                            fontSize: (sw * (isTablet ? 0.038 : 0.054))
                                .clamp(18.0, 30.0),
                            fontWeight: FontWeight.bold,
                            color: esCorrecto
                                ? Colors.green[900]
                                : Colors.red[900],
                          ),
                        ),
                        if (esCorrecto)
                          Text(
                            '¡Muy bien! Sigue así 🌟',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: (sw * (isTablet ? 0.022 : 0.032))
                                  .clamp(12.0, 18.0),
                              color: Colors.green[800],
                            ),
                          )
                        else
                          Text(
                            'No te rindas, ¡inténtalo de nuevo!',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: (sw * (isTablet ? 0.022 : 0.032))
                                  .clamp(12.0, 18.0),
                              color: Colors.red[800],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: isTablet ? 28 : 20),
              SizedBox(
                width: double.infinity,
                height: isTablet ? 64 : 54,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: esCorrecto ? _verdeNumi : _rojoNumi,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () async {
                    Navigator.pop(ctx);
                    if (esCorrecto) {
                      if (quizCompletado) {
                        // Registrar progreso 100% + racha antes del video
                        await _onQuizCompletado();
                        if (!mounted) return;
                        FelicitacionesModal.mostrar(
                          context,
                          duracion: const Duration(seconds: 6),
                          onFinished: () => Navigator.of(context).pop(),
                        );
                      } else {
                        ref
                            .read(ragQuizViewModelProvider.notifier)
                            .avanzar();
                      }
                    } else {
                      ref
                          .read(ragQuizViewModelProvider.notifier)
                          .reintentarActual();
                    }
                  },
                  child: Text(
                    esCorrecto
                        ? (quizCompletado ? '🎉 ¡Completado!' : 'Continuar')
                        : 'Reintentar',
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.bold,
                      fontSize:
                          (sw * (isTablet ? 0.028 : 0.042))
                              .clamp(14.0, 22.0),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Header con barra de progreso ──────────────────────────────

class _QuizHeader extends StatelessWidget {
  final String materia;
  final Color colorMateria;
  final IconData icono;
  final int correctas;
  final int meta;
  final VoidCallback onClose;

  const _QuizHeader({
    required this.materia,
    required this.colorMateria,
    required this.icono,
    required this.correctas,
    required this.meta,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final mq      = MediaQuery.of(context);
    final topPad  = mq.padding.top;
    final sw      = mq.size.width;
    final sh      = mq.size.height;
    final isTablet = sw >= 600;

    final contentH = (sh * 0.13).clamp(72.0, 120.0);
    final totalH   = topPad + contentH;

    return SizedBox(
      height: totalH,
      child: Stack(
        children: [
          Positioned.fill(
            top: topPad,
            child: Align(
              alignment: const Alignment(0, -0.2),
              child: Padding(
                padding: EdgeInsets.symmetric(
                    horizontal: isTablet ? 80.0 : 56.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(icono, color: Colors.white,
                            size: (sw * 0.06).clamp(20.0, 32.0)),
                        const SizedBox(width: 8),
                        Text(
                          AsistenteIaViewModel.nombreMateria(materia),
                          style: TextStyle(
                            fontFamily: 'Hiruko',
                            fontSize:
                                (sw * (isTablet ? 0.044 : 0.054))
                                    .clamp(18.0, 34.0),
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$correctas / $meta correctas',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize:
                            (sw * (isTablet ? 0.022 : 0.030))
                                .clamp(11.0, 18.0),
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Botón cerrar
          Positioned(
            top: topPad + 4,
            right: 8,
            child: IconButton(
              icon: Icon(
                Icons.close_rounded,
                color: Colors.white,
                size: (sw * 0.070).clamp(22.0, 36.0),
              ),
              onPressed: onClose,
            ),
          ),
          // Barra de progreso
          Positioned(
            bottom: 10,
            left: isTablet ? 60 : 40,
            right: isTablet ? 60 : 40,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: correctas / meta,
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                valueColor: const AlwaysStoppedAnimation<Color>(
                  Color(0xFF59E347),
                ),
                minHeight: (sh * 0.013).clamp(8.0, 14.0),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Tarjeta de pregunta ───────────────────────────────────────

class _TarjetaPregunta extends StatelessWidget {
  final String texto;
  final String tema;
  final String avatar;
  final Color colorMateria;

  const _TarjetaPregunta({
    required this.texto,
    required this.tema,
    required this.avatar,
    required this.colorMateria,
  });

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;
    final isTablet = sw >= 600;

    // El tutor NUMI usa el personaje opuesto al del estudiante
    final avatarTutor = avatar == 'pollito' ? 'mono' : 'pollo';

    return Container(
      padding: EdgeInsets.all(sw * 0.048),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: colorMateria.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // NUMI avatar + etiqueta del tema
          Row(
            children: [
              CircleAvatar(
                radius: isTablet ? 26 : 22,
                backgroundImage: AssetImage(
                  'assets/images/avatares/avatar_${avatarTutor}1.jpg',
                ),
              ),
              SizedBox(width: sw * 0.027),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pregunta sobre:',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize:
                            (sw * (isTablet ? 0.020 : 0.028)).clamp(10.0, 16.0),
                        color: Colors.grey.shade500,
                      ),
                    ),
                    if (tema.isNotEmpty)
                      Text(
                        tema,
                        style: TextStyle(
                          fontFamily: 'Hiruko',
                          fontSize:
                              (sw * (isTablet ? 0.026 : 0.034))
                                  .clamp(13.0, 20.0),
                          fontWeight: FontWeight.bold,
                          color: colorMateria,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: sw * 0.037),
          Text(
            texto,
            style: TextStyle(
              fontFamily: 'Hiruko',
              fontSize: (sw * (isTablet ? 0.038 : 0.050)).clamp(17.0, 28.0),
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1E293B),
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Estado visual de cada botón de opción ─────────────────────

enum _EstadoBoton { normal, correcto }

// ── Botón de opción ───────────────────────────────────────────

class _BotonOpcion extends StatelessWidget {
  final String letra;
  final String texto;
  final _EstadoBoton estado;
  final Color colorMateria;
  final VoidCallback? onTap;

  const _BotonOpcion({
    required this.letra,
    required this.texto,
    required this.estado,
    required this.colorMateria,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;
    final isTablet = sw >= 600;

    final Color bgColor;
    final Color borderColor;
    final Color letraColor;
    final Color textColor;

    switch (estado) {
      case _EstadoBoton.correcto:
        bgColor     = const Color(0xFFD7FFD3);
        borderColor = const Color(0xFF59E347);
        letraColor  = const Color(0xFF59E347);
        textColor   = Colors.green.shade900;
        break;
      case _EstadoBoton.normal:
        bgColor     = Colors.white;
        borderColor = Colors.grey.shade200;
        letraColor  = colorMateria;
        textColor   = const Color(0xFF1E293B);
        break;
    }

    return GestureDetector(
      onTap: onTap,
      child: SizedBox.expand(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(
            horizontal: sw * 0.037,
            vertical: sw * 0.022,
          ),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor, width: 1.8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: isTablet ? 44 : 38,
                height: isTablet ? 44 : 38,
                decoration: BoxDecoration(
                  color: letraColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(
                  letra,
                  style: TextStyle(
                    fontFamily: 'Hiruko',
                    fontSize:
                        (sw * (isTablet ? 0.030 : 0.042)).clamp(14.0, 24.0),
                    fontWeight: FontWeight.bold,
                    color: letraColor,
                  ),
                ),
              ),
              SizedBox(width: sw * 0.035),
              Expanded(
                child: Text(
                  texto,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize:
                        (sw * (isTablet ? 0.026 : 0.036)).clamp(13.0, 20.0),
                    color: textColor,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Sin contenido descargado ──────────────────────────────────

class _SinContenido extends StatelessWidget {
  final String materia;
  final Color color;

  const _SinContenido({required this.materia, required this.color});

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;
    final sh = MediaQuery.of(context).size.height;

    return Center(
      child: Padding(
        padding: EdgeInsets.all(sw * 0.085),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.download_for_offline_rounded, size: sw * 0.213, color: color),
            SizedBox(height: sh * 0.02),
            Text(
              'Contenido no descargado',
              style: TextStyle(
                fontFamily: 'Hiruko',
                fontSize: sw * 0.059,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            SizedBox(height: sh * 0.01),
            Text(
              'Descarga el contenido de '
              '${AsistenteIaViewModel.nombreMateria(materia)} '
              'desde el chat del asistente para activar el Quiz.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: sw * 0.037,
                color: Colors.black54,
              ),
            ),
            SizedBox(height: sh * 0.03),
            ElevatedButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back_rounded),
              label: const Text(
                'Volver al chat',
                style: TextStyle(fontFamily: 'Poppins'),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: sw * 0.075, vertical: sh * 0.017),
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
