import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../viewmodels/matematicas_view_model.dart';

class MatematicasView extends ConsumerStatefulWidget {
  const MatematicasView({super.key});

  @override
  ConsumerState<MatematicasView> createState() => _MatematicasViewState();
}

class _MatematicasViewState extends ConsumerState<MatematicasView>
    with TickerProviderStateMixin {
  late final AnimationController _pollitoCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat(reverse: true);

  late final AnimationController _monoCtrl = AnimationController(
    vsync: this, 
    duration: const Duration(milliseconds: 1500),
  )..repeat(reverse: true);

  late final Animation<double> _pollitoY =
      Tween<double>(begin: 0, end: -8).animate(
    CurvedAnimation(parent: _pollitoCtrl, curve: Curves.easeInOut),
  );

  late final Animation<double> _monoY =
      Tween<double>(begin: 0, end: -6).animate(
    CurvedAnimation(parent: _monoCtrl, curve: Curves.easeInOut),
  );

  @override
  void dispose() {
    _pollitoCtrl.dispose();
    _monoCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = ref.read(matematicasViewModelProvider);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF64D8EB), Color(0xFFB4E6A5)],
          ),
        ),
        child: Stack(
          children: [
            // ── Fondo Paisaje ──────────────────────────────
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Image.asset(
                'assets/images/interfaz/fondos/fondo.jpg',
                fit: BoxFit.cover,
              ),
            ),

            // ── Pollito flotante (posicionado detrás del SafeArea) ──
            Positioned(
              top: MediaQuery.of(context).size.height * 0.22,
              left: 50,
              child: AnimatedBuilder(
                animation: _pollitoY,
                builder: (_, child) => Transform.translate(
                  offset: Offset(0, _pollitoY.value),
                  child: child,
                ),
                child: Image.asset(
                  'assets/images/avatares/avatar_pollo1.jpg',
                  width: 140,
                ),
              ),
            ),

            SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  // ── Flecha volver y Título ──────────────
                  GestureDetector(
                    onTap: () {
                      viewModel.commandVolver();
                      Navigator.of(context).maybePop();
                    },
                    child: const Icon(Icons.arrow_back, size: 40, color: Colors.black),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'matemáticas',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),

                  const Spacer(flex: 2),

                  // ── Botones Centrales ───────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Column(
                      children: [
                        _BotonMateria(
                          icono: const _IconoNumeros(),
                          texto: 'Los números',
                          onTap: () => viewModel.commandSeleccionarLeccion('Los números'),
                        ),
                        const SizedBox(height: 15),
                        _BotonMateria(
                          icono: const _IconoPregunta(),
                          texto: 'Quien tiene más',
                          onTap: () => viewModel.commandSeleccionarLeccion('Quien tiene más'),
                        ),
                        const SizedBox(height: 15),
                        _BotonMateria(
                          icono: const _IconoSumar(),
                          texto: 'Sumar',
                          onTap: () => viewModel.commandSeleccionarLeccion('Sumar'),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(flex: 3),
                ],
              ),
            ),

            // ── Mono flotante abajo derecha ─────────
            Positioned(
              bottom: 10,
              right: 10,
              child: AnimatedBuilder(
                animation: _monoY,
                builder: (_, child) => Transform.translate(
                  offset: Offset(0, _monoY.value),
                  child: child,
                ),
                child: Image.asset(
                  'assets/images/avatares/avatar_mono1.jpg',
                  width: 250,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BotonMateria extends StatefulWidget {
  final Widget icono;
  final String texto;
  final VoidCallback onTap;

  const _BotonMateria({
    required this.icono,
    required this.texto,
    required this.onTap,
  });

  @override
  State<_BotonMateria> createState() => _BotonMateriaState();
}

class _BotonMateriaState extends State<_BotonMateria>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 80),
  );
  late final Animation<double> _scale =
      Tween<double>(begin: 1.0, end: 0.96).animate(_ctrl);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onTap();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          height: 90,
          decoration: BoxDecoration(
            color: const Color(0xFF427CFF),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: const [
              BoxShadow(
                color: Color(0xFF1C5FBF),
                blurRadius: 0,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                margin: const EdgeInsets.all(5),
                width: 80,
                height: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(child: widget.icono),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    widget.texto,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(right: 14),
                child: Icon(Icons.arrow_forward_ios,
                    color: Colors.white, size: 30),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IconoNumeros extends StatelessWidget {
  const _IconoNumeros();
  @override
  Widget build(BuildContext context) {
    const s = TextStyle(fontSize: 16, fontWeight: FontWeight.w900);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(mainAxisSize: MainAxisSize.min, children: [
          Text('1', style: s.copyWith(color: const Color(0xFFE74C3C))),
          const SizedBox(width: 3),
          Text('2', style: s.copyWith(color: const Color(0xFF3498DB))),
        ]),
        Row(mainAxisSize: MainAxisSize.min, children: [
          Text('3', style: s.copyWith(color: const Color(0xFF27AE60))),
          const SizedBox(width: 3),
          Text('4', style: s.copyWith(color: const Color(0xFF9B59B6))),
        ]),
      ],
    );
  }
}

class _IconoPregunta extends StatelessWidget {
  const _IconoPregunta();
  @override
  Widget build(BuildContext context) {
    return const Text(
      '?',
      style: TextStyle(
        fontSize: 30,
        fontWeight: FontWeight.w900,
        color: Color(0xFF9B59B6),
      ),
    );
  }
}

class _IconoSumar extends StatelessWidget {
  const _IconoSumar();
  @override
  Widget build(BuildContext context) {
    const s = TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.w900,
      color: Color(0xFFE67E22),
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('+', style: s),
        const SizedBox(width: 4),
        const Text(':', style: s),
      ],
    );
  }
}