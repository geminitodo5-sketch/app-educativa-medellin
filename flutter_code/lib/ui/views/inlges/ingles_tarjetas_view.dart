// lib/ui/views/ingles_tarjetas_view.dart
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'ingles_congratulations_view.dart';

const _j3 = 'assets/images/areas/ingles/juego_3/';
const _back = 'assets/images/areas/ingles/juego_3/numi.png';
const _audJ3 = 'assets/images/areas/ingles/juego_3/selecciona la pareja.mp3';

const _cardColors = [
  Color(0xFFEF5350),
  Color(0xFFFF9800),
  Color(0xFF1E88E5),
  Color(0xFF43A047),
  Color(0xFF8E24AA),
  Color(0xFFE91E63),
];

enum TipoTarjeta { imagen, palabra, imagenVolumen }

class _CardData {
  final int id;
  final TipoTarjeta tipo;
  final String? img;
  final String? palabra;
  final Color color;

  const _CardData({
    required this.id,
    required this.tipo,
    this.img,
    this.palabra,
    required this.color,
  });
}

final _niveles = [
  [
    _CardData(id: 0, tipo: TipoTarjeta.imagen, img: '${_j3}balon.png', color: _cardColors[0]),
    _CardData(id: 0, tipo: TipoTarjeta.palabra, palabra: 'ball', color: _cardColors[1]),
    _CardData(id: 1, tipo: TipoTarjeta.imagen, img: '${_j3}carro.png', color: _cardColors[2]),
    _CardData(id: 1, tipo: TipoTarjeta.palabra, palabra: 'car', color: _cardColors[3]),
    _CardData(id: 2, tipo: TipoTarjeta.imagen, img: '${_j3}mano.png', color: _cardColors[4]),
    _CardData(id: 2, tipo: TipoTarjeta.palabra, palabra: 'hand', color: _cardColors[5]),
  ],
  [
    _CardData(id: 0, tipo: TipoTarjeta.imagen, img: '${_j3}oso.png', color: _cardColors[0]),
    _CardData(id: 0, tipo: TipoTarjeta.imagenVolumen, img: '${_j3}volumen_bear.png', color: _cardColors[1], palabra: 'bear'),
    _CardData(id: 1, tipo: TipoTarjeta.imagen, img: '${_j3}boca.png', color: _cardColors[2]),
    _CardData(id: 1, tipo: TipoTarjeta.imagenVolumen, img: '${_j3}volumen_mouth.png', color: _cardColors[3], palabra: 'mouth'),
    _CardData(id: 2, tipo: TipoTarjeta.imagen, img: '${_j3}naranja.png', color: _cardColors[4]),
    _CardData(id: 2, tipo: TipoTarjeta.imagenVolumen, img: '${_j3}volumen_orange.png', color: _cardColors[5], palabra: 'orange'),
  ],
  [
    _CardData(id: 0, tipo: TipoTarjeta.imagen, img: '${_j3}ojo.png', color: _cardColors[0]),
    _CardData(id: 0, tipo: TipoTarjeta.palabra, palabra: 'eye', color: _cardColors[1]),
    _CardData(id: 1, tipo: TipoTarjeta.imagen, img: '${_j3}6.png', color: _cardColors[2]),
    _CardData(id: 1, tipo: TipoTarjeta.palabra, palabra: 'six', color: _cardColors[3]),
    _CardData(id: 2, tipo: TipoTarjeta.imagen, img: '${_j3}libro.png', color: _cardColors[4]),
    _CardData(id: 2, tipo: TipoTarjeta.palabra, palabra: 'book', color: _cardColors[5]),
  ],
];

// ─────────────────────────────────────────────────────────────────────────
class InglesTarjetasView extends StatefulWidget {
  const InglesTarjetasView({super.key, this.onCompleted});
  final VoidCallback? onCompleted;
  @override
  State<InglesTarjetasView> createState() => _InglesTarjetasViewState();
}

class _InglesTarjetasViewState extends State<InglesTarjetasView> {
  final _player = AudioPlayer();

  int _nivel = 0;
  String _fase = 'preview';
  Timer? _previewTimer;

  late List<_CardData> _cartas;
  late List<bool> _volteada;
  late List<bool> _encontrada;

  int _primerIdx = -1;
  bool _bloqueado = false;

  @override
  void initState() {
    super.initState();
    _iniciarNivel();
  }

  void _iniciarNivel() {
    _cartas = List.from(_niveles[_nivel])..shuffle(Random());
    _volteada = List.filled(6, true);
    _encontrada = List.filled(6, false);
    _primerIdx = -1;
    _bloqueado = false;
    _fase = 'preview';

    _play(_audJ3);

    _previewTimer?.cancel();
    _previewTimer = Timer(const Duration(seconds: 3), () {
      if (!mounted) return;
      setState(() {
        _volteada = List.filled(6, false);
        _fase = 'juego';
      });
    });
  }

  void _mostrarFeedback(bool esCorrecto, VoidCallback onAction) {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(30),
          decoration: BoxDecoration(
            color: esCorrecto ? const Color(0xFFD7FFD3) : const Color(0xFFFFD3D3),
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
                    color: esCorrecto ? const Color(0xFF59E347) : const Color(0xFFF65757),
                    size: 40,
                  ),
                  const SizedBox(width: 15),
                  Text(
                    esCorrecto ? '¡Excelente trabajo!' : '¡Casi lo tienes!',
                    style: TextStyle(
                      fontFamily: 'Hiruko',
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: esCorrecto ? Colors.green[900] : Colors.red[900],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: esCorrecto ? const Color(0xFF59E347) : const Color(0xFFF65757),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    onAction();
                  },
                  child: Text(
                    esCorrecto ? 'Continuar' : 'Reintentar',
                    style: const TextStyle(
                      color: Colors.white,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _play(String path) async {
    try {
      await _player.stop();
      await _player.setAudioSource(AudioSource.asset(path));
      await _player.play();
    } catch (e) {
      debugPrint('Audio: $e');
    }
  }

  void _tocarCarta(int idx) {
    if (_bloqueado) return;
    if (_fase != 'juego') return;
    if (_volteada[idx]) return;
    if (_encontrada[idx]) return;

    setState(() => _volteada[idx] = true);

    if (_primerIdx == -1) {
      _primerIdx = idx;
    } else {
      final a = _cartas[_primerIdx];
      final b = _cartas[idx];
      final esPareja = a.id == b.id && a.tipo != b.tipo;

      if (esPareja) {
        setState(() {
          _encontrada[_primerIdx] = true;
          _encontrada[idx] = true;
          _primerIdx = -1;
        });
        if (_encontrada.every((e) => e)) {
          Future.delayed(const Duration(milliseconds: 600), _siguienteNivel);
        }
      } else {
        _bloqueado = true;
        final firstIdx = _primerIdx;
        _primerIdx = -1;
        Future.delayed(const Duration(milliseconds: 600), () {
          if (!mounted) return;
          setState(() {
            _volteada[firstIdx] = false;
            _volteada[idx] = false;
          });
          _mostrarFeedback(false, () {
            if (mounted) setState(() => _bloqueado = false);
          });
        });
      }
    }
  }

  void _siguienteNivel() {
    if (_nivel < 2) {
      setState(() => _nivel++);
      _iniciarNivel();
    } else {
      widget.onCompleted?.call();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const InglesCongratulationsView()),
      );
    }
  }

  @override
  void dispose() {
    _previewTimer?.cancel();
    _player.dispose();
    super.dispose();
  }

  Widget _buildIndicador() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (i) {
            final activo = i == _nivel;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: activo ? 24 : 9,
              height: 9,
              decoration: BoxDecoration(
                color: activo ? Colors.white : Colors.white38,
                borderRadius: BorderRadius.circular(5),
              ),
            );
          }),
        ),
        const SizedBox(height: 4),
        Text(
          'Level ${_nivel + 1}',
          style: const TextStyle(
            fontFamily: 'Hiruko',
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // Tomamos el alto disponible para calcular proporciones
    final screenHeight = MediaQuery.of(context).size.height;
    final topPadding = MediaQuery.of(context).padding.top;

    // Alto aproximado del header morado
    const headerHeight = 130.0;
    // Alto disponible para el cuerpo blanco
    final bodyHeight = screenHeight - topPadding - headerHeight;
    // Alto disponible para el grid dentro del cuerpo
    // (descontamos: instrucción ~32, preview msg ~20, spacing ~60)
    final gridHeight = bodyHeight - 130;
    // Cada tarjeta: gridHeight / 3 filas - spacing
    final cardHeight = (gridHeight - 28) / 3;
    // Ancho de tarjeta: mitad del ancho menos paddings y spacing
    final cardWidth = (MediaQuery.of(context).size.width - 40 - 14) / 2;
    final ratio = cardWidth / cardHeight;

    return Scaffold(
      backgroundColor: const Color(0xFF8B2FC9),
      body: SafeArea(
        child: Column(
          children: [
            // ── HEADER ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Align(
                    alignment: Alignment.topRight,
                    child: GestureDetector(
                      onTap: () => Navigator.maybePop(context),
                      child: const Icon(Icons.close, color: Colors.white, size: 24),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '¡Tarjetas!',
                    style: TextStyle(
                      fontFamily: 'Hiruko',
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildIndicador(),
                ],
              ),
            ),

            // ── CUERPO BLANCO ────────────────────────────────────────────
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(28),
                    topRight: Radius.circular(28),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Instrucción
                      Row(
                        children: const [
                          Icon(Icons.volume_up, color: Colors.black87, size: 22),
                          SizedBox(width: 8),
                          Text(
                            'Selecciona  la pareja',
                            style: TextStyle(
                              fontFamily: 'Hiruko',
                              fontSize: 16,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),

                      // Mensaje preview (solo cuando está mostrando)
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: _fase == 'preview'
                            ? Padding(
                                key: const ValueKey('preview'),
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  '¡Memoriza las tarjetas!',
                                  style: TextStyle(
                                    fontFamily: 'Hiruko',
                                    fontSize: 13,
                                    color: Colors.purple.shade300,
                                  ),
                                ),
                              )
                            : const SizedBox(key: ValueKey('empty'), height: 6),
                      ),

                      const SizedBox(height: 10),

                      // ── GRID ────────────────────────────────────────────
                      Expanded(
                        child: GridView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: 6,
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: ratio.clamp(0.85, 1.25),
                          ),
                          itemBuilder: (context, i) {
                            return _TarjetaFlip(
                              key: ValueKey(
                                '$_nivel-$i-${_cartas[i].id}-${_cartas[i].tipo}',
                              ),
                              data: _cartas[i],
                              volteada: _volteada[i],
                              encontrada: _encontrada[i],
                              onTap: () => _tocarCarta(i),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
// Tarjeta con volteo 3D
// ══════════════════════════════════════════════════════════════════════════
class _TarjetaFlip extends StatefulWidget {
  final _CardData data;
  final bool volteada;
  final bool encontrada;
  final VoidCallback onTap;

  const _TarjetaFlip({
    super.key,
    required this.data,
    required this.volteada,
    required this.encontrada,
    required this.onTap,
  });

  @override
  State<_TarjetaFlip> createState() => _TarjetaFlipState();
}

class _TarjetaFlipState extends State<_TarjetaFlip>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _anim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
    if (widget.volteada) _ctrl.value = 1.0;
  }

  @override
  void didUpdateWidget(_TarjetaFlip old) {
    super.didUpdateWidget(old);
    if (widget.volteada != old.volteada) {
      widget.volteada ? _ctrl.forward() : _ctrl.reverse();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _anim,
        builder: (_, __) {
          final angle = _anim.value * pi;
          final isFront = _anim.value >= 0.5;

          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(angle),
            child: isFront
                ? Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()..rotateY(pi),
                    child: _FrenteTarjeta(
                      data: widget.data,
                      encontrada: widget.encontrada,
                    ),
                  )
                : _ReversoTarjeta(),
          );
        },
      ),
    );
  }
}

// ── Frente ────────────────────────────────────────────────────────────────
class _FrenteTarjeta extends StatelessWidget {
  final _CardData data;
  final bool encontrada;

  const _FrenteTarjeta({required this.data, required this.encontrada});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: data.color,
        borderRadius: BorderRadius.circular(18),
        border: encontrada ? Border.all(color: Colors.white, width: 3) : null,
        boxShadow: [
          BoxShadow(
            color: encontrada
                ? Colors.greenAccent.withOpacity(0.6)
                : Colors.black26,
            blurRadius: encontrada ? 14 : 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Stack(
        children: [
          if (encontrada)
            Positioned(
              top: 6,
              right: 6,
              child: Container(
                width: 20,
                height: 20,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Color(0xFF43A047), size: 14),
              ),
            ),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: _contenido(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _contenido() {
    switch (data.tipo) {
      case TipoTarjeta.imagen:
        return Image.asset(
          data.img!,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) =>
              const Icon(Icons.image_not_supported, color: Colors.white54, size: 36),
        );

      case TipoTarjeta.palabra:
        return FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            data.palabra!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Hiruko',
              fontSize: 30,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        );

      case TipoTarjeta.imagenVolumen:
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Image.asset(
                data.img!,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.volume_up, color: Colors.white, size: 36),
              ),
            ),
            if (data.palabra != null) ...[
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  data.palabra!,
                  style: const TextStyle(
                    fontFamily: 'Hiruko',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        );
    }
  }
}

// ── Reverso (Numi) ────────────────────────────────────────────────────────
class _ReversoTarjeta extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF4DD0E1),
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 5, offset: Offset(0, 3)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Image.asset(
          _back,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const Center(
            child: Text(
              'NUMI',
              style: TextStyle(
                fontFamily: 'Hiruko',
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}