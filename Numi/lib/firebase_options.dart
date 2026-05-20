// ─────────────────────────────────────────────────────────────
//  lib/firebase_options.dart
//  Configuración Firebase — proyecto: rag-numi
//  Generado a partir de google-services.json
// ─────────────────────────────────────────────────────────────

// ignore_for_file: lines_longer_than_80_chars, avoid_classes_with_only_static_members

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions no están soportadas en esta plataforma.',
        );
    }
  }

  // ── App Web (Rag-NUMI) ────────────────────────────────────────
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDf82cM2oWpU1M_N2_Rxs6iVArQoMc2HLg',
    appId: '1:237541733416:web:78ed4347a78a59107bf11d',
    messagingSenderId: '237541733416',
    projectId: 'rag-numi',
    authDomain: 'rag-numi.firebaseapp.com',
    storageBucket: 'rag-numi.firebasestorage.app',
    measurementId: 'G-JV4YDXFP4Z',
  );

  // ── App Android (com.example.flutter_code) ────────────────────
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAl2D18Y7q0V2KchD6lDJKXtaG1wijsAlw',
    appId: '1:237541733416:android:49151d179042186c7bf11d',
    messagingSenderId: '237541733416',
    projectId: 'rag-numi',
    storageBucket: 'rag-numi.firebasestorage.app',
  );
}
