//  lib/data/services/descarga_primer_plano.dart
//  Capa: Datos — Responsabilidad: Ingeniería
//
//  Mantiene vivo el proceso de la app mientras se descarga el modelo, para que
//  Android no lo congele al minimizarla. Muestra una notificación con el
//  porcentaje. Es "mejor esfuerzo": si no se puede iniciar (p. ej. el usuario
//  negó las notificaciones o no es Android) la descarga sigue mientras la app
//  esté abierta y se retoma desde el último byte al volver.

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart' show Color;
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

class DescargaPrimerPlano {
  const DescargaPrimerPlano._();

  static const int _serviceId = 4711;
  static bool _inicializado = false;

  // Silueta de la N de Numi (res/drawable-*/ic_stat_numi.png) sobre el celeste de la marca.
  static const _icono = NotificationIcon(
    metaDataName: 'com.example.flutter_code.service.NUMI_ICON',
    backgroundColor: Color(0xFF66CDE3),
  );

  static void _configurar() {
    if (_inicializado) return;
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'numi_descarga_modelo',
        channelName: 'Descarga del asistente Numi',
        channelDescription: 'Progreso de la descarga del modelo de IA',
        onlyAlertOnce: true,
      ),
      iosNotificationOptions: const IOSNotificationOptions(),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.nothing(),
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );
    _inicializado = true;
  }

  static Future<void> iniciar({String texto = 'Preparando descarga…'}) async {
    if (!Platform.isAndroid) return;
    try {
      _configurar();
      final permiso = await FlutterForegroundTask.checkNotificationPermission();
      if (permiso != NotificationPermission.granted) {
        await FlutterForegroundTask.requestNotificationPermission();
      }
      if (await FlutterForegroundTask.isRunningService) return;
      await FlutterForegroundTask.startService(
        serviceId: _serviceId,
        serviceTypes: [ForegroundServiceTypes.dataSync],
        notificationTitle: 'Descargando asistente de Numi',
        notificationText: texto,
        notificationIcon: _icono,
      );
    } catch (e) {
      debugPrint('DescargaPrimerPlano.iniciar: $e');
    }
  }

  static Future<void> actualizar(String texto) async {
    if (!Platform.isAndroid) return;
    try {
      if (await FlutterForegroundTask.isRunningService) {
        await FlutterForegroundTask.updateService(
          notificationText: texto,
          notificationIcon: _icono,
        );
      }
    } catch (_) {}
  }

  static Future<void> detener() async {
    if (!Platform.isAndroid) return;
    try {
      if (await FlutterForegroundTask.isRunningService) {
        await FlutterForegroundTask.stopService();
      }
    } catch (e) {
      debugPrint('DescargaPrimerPlano.detener: $e');
    }
  }
}
