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
  bool _sonidoActivo = true;
  bool _musicaActiva = true;
  bool _modoOffline = true;
  String _idiomaSeleccionado = 'Español';

  @override
  void initState() {
    super.initState();
    _musicaActiva = ref.read(musicaServiceProvider).musicaActiva;
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

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // ── Perfil ─────────────────────────────────────
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _royalBlue,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        // Avatar
                        Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border:
                                Border.all(color: Colors.white, width: 3),
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
                                errorBuilder: (ctx, e, _) => const Icon(
                                    Icons.face_rounded,
                                    color: Colors.white,
                                    size: 40),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    nombre,
                                    style: const TextStyle(
                                      fontFamily: 'Hiruko',
                                      fontWeight: FontWeight.bold,
                                      fontSize: 22,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  GestureDetector(
                                    onTap: _mostrarDialogoNombre,
                                    child: const Icon(Icons.edit_rounded,
                                        color: Colors.white70, size: 20),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Text(
                                    '$grado° Grado',
                                    style: const TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 14,
                                      color: Colors.white70,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  GestureDetector(
                                    onTap: _mostrarDialogoGrado,
                                    child: const Icon(Icons.edit_rounded,
                                        color: Colors.white54, size: 16),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ── Sonido ─────────────────────────────────────
                  _buildSoundCard(),
                  const SizedBox(height: 12),

                  // ── Idioma ─────────────────────────────────────
                  _buildLanguageCard(),
                  const SizedBox(height: 12),

                  // ── Modo Offline ───────────────────────────────
                  _buildOfflineCard(),
                  const SizedBox(height: 12),

                  // ── Sync info ──────────────────────────────────
                  _buildSyncCard(),
                  const SizedBox(height: 12),

                  // ── Reiniciar BD ────────────────────────────────
                  _buildResetCard(),
                  const SizedBox(height: 12),

                  // ── Cerrar sesión ───────────────────────────────
                  _buildLogoutCard(),
                ],
              ),
            ),

            // ── Barra de navegación ─────────────────────────────
            _buildBottomNavBar(context),
          ],
        ),
      ),
    );
  }

  Widget _buildSoundCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cyanTeal,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.volume_up_outlined, color: Colors.white, size: 40),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Sonido',
                    style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.white)),
                const SizedBox(height: 8),
                _buildToggleRow('Sonido', _sonidoActivo,
                    (v) => setState(() => _sonidoActivo = v)),
                const SizedBox(height: 8),
                _buildToggleRow('Música', _musicaActiva, (v) {
                  setState(() => _musicaActiva = v);
                  ref.read(musicaServiceProvider).setMusicaActiva(v);
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleRow(
      String title, bool value, ValueChanged<bool> onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title,
            style: const TextStyle(
                fontFamily: 'Poppins', fontSize: 14, color: Colors.white)),
        SizedBox(
          height: 30,
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

  Widget _buildLanguageCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cyanTeal,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.language_outlined, color: Colors.white, size: 40),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Idioma',
                    style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.white)),
                const SizedBox(height: 8),
                _buildRadioOption('Español'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRadioOption(String title) {
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
              style: const TextStyle(
                  fontFamily: 'Poppins', fontSize: 14, color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buildOfflineCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cyanTeal,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const Icon(Icons.wifi_off_outlined, color: Colors.white, size: 40),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Modo Offline',
                    style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.white)),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Text('¡Funciona sin internet!',
                          style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 14,
                              color: Colors.white)),
                    ),
                    SizedBox(
                      height: 30,
                      child: Switch(
                        value: _modoOffline,
                        onChanged: (v) => setState(() => _modoOffline = v),
                        activeThumbColor: Colors.white,
                        activeTrackColor: Colors.green,
                        inactiveTrackColor: Colors.white24,
                        inactiveThumbColor: Colors.white,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
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

  Widget _buildSyncCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF3475F7).withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const Icon(Icons.sync_rounded, color: Colors.white, size: 36),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('Sincronización',
                    style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.white)),
                SizedBox(height: 4),
                Text(
                  'Tu progreso se guarda localmente y se sincroniza automáticamente cuando haya internet.',
                  style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResetCard() {
    return GestureDetector(
      onTap: _confirmarReset,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFF8C00),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Row(
          children: [
            Icon(Icons.delete_forever_rounded, color: Colors.white, size: 36),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Reiniciar base de datos',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Borra todos los datos y empieza desde cero',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
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

  Widget _buildLogoutCard() {
    return GestureDetector(
      onTap: _cerrarSesion,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFEF5353),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Row(
          children: [
            Icon(Icons.logout_rounded, color: Colors.white, size: 36),
            SizedBox(width: 16),
            Text(
              'Cerrar sesión',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavBar(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: _cyanTeal,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              icon: const Icon(Icons.home_rounded,
                  color: Colors.white, size: 28),
              onPressed: () => Navigator.of(context).maybePop(),
              tooltip: 'Inicio',
            ),
            IconButton(
              icon: const Icon(Icons.bar_chart_rounded,
                  color: Colors.white, size: 28),
              onPressed: () => Navigator.of(context).maybePop(),
              tooltip: 'Progreso',
            ),
            IconButton(
              icon: const Icon(Icons.settings_rounded,
                  color: Colors.white, size: 28),
              onPressed: () {},
              tooltip: 'Configuración',
            ),
          ],
        ),
      ),
    );
  }
}
