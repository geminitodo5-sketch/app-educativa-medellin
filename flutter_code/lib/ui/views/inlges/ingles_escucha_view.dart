import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
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

// Ruta del audio de instrucción general
const _audioInstruccion = 'assets/images/areas/ingles/juego_1/audios_1/audio.mp3';

class InglesEscuchaView extends StatefulWidget {
  const InglesEscuchaView({super.key, this.onCompleted});
  final VoidCallback? onCompleted;

  @override
  State<InglesEscuchaView> createState() => _InglesEscuchaViewState();
}

class _InglesEscuchaViewState extends State<InglesEscuchaView> {
  late final Player _player;

  int _nivel = 0;
  int _seleccion = -1;
  bool _respondido = false;
  int _puntos = 0;

  Map get _data => _niveles[_nivel];
  int get _correcta => _data['correcta'] as int;
  List get _opciones => _data['opciones'] as List;

  @override
  void initState() {
    super.initState();
    _player = Player();
    // Reproduce instrucción automáticamente al entrar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _reproducirInstruccion();
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  /// Reproduce el audio de instrucción general
  Future<void> _reproducirInstruccion() async {
    try {
      await _player.open(Media('asset:///$_audioInstruccion'));
      await _player.play();
    } catch (e) {
      debugPrint('Error audio instrucción: $e');
    }
  }

  /// Reproduce cualquier audio por ruta
  Future<void> _play(String assetPath) async {
    try {
      await _player.open(Media('asset:///$assetPath'));
      await _player.play();
    } catch (e) {
      debugPrint('Audio error: $e');
    }
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
            color: esCorrecto
                ? const Color(0xFFD7FFD3)
                : const Color(0xFFFFD3D3),
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
                    color: esCorrecto
                        ? const Color(0xFF59E347)
                        : const Color(0xFFF65757),
                    size: 40,
                  ),
                  const SizedBox(width: 15),
                  Text(
                    esCorrecto ? '¡Excelente trabajo!' : '¡Casi lo tienes!',
                    style: TextStyle(
                      fontFamily: 'Hiruko',
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: esCorrecto
                          ? Colors.green[900]
                          : Colors.red[900],
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
                    backgroundColor: esCorrecto
                        ? const Color(0xFF59E347)
                        : const Color(0xFFF65757),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
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
                      // Instrucción con ícono tappable
                      GestureDetector(
                        onTap: _reproducirInstruccion,
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF0F4FF),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.volume_up_rounded,
                                color: Color(0xFF3475F7),
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              'Escucha y elige el correcto',
                              style: TextStyle(
                                fontFamily: 'Hiruko',
                                fontSize: 15,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Botón de audio de la pregunta
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

                      // Grid de opciones
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