import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

class FelicitacionesModal extends StatefulWidget {
  final VoidCallback? onFinished;
  final Duration duracion;

  const FelicitacionesModal({
    super.key,
    this.onFinished,
    this.duracion = const Duration(seconds: 5),
  });

  static void mostrar(
    BuildContext context, {
    VoidCallback? onFinished,
    Duration duracion = const Duration(seconds: 5),
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => FelicitacionesModal(
        onFinished: onFinished,
        duracion: duracion,
      ),
    );
  }

  @override
  State<FelicitacionesModal> createState() => _FelicitacionesModalState();
}

class _FelicitacionesModalState extends State<FelicitacionesModal> {
  late final player = Player();
  late final controller = VideoController(player);
  final AudioPlayer _audioPlayer = AudioPlayer();

  static const _audioAsset =
      'assets/Audio/correcto_incorrecto/sonido_felicitaciones.mp3';

  @override
  void initState() {
    super.initState();
    _inicializar();
  }

  Future<void> _inicializar() async {
    // Sonido y video simultáneos
    _audioPlayer
        .setAsset(_audioAsset)
        .then((_) => _audioPlayer.play())
        .catchError((e) => debugPrint('Audio felicitaciones error: $e'));

    await player.setPlaylistMode(PlaylistMode.none);
    await player.open(
        Media('asset://assets/animations/felicidades_animacion_fondo.mp4'));

    player.stream.completed.listen((completed) {
      if (completed && mounted) {
        final dur = player.state.duration;
        if (dur > Duration.zero) {
          player.seek(dur - const Duration(milliseconds: 100));
        }
        player.pause();
      }
    });

    Future.delayed(widget.duracion, () {
      if (mounted) {
        Navigator.pop(context);
        widget.onFinished?.call();
      }
    });
  }

  @override
  void dispose() {
    player.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final w  = mq.size.width;
    final h  = mq.size.height;

    const videoAspect = 9.0 / 16.0;
    double videoW = w;
    double videoH = w / videoAspect;
    if (videoH < h) {
      videoH = h;
      videoW = h * videoAspect;
    }

    return Dialog(
      backgroundColor: Colors.black,
      insetPadding: EdgeInsets.zero,
      child: SizedBox(
        width: w,
        height: h,
        child: ClipRect(
          child: Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: videoW,
              height: videoH,
              child: Video(
                controller: controller,
                controls: NoVideoControls,
                fit: BoxFit.fill,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
