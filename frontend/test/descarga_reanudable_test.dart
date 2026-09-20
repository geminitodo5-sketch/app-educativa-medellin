import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_code/data/services/descarga_reanudable.dart';
import 'package:flutter_test/flutter_test.dart';

/// Servidor local con soporte de Range. Puede cortar la conexión a mitad de
/// la primera respuesta o ignorar el Range, para simular fallos reales.
class _Servidor {
  final Uint8List datos;
  final bool soportaRange;
  final int? cortarTrasBytes; // corta la 1.ª respuesta con datos tras N bytes
  final rangos = <String>[];
  var _cortado = false;
  late final HttpServer _srv;

  _Servidor(this.datos, {this.soportaRange = true, this.cortarTrasBytes});

  String get url => 'http://127.0.0.1:${_srv.port}/modelo.bin';

  Future<void> iniciar() async {
    _srv = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    _srv.listen(_atender);
  }

  Future<void> detener() => _srv.close(force: true);

  Future<void> _atender(HttpRequest req) async {
    final r = req.headers.value('range');
    rangos.add(r ?? '');
    var ini = 0;
    var fin = datos.length - 1;
    var parcial = false;
    if (soportaRange && r != null) {
      final m = RegExp(r'bytes=(\d+)-(\d*)').firstMatch(r)!;
      ini = int.parse(m.group(1)!);
      if (m.group(2)!.isNotEmpty) fin = int.parse(m.group(2)!);
      parcial = true;
    }
    final res = req.response;
    if (parcial) {
      res.statusCode = HttpStatus.partialContent;
      res.headers.set('content-range', 'bytes $ini-$fin/${datos.length}');
    }
    final cuerpo = datos.sublist(ini, fin + 1);
    res.contentLength = cuerpo.length;

    final cortar = cortarTrasBytes != null && !_cortado && cuerpo.length > 100;
    if (cortar) {
      _cortado = true;
      final socket = await res.detachSocket(); // envía cabeceras (con content-length completo)
      socket.add(datosParciales(cuerpo, cortarTrasBytes!));
      await socket.flush();
      socket.destroy(); // conexión rota a mitad de la descarga
      return;
    }
    res.add(cuerpo);
    await res.close();
  }
}

Uint8List datosParciales(Uint8List cuerpo, int n) => cuerpo.sublist(0, n);

Uint8List _datos(int n) =>
    Uint8List.fromList(List<int>.generate(n, (i) => (i * 31 + 7) & 0xFF));

void main() {
  late Directory tmp;
  late File destino;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('descarga_test_');
    destino = File('${tmp.path}/modelo.bin');
  });

  tearDown(() async {
    if (await tmp.exists()) await tmp.delete(recursive: true);
  });

  DescargaReanudable nueva() =>
      DescargaReanudable(espera: (_) => const Duration(milliseconds: 10));

  test('descarga completa sin problemas', () async {
    final srv = _Servidor(_datos(500000));
    await srv.iniciar();
    addTearDown(srv.detener);

    await nueva().descargar(
        url: srv.url, destino: destino, onProgress: (_, __) {});

    expect(await destino.readAsBytes(), srv.datos);
    expect(File('${destino.path}.part').existsSync(), isFalse);
    expect(File('${destino.path}.part.meta').existsSync(), isFalse);
  });

  test('si la conexión se corta, continúa desde donde quedó (no desde 0)',
      () async {
    final srv = _Servidor(_datos(1000000), cortarTrasBytes: 400000);
    await srv.iniciar();
    addTearDown(srv.detener);

    final avances = <int>[];
    await nueva().descargar(
        url: srv.url,
        destino: destino,
        onProgress: (rec, tot) => avances.add(rec));

    expect(await destino.readAsBytes(), srv.datos);
    // Hubo una petición posterior que empezó pasado el byte 0
    final reanudos = srv.rangos
        .map((r) => int.tryParse(RegExp(r'bytes=(\d+)-').firstMatch(r)?.group(1) ?? ''))
        .where((o) => o != null && o > 0)
        .toList();
    expect(reanudos, isNotEmpty, reason: 'debió reanudar con Range > 0');
    // El progreso nunca retrocedió
    for (var i = 1; i < avances.length; i++) {
      expect(avances[i] >= avances[i - 1], isTrue,
          reason: 'progreso retrocedió en $i: ${avances[i - 1]} → ${avances[i]}');
    }
  });

  test('una descarga previa a medias (app cerrada) se retoma en otra ejecución',
      () async {
    final datos = _datos(800000);
    final srv = _Servidor(datos);
    await srv.iniciar();
    addTearDown(srv.detener);

    // Simula el estado que deja una app cerrada a la mitad
    await File('${destino.path}.part').writeAsBytes(datos.sublist(0, 300000));
    await File('${destino.path}.part.meta').writeAsString('${datos.length}');

    final d = nueva();
    expect(await d.progresoGuardado(destino), closeTo(300000 / 800000, 1e-9));

    await d.descargar(url: srv.url, destino: destino, onProgress: (_, __) {});

    expect(await destino.readAsBytes(), datos);
    // No volvió a pedir desde 0: las peticiones de datos empiezan en 300000
    expect(srv.rangos.any((r) => r == 'bytes=300000-'), isTrue);
    expect(srv.rangos.any((r) => r == 'bytes=0-'), isFalse);
  });

  test('si el servidor ignora Range, reinicia y aun así termina bien',
      () async {
    final datos = _datos(200000);
    final srv = _Servidor(datos, soportaRange: false);
    await srv.iniciar();
    addTearDown(srv.detener);

    await File('${destino.path}.part').writeAsBytes(datos.sublist(0, 50000));
    await File('${destino.path}.part.meta').writeAsString('${datos.length}');

    await nueva().descargar(
        url: srv.url, destino: destino, onProgress: (_, __) {});
    expect(await destino.readAsBytes(), datos);
  });

  test('un .part más grande que el total se descarta y se rehace', () async {
    final datos = _datos(100000);
    final srv = _Servidor(datos);
    await srv.iniciar();
    addTearDown(srv.detener);

    await File('${destino.path}.part').writeAsBytes(_datos(150000));
    await File('${destino.path}.part.meta').writeAsString('${datos.length}');

    await nueva().descargar(
        url: srv.url, destino: destino, onProgress: (_, __) {});
    expect(await destino.readAsBytes(), datos);
  });

  test('en Isolate: se corta la conexión, reanuda y el archivo queda idéntico',
      () async {
    final srv = _Servidor(_datos(3000000), cortarTrasBytes: 1200000);
    await srv.iniciar();
    addTearDown(srv.detener);

    var ultimo = 0;
    await DescargaReanudable(espera: (_) => const Duration(milliseconds: 10))
        .descargarEnSegundoPlano(
      url: srv.url,
      destino: destino,
      onProgress: (rec, tot) => ultimo = rec,
    );

    expect(await destino.readAsBytes(), srv.datos);
    expect(ultimo, srv.datos.length);
    expect(File('${destino.path}.part').existsSync(), isFalse);
  });

  test('en Isolate: un 404 se propaga como error', () async {
    final srv = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => srv.close(force: true));
    srv.listen((req) async {
      req.response.statusCode = HttpStatus.notFound;
      await req.response.close();
    });
    await expectLater(
      DescargaReanudable().descargarEnSegundoPlano(
          url: 'http://127.0.0.1:${srv.port}/x',
          destino: destino,
          onProgress: (_, __) {}),
      throwsA(anything),
    );
  });

  test('error 404 no se reintenta indefinidamente', () async {
    final srv = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => srv.close(force: true));
    var peticiones = 0;
    srv.listen((req) async {
      peticiones++;
      req.response.statusCode = HttpStatus.notFound;
      await req.response.close();
    });

    await expectLater(
      nueva().descargar(
          url: 'http://127.0.0.1:${srv.port}/x',
          destino: destino,
          onProgress: (_, __) {}),
      throwsA(anything),
    );
    expect(peticiones, 1);
  });

  test('sin descarga previa el progreso guardado es 0', () async {
    expect(await nueva().progresoGuardado(destino), 0.0);
  });
}
