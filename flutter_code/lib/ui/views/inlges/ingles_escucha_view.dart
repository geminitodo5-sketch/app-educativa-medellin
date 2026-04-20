import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'ingles_congratulations_view.dart';

const _img = 'assets/images/areas/ingles/juego_1/imagenes_1/';
const _aud = 'assets/images/areas/ingles/juego_1/audios_1/';

final _niveles = [
  {
    'pregunta': '${_aud}strawberry.mp3',
    'correcta': 1,
    'opciones': [
      {'img': '${_img}manzana.png', 'audio': '${_aud}apple.mp3'},
      {'img': '${_img}fresa.png', 'audio': '${_aud}strawberry.mp3'},
      {'img': '${_img}uva.png', 'audio': '${_aud}grapes.mp3'},
      {'img': '${_img}banana.png', 'audio': '${_aud}banana.mp3'},
    ],
  },
  {
    'pregunta': '${_aud}three.mp3',
    'correcta': 1,
    'opciones': [
      {'img': '${_img}4.png', 'audio': '${_aud}four.mp3'},
      {'img': '${_img}3.png', 'audio': '${_aud}three.mp3'},
      {'img': '${_img}0.png', 'audio': '${_aud}zero.mp3'},
      {'img': '${_img}1.png', 'audio': '${_aud}one.mp3'},
    ],
  },
  {
    'pregunta': '${_aud}bear.mp3',
    'correcta': 3,
    'opciones': [
      {'img': '${_img}perro.png', 'audio': '${_aud}dog.mp3'},
      {'img': '${_img}pato.png', 'audio': '${_aud}duck.mp3'},
      {'img': '${_img}gato.png', 'audio': '${_aud}cat.mp3'},
      {'img': '${_img}oso.png', 'audio': '${_aud}bear.mp3'},
    ],
  },
];

const _colores = [
  Color(0xFF2196F3),
  Color(0xFFFF9800),
  Color(0xFF4CAF50),
  Color(0xFF9C27B0),
];

const _etiquetas = ['Fruits', 'Numbers', 'Animals'];

class InglesEscuchaView extends StatefulWidget {
  const InglesEscuchaView({super.key, this.onCompleted});
  final VoidCallback? onCompleted;

  @override
  State<InglesEscuchaView> createState() => _InglesEscuchaViewState();
}

class _InglesEscuchaViewState extends State<InglesEscuchaView> {
  final _player = AudioPlayer();

  int _nivel = 0;
  int _seleccion = -1;
  bool _respondido = false;
  int _puntos = 0;

  Map get _data => _niveles[_nivel];
  int get _correcta => _data['correcta'] as int;
  List get _opciones => _data['opciones'] as List;

  Future<void> _play(String path) async {
    try {
      await _player.stop();
      await _player.setAudioSource(AudioSource.asset(path));
      await _player.play();
    } catch (e) {
      debugPrint('Audio error: $e');
    }
  }

  void _mostrarFeedback(bool esCorrecto, VoidCallback onAction) {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: esCorrecto ? const Color(0xFFD7FFD3) : const Color(0xFFFFD3D3),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              esCorrecto ? Icons.check_circle_rounded : Icons.cancel_rounded,
              color: esCorrecto ? Colors.green[800] : Colors.red[800],
              size: 56,
            ),
            const SizedBox(height: 12),
            Text(
              esCorrecto ? '¡Excelente trabajo!' : '¡Casi lo tienes!',
              style: TextStyle(
                fontFamily: 'Hiruko',
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: esCorrecto ? Colors.green[900] : Colors.red[900],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: esCorrecto ? Colors.green[700] : Colors.red[700],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  onAction();
                },
                child: Text(
                  esCorrecto ? 'Continuar' : 'Reintentar',
                  style: const TextStyle(
                    fontFamily: 'Hiruko',
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _seleccionar(int i) {
    if (_respondido) return;
    setState(() {
      _seleccion = i;
      _respondido = true;
      if (i == _correcta) _puntos++;
    });
    _play(_opciones[i]['audio'] as String);
    final esCorrecto = i == _correcta;
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) {
        _mostrarFeedback(esCorrecto, () {
          if (esCorrecto) {
            _siguiente();
          } else {
            setState(() {
              _seleccion = -1;
              _respondido = false;
            });
          }
        });
      }
    });
  }

  void _siguiente() {
    if (_nivel < 2) {
      setState(() {
        _nivel++;
        _seleccion = -1;
        _respondido = false;
      });
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
              width: activo ? 26 : 10,
              height: 10,
              decoration: BoxDecoration(
                color: activo ? Colors.white : Colors.white38,
                borderRadius: BorderRadius.circular(5),
              ),
            );
          }),
        ),
        const SizedBox(height: 5),
        Text(
          _etiquetas[_nivel],
          style: const TextStyle(
            fontFamily: 'Hiruko',
            color: Colors.white70,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF8B2FC9),
      body: SafeArea(
        child: Column(
          children: [
            // ── HEADER ── reducido para dar más espacio al grid
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Align(
                    alignment: Alignment.topRight,
                    child: GestureDetector(
                      onTap: () => Navigator.maybePop(context),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '¡Aprende escuchando!',
                    style: TextStyle(
                      fontFamily: 'Hiruko',
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildIndicador(),
                ],
              ),
            ),

            // ── CONTENIDO ──
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                  child: Column(
                    children: [
                      // Instrucción
                      Row(
                        children: const [
                          Icon(Icons.volume_up, color: Colors.black87, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Escucha y elige el correcto',
                            style: TextStyle(
                              fontFamily: 'Hiruko',
                              fontSize: 15,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Botón de audio — más pequeño
                      GestureDetector(
                        onTap: () => _play(_data['pregunta'] as String),
                        child: Image.asset(
                          '${_img}altavoz 1.png',
                          width: 56,
                          height: 56,
                          color: Colors.black87,
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Grid de opciones — ocupa todo el espacio restante
                      Expanded(
                        child: GridView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: 4,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 14,
                            mainAxisSpacing: 14,
                            childAspectRatio: 1.0,
                          ),
                          itemBuilder: (context, i) {
                            final op = _opciones[i];
                            final esCorrecta = i == _correcta;
                            final seleccionada = _seleccion == i;

                            Color color = _colores[i];
                            if (_respondido && esCorrecta) {
                              color = const Color(0xFF4AC338);
                            }
                            if (_respondido && seleccionada && !esCorrecta) {
                              color = const Color(0xFFEF5353);
                            }

                            return GestureDetector(
                              onTap: () => _seleccionar(i),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                decoration: BoxDecoration(
                                  color: color,
                                  borderRadius: BorderRadius.circular(18),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Colors.black26,
                                      blurRadius: 6,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(18),
                                    child: Image.asset(op['img'] as String),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                      const SizedBox(height: 16),
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