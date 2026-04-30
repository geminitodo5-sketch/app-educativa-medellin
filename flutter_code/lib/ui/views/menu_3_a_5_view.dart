// ─────────────────────────────────────────────────────────────
//  lib/ui/views/menu_3_a_5_view.dart
//  Menú principal para grados 3, 4 y 5.
//  Toda la interacción pasa por el asistente RAG offline.
// ─────────────────────────────────────────────────────────────

import 'dart:async';

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
  int _currentPage = 0;
  final Map<String, bool> _descargado = {};
  final Map<String, double> _progresosDescarga = {};
  final Set<String> _descargando = {};
  bool _verificando = true;

  late final DescargaPaqueteService _svc;
  late final PageController _pageController;
  Timer? _carruselTimer;
  bool _pausarCarrusel = false;

  // Evita doble-salir cuando dispose corre después de didPushNext.
  bool _salidoPorPush = false;

  @override
  void initState() {
    super.initState();
    _svc = DescargaPaqueteService(ref.read(sqliteServiceProvider));
    _verificarDescargas();
    _pageController = PageController(viewportFraction: 0.82);
    _iniciarCarrusel();
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

  void _iniciarCarrusel() {
    _carruselTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted || !_pageController.hasClients || _pausarCarrusel) return;
      final next = (_currentPage + 1) % _materias.length;
      _pageController.animateToPage(
        next,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOut,
      );
    });
  }

  void _onScrollStart() {
    if (!_pausarCarrusel) setState(() => _pausarCarrusel = true);
  }

  void _onScrollEnd() {
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted && _pausarCarrusel) setState(() => _pausarCarrusel = false);
    });
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    if (!_salidoPorPush) ref.read(musicaServiceProvider).salir();
    _carruselTimer?.cancel();
    _pageController.dispose();
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
                pageController: _pageController,
                currentPage: _currentPage,
                onPageChanged: (i) => setState(() => _currentPage = i),
                onDescargar: _descargar,
                onAbrir: _abrirAsistente,
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
              onAsistente: () {
                final primera = _materias.firstWhere(
                  (m) => _descargado[m.clave] == true,
                  orElse: () => _materias.first,
                );
                _abrirAsistente(primera);
              },
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

class _HomeTab extends StatelessWidget {
  final String saludo;
  final String nombre;
  final String avatar;
  final int nivel;
  final bool verificando;
  final Map<String, bool> descargado;
  final Set<String> descargando;
  final Map<String, double> progresosDescarga;
  final PageController pageController;
  final int currentPage;
  final ValueChanged<int> onPageChanged;
  final void Function(String) onDescargar;
  final void Function(_MateriaInfo) onAbrir;

  const _HomeTab({
    required this.saludo,
    required this.nombre,
    required this.avatar,
    required this.nivel,
    required this.verificando,
    required this.descargado,
    required this.descargando,
    required this.progresosDescarga,
    required this.pageController,
    required this.currentPage,
    required this.onPageChanged,
    required this.onDescargar,
    required this.onAbrir,
  });

  String get _avatarPath => avatar == 'pollito'
      ? 'assets/images/bienvenida/pollo feliz 2 (2).png'
      : 'assets/images/bienvenida/mono.png';

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        saludo,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 16,
                          color: Colors.black54,
                        ),
                      ),
                      Text(
                        '$nombre!',
                        style: const TextStyle(
                          fontFamily: 'Hiruko',
                          fontSize: 30,
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
                  padding: const EdgeInsets.only(
                    left: 16,
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
                        'Nivel $nivel',
                        style: const TextStyle(
                          fontFamily: 'Hiruko',
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        width: 40,
                        height: 40,
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

          const SizedBox(height: 20),

          // ── Banner ────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.topCenter,
              children: [
                // 1. Contenedor base responsivo (define el tamaño del Stack)
                Padding(
                  padding: const EdgeInsets.only(
                    top: 55,
                  ), // Espacio fijo para la mascota
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeInOut,
                    // Eliminamos el height: 155 para que crezca según el texto interior
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(26),
                      boxShadow: [
                        BoxShadow(
                          color:
                              _materias[currentPage.clamp(
                                    0,
                                    _materias.length - 1,
                                  )]
                                  .sombra,
                          blurRadius: 0,
                          offset: const Offset(0, 8),
                        ),
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(22),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeInOut,
                        color:
                            _materias[currentPage.clamp(
                                  0,
                                  _materias.length - 1,
                                )]
                                .color,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                          // Eliminamos el Align(bottomCenter) para que el layout fluya natural
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize:
                                        MainAxisSize.min, // Se adapta al texto
                                    children: [
                                      const Text(
                                        '¡No pares de aprender!',
                                        style: TextStyle(
                                          fontFamily: 'Hiruko',
                                          fontSize: 18,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      const Text(
                                        'Cada pregunta es un nuevo descubrimiento',
                                        style: TextStyle(
                                          fontFamily: 'Poppins',
                                          fontSize: 13,
                                          color: Colors.black54,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFF8C00),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.arrow_forward_rounded,
                                    color: Colors.white,
                                    size: 22,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // 2. Mascota asomándose desde arriba
                Positioned(
                  top: -35,
                  child: ClipRect(
                    child: Align(
                      alignment: Alignment.topCenter,
                      heightFactor: 0.78,
                      child: Image.asset(
                        _avatarPath,
                        height: 136,
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) => const SizedBox(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 44),

          // ── Título "Mis Clases" ────────────────────────────
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Mis Clases',
              style: TextStyle(
                fontFamily: 'Hiruko',
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: Colors.black87,
              ),
            ),
          ),

          const SizedBox(height: 14),

          // ── Carrusel de clases ─────────────────────────────
          if (verificando)
            const SizedBox(
              height: 260,
              child: Center(
                child: CircularProgressIndicator(color: Color(0xFF3E7DFE)),
              ),
            )
          else ...[
            SizedBox(
              height: 260,
              child: PageView.builder(
                controller: pageController,
                onPageChanged: onPageChanged,
                physics: const PageScrollPhysics(),
                itemCount: _materias.length,
                padEnds: false,
                clipBehavior: Clip.none,
                itemBuilder: (context, i) {
                  final m = _materias[i];
                  return Padding(
                    padding: const EdgeInsets.only(left: 20, right: 10),
                    child: _ClaseCard(
                      info: m,
                      descargado: descargado[m.clave] ?? false,
                      descargando: descargando.contains(m.clave),
                      progreso: progresosDescarga[m.clave] ?? 0.0,
                      onDescargar: () => onDescargar(m.clave),
                      onAbrir: () => onAbrir(m),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 10),

            // Puntos indicadores (tapeables)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _materias.length,
                (i) => GestureDetector(
                  onTap: () => pageController.animateToPage(
                    i,
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeInOut,
                  ),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: i == currentPage ? 20 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color: i == currentPage
                          ? const Color(0xFF3E7DFE)
                          : Colors.grey[300],
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 10),
          ],
        ],
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
                color: info.sombra,
                blurRadius: 0,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 8,
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
                                size: 52,
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
                  Expanded(
                    flex: 38,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            info.categoria,
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: info.color,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            info.titulo,
                            style: const TextStyle(
                              fontFamily: 'Hiruko',
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Colors.black87,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Row(
                            children: [
                              Icon(
                                Icons.access_time_rounded,
                                size: 14,
                                color: Colors.grey[500],
                              ),
                              const SizedBox(width: 3),
                              Text(
                                '10 minutos',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 13,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
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
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),

            // Tarjeta de perfil
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                height: 110,
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
                      top: 10,
                      left: 16,
                      child: Container(
                        width: 90,
                        height: 90,
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
                      left: 120,
                      top: 22,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            nombre,
                            style: const TextStyle(
                              fontFamily: 'Hiruko',
                              fontSize: 22,
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

            const SizedBox(height: 60),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Tu progreso',
                style: TextStyle(
                  fontFamily: 'Hiruko',
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Colors.black87,
                ),
              ),
            ),

            const SizedBox(height: 14),

            progresoAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: CircularProgressIndicator(color: Color(0xFF3E7DFE)),
                ),
              ),
              error: (_, _) => _buildBarras({}),
              data: (progreso) => _buildBarras(progreso),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBarras(Map<String, double> progreso) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
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
  final VoidCallback onAsistente;
  final VoidCallback onProgreso;
  final VoidCallback onConfiguracion;

  const _NavBar({
    required this.selectedIndex,
    required this.onHome,
    required this.onAsistente,
    required this.onProgreso,
    required this.onConfiguracion,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
      height: 68,
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
          _NavItem(
            icon: Icons.home_rounded,
            selected: selectedIndex == 0,
            onTap: onHome,
          ),
          _NavItem(
            icon: Icons.psychology_rounded,
            selected: false,
            onTap: onAsistente,
          ),
          _NavItem(
            icon: Icons.emoji_events_rounded,
            selected: selectedIndex == 1,
            onTap: onProgreso,
          ),
          _NavItem(
            icon: Icons.settings_rounded,
            selected: false,
            onTap: onConfiguracion,
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.selected,
    required this.onTap,
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
        child: Icon(icon, size: 28, color: Colors.white),
      ),
    );
  }
}