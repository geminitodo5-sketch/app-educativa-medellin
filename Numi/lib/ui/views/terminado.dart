import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import '../../data/providers/app_state_provider.dart';
import '../../data/providers/racha_provider.dart';

class ActividadTerminadaScreen extends ConsumerStatefulWidget {
  final VoidCallback? onVolver;

  const ActividadTerminadaScreen({super.key, this.onVolver});

  @override
  ConsumerState<ActividadTerminadaScreen> createState() =>
      _ActividadTerminadaScreenState();
}

class _ActividadTerminadaScreenState
    extends ConsumerState<ActividadTerminadaScreen> {
  late final Player _videoPlayer;
  late final VideoController _videoController;
  final AudioPlayer _audioPlayer = AudioPlayer();

  static const _videoAsset =
      'asset://assets/animations/felicidades_animacion_fondo.mp4';
  static const _audioAsset =
      'assets/Audio/correcto_incorrecto/sonido_felicitaciones.mp3';

  @override
  void initState() {
    super.initState();
    _videoPlayer = Player();
    _videoController = VideoController(_videoPlayer);
    _inicializar();
  }

  Future<void> _inicializar() async {
    // Sonido y video simultáneos
    _audioPlayer
        .setAsset(_audioAsset)
        .then((_) => _audioPlayer.play())
        .catchError((e) => debugPrint('Audio felicitaciones error: $e'));

    await _videoPlayer.setPlaylistMode(PlaylistMode.none);
    await _videoPlayer.open(Media(_videoAsset));

    // Al terminar el video, pausar en el último frame
    _videoPlayer.stream.completed.listen((completed) {
      if (completed && mounted) {
        final dur = _videoPlayer.state.duration;
        if (dur > Duration.zero) {
          _videoPlayer.seek(dur - const Duration(milliseconds: 100));
        }
        _videoPlayer.pause();
      }
    });

    // Verificar racha después de un momento
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) _verificarRacha();
    });
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
  void dispose() {
    _videoPlayer.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Video a pantalla completa
          Video(
            controller: _videoController,
            controls: NoVideoControls,
            fit: BoxFit.cover,
          ),

          // Botón de volver superpuesto
          SafeArea(
            child: Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: EdgeInsets.all(w * 0.04),
                child: GestureDetector(
                  onTap: widget.onVolver ?? () => Navigator.of(context).pop(),
                  child: Container(
                    padding: EdgeInsets.all(w * 0.025),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.arrow_back_rounded,
                      color: Colors.white,
                      size: w * 0.065,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
