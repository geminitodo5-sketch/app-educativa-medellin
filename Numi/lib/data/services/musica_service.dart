// ─────────────────────────────────────────────────────────────
//  lib/data/services/musica_service.dart
//  Servicio global de música de fondo.
//  Usa ref-counting para soportar transiciones suaves entre
//  pantallas target sin cortar la música.
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MusicaService with WidgetsBindingObserver {
  static const _kMusicaActiva = 'musica_activa';
  static const _kVolumen     = 'musica_volumen';
  static const _asset =
      'assets/Audio/musica_aplicacion/musica_principal_fix.mp3';

  final AudioPlayer _player = AudioPlayer();
  late final Future<void> _listo;

  int _contadorPantallas = 0;
  bool _musicaActiva = true;
  double _volumen = 1.0;

  MusicaService() {
    _listo = _init();
    WidgetsBinding.instance.addObserver(this);
  }

  // Pausa al ir a background, retoma al volver si corresponde.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _player.pause();
    } else if (state == AppLifecycleState.resumed) {
      if (_musicaActiva && _contadorPantallas > 0 && !_player.playing) {
        _listo.then((_) {
          if (_musicaActiva && _contadorPantallas > 0 && !_player.playing) {
            _player.play();
          }
        });
      }
    }
  }

  Future<void> _init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _musicaActiva = prefs.getBool(_kMusicaActiva) ?? true;
      _volumen      = prefs.getDouble(_kVolumen) ?? 1.0;
      await _player.setAsset(_asset);
      await _player.setLoopMode(LoopMode.one);
      await _player.setVolume(_volumen);
    } catch (e) {
      debugPrint('MusicaService._init error: $e');
    }
  }

  /// Llamar en initState de una pantalla target.
  Future<void> entrar() async {
    _contadorPantallas++;
    if (_contadorPantallas == 1 && _musicaActiva) {
      await _listo;
      // Re-verificar tras esperar, por si salir() se llamó mientras tanto.
      if (_musicaActiva && _contadorPantallas > 0 && !_player.playing) {
        await _player.play();
      }
    }
  }

  /// Llamar en dispose de una pantalla target, o en didPushNext de RouteAware.
  Future<void> salir() async {
    if (_contadorPantallas > 0) _contadorPantallas--;
    if (_contadorPantallas == 0 && _player.playing) {
      await _player.pause();
    }
  }

  /// Actualiza preferencia de música y actúa de inmediato.
  Future<void> setMusicaActiva(bool activa) async {
    _musicaActiva = activa;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kMusicaActiva, activa);
    } catch (e) {
      debugPrint('MusicaService.setMusicaActiva error: $e');
    }
    await _listo;
    if (activa && _contadorPantallas > 0 && !_player.playing) {
      await _player.play();
    } else if (!activa && _player.playing) {
      await _player.pause();
    }
  }

  bool   get musicaActiva => _musicaActiva;
  double get volumen      => _volumen;

  Future<void> setVolumen(double v) async {
    _volumen = v.clamp(0.0, 1.0);
    try {
      await _player.setVolume(_volumen);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_kVolumen, _volumen);
    } catch (e) {
      debugPrint('MusicaService.setVolumen error: $e');
    }
  }

  Future<void> cerrar() async {
    WidgetsBinding.instance.removeObserver(this);
    await _player.dispose();
  }
}
