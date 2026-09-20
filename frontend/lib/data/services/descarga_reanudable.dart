//  lib/data/services/descarga_reanudable.dart
//  Capa: Datos — Responsabilidad: Ingeniería
//
//  Descarga de archivos grandes que SE REANUDA donde quedó.
//
//  Escribe en "<destino>.part" y guarda el tamaño total en "<destino>.part.meta".
//  Si la conexión se corta, la app se minimiza o el proceso muere, la próxima
//  llamada continúa desde el último byte escrito (cabecera HTTP Range) en vez
//  de empezar de cero. Al terminar renombra ".part" al nombre final.
//
//  Sin estado en memoria: el progreso guardado se deduce de los archivos en disco.

import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';
import 'package:dio/dio.dart';

class DescargaReanudable {
  static const int _bloqueEscritura = 1024 * 1024;

  final Dio _dio;

  /// Fallos consecutivos SIN avanzar ni un byte antes de rendirse.
  final int reintentosMax;

  /// Espera antes del reintento número [n] (1, 2, 3…). Inyectable para pruebas.
  final Duration Function(int n) espera;

  /// Tiempo sin recibir datos tras el cual se considera la conexión colgada.
  final Duration inactividad;

  DescargaReanudable({
    Dio? dio,
    this.reintentosMax = 40,
    Duration Function(int n)? espera,
    this.inactividad = const Duration(seconds: 45),
  })  : _dio = dio ??
            Dio(BaseOptions(
              connectTimeout: const Duration(seconds: 20),
              followRedirects: true,
              maxRedirects: 5,
            )),
        espera = espera ?? _esperaExponencial;

  static Duration _esperaExponencial(int n) =>
      Duration(seconds: (1 << (n.clamp(1, 6) - 1)).clamp(1, 60));

  File _part(File destino) => File('${destino.path}.part');
  File _meta(File destino) => File('${destino.path}.part.meta');

  /// Fracción 0.0–1.0 ya descargada (0 si no hay descarga a medias).
  Future<double> progresoGuardado(File destino) async {
    try {
      final total = await _leerTotal(_meta(destino));
      final part = _part(destino);
      if (total == null || total <= 0 || !await part.exists()) return 0.0;
      return ((await part.length()) / total).clamp(0.0, 1.0);
    } catch (_) {
      return 0.0;
    }
  }

  /// Igual que [descargar], pero el trabajo (red, TLS y disco) corre en un
  /// Isolate propio para no competir con el hilo de la interfaz. El avance
  /// llega limitado a ~2 veces por segundo.
  Future<void> descargarEnSegundoPlano({
    required String url,
    required File destino,
    required void Function(int recibidos, int total) onProgress,
  }) async {
    if (await destino.exists()) return;
    final mensajes = ReceivePort();
    final errores = ReceivePort();
    final terminado = Completer<void>();

    final isolate = await Isolate.spawn<_Trabajo>(
      _entradaIsolate,
      _Trabajo(mensajes.sendPort, url, destino.path, reintentosMax, inactividad),
      onError: errores.sendPort,
      debugName: 'descarga-modelo',
    );

    mensajes.listen((m) {
      if (m is List && m[0] == 'p') {
        onProgress(m[1] as int, m[2] as int);
      } else if (m == 'ok') {
        if (!terminado.isCompleted) terminado.complete();
      } else if (m is List && m[0] == 'e') {
        if (!terminado.isCompleted) terminado.completeError(Exception(m[1]));
      }
    });
    errores.listen((e) {
      if (!terminado.isCompleted) {
        terminado.completeError(Exception('Fallo interno de la descarga: $e'));
      }
    });

    try {
      await terminado.future;
    } finally {
      isolate.kill(priority: Isolate.immediate);
      mensajes.close();
      errores.close();
    }
  }

  /// Descarga [url] a [destino]. Si [destino] ya existe no hace nada.
  /// [onProgress] recibe (bytesRecibidos, bytesTotales) incluyendo lo previo.
  Future<void> descargar({
    required String url,
    required File destino,
    required void Function(int recibidos, int total) onProgress,
    CancelToken? cancelToken,
  }) async {
    if (await destino.exists()) return;
    await destino.parent.create(recursive: true);

    final part = _part(destino);
    final meta = _meta(destino);
    int? total = await _leerTotal(meta);
    var fallosSeguidos = 0;

    while (true) {
      _revisarCancelado(cancelToken);
      try {
        if (total == null) {
          total = await _consultarTotal(url, cancelToken);
          await meta.writeAsString('$total');
        }

        var offset = await part.exists() ? await part.length() : 0;
        if (offset > total) {
          await part.delete();
          offset = 0;
        }
        onProgress(offset, total);

        if (offset < total) {
          final avanzo =
              await _transferir(url, part, offset, total, onProgress, cancelToken);
          if (avanzo) fallosSeguidos = 0;
        }

        if (await part.length() == total) break;
        throw const _Incompleto();
      } on DioException catch (e) {
        if (CancelToken.isCancel(e)) rethrow;
        final code = e.response?.statusCode;
        if (code == 416) {
          // El servidor rechaza el rango: el .part no corresponde al archivo.
          if (await part.exists()) await part.delete();
          total = null;
        } else if (code != null &&
            code >= 400 &&
            code < 500 &&
            code != 408 &&
            code != 429) {
          rethrow; // 401/403/404…: reintentar no sirve
        }
        await _esperarReintento(++fallosSeguidos, e, cancelToken);
      } on FileSystemException {
        rethrow; // disco lleno / sin permisos: no se arregla reintentando
      } on _Incompleto catch (e) {
        await _esperarReintento(++fallosSeguidos, e, cancelToken);
      } on IOException catch (e) {
        await _esperarReintento(++fallosSeguidos, e, cancelToken);
      } on TimeoutException catch (e) {
        await _esperarReintento(++fallosSeguidos, e, cancelToken);
      }
    }

    await part.rename(destino.path);
    if (await meta.exists()) await meta.delete();
  }

  void _revisarCancelado(CancelToken? token) {
    if (token != null && token.isCancelled) throw token.cancelError!;
  }

  Future<void> _esperarReintento(
      int fallos, Object causa, CancelToken? cancelToken) async {
    if (fallos > reintentosMax) {
      throw Exception('Descarga interrumpida tras $reintentosMax intentos: $causa');
    }
    await Future<void>.delayed(espera(fallos));
    _revisarCancelado(cancelToken);
  }

  /// Averigua el tamaño total pidiendo el primer byte (a la vez prueba el Range).
  Future<int> _consultarTotal(String url, CancelToken? cancelToken) async {
    final ct = CancelToken();
    cancelToken?.whenCancel.then((_) => ct.cancel());
    final resp = await _dio.get<ResponseBody>(
      url,
      options: Options(
        responseType: ResponseType.stream,
        headers: {'Range': 'bytes=0-0'},
        validateStatus: (s) => s == 200 || s == 206,
      ),
      cancelToken: ct,
    );

    int? total;
    final cr = resp.headers.value('content-range'); // "bytes 0-0/12345"
    if (resp.statusCode == 206 && cr != null && cr.contains('/')) {
      total = int.tryParse(cr.split('/').last.trim());
    }
    total ??= int.tryParse(resp.headers.value('content-length') ?? '');

    // Solo queríamos las cabeceras: cerrar el cuerpo sin leerlo.
    ct.cancel();
    try {
      await resp.data?.stream.drain<void>();
    } catch (_) {}

    if (total == null || total <= 0) {
      throw StateError('El servidor no informó el tamaño del archivo.');
    }
    return total;
  }

  /// Descarga desde [offset] hasta el final. Devuelve true si escribió algo.
  Future<bool> _transferir(
    String url,
    File part,
    int offset,
    int total,
    void Function(int, int) onProgress,
    CancelToken? cancelToken,
  ) async {
    final resp = await _dio.get<ResponseBody>(
      url,
      options: Options(
        responseType: ResponseType.stream,
        headers: {'Range': 'bytes=$offset-'},
        validateStatus: (s) => s == 200 || s == 206,
      ),
      cancelToken: cancelToken,
    );

    // 200 con offset>0: el servidor ignoró el Range y envía todo desde el inicio.
    final desdeCero = resp.statusCode == 200 && offset > 0;
    var recibidos = desdeCero ? 0 : offset;
    final raf = await part.open(mode: desdeCero ? FileMode.write : FileMode.append);

    var escribio = false;
    var ultimoAviso = 0;
    // Acumula en bloques de ~1 MB: muchísimas menos escrituras a disco que
    // escribir cada trozo (~16 KB) que entrega la red.
    final buffer = BytesBuilder(copy: false);
    Future<void> volcar() async {
      if (buffer.isEmpty) return;
      await raf.writeFrom(buffer.takeBytes());
    }

    try {
      await for (final chunk in resp.data!.stream.timeout(inactividad)) {
        buffer.add(chunk);
        recibidos += chunk.length;
        escribio = true;
        if (buffer.length >= _bloqueEscritura) await volcar();
        // Avisar como máximo cada ~256 KB para no saturar a quien escucha.
        if (recibidos - ultimoAviso >= 262144 || recibidos >= total) {
          ultimoAviso = recibidos;
          onProgress(recibidos, total);
        }
      }
    } finally {
      // Lo recibido hasta un corte también se guarda: así se reanuda exacto.
      await volcar();
      await raf.flush();
      await raf.close();
    }
    onProgress(recibidos, total);
    return escribio;
  }

  Future<int?> _leerTotal(File meta) async {
    try {
      if (!await meta.exists()) return null;
      return int.tryParse((await meta.readAsString()).trim());
    } catch (_) {
      return null;
    }
  }
}

class _Incompleto implements Exception {
  const _Incompleto();
  @override
  String toString() => 'archivo incompleto';
}

/// Datos que viajan al Isolate (solo tipos simples: se copian entre hilos).
class _Trabajo {
  final SendPort puerto;
  final String url;
  final String destino;
  final int reintentosMax;
  final Duration inactividad;
  const _Trabajo(
      this.puerto, this.url, this.destino, this.reintentosMax, this.inactividad);
}

Future<void> _entradaIsolate(_Trabajo t) async {
  final d = DescargaReanudable(
      reintentosMax: t.reintentosMax, inactividad: t.inactividad);
  final reloj = Stopwatch()..start();
  var ultimoEnvio = -1000;
  try {
    await d.descargar(
      url: t.url,
      destino: File(t.destino),
      onProgress: (rec, tot) {
        // Como máximo ~2 avisos por segundo (y siempre el último).
        final ahora = reloj.elapsedMilliseconds;
        if (ahora - ultimoEnvio >= 500 || rec >= tot) {
          ultimoEnvio = ahora;
          t.puerto.send(['p', rec, tot]);
        }
      },
    );
    t.puerto.send('ok');
  } catch (e) {
    t.puerto.send(['e', e.toString()]);
  }
}
