// ─────────────────────────────────────────────────────────────
//  lib/ui/views/menu_3_a_5_view.dart
//  Menú principal para grados 3, 4 y 5.
//  Toda la interacción pasa por el asistente RAG offline.
// ─────────────────────────────────────────────────────────────

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/providers/app_state_provider.dart';
import '../../data/providers/database_provider.dart';
import '../../data/services/descarga_paquete_service.dart';
import 'inicio_view.dart';
import 'configuracion_view.dart';
import 'asistente_ia/asistente_ia_view.dart';

// ── Datos de cada materia ─────────────────────────────────────

class _MateriaInfo {
  final String clave;
  final String nombre;
  final Color color;
  final Color sombra;
  final IconData icono;
  final String imagen;

  const _MateriaInfo({
    required this.clave,
    required this.nombre,
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
    color: Color(0xFF3E7DFE),
    sombra: Color(0xFF2C60D2),
    icono: Icons.calculate_rounded,
    imagen: 'assets/images/menu_materias/123_1.png',
  ),
  _MateriaInfo(
    clave: 'ciencias',
    nombre: 'Ciencias',
    color: Color(0xFF3DCC52),
    sombra: Color(0xFF22A45D),
    icono: Icons.science_rounded,
    imagen: 'assets/images/menu_materias/planta_1.png',
  ),
  _MateriaInfo(
    clave: 'espanol',
    nombre: 'Español',
    color: Color(0xFFB83232),
    sombra: Color(0xFF8B1A1A),
    icono: Icons.menu_book_rounded,
    imagen: 'assets/images/menu_materias/alfabeto_1.png',
  ),
  _MateriaInfo(
    clave: 'sociales',
    nombre: 'Sociales',
    color: Color(0xFFF5A623),
    sombra: Color(0xFFB8710A),
    icono: Icons.public_rounded,
    imagen: 'assets/images/menu_materias/globo_1.png',
  ),
  _MateriaInfo(
    clave: 'ingles',
    nombre: 'Inglés',
    color: Color(0xFF8B5CF6),
    sombra: Color(0xFF6A3592),
    icono: Icons.language_rounded,
    imagen: 'assets/images/menu_materias/libros_1.png',
  ),
];

// ── Pantalla ──────────────────────────────────────────────────

class Menu3A5Screen extends ConsumerStatefulWidget {
  const Menu3A5Screen({super.key});

  @override
  ConsumerState<Menu3A5Screen> createState() => _Menu3A5ScreenState();
}

class _Menu3A5ScreenState extends ConsumerState<Menu3A5Screen> {
  final Map<String, bool>   _descargado        = {};
  final Map<String, double> _progresosDescarga = {};
  final Set<String>         _descargando       = {};
  bool _verificando = true;

  late final DescargaPaqueteService _svc;

  @override
  void initState() {
    super.initState();
    _svc = DescargaPaqueteService(ref.read(sqliteServiceProvider));
    _verificarDescargas();
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
        .push(MaterialPageRoute(
          builder: (_) => AsistenteIaView(
            materiaInicial: materia.clave,
            gradoInicial: estudiante?.grado ?? 3,
          ),
        ))
        .then((_) => _verificarDescargas());
  }

  Future<void> _confirmarReset() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reiniciar base de datos'),
        content: const Text(
            '¿Borrar todos los datos y empezar desde cero?\nEsta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Borrar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmar != true || !mounted) return;
    await ref.read(resetDbProvider)();
    await ref.read(sqliteServiceProvider).database;
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const InicioView()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final estudiante = ref.watch(estudianteActivoProvider);
    final nombre = estudiante?.nombre ?? 'Estudiante';
    final avatar = estudiante?.personaje ?? 'pollito';
    final nivel = estudiante?.grado ?? 3;

    return Scaffold(
      body: Stack(
        children: [
          // ── Fondo degradado ───────────────────────────────────
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF1A3A6B), Color(0xFF7BD0E8)],
                stops: [0.0, 0.55],
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Image.asset(
              'assets/images/bienvenida/fondos (1).png',
              width: double.infinity,
              fit: BoxFit.fitWidth,
              alignment: Alignment.bottomCenter,
              errorBuilder: (_, _, _) => const SizedBox(),
            ),
          ),

          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Barra de perfil ──────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                  child: _BarraPerfil(
                    nombre: nombre,
                    avatar: avatar,
                    nivel: nivel,
                  ),
                ),

                const SizedBox(height: 14),

                // ── Cabecera IA ──────────────────────────────────
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: _CabeceraIA(),
                ),

                const SizedBox(height: 14),

                // ── Cuadrícula de las 5 materias ─────────────────
                Expanded(
                  child: _verificando
                      ? const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        )
                      : SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 110),
                          child: Column(
                            children: [
                              // Fila 1: Matemáticas + Ciencias
                              _FilaTarjetas(
                                izquierda: _materias[0],
                                derecha: _materias[1],
                                descargado: _descargado,
                                descargando: _descargando,
                                progresos: _progresosDescarga,
                                onDescargar: _descargar,
                                onAbrir: _abrirAsistente,
                              ),
                              const SizedBox(height: 14),
                              // Fila 2: Español + Sociales
                              _FilaTarjetas(
                                izquierda: _materias[2],
                                derecha: _materias[3],
                                descargado: _descargado,
                                descargando: _descargando,
                                progresos: _progresosDescarga,
                                onDescargar: _descargar,
                                onAbrir: _abrirAsistente,
                              ),
                              const SizedBox(height: 14),
                              // Fila 3: Inglés (ancho completo)
                              _TarjetaMateria(
                                info: _materias[4],
                                descargado: _descargado[_materias[4].clave] ?? false,
                                descargando: _descargando.contains(_materias[4].clave),
                                progreso: _progresosDescarga[_materias[4].clave] ?? 0.0,
                                anchoCompleto: true,
                                onDescargar: () => _descargar(_materias[4].clave),
                                onAbrir: () => _abrirAsistente(_materias[4]),
                              ),
                            ],
                          ),
                        ),
                ),
              ],
            ),
          ),

          // ── Debug reset ──────────────────────────────────────
          if (kDebugMode)
            Positioned(
              top: 12,
              right: 12,
              child: SafeArea(
                child: IconButton(
                  icon: const Icon(Icons.delete_forever,
                      color: Colors.white38, size: 26),
                  tooltip: 'Reiniciar BD',
                  onPressed: _confirmarReset,
                ),
              ),
            ),

          // ── Barra de navegación inferior ─────────────────────
          Align(
            alignment: Alignment.bottomCenter,
            child: _NavBar(
              onInicio: () {},
              onAsistente: () {
                // Abre la materia que ya esté descargada, o la primera
                final primera = _materias.firstWhere(
                  (m) => _descargado[m.clave] == true,
                  orElse: () => _materias.first,
                );
                _abrirAsistente(primera);
              },
              onConfiguracion: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const ConfiguracionView(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Fila de dos tarjetas ──────────────────────────────────────

class _FilaTarjetas extends StatelessWidget {
  final _MateriaInfo izquierda;
  final _MateriaInfo derecha;
  final Map<String, bool>   descargado;
  final Set<String>         descargando;
  final Map<String, double> progresos;
  final void Function(String)       onDescargar;
  final void Function(_MateriaInfo) onAbrir;

  const _FilaTarjetas({
    required this.izquierda,
    required this.derecha,
    required this.descargado,
    required this.descargando,
    required this.progresos,
    required this.onDescargar,
    required this.onAbrir,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _TarjetaMateria(
              info: izquierda,
              descargado: descargado[izquierda.clave] ?? false,
              descargando: descargando.contains(izquierda.clave),
              progreso: progresos[izquierda.clave] ?? 0.0,
              onDescargar: () => onDescargar(izquierda.clave),
              onAbrir: () => onAbrir(izquierda),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: _TarjetaMateria(
              info: derecha,
              descargado: descargado[derecha.clave] ?? false,
              descargando: descargando.contains(derecha.clave),
              progreso: progresos[derecha.clave] ?? 0.0,
              onDescargar: () => onDescargar(derecha.clave),
              onAbrir: () => onAbrir(derecha),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Tarjeta de materia ────────────────────────────────────────

class _TarjetaMateria extends StatefulWidget {
  final _MateriaInfo info;
  final bool descargado;
  final bool descargando;
  final double progreso;        // 0.0–1.0 mientras descarga
  final bool anchoCompleto;
  final VoidCallback onDescargar;
  final VoidCallback onAbrir;

  const _TarjetaMateria({
    required this.info,
    required this.descargado,
    required this.descargando,
    required this.progreso,
    required this.onDescargar,
    required this.onAbrir,
    this.anchoCompleto = false,
  });

  @override
  State<_TarjetaMateria> createState() => _TarjetaMateriaState();
}

class _TarjetaMateriaState extends State<_TarjetaMateria>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 80),
  );
  late final Animation<double> _scale =
      Tween<double>(begin: 1.0, end: 0.95).animate(_ctrl);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final info = widget.info;
    final listo = widget.descargado;
    final descargando = widget.descargando;

    return GestureDetector(
      onTapDown: listo ? (_) => _ctrl.forward() : null,
      onTapUp: listo
          ? (_) {
              _ctrl.reverse();
              widget.onAbrir();
            }
          : null,
      onTapCancel: listo ? () => _ctrl.reverse() : null,
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          // Altura mínima garantizada para el card
          constraints: BoxConstraints(
            minHeight: widget.anchoCompleto ? 100 : 155,
          ),
          decoration: BoxDecoration(
            color: info.color,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: info.sombra,
                blurRadius: 0,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Imagen de fondo tenue
              Positioned(
                right: -8,
                bottom: -8,
                child: Opacity(
                  opacity: 0.12,
                  child: Image.asset(
                    info.imagen,
                    width: 72,
                    height: 72,
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => const SizedBox(),
                  ),
                ),
              ),

              // Contenido principal
              Padding(
                padding: const EdgeInsets.all(14),
                child: widget.anchoCompleto
                    ? _ContenidoHorizontal(
                        info: info,
                        listo: listo,
                        descargando: descargando,
                        progreso: widget.progreso,
                        onDescargar: widget.onDescargar,
                      )
                    : _ContenidoVertical(
                        info: info,
                        listo: listo,
                        descargando: descargando,
                        progreso: widget.progreso,
                        onDescargar: widget.onDescargar,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Layout vertical (tarjetas cuadradas) ──────────────────────

class _ContenidoVertical extends StatelessWidget {
  final _MateriaInfo info;
  final bool listo;
  final bool descargando;
  final double progreso;
  final VoidCallback onDescargar;

  const _ContenidoVertical({
    required this.info,
    required this.listo,
    required this.descargando,
    required this.progreso,
    required this.onDescargar,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Ícono + badge estado
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(info.icono, color: Colors.white, size: 22),
            ),
            if (listo)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle_rounded, color: Colors.white, size: 12),
                    SizedBox(width: 3),
                    Text('Listo',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        )),
                  ],
                ),
              ),
          ],
        ),

        const SizedBox(height: 10),

        // Nombre
        Text(
          info.nombre,
          style: const TextStyle(
            fontFamily: 'Hiruko',
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),

        const SizedBox(height: 10),

        // Botón o barra de progreso
        if (descargando) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progreso,
              minHeight: 7,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${(progreso * 100).toInt()}%',
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 10,
              color: Colors.white70,
            ),
          ),
        ] else if (!listo)
          SizedBox(
            width: double.infinity,
            height: 34,
            child: ElevatedButton.icon(
              onPressed: onDescargar,
              icon: const Icon(Icons.download_rounded, size: 14),
              label: const Text(
                'Descargar',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black87,
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
            ),
          )
        else
          const Text(
            'Toca para preguntar',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 11,
              color: Colors.white70,
            ),
          ),
      ],
    );
  }
}

// ── Layout horizontal (tarjeta de ancho completo — Inglés) ────

class _ContenidoHorizontal extends StatelessWidget {
  final _MateriaInfo info;
  final bool listo;
  final bool descargando;
  final double progreso;
  final VoidCallback onDescargar;

  const _ContenidoHorizontal({
    required this.info,
    required this.listo,
    required this.descargando,
    required this.progreso,
    required this.onDescargar,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Ícono
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(info.icono, color: Colors.white, size: 26),
        ),
        const SizedBox(width: 14),

        // Nombre + subtítulo
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                info.nombre,
                style: const TextStyle(
                  fontFamily: 'Hiruko',
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              if (descargando) ...[
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: progreso,
                    minHeight: 7,
                    backgroundColor: Colors.white24,
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${(progreso * 100).toInt()}%',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 10,
                    color: Colors.white70,
                  ),
                ),
              ] else
                Text(
                  listo ? 'Toca para preguntar' : 'Base de conocimiento disponible',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                ),
            ],
          ),
        ),

        const SizedBox(width: 12),

        // Botón o check
        if (!descargando)
          listo
              ? const Icon(Icons.arrow_forward_ios_rounded,
                  color: Colors.white70, size: 20)
              : ElevatedButton.icon(
                  onPressed: onDescargar,
                  icon: const Icon(Icons.download_rounded, size: 16),
                  label: const Text(
                    'Descargar',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black87,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                ),
      ],
    );
  }
}

// ── Barra de perfil ───────────────────────────────────────────

class _BarraPerfil extends StatelessWidget {
  final String nombre;
  final String avatar;
  final int nivel;

  const _BarraPerfil({
    required this.nombre,
    required this.avatar,
    required this.nivel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
            padding: const EdgeInsets.all(4),
            child: ClipOval(
              child: Image.asset(
                avatar == 'pollito'
                    ? 'assets/images/bienvenida/pollo feliz 2 (2).png'
                    : 'assets/images/bienvenida/mono.png',
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) =>
                    const Icon(Icons.person, color: Color(0xFF3B74FF)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              nombre,
              style: const TextStyle(
                fontFamily: 'Hiruko',
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$nivel° Grado',
              style: const TextStyle(
                fontFamily: 'Hiruko',
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }
}

// ── Cabecera IA ───────────────────────────────────────────────

class _CabeceraIA extends StatelessWidget {
  const _CabeceraIA();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF3475F7),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF3475F7).withValues(alpha: 0.5),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Icon(Icons.psychology_rounded, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Asistente IA',
                  style: TextStyle(
                    fontFamily: 'Hiruko',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Descarga una materia y pregunta lo que quieras',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Barra de navegación inferior ─────────────────────────────

class _NavBar extends StatelessWidget {
  final VoidCallback onInicio;
  final VoidCallback onAsistente;
  final VoidCallback onConfiguracion;

  const _NavBar({
    required this.onInicio,
    required this.onAsistente,
    required this.onConfiguracion,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
      height: 68,
      decoration: BoxDecoration(
        color: const Color(0xFF1A3A6B),
        borderRadius: BorderRadius.circular(40),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            onPressed: onInicio,
            icon: const Icon(Icons.home_rounded, color: Colors.white, size: 32),
            tooltip: 'Inicio',
          ),
          GestureDetector(
            onTap: onAsistente,
            child: Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: const Color(0xFF3475F7),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF3475F7).withValues(alpha: 0.5),
                    blurRadius: 12,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(Icons.psychology_rounded, color: Colors.white, size: 28),
            ),
          ),
          IconButton(
            onPressed: onConfiguracion,
            icon: const Icon(Icons.settings_rounded, color: Colors.white, size: 32),
            tooltip: 'Configuración',
          ),
        ],
      ),
    );
  }
}
