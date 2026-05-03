// ─────────────────────────────────────────────────────────────
//  lib/ui/views/menu_3_a_5_view.dart
//  Menú principal para grados 3, 4 y 5.
//  Toda la interacción pasa por el asistente RAG offline.
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/providers/app_state_provider.dart';
import '../../data/providers/database_provider.dart';
import '../../data/providers/musica_provider.dart';
import '../../data/services/descarga_paquete_service.dart';
import '../../main.dart' show routeObserver;
import 'configuracion_view.dart';
import 'asistente_ia/asistente_ia_view.dart';

// ── Datos de cada materia ─────────────────────────────────────

class _MateriaInfo {
  final String clave;
  final String nombre;
  final String categoria;
  final String titulo;
  final Color color;
  final Color sombra;
  final IconData icono;
  final String imagen;

  const _MateriaInfo({
    required this.clave,
    required this.nombre,
    required this.categoria,
    required this.titulo,
    required this.color,
    required this.sombra,
    required this.icono,
    required this.imagen,
  });
}

const _materias = [
  _MateriaInfo(
    clave: 'matematicas',
    nombre: 'Matemáticas',
    categoria: 'Matemática',
    titulo: 'Matemática Divertida',
    color: Color(0xFF3E7DFE),
    sombra: Color(0xFF2C60D2),
    icono: Icons.calculate_rounded,
    imagen: 'assets/images/menu_materias/123_1.png',
  ),
  _MateriaInfo(
    clave: 'ciencias',
    nombre: 'Ciencias',
    categoria: 'Ciencias Naturales',
    titulo: 'Mis Pequeñas Ciencias',
    color: Color(0xFF3DCC52),
    sombra: Color(0xFF22A45D),
    icono: Icons.science_rounded,
    imagen: 'assets/images/menu_materias/planta_1.png',
  ),
  _MateriaInfo(
    clave: 'espanol',
    nombre: 'Español',
    categoria: 'Español',
    titulo: 'Español Avanzado',
    color: Color(0xFFEF5353),
    sombra: Color(0xFFC53030),
    icono: Icons.menu_book_rounded,
    imagen: 'assets/images/menu_materias/alfabeto_1.png',
  ),
  _MateriaInfo(
    clave: 'sociales',
    nombre: 'Sociales',
    categoria: 'Ciencias Sociales',
    titulo: 'Explorando el Mundo',
    color: Color(0xFFF5A623),
    sombra: Color(0xFFB8710A),
    icono: Icons.public_rounded,
    imagen: 'assets/images/menu_materias/globo_1.png',
  ),
  _MateriaInfo(
    clave: 'ingles',
    nombre: 'Inglés',
    categoria: 'Inglés',
    titulo: 'Inglés Explorando',
    color: Color(0xFF8B5CF6),
    sombra: Color(0xFF6A3592),
    icono: Icons.language_rounded,
    imagen: 'assets/images/menu_materias/libros_1.png',
  ),
];

// ── Item para barras de progreso ──────────────────────────────

class _ProgresoItem {
  final String clave;
  final String etiqueta;
  final Color color;
  final Color sombra;

  const _ProgresoItem({
    required this.clave,
    required this.etiqueta,
    required this.color,
    required this.sombra,
  });
}

const _progresoItems = [
  _ProgresoItem(
    clave: 'matematicas',
    etiqueta: 'matemáticas',
    color: Color(0xFF3E7DFE),
    sombra: Color(0xFF2C60D2),
  ),
  _ProgresoItem(
    clave: 'ingles',
    etiqueta: 'inglés',
    color: Color(0xFF8B5CF6),
    sombra: Color(0xFF6A3592),
  ),
  _ProgresoItem(
    clave: 'ciencias',
    etiqueta: 'ciencias naturales',
    color: Color(0xFF3DCC52),
    sombra: Color(0xFF22A45D),
  ),
  _ProgresoItem(
    clave: 'español',
    etiqueta: 'español',
    color: Color(0xFFEF5353),
    sombra: Color(0xFFC53030),
  ),
  _ProgresoItem(
    clave: 'sociales',
    etiqueta: 'sociales',
    color: Color(0xFFF5A623),
    sombra: Color(0xFFB8710A),
  ),
];

// ── Pantalla ──────────────────────────────────────────────────

class Menu3A5Screen extends ConsumerStatefulWidget {
  const Menu3A5Screen({super.key});

  @override
  ConsumerState<Menu3A5Screen> createState() => _Menu3A5ScreenState();
}

class _Menu3A5ScreenState extends ConsumerState<Menu3A5Screen> with RouteAware {
  int _tabIndex = 0;
  final Map<String, bool> _descargado = {};
  final Map<String, double> _progresosDescarga = {};
  final Set<String> _descargando = {};
  bool _verificando = true;

  late final DescargaPaqueteService _svc;

  // Evita doble-salir cuando dispose corre después de didPushNext.
  bool _salidoPorPush = false;

  @override
  void initState() {
    super.initState();
    _svc = DescargaPaqueteService(ref.read(sqliteServiceProvider));
    _verificarDescargas();
    ref.read(musicaServiceProvider).entrar();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void didPushNext() {
    _salidoPorPush = true;
    ref.read(musicaServiceProvider).salir();
  }

  @override
  void didPopNext() {
    _salidoPorPush = false;
    ref.read(musicaServiceProvider).entrar();
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    if (!_salidoPorPush) ref.read(musicaServiceProvider).salir();
    super.dispose();
  }

  Future<void> _verificarDescargas() async {
    setState(() => _verificando = true);
    for (final m in _materias) {
      _descargado[m.clave] = await _svc.estaDescargado(m.clave);
    }
    if (mounted) setState(() => _verificando = false);
  }

  Future<void> _descargar(String clave) async {
    if (_descargando.contains(clave)) return;
    setState(() {
      _descargando.add(clave);
      _progresosDescarga[clave] = 0.0;
    });
    try {
      await _svc.descargarPaquete(
        clave,
        onProgress: (p) {
          if (mounted) setState(() => _progresosDescarga[clave] = p);
        },
      );
      if (mounted) {
        setState(() {
          _descargado[clave] = true;
          _descargando.remove(clave);
          _progresosDescarga.remove(clave);
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _descargando.remove(clave);
        _progresosDescarga.remove(clave);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al descargar $clave: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _abrirAsistente(_MateriaInfo materia) {
    final estudiante = ref.read(estudianteActivoProvider);
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (_) => AsistenteIaView(
              materiaInicial: materia.clave,
              gradoInicial: estudiante?.grado ?? 3,
            ),
          ),
        )
        .then((_) => _verificarDescargas());
  }

  Future<void> _abrirUltimoChat() async {
    final estudiante = ref.read(estudianteActivoProvider);
    if (estudiante?.id == null) {
      _abrirAsistente(_materias.first);
      return;
    }
    final db = ref.read(sqliteServiceProvider);
    final rows = await db.rawQuery(
      'SELECT materia FROM historial_rag WHERE estudiante_id = ? ORDER BY fecha DESC LIMIT 1',
      [estudiante!.id],
    );
    String clave = 'matematicas';
    if (rows.isNotEmpty) {
      final m = rows.first['materia'] as String;
      clave = m == 'español' ? 'espanol' : m;
    }
    final materia = _materias.firstWhere(
      (m) => m.clave == clave,
      orElse: () => _materias.first,
    );
    _abrirAsistente(materia);
  }

  String get _saludo {
    final h = DateTime.now().hour;
    if (h < 12) return 'Buenos días';
    if (h < 18) return 'Buenas tardes';
    return 'Buenas noches';
  }

  @override
  Widget build(BuildContext context) {
    final estudiante = ref.watch(estudianteActivoProvider);
    final nombre = estudiante?.nombre ?? 'Estudiante';
    final avatar = estudiante?.personaje ?? 'pollito';
    final nivel = estudiante?.grado ?? 3;
    final progresoAsync = ref.watch(menuProgresoProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Stack(
        children: [
          IndexedStack(
            index: _tabIndex,
            children: [
              _HomeTab(
                saludo: _saludo,
                nombre: nombre,
                avatar: avatar,
                nivel: nivel,
                verificando: _verificando,
                descargado: _descargado,
                descargando: _descargando,
                progresosDescarga: _progresosDescarga,
                onDescargar: _descargar,
                onAbrir: _abrirAsistente,
                onAbrirUltimoChat: _abrirUltimoChat,
              ),
              _ProgresoTab(
                nombre: nombre,
                avatar: avatar,
                nivel: nivel,
                progresoAsync: progresoAsync,
              ),
            ],
          ),

          // Barra de navegación inferior
          Align(
            alignment: Alignment.bottomCenter,
            child: _NavBar(
              selectedIndex: _tabIndex,
              onHome: () => setState(() => _tabIndex = 0),
              onProgreso: () => setState(() => _tabIndex = 1),
              onConfiguracion: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ConfiguracionView()),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Tab: Inicio ───────────────────────────────────────────────

class _HomeTab extends StatefulWidget {
  final String saludo;
  final String nombre;
  final String avatar;
  final int nivel;
  final bool verificando;
  final Map<String, bool> descargado;
  final Set<String> descargando;
  final Map<String, double> progresosDescarga;
  final void Function(String) onDescargar;
  final void Function(_MateriaInfo) onAbrir;
  final VoidCallback onAbrirUltimoChat;

  const _HomeTab({
    required this.saludo,
    required this.nombre,
    required this.avatar,
    required this.nivel,
    required this.verificando,
    required this.descargado,
    required this.descargando,
    required this.progresosDescarga,
    required this.onDescargar,
    required this.onAbrir,
    required this.onAbrirUltimoChat,
  });

  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
  int _scrollIndex = 0;
  late final ScrollController _scrollCtrl;

  String get _avatarPath => widget.avatar == 'pollito'
      ? 'assets/images/bienvenida/pollo feliz 2 (2).png'
      : 'assets/images/bienvenida/mono.png';

  @override
  void initState() {
    super.initState();
    _scrollCtrl = ScrollController();
    _scrollCtrl.addListener(_onScroll);
  }

  void _onScroll() {
    final mq = MediaQuery.of(context);
    final screenW = mq.size.width;
    final isTablet = screenW >= 600;
    final cardW = isTablet ? screenW * 0.38 : screenW * 0.72;
    final gap = isTablet ? 16.0 : 12.0;
    final step = cardW + gap;
    final atEnd = _scrollCtrl.position.pixels >= _scrollCtrl.position.maxScrollExtent - 1;
    final idx = atEnd
        ? _materias.length - 1
        : (_scrollCtrl.offset / step).round().clamp(0, _materias.length - 1);
    if (idx != _scrollIndex) setState(() => _scrollIndex = idx);
  }

  @override
  void dispose() {
    _scrollCtrl.removeListener(_onScroll);
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final screenW = mq.size.width;
    final isTablet = screenW >= 600;
    final hPad = isTablet ? screenW * 0.06 : 20.0;
    final saludoFs = isTablet ? 18.0 : 16.0;
    final nombreFs = isTablet ? 36.0 : 30.0;
    final nivelFs = isTablet ? 22.0 : 18.0;
    final avatarCircle = isTablet ? 52.0 : 40.0;
    // La mascota: pequeña, asomando por la izquierda del recuadro
    final bannerMascotaH = screenW * 0.22;
    final bannerTitleFs = isTablet ? 22.0 : screenW * 0.045;
    final bannerSubFs = isTablet ? 19.0 : screenW * 0.048;
    final screenH = mq.size.height;
    final mClasesFs = isTablet ? 34.0 : 28.0;

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header fijo arriba ─────────────────────────────
          Padding(
            padding: EdgeInsets.fromLTRB(hPad, isTablet ? 24 : 18, hPad, 0),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.saludo,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: saludoFs,
                          color: Colors.black54,
                        ),
                      ),
                      Text(
                        '${widget.nombre}!',
                        style: TextStyle(
                          fontFamily: 'Hiruko',
                          fontSize: nombreFs,
                          fontWeight: FontWeight.w800,
                          color: Colors.black87,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // Píldora blanca con "Nivel X" + avatar
                Container(
                  padding: EdgeInsets.only(
                    left: isTablet ? 20 : 16,
                    top: 6,
                    bottom: 6,
                    right: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(40),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.10),
                        blurRadius: 12,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Nivel ${widget.nivel}',
                        style: TextStyle(
                          fontFamily: 'Hiruko',
                          fontSize: nivelFs,
                          fontWeight: FontWeight.w800,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        width: avatarCircle,
                        height: avatarCircle,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFFFFF0D6),
                        ),
                        padding: const EdgeInsets.all(2),
                        child: ClipOval(
                          child: Image.asset(
                            _avatarPath,
                            fit: BoxFit.contain,
                            errorBuilder: (_, _, _) => const Icon(
                              Icons.person,
                              color: Color(0xFF3B74FF),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Contenido centrado verticalmente ──────────────
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

          // ── Banner: mascota asomando desde el recuadro blanco ───
          Padding(
            padding: EdgeInsets.symmetric(horizontal: hPad),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // 1) Recuadro dinámico — color según materia activa
                Builder(builder: (context) {
                  final bannerColor = _materias[_scrollIndex].color;
                  final bannerSombra = _materias[_scrollIndex].sombra;
                  return Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(screenW * 0.065),
                    boxShadow: [
                      BoxShadow(
                        color: bannerSombra,
                        blurRadius: 0,
                        offset: Offset(0, screenW * 0.02),
                      ),
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(screenW * 0.055),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      color: bannerColor,
                      padding: EdgeInsets.fromLTRB(
                        screenW * 0.04,
                        screenW * 0.27 * 0.78 - screenW * 0.14,
                        screenW * 0.04,
                        screenW * 0.04,
                      ),
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(
                          horizontal: screenW * 0.04,
                          vertical: screenW * 0.035,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(screenW * 0.045),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '¡No pares de aprender!',
                                    style: TextStyle(
                                      fontFamily: 'Hiruko',
                                      fontSize: bannerTitleFs,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  SizedBox(height: screenW * 0.01),
                                  Text(
                                    'Cada pregunta es un nuevo descubrimiento',
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: bannerSubFs,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(width: screenW * 0.025),
                            GestureDetector(
                              onTap: widget.onAbrirUltimoChat,
                              child: Container(
                                width: screenW * 0.1,
                                height: screenW * 0.1,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFF8C00),
                                  borderRadius: BorderRadius.circular(screenW * 0.03),
                                ),
                                child: Icon(
                                  Icons.arrow_forward_rounded,
                                  color: Colors.white,
                                  size: screenW * 0.055,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  );
                }),
                // 2) Mascota asomándose desde arriba del recuadro blanco
                Positioned(
                  top: -(screenW * 0.14),
                  left: 0,
                  right: 0,
                  child: Center(
                    child: ClipRect(
                      child: Align(
                        alignment: Alignment.topCenter,
                        heightFactor: 0.78,
                        child: Image.asset(
                          _avatarPath,
                          height: screenW * 0.27,
                          fit: BoxFit.contain,
                          errorBuilder: (_, _, _) => const SizedBox(),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: isTablet ? 36 : 28),

          // ── Título "Mis Clases" ────────────────────────────
          Padding(
            padding: EdgeInsets.symmetric(horizontal: hPad),
            child: Text(
              'Mis Clases',
              style: TextStyle(
                fontFamily: 'Hiruko',
                fontSize: mClasesFs,
                fontWeight: FontWeight.w800,
                color: Colors.black87,
              ),
            ),
          ),

          SizedBox(height: isTablet ? 14 : 10),

          // ── Scroll horizontal de clases ────────────────────
          if (widget.verificando)
            SizedBox(
              height: screenH * 0.44,
              child: const Center(
                child: CircularProgressIndicator(color: Color(0xFF3E7DFE)),
              ),
            )
          else ...[
            SizedBox(
              height: isTablet ? screenH * 0.46 : screenH * 0.44,
              child: ListView.builder(
                controller: _scrollCtrl,
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.only(
                  left: hPad,
                  right: hPad,
                  bottom: 14,
                ),
                itemCount: _materias.length,
                itemBuilder: (context, i) {
                  final m = _materias[i];
                  final cardW = isTablet ? screenW * 0.38 : screenW * 0.72;
                  return Padding(
                    padding: EdgeInsets.only(right: isTablet ? 16 : 12),
                    child: SizedBox(
                      width: cardW,
                      child: _ClaseCard(
                        info: m,
                        descargado: widget.descargado[m.clave] ?? false,
                        descargando: widget.descargando.contains(m.clave),
                        progreso: widget.progresosDescarga[m.clave] ?? 0.0,
                        onDescargar: () => widget.onDescargar(m.clave),
                        onAbrir: () => widget.onAbrir(m),
                      ),
                    ),
                  );
                },
              ),
            ),

            // ── Indicador de puntos ────────────────────────
            SizedBox(height: isTablet ? 16 : 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_materias.length, (i) {
                final selected = i == _scrollIndex;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: EdgeInsets.symmetric(horizontal: screenW * 0.008),
                  width: selected ? screenW * 0.05 : screenW * 0.02,
                  height: screenW * 0.02,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(screenW * 0.01),
                    color: selected
                        ? const Color(0xFF3E7DFE)
                        : Colors.grey[350],
                  ),
                );
              }),
            ),
            SizedBox(height: isTablet ? 18 : 12),
          ], // else
              ], // Column interior children
            ),
          ), // Expanded
          ], // Column exterior children
      ),
    );
  }
}

// ── Tarjeta de clase ──────────────────────────────────────────

class _ClaseCard extends StatefulWidget {
  final _MateriaInfo info;
  final bool descargado;
  final bool descargando;
  final double progreso;
  final VoidCallback onDescargar;
  final VoidCallback onAbrir;

  const _ClaseCard({
    required this.info,
    required this.descargado,
    required this.descargando,
    required this.progreso,
    required this.onDescargar,
    required this.onAbrir,
  });

  @override
  State<_ClaseCard> createState() => _ClaseCardState();
}

class _ClaseCardState extends State<_ClaseCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 80),
  );
  late final Animation<double> _scale = Tween<double>(
    begin: 1.0,
    end: 0.95,
  ).animate(_ctrl);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final info = widget.info;
    final listo = widget.descargado;
    final enDescarga = widget.descargando;
    final screenW = MediaQuery.of(context).size.width;
    final isTablet = screenW >= 600;
    final categoriaFs = isTablet ? 16.0 : 14.0;
    final tituloFs = isTablet ? 26.0 : 22.0;
    final timeFs = isTablet ? 16.0 : 14.0;
    final iconSz = isTablet ? 60.0 : 48.0;

    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        if (listo) {
          widget.onAbrir();
        } else if (!enDescarga) {
          widget.onDescargar();
        }
      },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: info.sombra.withValues(alpha: 0.85),
                blurRadius: 0,
                offset: const Offset(0, 10),
              ),
              BoxShadow(
                color: info.sombra.withValues(alpha: 0.30),
                blurRadius: 16,
                offset: const Offset(0, 14),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Área de imagen
                  Expanded(
                    flex: 62,
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(color: info.color),
                      child: Stack(
                        children: [
                          Center(
                            child: Image.asset(
                              info.imagen,
                              fit: BoxFit.contain,
                              errorBuilder: (_, _, _) => Icon(
                                info.icono,
                                color: Colors.white,
                                size: iconSz,
                              ),
                            ),
                          ),
                          if (!listo)
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Container(
                                padding: const EdgeInsets.all(5),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.25),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: enDescarga
                                    ? SizedBox(
                                        width: 14,
                                        height: 14,
                                        child: CircularProgressIndicator(
                                          value: widget.progreso > 0
                                              ? widget.progreso
                                              : null,
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Icon(
                                        Icons.download_rounded,
                                        color: Colors.white,
                                        size: 14,
                                      ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  // Texto inferior
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          info.categoria,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: categoriaFs,
                            fontWeight: FontWeight.w700,
                            color: info.color,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          info.titulo,
                          style: TextStyle(
                            fontFamily: 'Hiruko',
                            fontSize: tituloFs,
                            fontWeight: FontWeight.w800,
                            color: Colors.black87,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              Icons.access_time_rounded,
                              size: timeFs,
                              color: Colors.grey[500],
                            ),
                            const SizedBox(width: 3),
                            Text(
                              '10 minutos',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: timeFs,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Tab: Progreso ─────────────────────────────────────────────

class _ProgresoTab extends StatelessWidget {
  final String nombre;
  final String avatar;
  final int nivel;
  final AsyncValue<Map<String, double>> progresoAsync;

  const _ProgresoTab({
    required this.nombre,
    required this.avatar,
    required this.nivel,
    required this.progresoAsync,
  });

  String get _avatarPath => avatar == 'pollito'
      ? 'assets/images/bienvenida/pollo feliz 2 (2).png'
      : 'assets/images/bienvenida/mono.png';

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final screenW = mq.size.width;
    final isTablet = screenW >= 600;
    final hPad = isTablet ? screenW * 0.06 : 20.0;
    final cardH = isTablet ? 130.0 : 110.0;
    final avatarSize = isTablet ? 108.0 : 90.0;
    final avatarLeft = isTablet ? 20.0 : 16.0;
    final nameLeft = isTablet ? 148.0 : 120.0;
    final nameFs = isTablet ? 26.0 : 22.0;
    final progresoTitleFs = isTablet ? 26.0 : 22.0;

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.only(bottom: isTablet ? 120 : 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: isTablet ? 28 : 20),

            // Tarjeta de perfil
            Padding(
              padding: EdgeInsets.symmetric(horizontal: hPad),
              child: Container(
                height: cardH,
                decoration: BoxDecoration(
                  color: const Color(0xFF45C0D0),
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2DA0AE),
                      blurRadius: 0,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Avatar centrado verticalmente
                    Positioned(
                      top: (cardH - avatarSize) / 2,
                      left: avatarLeft,
                      child: Container(
                        width: avatarSize,
                        height: avatarSize,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          border: Border.all(color: Colors.white, width: 4),
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            _avatarPath,
                            fit: BoxFit.contain,
                            errorBuilder: (_, _, _) => const Icon(
                              Icons.person,
                              color: Color(0xFF45C0D0),
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Nombre y grado
                    Positioned(
                      left: nameLeft,
                      top: 22,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            nombre,
                            style: TextStyle(
                              fontFamily: 'Hiruko',
                              fontSize: nameFs,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF8C00),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFCC6600),
                                  blurRadius: 0,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Text(
                              '$nivel°',
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: isTablet ? 70 : 60),

            Padding(
              padding: EdgeInsets.symmetric(horizontal: hPad),
              child: Text(
                'Tu progreso',
                style: TextStyle(
                  fontFamily: 'Hiruko',
                  fontSize: progresoTitleFs,
                  fontWeight: FontWeight.w800,
                  color: Colors.black87,
                ),
              ),
            ),

            SizedBox(height: isTablet ? 18 : 14),

            progresoAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: CircularProgressIndicator(color: Color(0xFF3E7DFE)),
                ),
              ),
              error: (_, _) => _buildBarras({}, context),
              data: (progreso) => _buildBarras(progreso, context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBarras(Map<String, double> progreso, BuildContext context) {
    final mq = MediaQuery.of(context);
    final screenW = mq.size.width;
    final isTablet = screenW >= 600;
    final hPad = isTablet ? screenW * 0.06 : 20.0;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: hPad),
      child: Column(
        children: _progresoItems.map((item) {
          final pct = (progreso[item.clave] ?? 0.0).clamp(0.0, 100.0);
          return Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: _BarraProgreso(
              etiqueta: item.etiqueta,
              porcentaje: pct,
              color: item.color,
              sombra: item.sombra,
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Barra de progreso ─────────────────────────────────────────

class _BarraProgreso extends StatelessWidget {
  final String etiqueta;
  final double porcentaje;
  final Color color;
  final Color sombra;

  const _BarraProgreso({
    required this.etiqueta,
    required this.porcentaje,
    required this.color,
    required this.sombra,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: sombra, blurRadius: 0, offset: const Offset(0, 10)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              etiqueta,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            Text(
              '${porcentaje.toInt()}%',
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Barra de navegación inferior ─────────────────────────────

class _NavBar extends StatelessWidget {
  final int selectedIndex;
  final VoidCallback onHome;
  final VoidCallback onProgreso;
  final VoidCallback onConfiguracion;

  const _NavBar({
    required this.selectedIndex,
    required this.onHome,
    required this.onProgreso,
    required this.onConfiguracion,
  });

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final screenW = mq.size.width;
    final isTablet = screenW >= 600;
    final navH = isTablet ? 80.0 : 68.0;
    final hMargin = isTablet ? screenW * 0.15 : 20.0;
    final iconSz = isTablet ? 32.0 : 28.0;

    return Container(
      margin: EdgeInsets.only(left: hMargin, right: hMargin, bottom: isTablet ? 28 : 20),
      height: navH,
      decoration: BoxDecoration(
        color: const Color(0xFF45C0D0),
        borderRadius: BorderRadius.circular(40),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2DA0AE).withValues(alpha: 0.45),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _NavItem(icon: Icons.home_rounded, selected: selectedIndex == 0, onTap: onHome, iconSize: iconSz),
          _NavItem(icon: Icons.emoji_events_rounded, selected: selectedIndex == 1, onTap: onProgreso, iconSize: iconSz),
          _NavItem(icon: Icons.settings_rounded, selected: false, onTap: onConfiguracion, iconSize: iconSz),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final double iconSize;

  const _NavItem({
    required this.icon,
    required this.selected,
    required this.onTap,
    this.iconSize = 28,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: selected
              ? Colors.white.withValues(alpha: 0.25)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(icon, size: iconSize, color: Colors.white),
      ),
    );
  }
}