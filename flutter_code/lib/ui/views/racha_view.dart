// ─────────────────────────────────────────────────────────────
//  lib/ui/views/racha_view.dart
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import '../../data/services/racha_service.dart';

class _R {
  final double screenW;
  final double screenH;

  const _R({required this.screenW, required this.screenH});

  double get sw => screenW / 390;
  double get sh => screenH / 844;
  double get s  => (sw * 0.4 + sh * 0.6).clamp(0.7, 1.6);

  double get fontDias       => _c(108 * s, 72,  160);
  double get fontLabel      => _c(25  * s, 18,  34);
  double get fontBoton      => _c(20  * s, 15,  28);
  double get fontDiaCirculo => _c(11  * s, 9,   15);

  double get topPadding       => 20 * sh;
  double get gapDiasLabel     => 3  * sh;
  double get gapCirculos      => 14 * sh;
  double get gapBoton         => 16 * sh;
  double get bottomBoton      => 28 * sh;
  double get paddingHBoton    => 22 * sw;
  double get paddingHCirculos => 8  * sw;

  double get botonH      => _c(54 * sh, 44, 68);
  double get botonRadius => 30 * s;
  double get botonSombra => 5  * sh;

  double get circuloSize   => _c(34 * s, 26, 48);
  double get circuloBorder => 2  * s;

  static double _c(double v, double mn, double mx) => v.clamp(mn, mx);
}

// ─────────────────────────────────────────────────────────────

class RachaView extends StatelessWidget {
  final RachaInfo info;

  const RachaView({super.key, required this.info});

  static const _labels = ['L', 'Ma', 'Mi', 'J', 'V', 'S', 'D'];

  @override
  Widget build(BuildContext context) {
    final mq  = MediaQuery.of(context);
    final r   = _R(screenW: mq.size.width, screenH: mq.size.height);
    final hoy = DateTime.now().weekday;

    return Scaffold(
      backgroundColor: const Color(0xFF7BD0E8),
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(height: r.topPadding),

            Text(
              '${info.dias}',
              style: TextStyle(
                fontFamily: 'Hiruko',
                fontSize: r.fontDias,
                fontWeight: FontWeight.w900,
                color: Colors.black,
                height: 1.0,
                shadows: [
                  Shadow(
                    color: Colors.black.withValues(alpha: 0.20),
                    offset: Offset(3 * r.sw, 4 * r.sh),
                    blurRadius: 0,
                  ),
                ],
              ),
            ),

            SizedBox(height: r.gapDiasLabel),

            Text(
              info.dias == 1 ? 'dia de racha' : 'dias de racha',
              style: TextStyle(
                fontFamily: 'Hiruko',
                fontSize: r.fontLabel,
                fontWeight: FontWeight.w900,
                color: Colors.black,
              ),
            ),

            Expanded(
              child: LayoutBuilder(
                builder: (_, cs) => _PersonajesStack(
                  availH: cs.maxHeight,
                  availW: cs.maxWidth,
                ),
              ),
            ),

            SizedBox(height: r.gapCirculos),

            Padding(
              padding: EdgeInsets.symmetric(horizontal: r.paddingHCirculos),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(7, (i) {
                  final weekday = i + 1;
                  return _DiaCircle(
                    label: _labels[i],
                    activo: info.diasActivosSemana.contains(weekday),
                    esHoy: hoy == weekday,
                    r: r,
                  );
                }),
              ),
            ),

            SizedBox(height: r.gapBoton),

            Padding(
              padding: EdgeInsets.fromLTRB(
                  r.paddingHBoton, 0, r.paddingHBoton, r.bottomBoton),
              child: _BotonSiguiente(
                r: r,
                onTap: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Stack de personajes
// ─────────────────────────────────────────────────────────────

class _PersonajesStack extends StatelessWidget {
  final double availH;
  final double availW;

  const _PersonajesStack({required this.availH, required this.availW});

  @override
  Widget build(BuildContext context) {
    // ─── TAMAÑO PERSONAJES (no tocar) ─────────────────────
    final limiteAlto  = availH * 0.65;
    final limiteAncho = availW * 0.44;
    final personajeH  = limiteAlto < limiteAncho ? limiteAlto : limiteAncho;

    // ─── FUEGO MÁS GRANDE ─────────────────────────────────
    final fuegoH = personajeH * 1.55;
    final fuegoW = availW * 0.65;

    // ─── SEPARACIÓN LATERAL POLLO-MONO ────────────────────
    final overlap = personajeH * 0.18;

    // ─── SOMBRA ───────────────────────────────────────────
    final sombraW = personajeH * 1.80;
    const sombraH = 20.0;

    // ─── CENTRADO VERTICAL DEL GRUPO COMPLETO ─────────────
    final fuegoSobresale = fuegoH - (personajeH * 0.50);
    final grupoTotalH    = sombraH + 10 + personajeH + fuegoSobresale;

    // ✅ CAMBIO: se suma availH * 0.10 para subir todo el grupo
    final margenBase = ((availH - grupoTotalH) / 2 + availH * 0.10).clamp(8.0, availH * 0.40);

    final sombraBottom     = margenBase;
    final personajesBottom = margenBase + sombraH + 6.0;
    final fuegoBottom      = personajesBottom + personajeH * 0.32;

    return Stack(
      clipBehavior: Clip.hardEdge,
      children: [
        // ── 1. Fuego (más grande, detrás) ─────────────────
        Positioned(
          bottom: fuegoBottom,
          left: 0,
          right: 0,
          child: Center(
            child: SizedBox(
              height: fuegoH,
              width: fuegoW,
              child: Image.asset(
                'assets/images/racha/fuego.png',
                fit: BoxFit.contain,
                alignment: Alignment.bottomCenter,
                errorBuilder: (_, __, ___) => const SizedBox(),
              ),
            ),
          ),
        ),

        // ── 2. Personajes (mismo alto, centrados) ─────────
        Positioned(
          bottom: personajesBottom,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Mono
              SizedBox(
                height: personajeH,
                child: Image.asset(
                  'assets/images/areas/ingles/mono gano.png',
                  height: personajeH,
                  fit: BoxFit.fitHeight,
                  alignment: Alignment.bottomCenter,
                  errorBuilder: (_, __, ___) => const SizedBox(),
                ),
              ),
              // Pollito — mismo height, solapado
              Transform.translate(
                offset: Offset(-overlap, 0),
                child: SizedBox(
                  height: personajeH,
                  child: Image.asset(
                    'assets/images/areas/ingles/pollo gano.png',
                    height: personajeH,
                    fit: BoxFit.fitHeight,
                    alignment: Alignment.bottomCenter,
                    errorBuilder: (_, __, ___) => const SizedBox(),
                  ),
                ),
              ),
            ],
          ),
        ),

        // ── 3. Sombra oval centrada bajo los pies ─────────
        Positioned(
          bottom: sombraBottom,
          left: (availW - sombraW) / 2,
          child: Container(
            width:  sombraW,
            height: sombraH,
            decoration: BoxDecoration(
              color: const Color(0xFF2E8FA5).withValues(alpha: 0.60),
              borderRadius: BorderRadius.circular(sombraH / 2),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Círculo indicador de día
// ─────────────────────────────────────────────────────────────

class _DiaCircle extends StatelessWidget {
  final String label;
  final bool activo;
  final bool esHoy;
  final _R r;

  const _DiaCircle({
    required this.label,
    required this.activo,
    required this.esHoy,
    required this.r,
  });

  @override
  Widget build(BuildContext context) {
    final size = r.circuloSize;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: activo
                ? Colors.transparent
                : Colors.black.withValues(alpha: 0.22),
            border: esHoy && !activo
                ? Border.all(color: Colors.white, width: r.circuloBorder)
                : null,
          ),
          child: activo
              ? ClipOval(
                  child: Image.asset(
                    'assets/images/racha/icono.png',
                    width: size,
                    height: size,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFFFF9500),
                      ),
                      child: Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: size * 0.55,
                      ),
                    ),
                  ),
                )
              : null,
        ),
        SizedBox(height: 4 * r.sh),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Hiruko',
            fontSize: r.fontDiaCirculo,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Botón ¡Sigue así!
// ─────────────────────────────────────────────────────────────

class _BotonSiguiente extends StatelessWidget {
  final _R r;
  final VoidCallback onTap;

  const _BotonSiguiente({required this.r, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: r.botonH,
        decoration: BoxDecoration(
          color: const Color(0xFF5CD65C),
          borderRadius: BorderRadius.circular(r.botonRadius),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2E7D32),
              blurRadius: 0,
              offset: Offset(0, r.botonSombra),
            ),
          ],
        ),
        child: Center(
          child: Text(
            '¡Sigue así!',
            style: TextStyle(
              fontFamily: 'Hiruko',
              fontSize: r.fontBoton,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}