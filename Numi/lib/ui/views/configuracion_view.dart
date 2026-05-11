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
import 'inicio_view.dart';
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

  // ── Reiniciar base de datos ───────────────────────────────────
  Future<void> _confirmarReset() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Reiniciar base de datos',
            style: TextStyle(fontFamily: 'Hiruko', fontSize: 20)),
        content: const Text(
          '¿Borrar todos los datos y empezar desde cero?\nEsta acción no se puede deshacer.',
          style: TextStyle(fontFamily: 'Poppins', fontSize: 15),
        ),
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
            child: const Text('Borrar',
                style: TextStyle(fontFamily: 'Poppins')),
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
                  _buildResetCard(cardPadding, cardRadius, cardTitleSize, cardSubSize, iconSize),
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

  Widget _buildResetCard(double cardPadding, double cardRadius,
      double titleSize, double subSize, double iconSize) {
    return GestureDetector(
      onTap: _confirmarReset,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(cardPadding),
        decoration: BoxDecoration(
          color: const Color(0xFFFF8C00),
          borderRadius: BorderRadius.circular(cardRadius),
        ),
        child: Row(
          children: [
            Icon(Icons.delete_forever_rounded, color: Colors.white, size: iconSize),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Reiniciar base de datos',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.bold,
                      fontSize: titleSize,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Borra todos los datos y empieza desde cero',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: subSize,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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