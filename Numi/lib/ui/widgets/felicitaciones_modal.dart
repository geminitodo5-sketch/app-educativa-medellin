// ─────────────────────────────────────────────────────────────
//  lib/ui/widgets/felicitaciones_modal.dart
//  Modal de felicitaciones con animación de video
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:media_kit/media_kit.dart';

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

  @override
  void initState() {
    super.initState();
    _inicializar();
  }

  Future<void> _inicializar() async {
    await player.setPlaylistMode(PlaylistMode.none);
    await player.open(Media('asset://assets/animations/felicidades_animacion_fondo.mp4'));
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Dialog(
      backgroundColor: Colors.black,
      insetPadding: EdgeInsets.zero,
      child: SizedBox(
        width: size.width,
        height: size.height,
        child: Video(
          controller: controller,
          controls: NoVideoControls,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
