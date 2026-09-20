// lib/ui/views/ingles_congratulations_view.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/providers/app_state_provider.dart';
import '../../../data/providers/racha_provider.dart';

class InglesCongratulationsView extends ConsumerStatefulWidget {
  const InglesCongratulationsView({super.key});

  @override
  ConsumerState<InglesCongratulationsView> createState() =>
      _InglesCongratulationsViewState();
}

class _InglesCongratulationsViewState
    extends ConsumerState<InglesCongratulationsView> {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _verificarRacha());
  }

  Future<void> _verificarRacha() async {
    final estudiante = ref.read(estudianteActivoProvider);
    if (estudiante?.id == null || estudiante!.grado > 2 || !mounted) return;
    final svc = ref.read(rachaServiceProvider);
    final info = await svc.verificarRacha(estudiante.id!);
    if (info != null && mounted) {
      ref.read(rachaPendienteProvider.notifier).state = info;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final h = constraints.maxHeight;
          final w = constraints.maxWidth;

          return Stack(
            children: [
              // ── Fondo completo ──────────────────────────────────────────
              Positioned.fill(
                child: Image.asset(
                  'assets/images/bienvenida/fondos (1).png',
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) =>
                      Container(color: const Color(0xFF87CEEB)),
                ),
              ),

              // ── Contenido ───────────────────────────────────────────────
              SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Barra superior
                    Padding(
                      padding: EdgeInsets.fromLTRB(w * 0.043, h * 0.030, w * 0.043, h * 0.017),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.maybePop(context),
                            child: Icon(
                              Icons.arrow_back_rounded,
                              size: w * 0.107,
                              color: Colors.black,
                            ),
                          ),
                          SizedBox(width: w * 0.067),
                          Text(
                            'Completaste  las\nactividades',
                            style: TextStyle(
                              fontFamily: 'Hiruko',
                              fontSize: w * 0.067,
                              fontWeight: FontWeight.w900,
                              color: Colors.black87,
                              height: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Texto congratulations
                    Padding(
                      padding: EdgeInsets.only(top: h * 0.30, left: w * 0.15),
                      child: Text(
                        '¡Congratulations!',
                        style: TextStyle(
                          fontFamily: 'Hiruko',
                          fontSize: w * 0.08,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),

                    const Spacer(),
                  ],
                ),
              ),

              // ── Pollo — arriba izquierda, inclinado ─────────────────────
              Positioned(
                right: w * 0.7,
                bottom: h * 0.22,
                child: Transform.rotate(
                  angle: 0.4,
                  child: Image.asset(
                    'assets/images/areas/ingles/pollo gano.png',
                    width: w * 0.38,
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => const SizedBox(),
                  ),
                ),
              ),

              // ── Mono — centro-derecha abajo, grande ─────────────────────
              Positioned(
                left: w * 0.25,
                bottom: h * -0.01,
                child: Image.asset(
                  'assets/images/areas/ingles/mono gano.png',
                  width: w * 0.8,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => const SizedBox(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
