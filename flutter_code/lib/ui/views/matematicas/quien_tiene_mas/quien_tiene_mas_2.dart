import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart'; // ✅ Importante
import 'quien_tiene_mas_3.dart';

class MenosFrutasview extends StatefulWidget {
  const MenosFrutasview({super.key});

  @override
  State<MenosFrutasview> createState() => _MenosFrutasviewState();
}

class _MenosFrutasviewState extends State<MenosFrutasview> {
  // ✅ Definición del reproductor
  Player? _player;

  @override
  void initState() {
    super.initState();
    _player = Player();
    
    // Reproducir automáticamente al entrar
    Future.microtask(() => _reproducirInstruccion());
  }

  @override
  void dispose() {
    _player?.dispose(); // ✅ Liberar memoria
    super.dispose();
  }

  Future<void> _reproducirInstruccion() async {
    try {
      await _player?.open(
        Media('asset:///assets/Audio/Matematicas/audio mate5_mezcla.mp3'),
      );
    } catch (e) {
      debugPrint('Error al reproducir audio: $e');
    }
  }

  void _mostrarFeedback(BuildContext context, bool esCorrecto, VoidCallback onAction) {
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

  void _verificarRespuesta(BuildContext context, int seleccion) {
    final esCorrecto = seleccion == 1;
    _mostrarFeedback(context, esCorrecto, () {
      if (esCorrecto) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const QuienTieneMasview3()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF3475F7),
      body: Stack(
        children: [
          const Positioned(
            top: 70,
            left: 0,
            right: 0,
            child: Text(
              'Quién tiene más',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontFamily: 'Hiruko',
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: MediaQuery.of(context).size.height * 0.82,
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(50),
                  topRight: Radius.circular(50),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 40),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _buildTreeDisplay(
                          imagePath: 'assets/images/actividades/matematicas/arbol_manzana.png',
                          index: '1',
                          indexColor: const Color(0xFFF65757),
                        ),
                        _buildTreeDisplay(
                          imagePath: 'assets/images/actividades/matematicas/arbol_naranjas.png',
                          index: '2',
                          indexColor: const Color(0xFFEF9325),
                        ),
                      ],
                    ),

                    const Spacer(),

                    // Fila de Instrucción con botón de audio funcional
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.volume_up_outlined, size: 60),
                          color: Colors.black87,
                          onPressed: _reproducirInstruccion, // ✅ Acción de audio
                        ),
                        const SizedBox(width: 15),
                        const Expanded(
                          child: Text(
                            '¿Cuál árbol tiene menos frutas?',
                            style: TextStyle(
                              fontSize: 22,
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w700,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 40),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildActionButton(
                          context,
                          label: 'Árbol 1',
                          color: const Color(0xFF3475F7),
                          onPressed: () => _verificarRespuesta(context, 1),
                        ),
                        _buildActionButton(
                          context,
                          label: 'Árbol 2',
                          color: const Color(0xFF3475F7),
                          onPressed: () => _verificarRespuesta(context, 2),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),

          Positioned(
            top: 35,
            right: 15,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 30),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTreeDisplay({
    required String imagePath,
    required String index,
    required Color indexColor,
  }) {
    return Column(
      children: [
        Text(
          index,
          style: TextStyle(
            fontSize: 45,
            fontFamily: 'Behove',
            fontWeight: FontWeight.w900,
            color: indexColor,
          ),
        ),
        const SizedBox(height: 10),
        Image.asset(imagePath, height: 180, fit: BoxFit.contain),
      ],
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: 150,
      height: 55,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.black,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 18,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}