//  lib/data/services/api_sync_service.dart
//  Capa: Datos — Responsabilidad: Ingeniería
//
//  Sube y descarga perfil y progreso del estudiante hacia/desde el BACKEND
//  (API REST propia con su propia base de datos). El cliente ya no escribe
//  directo en ninguna base de datos remota.
//
//  Autenticación: cada request lleva el ID token de Firebase Auth; el backend
//  lo valida y usa su `uid` como dueño de los datos.
//
//    GET/PUT  /api/v1/me/perfil
//    GET/PUT  /api/v1/me/progreso     (PUT hace upsert en lote; gana el mayor avance)
//
//  No guarda estado local — solo opera sobre la red.

import 'dart:async';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/estudiante_model.dart';
import '../models/progreso_model.dart';
import 'api_config.dart';

/// Devuelve un ID token vigente, o null si no hay sesión.
typedef TokenProvider = Future<String?> Function();

class ApiSyncService {
  final Dio _dio;
  final TokenProvider _token;

  /// Tamaño máximo de lote aceptado por el backend (MAX_PROGRESO_POR_REQUEST = 500).
  static const int _lote = 400;

  /// Cada cuánto se consulta el servidor para reflejar cambios de otro dispositivo.
  static const Duration intervaloConsulta = Duration(seconds: 60);

  ApiSyncService({Dio? dio, TokenProvider? tokenProvider})
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: ApiConfig.baseUrl,
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 30),
            )),
        _token = tokenProvider ??
            (() async => FirebaseAuth.instance.currentUser?.getIdToken());

  Future<Options> _auth() async {
    final token = await _token();
    if (token == null) {
      throw StateError('Sin sesión: no se puede sincronizar.');
    }
    return Options(headers: {'Authorization': 'Bearer $token'});
  }

  // ── Perfil del estudiante ─────────────────────────────────────

  /// Sube (o actualiza) el perfil del estudiante.
  Future<void> subirPerfil(EstudianteModel e) async {
    if (e.firebaseUid == null) return;
    await _dio.put(
      '/api/v1/me/perfil',
      data: {
        'nombre':         _recortar(e.nombre, 60),
        'grado':          e.grado,
        'personaje':      _recortar(e.personaje, 30),
        if (e.email != null)          'email':          _recortar(e.email!, 254),
        if (e.edad != null)           'edad':           e.edad,
        if (e.genero != null)         'genero':         _recortar(e.genero!, 20),
        if (e.fechaRegistro.isNotEmpty) 'fecha_registro': e.fechaRegistro,
      },
      options: await _auth(),
    );
  }

  /// Descarga el perfil. Retorna null si el usuario no tiene perfil todavía.
  Future<Map<String, dynamic>?> descargarPerfil() async {
    try {
      final resp = await _dio.get<Map<String, dynamic>>(
        '/api/v1/me/perfil',
        options: await _auth(),
      );
      return resp.data;
    } on DioException catch (e) {
      // Solo un 404 con el código propio significa "cuenta sin perfil". Un 404
      // genérico (servidor sin estas rutas, URL equivocada) es un fallo, no una
      // cuenta nueva.
      if (e.response?.statusCode == 404 && _esPerfilInexistente(e.response?.data)) {
        return null;
      }
      rethrow;
    }
  }

  // ── Progreso ─────────────────────────────────────────────────

  /// Sube el progreso en lotes. El servidor fusiona: gana el mayor avance.
  Future<void> subirProgreso(List<ProgresoModel> registros) async {
    if (registros.isEmpty) return;
    final options = await _auth();
    for (int i = 0; i < registros.length; i += _lote) {
      final items = registros.skip(i).take(_lote).map((p) => {
            'grado':      p.grado,
            'materia':    p.materia,
            'actividad':  _recortar(p.actividad, 120),
            'porcentaje': p.porcentaje.clamp(0.0, 100.0),
            'intentos':   p.intentos,
            if (p.ultimaVez != null) 'ultima_vez': p.ultimaVez,
          }).toList();
      await _dio.put('/api/v1/me/progreso', data: {'items': items}, options: options);
    }
  }

  /// Descarga todo el progreso del usuario.
  Future<List<Map<String, dynamic>>> descargarProgreso() async {
    final resp = await _dio.get<List<dynamic>>(
      '/api/v1/me/progreso',
      options: await _auth(),
    );
    return (resp.data ?? const []).cast<Map<String, dynamic>>();
  }

  // ── Multi-dispositivo ─────────────────────────────────────────

  /// Consulta periódicamente el servidor y emite el progreso completo.
  /// El consumidor aplica la regla "gana el mayor avance", por lo que emitir
  /// registros ya conocidos es inofensivo. Ante un fallo de red emite una
  /// lista vacía y reintenta en el siguiente ciclo.
  Stream<List<Map<String, dynamic>>> escucharProgreso() async* {
    while (true) {
      try {
        yield await descargarProgreso();
      } catch (_) {
        yield const [];
      }
      await Future<void>.delayed(intervaloConsulta);
    }
  }

  static bool _esPerfilInexistente(dynamic cuerpo) {
    if (cuerpo is! Map) return false;
    final detalle = cuerpo['detail'];
    return detalle is Map && detalle['codigo'] == 'perfil_no_existe';
  }

  static String _recortar(String s, int max) =>
      s.length <= max ? s : s.substring(0, max);
}
