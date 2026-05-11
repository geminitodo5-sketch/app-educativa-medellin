// ─────────────────────────────────────────────────────────────
//  lib/data/services/feedback_sounds.dart
//  Singleton que reproduce el sonido de correcto/incorrecto.
//  Llamar FeedbackSounds.instance.reproducir(esCorrecto) desde
//  cualquier pantalla de actividad antes de mostrar el feedback.
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

class FeedbackSounds {
  FeedbackSounds._();
  static final FeedbackSounds instance = FeedbackSounds._();

  final AudioPlayer _player = AudioPlayer();

  static const _correcto   = 'assets/Audio/correcto_incorrecto/sonido_correcto.mp3';
  static const _incorrecto = 'assets/Audio/correcto_incorrecto/sonido incorrecto.mp3';

  Future<void> reproducir(bool esCorrecto) async {
    try {
      await _player.stop();
      await _player.setAsset(esCorrecto ? _correcto : _incorrecto);
      await _player.play();
    } catch (e) {
      debugPrint('FeedbackSounds error: $e');
    }
  }
}
