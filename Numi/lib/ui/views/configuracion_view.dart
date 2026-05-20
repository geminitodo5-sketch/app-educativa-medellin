// ─────────────────────────────────────────────────────────────
//  lib/ui/views/configuracion_view.dart
//  Pantalla de configuración: muestra datos reales del estudiante
//  y permite cambiar nombre. Guarda ajustes en la BD.
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/providers/app_state_provider.dart';
import '../../data/providers/database_provider.dart';
import '../../data/providers/musica_provider.dart';
import 'registro_view.dart';
import 'menu_1_y_2_view.dart';
import 'menu_3_a_5_view.dart';

class ConfiguracionView extends ConsumerStatefulWidget {
  const ConfiguracionView({super.key});

  @override
  ConsumerState<ConfiguracionView> createState() => _ConfiguracionViewState();
}

class _ConfiguracionViewState extends ConsumerState<ConfiguracionView> {
  bool   _sonidoActivo = true;
  bool   _musicaActiva = true;
  double _volumen      = 1.0;
  bool   _modoOffline  = true;
  String _idiomaSeleccionado = 'Español';

  @override
  void initState() {
    super.initState();
    final svc = ref.read(musicaServiceProvider);
    _musicaActiva = svc.musicaActiva;
    _volumen      = svc.volumen;
  }

  static const Color _cyanTeal = Color(0xFF65CEE3);
  static const Color _royalBlue = Color(0xFF3475F7);

  // ── Cerrar sesión ─────────────────────────────────────────────
  Future<void> _cerrarSesion() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Cerrar sesión',
            style: TextStyle(fontFamily: 'Hiruko', fontSize: 20)),
        content: const Text('¿Seguro que quieres cerrar sesión?',
            style: TextStyle(fontFamily: 'Poppins', fontSize: 15)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar',
                style: TextStyle(fontFamily: 'Poppins')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF5353),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Salir',
                style: TextStyle(fontFamily: 'Poppins')),
          ),
        ],
      ),
    );

    if (confirmar != true || !mounted) return;

    ref.read(estudianteActivoProvider.notifier).state = null;

    Navigator.of(context).pushAndRemoveUntil(
      PageRouteBuilder(
        pageBuilder: (ctx, a, _) => const RegistroView(),
        transitionsBuilder: (ctx, anim, _, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
      (_) => false,
    );
  }

  // ── Cambiar nombre ────────────────────────────────────────────
  Future<void> _mostrarDialogoNombre() async {
    final estudiante = ref.read(estudianteActivoProvider);
    if (estudiante == null) return;

    final controller =
        TextEditingController(text: estudiante.nombre);

    final nuevoNombre = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cambiar nombre',
            style: TextStyle(fontFamily: 'Hiruko', fontSize: 20)),
        content: TextField(
          controller: controller,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            hintText: 'Tu nombre',
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
          style: const TextStyle(fontFamily: 'Poppins', fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar',
                style: TextStyle(fontFamily: 'Poppins')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: _royalBlue,
                foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Guardar',
                style: TextStyle(fontFamily: 'Poppins')),
          ),
        ],
      ),
    );

    if (nuevoNombre == null || nuevoNombre.isEmpty) return;
    if (!mounted) return;

    final actualizado = estudiante.copyWith(nombre: nuevoNombre);
    await ref.read(estudianteRepositoryProvider).actualizar(actualizado);
    ref.read(estudianteActivoProvider.notifier).state = actualizado;
  }

  // ── Cambiar grado ─────────────────────────────────────────────
  Future<void> _mostrarDialogoGrado() async {
    final estudiante = ref.read(estudianteActivoProvider);
    if (estudiante == null) return;

    int gradoSeleccionado = estudiante.grado;

    final nuevoGrado = await showDialog<int>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
          title: const Text('Cambiar grado',
              style: TextStyle(fontFamily: 'Hiruko', fontSize: 20)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(5, (i) {
              final g = i + 1;
              return RadioListTile<int>(
                value: g,
                groupValue: gradoSeleccionado,
                onChanged: (v) {
                  if (v != null) setDialogState(() => gradoSeleccionado = v);
                },
                title: Text('Grado $g',
                    style: const TextStyle(fontFamily: 'Poppins')),
                activeColor: _royalBlue,
              );
            }),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar',
                  style: TextStyle(fontFamily: 'Poppins')),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: _royalBlue,
                  foregroundColor: Colors.white),
              onPressed: () => Navigator.pop(context, gradoSeleccionado),
              child: const Text('Guardar',
                  style: TextStyle(fontFamily: 'Poppins')),
            ),
          ],
        ),
      ),
    );

    if (nuevoGrado == null || nuevoGrado == estudiante.grado) return;
    if (!mounted) return;

    final actualizado = estudiante.copyWith(grado: nuevoGrado);
    await ref.read(estudianteRepositoryProvider).actualizar(actualizado);
    ref.read(estudianteActivoProvider.notifier).state = actualizado;

    if (!mounted) return;

    final Widget destino = nuevoGrado <= 2
        ? Menu1Y2Screen(
            nombre: actualizado.nombre,
            avatar: actualizado.personaje,
            nivel: actualizado.grado,
          )
        : const Menu3A5Screen();

    Navigator.of(context).pushAndRemoveUntil(
      PageRouteBuilder(
        pageBuilder: (ctx, a, _) => destino,
        transitionsBuilder: (ctx, anim, _, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 500),
      ),
      (_) => false,
    );
  }

  // ── Manual de usuario ─────────────────────────────────────────
  void _mostrarManual() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _ManualSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final estudiante = ref.watch(estudianteActivoProvider);
    final nombre = estudiante?.nombre ?? 'Estudiante';
    final avatar = estudiante?.personaje ?? 'pollito';
    final grado = estudiante?.grado ?? 1;

    final sw = MediaQuery.of(context).size.width;
    final isTablet = sw >= 600;

    final hPadding      = isTablet ? 32.0  : 16.0;
    final cardPadding   = isTablet ? 24.0  : 16.0;
    final cardRadius    = isTablet ? 24.0  : 20.0;
    final avatarSize    = isTablet ? 100.0 : 70.0;
    final nombreFontSize= isTablet ? 30.0  : 22.0;
    final gradoFontSize = isTablet ? 20.0  : 15.0;
    final cardTitleSize = isTablet ? 22.0  : 18.0;
    final cardSubSize   = isTablet ? 16.0  : 14.0;
    final iconSize      = isTablet ? 52.0  : 40.0;
    final cardGap       = isTablet ? 16.0  : 12.0;
    final editIconSize  = isTablet ? 26.0  : 20.0;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: EdgeInsets.all(hPadding),
                children: [
                  // ── Perfil ─────────────────────────────────────
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(cardPadding),
                    decoration: BoxDecoration(
                      color: _royalBlue,
                      borderRadius: BorderRadius.circular(cardRadius),
                    ),
                    child: Row(
                      children: [
                        // Avatar
                        Container(
                          width: avatarSize,
                          height: avatarSize,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                            color: Colors.white24,
                          ),
                          child: ClipOval(
                            child: Padding(
                              padding: const EdgeInsets.all(6),
                              child: Image.asset(
                                avatar == 'pollito'
                                    ? 'assets/images/bienvenida/pollo feliz 2 (2).png'
                                    : 'assets/images/bienvenida/mono.png',
                                fit: BoxFit.contain,
                                errorBuilder: (ctx, e, _) => Icon(
                                    Icons.face_rounded,
                                    color: Colors.white,
                                    size: avatarSize * 0.55),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: isTablet ? 24 : 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Nombre + lápiz
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      nombre,
                                      style: TextStyle(
                                        fontFamily: 'Hiruko',
                                        fontWeight: FontWeight.bold,
                                        fontSize: nombreFontSize,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  GestureDetector(
                                    onTap: _mostrarDialogoNombre,
                                    child: Icon(Icons.edit_rounded,
                                        color: Colors.white70,
                                        size: editIconSize),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              // Grado: botón grande y clicable
                              GestureDetector(
                                onTap: _mostrarDialogoGrado,
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: isTablet ? 16 : 12,
                                    vertical: isTablet ? 12 : 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white24,
                                    borderRadius: BorderRadius.circular(isTablet ? 14 : 10),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        '$grado° Grado',
                                        style: TextStyle(
                                          fontFamily: 'Poppins',
                                          fontSize: gradoFontSize,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                      SizedBox(width: isTablet ? 10 : 6),
                                      Icon(Icons.edit_rounded,
                                          color: Colors.white,
                                          size: isTablet ? 22 : 16),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: cardGap),
                  _buildSoundCard(cardPadding, cardRadius, cardTitleSize, cardSubSize, iconSize, isTablet),
                  SizedBox(height: cardGap),
                  _buildLanguageCard(cardPadding, cardRadius, cardTitleSize, cardSubSize, iconSize),
                  SizedBox(height: cardGap),
                  _buildOfflineCard(cardPadding, cardRadius, cardTitleSize, cardSubSize, iconSize),
                  SizedBox(height: cardGap),
                  _buildSyncCard(cardPadding, cardRadius, cardTitleSize, cardSubSize, iconSize),
                  SizedBox(height: cardGap),
                  _buildManualCard(cardPadding, cardRadius, cardTitleSize, cardSubSize, iconSize),
                  SizedBox(height: cardGap),
                  _buildLogoutCard(cardPadding, cardRadius, cardTitleSize, iconSize),
                ],
              ),
            ),

            _buildBottomNavBar(context, isTablet),
          ],
        ),
      ),
    );
  }

  Widget _buildSoundCard(double cardPadding, double cardRadius,
      double titleSize, double subSize, double iconSize, bool isTablet) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(cardPadding),
      decoration: BoxDecoration(
        color: _cyanTeal,
        borderRadius: BorderRadius.circular(cardRadius),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.volume_up_outlined, color: Colors.white, size: iconSize),
          SizedBox(width: isTablet ? 24 : 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Control de audio',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.bold,
                    fontSize: titleSize,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: isTablet ? 10 : 6),
                // ── Slider de volumen ───────────────────────────
                Row(
                  children: [
                    Icon(
                      _volumen == 0
                          ? Icons.volume_off_rounded
                          : _volumen < 0.5
                              ? Icons.volume_down_rounded
                              : Icons.volume_up_rounded,
                      color: Colors.white,
                      size: isTablet ? 26 : 20,
                    ),
                    Expanded(
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: Colors.white,
                          inactiveTrackColor: Colors.white30,
                          thumbColor: Colors.white,
                          overlayColor: Colors.white24,
                          trackHeight: isTablet ? 5 : 4,
                          thumbShape: RoundSliderThumbShape(
                              enabledThumbRadius: isTablet ? 10 : 8),
                        ),
                        child: Slider(
                          value: _volumen,
                          min: 0.0,
                          max: 1.0,
                          onChanged: (v) {
                            setState(() => _volumen = v);
                            ref.read(musicaServiceProvider).setVolumen(v);
                          },
                        ),
                      ),
                    ),
                    SizedBox(
                      width: isTablet ? 44 : 36,
                      child: Text(
                        '${(_volumen * 100).round()}%',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: subSize,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: isTablet ? 8 : 4),
                _buildToggleRow('Sonido', _sonidoActivo,
                    (v) => setState(() => _sonidoActivo = v), subSize, isTablet),
                SizedBox(height: isTablet ? 12 : 8),
                _buildToggleRow('Música', _musicaActiva, (v) {
                  setState(() => _musicaActiva = v);
                  ref.read(musicaServiceProvider).setMusicaActiva(v);
                }, subSize, isTablet),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleRow(String title, bool value, ValueChanged<bool> onChanged,
      double fontSize, bool isTablet) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title,
            style: TextStyle(
                fontFamily: 'Poppins', fontSize: fontSize, color: Colors.white)),
        SizedBox(
          height: isTablet ? 40 : 30,
          child: Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: Colors.white,
            activeTrackColor: Colors.green,
            inactiveTrackColor: Colors.white24,
            inactiveThumbColor: Colors.white,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
      ],
    );
  }

  Widget _buildLanguageCard(double cardPadding, double cardRadius,
      double titleSize, double subSize, double iconSize) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(cardPadding),
      decoration: BoxDecoration(
        color: _cyanTeal,
        borderRadius: BorderRadius.circular(cardRadius),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.language_outlined, color: Colors.white, size: iconSize),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Idioma',
                    style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.bold,
                        fontSize: titleSize,
                        color: Colors.white)),
                const SizedBox(height: 8),
                _buildRadioOption('Español', subSize),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRadioOption(String title, double fontSize) {
    final bool isSelected = _idiomaSeleccionado == title;
    return GestureDetector(
      onTap: () => setState(() => _idiomaSeleccionado = title),
      behavior: HitTestBehavior.opaque,
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected ? Colors.green : Colors.transparent,
              border: Border.all(
                  color: isSelected ? Colors.green : Colors.white, width: 2),
            ),
          ),
          const SizedBox(width: 12),
          Text(title,
              style: TextStyle(
                  fontFamily: 'Poppins', fontSize: fontSize, color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buildOfflineCard(double cardPadding, double cardRadius,
      double titleSize, double subSize, double iconSize) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(cardPadding),
      decoration: BoxDecoration(
        color: _cyanTeal,
        borderRadius: BorderRadius.circular(cardRadius),
      ),
      child: Row(
        children: [
          Icon(Icons.wifi_off_outlined, color: Colors.white, size: iconSize),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Modo Offline',
                    style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.bold,
                        fontSize: titleSize,
                        color: Colors.white)),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text('¡Funciona sin internet!',
                          style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: subSize,
                              color: Colors.white)),
                    ),
                    Switch(
                      value: _modoOffline,
                      onChanged: (v) => setState(() => _modoOffline = v),
                      activeThumbColor: Colors.white,
                      activeTrackColor: Colors.green,
                      inactiveTrackColor: Colors.white24,
                      inactiveThumbColor: Colors.white,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSyncCard(double cardPadding, double cardRadius,
      double titleSize, double subSize, double iconSize) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(cardPadding),
      decoration: BoxDecoration(
        color: const Color(0xFF3475F7).withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(cardRadius),
      ),
      child: Row(
        children: [
          Icon(Icons.sync_rounded, color: Colors.white, size: iconSize),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Sincronización',
                    style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.bold,
                        fontSize: titleSize,
                        color: Colors.white)),
                const SizedBox(height: 4),
                Text(
                  'Tu progreso se guarda localmente y se sincroniza automáticamente cuando haya internet.',
                  style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: subSize,
                      color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutCard(double cardPadding, double cardRadius,
      double titleSize, double iconSize) {
    return GestureDetector(
      onTap: _cerrarSesion,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(cardPadding),
        decoration: BoxDecoration(
          color: const Color(0xFFEF5353),
          borderRadius: BorderRadius.circular(cardRadius),
        ),
        child: Row(
          children: [
            Icon(Icons.logout_rounded, color: Colors.white, size: iconSize),
            const SizedBox(width: 16),
            Text(
              'Cerrar sesión',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.bold,
                fontSize: titleSize,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildManualCard(double cardPadding, double cardRadius,
      double titleSize, double subSize, double iconSize) {
    return GestureDetector(
      onTap: _mostrarManual,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(cardPadding),
        decoration: BoxDecoration(
          color: const Color(0xFF7C3AED),
          borderRadius: BorderRadius.circular(cardRadius),
        ),
        child: Row(
          children: [
            Icon(Icons.menu_book_rounded, color: Colors.white, size: iconSize),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Manual de usuario',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.bold,
                      fontSize: titleSize,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Aprende a usar numi paso a paso',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: subSize,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                color: Colors.white70, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavBar(BuildContext context, bool isTablet) {
    final navIconSize = isTablet ? 36.0 : 28.0;
    return Container(
      color: Colors.white,
      padding: EdgeInsets.only(
          left: isTablet ? 32 : 16,
          right: isTablet ? 32 : 16,
          bottom: isTablet ? 20 : 16),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: isTablet ? 12 : 8),
        decoration: BoxDecoration(
          color: _cyanTeal,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              icon: Icon(Icons.home_rounded, color: Colors.white, size: navIconSize),
              onPressed: () => Navigator.of(context).maybePop(),
              tooltip: 'Inicio',
            ),
            IconButton(
              icon: Icon(Icons.bar_chart_rounded, color: Colors.white, size: navIconSize),
              onPressed: () => Navigator.of(context).maybePop(),
              tooltip: 'Progreso',
            ),
            IconButton(
              icon: Icon(Icons.settings_rounded, color: Colors.white, size: navIconSize),
              onPressed: () {},
              tooltip: 'Configuración',
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Modal del Manual de Usuario ─────────────────────────────────────────────
class _ManualSheet extends StatelessWidget {
  const _ManualSheet();

  static const Color _purple   = Color(0xFF7C3AED);
  static const Color _blue     = Color(0xFF3475F7);
  static const Color _green    = Color(0xFF3DCC52);
  static const Color _red      = Color(0xFFB83232);
  static const Color _violet   = Color(0xFF8B5CF6);
  static const Color _orange   = Color(0xFFF5A623);
  static const Color _teal     = Color(0xFF65CEE3);

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;
    final isTablet = sw >= 600;
    final hPad = isTablet ? 32.0 : 20.0;
    final titleSize = isTablet ? 22.0 : 18.0;
    final bodySize  = isTablet ? 16.0 : 14.0;

    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),

            // Encabezado
            Padding(
              padding: EdgeInsets.symmetric(horizontal: hPad),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _purple.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.menu_book_rounded, color: _purple, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Manual de usuario',
                            style: TextStyle(
                                fontFamily: 'Hiruko',
                                fontSize: isTablet ? 26.0 : 22.0,
                                fontWeight: FontWeight.bold,
                                color: _purple)),
                        Text('numi v1.0.0  ·  Android  ·  Medellín 2026',
                            style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: bodySize - 1,
                                color: Colors.grey)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.grey),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),
            Divider(color: Colors.grey.shade200),

            // Contenido scrollable
            Expanded(
              child: ListView(
                controller: controller,
                padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 12),
                children: [

                  // 1 ─ ¿Qué es numi?
                  _Seccion(
                    numero: '1', titulo: '¿Qué es numi?',
                    icono: Icons.auto_stories_rounded, color: _purple,
                    titleSize: titleSize, bodySize: bodySize,
                    contenido:
                        'Numi es una app educativa móvil para niños y niñas de 1° a 5° de primaria en Medellín. '
                        'Combina actividades interactivas, juegos y un asistente de inteligencia artificial '
                        'que guía al estudiante a través de cinco áreas del conocimiento de forma divertida.\n\n'
                        'La app tiene elementos de gamificación — rachas de días y seguimiento de progreso — '
                        'para motivar el hábito de estudio diario.\n\n'
                        '🔢 Matemáticas — Números, comparación y sumas.\n'
                        '🔬 Ciencias Naturales — Seres vivos, cuerpo humano, animales y plantas.\n'
                        '📖 Español — Palabras, vocabulario y oraciones.\n'
                        '🌍 Inglés — Tarjetas, emparejamiento y escucha.\n'
                        '🏙️ Ciencias Sociales — Héroes, objetos y pasado/presente.',
                  ),

                  // 2 ─ Requisitos
                  _Seccion(
                    numero: '2', titulo: 'Requisitos del sistema',
                    icono: Icons.phone_android_rounded, color: _teal,
                    titleSize: titleSize, bodySize: bodySize,
                    contenido:
                        '📱 Sistema operativo: Android 8.0 o superior.\n'
                        '💾 Espacio en disco: mínimo 150 MB libres.\n'
                        '🖥️ Pantalla: resolución mínima 720 × 1280 px.\n'
                        '🔊 Altavoz o audífonos (recomendados).\n'
                        '🌐 Internet: solo para el registro inicial y sincronización.\n\n'
                        '💡 La mayoría de actividades funcionan sin conexión una vez que '
                        'el estudiante ha iniciado sesión al menos una vez.',
                  ),

                  // 3 ─ Primeros pasos
                  _Seccion(
                    numero: '3', titulo: 'Primeros pasos',
                    icono: Icons.rocket_launch_rounded, color: _blue,
                    titleSize: titleSize, bodySize: bodySize,
                    contenido:
                        '▶ Al abrir numi por primera vez se reproduce una animación de introducción. '
                        'La app detecta automáticamente si hay un perfil registrado.\n\n'
                        '— Si hay estudiante registrado → va al menú de su grado.\n'
                        '— Si no hay estudiante → abre la pantalla de Registro.\n\n'
                        '📝 REGISTRO — Etapa 1 (datos básicos):\n'
                        '1. Ingresa tu edad.\n'
                        '2. Selecciona tu género: Niño o Niña.\n'
                        '3. Escribe tu correo Gmail (@gmail.com).\n'
                        '4. Crea una contraseña (mín. 8 caracteres, una mayúscula y un número).\n'
                        '5. Toca "Continuar".\n\n'
                        '📝 REGISTRO — Etapa 2 (nombre y personaje):\n'
                        '1. Escribe tu nombre.\n'
                        '2. Elige tu personaje: Pollito 🐥 o Monito 🐒.\n'
                        '3. Selecciona tu grado escolar (1° a 5°).\n\n'
                        '🔑 INICIO DE SESIÓN:\n'
                        'Ingresa tu correo y contraseña, o usa "Entra con Google".\n'
                        'Si olvidaste tu contraseña, toca "¿Olvidaste tu contraseña?" '
                        'y recibirás un enlace en tu Gmail.',
                  ),

                  // 4 ─ Menú principal
                  _Seccion(
                    numero: '4', titulo: 'Menú principal',
                    icono: Icons.home_rounded, color: _teal,
                    titleSize: titleSize, bodySize: bodySize,
                    contenido:
                        '🎓 GRADOS 1° y 2°:\n'
                        'El menú muestra las 5 materias con íconos coloridos. '
                        'En la parte superior aparecen el nombre del estudiante, '
                        'su personaje y el indicador de Racha de días.\n\n'
                        '🎓 GRADOS 3° a 5°:\n'
                        'Diseño adaptado con actividades de mayor complejidad '
                        'dentro de las mismas cinco materias.\n\n'
                        '🔥 RACHA DE DÍAS:\n'
                        'Muestra cuántos días consecutivos ha ingresado el estudiante. '
                        'Se marca un círculo por cada día de la semana. '
                        'Si no ingresas un día completo, ¡la racha se reinicia!',
                  ),

                  // 5 ─ Matemáticas
                  _Seccion(
                    numero: '5', titulo: 'Matemáticas 🔢',
                    icono: Icons.calculate_rounded, color: _blue,
                    titleSize: titleSize, bodySize: bodySize,
                    contenido:
                        '📌 Descubre los Números\n'
                        'Reconocimiento y conteo de números del 1 al 10. '
                        'El estudiante asocia la cantidad con el símbolo numérico. '
                        'Incluye retroalimentación sonora al acertar.\n\n'
                        '📌 ¿Quién Tiene Más?\n'
                        'Comparación de cantidades. Se presentan dos grupos de objetos '
                        'y el estudiante identifica cuál tiene más elementos. '
                        'Tiene niveles de dificultad incremental.\n\n'
                        '📌 Sumar\n'
                        'Operaciones de adición con elementos visuales (frutas, figuras). '
                        'El estudiante arrastra objetos para completar sumas básicas '
                        'con mecánica drag & drop.',
                  ),

                  // 6 ─ Ciencias Naturales
                  _Seccion(
                    numero: '6', titulo: 'Ciencias Naturales 🔬',
                    icono: Icons.science_rounded, color: _green,
                    titleSize: titleSize, bodySize: bodySize,
                    contenido:
                        '📌 Vivo / No Vivo\n'
                        'El estudiante clasifica objetos entre seres vivos y no vivos. '
                        'Desarrolla pensamiento categórico y vocabulario científico básico.\n\n'
                        '📌 El Cuerpo Humano\n'
                        'Diagramas interactivos con las partes del cuerpo. '
                        'Aprende a identificar y nombrar cada parte con imágenes claras.\n\n'
                        '📌 Animales\n'
                        'Exploración de diferentes tipos de animales, sus características '
                        'y clasificaciones. Incluye imágenes, sonidos y descripciones.\n\n'
                        '📌 Las Plantas\n'
                        'Las partes de las plantas y su importancia para el ecosistema. '
                        'Actividades de reconocimiento con vocabulario básico de botánica.',
                  ),

                  // 7 ─ Español
                  _Seccion(
                    numero: '7', titulo: 'Español 📖',
                    icono: Icons.menu_book_rounded, color: _red,
                    titleSize: titleSize, bodySize: bodySize,
                    contenido:
                        '📌 Palabra Loca\n'
                        'El estudiante lee o escucha palabras y debe identificar '
                        'o completar la correcta. Trabaja vocabulario, ortografía '
                        'y lectura comprensiva en formato dinámico.\n\n'
                        '📌 Arma la Palabra\n'
                        'Letras o sílabas desordenadas que el niño o niña debe ordenar '
                        'para armar la palabra correcta. Desarrolla conciencia fonológica.\n\n'
                        '📌 Oraciones\n'
                        'El estudiante ordena palabras para construir oraciones completas '
                        'con sentido, reforzando gramática y comprensión del lenguaje.',
                  ),

                  // 8 ─ Inglés
                  _Seccion(
                    numero: '8', titulo: 'Inglés 🌍',
                    icono: Icons.language_rounded, color: _violet,
                    titleSize: titleSize, bodySize: bodySize,
                    contenido:
                        '📌 Tarjetas de Vocabulario\n'
                        'Flashcards interactivas con imágenes y palabras en inglés. '
                        'Se voltean para ver la traducción. Ideal para memorización visual.\n\n'
                        '📌 Emparejamiento de Palabras\n'
                        'El estudiante conecta palabras en inglés con su imagen '
                        'o traducción en español. Desarrolla asociación de vocabulario bilingüe.\n\n'
                        '📌 Inglés Escucha\n'
                        'Escucha palabras pronunciadas en inglés y selecciona la imagen '
                        'o palabra correcta. Fortalece comprensión auditiva y pronunciación.\n\n'
                        '🎉 Al completar las actividades de inglés aparece una pantalla '
                        'de celebración con animaciones y mensajes de motivación.',
                  ),

                  // 9 ─ Ciencias Sociales
                  _Seccion(
                    numero: '9', titulo: 'Ciencias Sociales 🏙️',
                    icono: Icons.location_city_rounded, color: _orange,
                    titleSize: titleSize, bodySize: bodySize,
                    contenido:
                        '📌 Héroes de la Ciudad\n'
                        'Aprende sobre los héroes cotidianos de Medellín: bomberos, médicos, '
                        'policías, docentes y más. Disponible en tres niveles progresivos '
                        'con tarjetas ilustradas.\n\n'
                        '📌 Detective de Objetos\n'
                        'Actividad de identificación donde el estudiante encuentra y clasifica '
                        'objetos del entorno cotidiano. Tres niveles de dificultad progresiva.\n\n'
                        '📌 Pasado y Presente\n'
                        'Comparación de cómo eran las cosas antes y cómo son ahora: '
                        'transporte, viviendas, herramientas. Desarrolla pensamiento histórico. '
                        'Tres niveles disponibles.',
                  ),

                  // 10 ─ Asistente IA
                  _Seccion(
                    numero: '10', titulo: 'Asistente de IA 🤖',
                    icono: Icons.smart_toy_rounded, color: _purple,
                    titleSize: titleSize, bodySize: bodySize,
                    contenido:
                        'Numi incluye un asistente de IA con tecnología RAG que responde '
                        'preguntas educativas relacionadas con las materias, adaptadas al grado.\n\n'
                        '¿Cómo usarlo?\n'
                        '1. Desde el menú principal, toca la materia que quieres.\n'
                        '2. Escribe tu pregunta en el campo de texto inferior.\n'
                        '3. Toca el botón de enviar.\n'
                        '4. El asistente responde con una explicación adaptada a tu grado.\n'
                        '5. Los grados 3° a 5° pueden hacer un Quiz tocando el ícono 🧩.\n\n'
                        'Color del chat por materia:\n'
                        '🔵 Matemáticas  🟢 Ciencias  🔴 Español  🟣 Inglés  🟠 Sociales',
                  ),

                  // 11 ─ Progreso y Racha
                  _Seccion(
                    numero: '11', titulo: 'Progreso y Racha 📊',
                    icono: Icons.bar_chart_rounded, color: _teal,
                    titleSize: titleSize, bodySize: bodySize,
                    contenido:
                        '🔥 Racha de Días:\n'
                        'La racha muestra cuántos días consecutivos ha ingresado el estudiante. '
                        'Aparece en el menú principal con un círculo por cada día de la semana.\n'
                        '— Días activos: marcados en color brillante.\n'
                        '— Días inactivos: tono más claro o gris.\n'
                        'La racha se reinicia si no ingresas un día completo.\n\n'
                        '📈 Mi Progreso:\n'
                        'Muestra el avance en cada materia mediante barras horizontales. '
                        'Cada barra aumenta al completar actividades dentro de cada módulo. '
                        '¡Los personajes celebran cada actividad completada!',
                  ),

                  // 12 ─ Configuración
                  _Seccion(
                    numero: '12', titulo: 'Configuración ⚙️',
                    icono: Icons.settings_rounded, color: _teal,
                    titleSize: titleSize, bodySize: bodySize,
                    contenido:
                        '• Nombre del estudiante: cambia el nombre que aparece en el menú.\n'
                        '• Grado escolar: cambia tu grado (redirige al menú correcto).\n'
                        '• Música de fondo: activa o desactiva la música ambiental.\n'
                        '• Efectos de sonido: activa o desactiva los sonidos de las actividades.\n'
                        '• Volumen: ajusta el volumen general con el deslizador.\n'
                        '• Modo sin conexión: activa el modo offline para usar sin internet.\n'
                        '• Idioma: actualmente disponible en Español.\n'
                        '• Manual de usuario: este manual que estás leyendo ahora.\n'
                        '• Reiniciar base de datos: borra todos los datos (¡no se puede deshacer!).\n'
                        '• Cerrar sesión: sale de la cuenta. La app regresa al Registro.',
                  ),

                  // 13 ─ Preguntas frecuentes
                  _Seccion(
                    numero: '13', titulo: 'Preguntas frecuentes ❓',
                    icono: Icons.help_outline_rounded, color: _purple,
                    titleSize: titleSize, bodySize: bodySize,
                    contenido:
                        '¿Puedo usar numi sin internet?\n'
                        'Sí. Una vez registrado e iniciada la sesión, la mayoría de actividades '
                        'funcionan sin conexión. Solo el registro inicial y la sincronización '
                        'requieren internet.\n\n'
                        '¿Qué hago si olvido mi contraseña?\n'
                        'En la pantalla de inicio de sesión toca "¿Olvidaste tu contraseña?" '
                        'y recibirás un enlace en tu Gmail para crear una nueva.\n\n'
                        '¿Puedo registrar más de un estudiante?\n'
                        'La versión actual está optimizada para un perfil por dispositivo. '
                        'Cierra sesión y registra un nuevo usuario para cambiar de perfil.\n\n'
                        '¿El progreso se guarda automáticamente?\n'
                        'Sí, se guarda en la base de datos del dispositivo al completar '
                        'cada actividad.\n\n'
                        '¿Los personajes (Pollito y Monito) tienen diferencias?\n'
                        'No. La elección es puramente estética. Ambos acceden exactamente '
                        'a las mismas actividades y contenidos.\n\n'
                        '¿Por qué algunos grados aparecen deshabilitados?\n'
                        'Los grados 1° y 2° están completamente activos. Los grados 3°, 4° '
                        'y 5° tienen menú diferenciado y algunas actividades pueden estar '
                        'en desarrollo.',
                  ),

                  // 14 ─ Soporte
                  _Seccion(
                    numero: '14', titulo: 'Soporte y solución de errores 🛠️',
                    icono: Icons.support_agent_rounded, color: _blue,
                    titleSize: titleSize, bodySize: bodySize,
                    contenido:
                        '• Consulta al docente o responsable que administre la app.\n'
                        '• Repositorio en GitHub: github.com/geminitodo5-sketch/app-educativa-medellin\n\n'
                        'Errores comunes:\n\n'
                        '🔇 La app no reproduce sonido\n'
                        'Verifica que el dispositivo no esté en silencio y activa el sonido en Configuración.\n\n'
                        '🎬 El video de intro no reproduce\n'
                        'La app detecta el error y continúa automáticamente después de 2 segundos.\n\n'
                        '🔑 No puedo iniciar sesión\n'
                        'Verifica el email y contraseña. Recuerda que distingue entre mayúsculas y minúsculas.\n\n'
                        '📊 El progreso no se actualiza\n'
                        'Completa la actividad hasta la pantalla final; el progreso se registra al terminar.\n\n'
                        '💥 La app se cierra inesperadamente\n'
                        'Cierra y vuelve a abrir la app. Si persiste, desinstala y vuelve a instalar.',
                  ),

                  const SizedBox(height: 32),
                  // Pie del manual
                  Center(
                    child: Text(
                      'NUMI — App Educativa para Medellín\nManual de Usuario v1.0  ·  2026',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: bodySize - 2,
                        color: Colors.grey.shade400,
                        height: 1.6,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Widget de sección del manual ────────────────────────────────────────────
class _Seccion extends StatelessWidget {
  final String numero;
  final String titulo;
  final IconData icono;
  final Color color;
  final double titleSize;
  final double bodySize;
  final String contenido;

  const _Seccion({
    required this.numero,
    required this.titulo,
    required this.icono,
    required this.color,
    required this.titleSize,
    required this.bodySize,
    required this.contenido,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    numero,
                    style: const TextStyle(
                      fontFamily: 'Hiruko',
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Icon(icono, color: color, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  titulo,
                  style: TextStyle(
                    fontFamily: 'Hiruko',
                    fontSize: titleSize,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E1E2E),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F3FF),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFEDE9FE)),
            ),
            child: Text(
              contenido,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: bodySize,
                color: const Color(0xFF374151),
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}