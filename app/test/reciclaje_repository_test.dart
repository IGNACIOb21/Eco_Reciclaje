import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:recircula/models/etiqueta_modelo.dart';
import 'package:recircula/models/material_type.dart';
import 'package:recircula/models/punto_qr.dart';
import 'package:recircula/repositories/reciclaje_repository.dart';
import 'package:recircula/repositories/reciclaje_repository_supabase.dart';
import 'package:recircula/services/clasificacion_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final _gps = Position(
  latitude: -33.4372,
  longitude: -70.6506,
  timestamp: DateTime(2026, 10, 17),
  accuracy: 6,
  altitude: 0,
  altitudeAccuracy: 0,
  heading: 0,
  headingAccuracy: 0,
  speed: 0,
  speedAccuracy: 0,
  isMocked: false,
);

const _punto = PuntoQr(
  qr: CodigoQrPunto('RB-ABC1234567', secreto: 'secreto'),
  idPunto: 7,
  nombre: 'Punto',
  lat: -33.4372,
  lng: -70.6506,
  materiales: {TipoMaterial.plastico},
);

final _ia = ResultadoClasificacion(
  etiqueta: EtiquetaModelo.deMaterial(TipoMaterial.plastico),
  confianza: 0.91,
  modeloVersion: '1.0.0',
);

void main() {
  late Directory dir;
  late File foto;
  late List<String> subidas;
  late List<(String, Map<String, dynamic>)> llamadas;
  late Object? Function(String funcion) responder;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('rebin_reciclaje');
    foto = File('${dir.path}/foto.jpg')..writeAsBytesSync([1, 2, 3]);
    subidas = [];
    llamadas = [];
    responder = (_) => {
      'estado_validacion': 'aprobado',
      'puntos_otorgados': 20,
      'punto_nombre': 'Punto',
    };
  });
  tearDown(() => dir.delete(recursive: true));

  ReciclajeRepositorySupabase repo() => ReciclajeRepositorySupabase(
    uid: () => 'u1',
    subir: (ruta, _) async => subidas.add(ruta),
    rpc: (funcion, params) async {
      llamadas.add((funcion, params));
      final r = responder(funcion);
      if (r is Exception) throw r;
      return r;
    },
    calcularHash: (Uint8List _) async => '0123456789abcdef',
  );

  Future<RegistroDeposito> depositar(ReciclajeRepositorySupabase r) =>
      r.registrarDeposito(
        foto: foto,
        punto: _punto,
        gps: _gps,
        horaCaptura: DateTime.utc(2026, 10, 17, 12),
        resultado: _ia,
      );

  test('envía el QR con su secreto, la IA, el hash y el GPS', () async {
    final registro = await depositar(repo());

    expect(registro.aprobado, isTrue);
    expect(registro.puntos, 20);
    expect(subidas.single, startsWith('u1/depositos/'));
    final (funcion, p) = llamadas.single;
    expect(funcion, 'app_registrar_deposito');
    expect(p['p_codigo_qr'], 'RB-ABC1234567');
    expect(p['p_qr_secreto'], 'secreto');
    expect(p['p_codigo_categoria'], 'plastico');
    expect(p['p_confianza_ia'], 0.91);
    expect(p['p_modelo_version'], '1.0.0');
    expect(p['p_hash_perceptual'], '0123456789abcdef');
    expect(p['p_foto_ruta'], subidas.single);
    expect(p['p_precision_gps'], 6);
    expect(p['p_ubicacion_simulada'], isFalse);
    expect(p['p_hora_captura'], '2026-10-17T12:00:00.000Z');
  });

  test('sin modelo manda modelo_version null y confianza 0', () async {
    await repo().registrarDeposito(
      foto: foto,
      punto: _punto,
      gps: _gps,
      horaCaptura: DateTime.now(),
      resultado: ResultadoClasificacion.elegida(
        EtiquetaModelo.deMaterial(TipoMaterial.plastico),
      ),
    );
    final p = llamadas.single.$2;
    expect(p['p_modelo_version'], isNull);
    expect(p['p_confianza_ia'], 0);
  });

  test('al reintentar con la misma foto reutiliza la ya subida', () async {
    final r = repo();
    responder = (_) => const SocketException('sin red');
    await expectLater(depositar(r), throwsA(isA<ReciclajeException>()));
    responder = (_) => {'estado_validacion': 'dudoso', 'motivo': 'sin_ia'};
    final registro = await depositar(r);

    expect(subidas, hasLength(1));
    expect(llamadas[0].$2['p_foto_ruta'], llamadas[1].$2['p_foto_ruta']);
    expect(registro.enRevision, isTrue);
  });

  test('si la base rechaza la ruta, el reintento sube otra foto', () async {
    final r = repo();
    responder = (_) =>
        const PostgrestException(message: 'foto_invalida', code: 'P0001');
    await expectLater(depositar(r), throwsA(isA<ReciclajeException>()));
    responder = (_) => {'estado_validacion': 'aprobado'};
    await depositar(r);

    expect(subidas, hasLength(2));
  });

  test('un QR desconocido se marca como QR inválido', () async {
    responder = (_) =>
        const PostgrestException(message: 'qr_invalido', code: 'P0001');
    await expectLater(
      repo().puntoPorQr(const CodigoQrPunto('RB-X')),
      throwsA(
        isA<ReciclajeException>().having((e) => e.qrInvalido, 'qr', isTrue),
      ),
    );
  });

  test('sin el SQL aplicado lo dice', () async {
    responder = (_) => const PostgrestException(
      message: 'Could not find the function',
      code: 'PGRST202',
    );
    await expectLater(
      depositar(repo()),
      throwsA(
        isA<ReciclajeException>().having(
          (e) => e.mensaje,
          'mensaje',
          contains('todavía no está habilitado'),
        ),
      ),
    );
  });

  test('lee el punto del QR', () async {
    responder = (_) => {
      'id_punto': 7,
      'nombre': 'Punto',
      'direccion': null,
      'lat': -33.4,
      'lng': -70.6,
      'estado_operativo': 'operativo',
      'estado_qr': 'faltante',
      'recibe_depositos': false,
      'categorias': ['plastico', 'vidrio', 'desconocida'],
    };
    final punto = await repo().puntoPorQr(
      const CodigoQrPunto('RB-ABC1234567', secreto: 's'),
    );

    expect(llamadas.single.$2, {
      'p_codigo_qr': 'RB-ABC1234567',
      'p_qr_secreto': 's',
    });
    expect(punto.materiales, {TipoMaterial.plastico, TipoMaterial.vidrio});
    expect(punto.recibeDepositos, isFalse);
    expect(punto.motivoNoRecibe, contains('faltante o dañado'));
  });

  test('un QR con el id de otro punto no vale', () async {
    responder = (_) => {
      'id_punto': 7,
      'nombre': 'Punto',
      'direccion': null,
      'lat': -33.4,
      'lng': -70.6,
      'estado_operativo': 'operativo',
      'estado_qr': 'activo',
      'recibe_depositos': true,
      'categorias': ['plastico'],
    };
    await expectLater(
      repo().puntoPorQr(const CodigoQrPunto('RB-X', secreto: 's', idPunto: 8)),
      throwsA(
        isA<ReciclajeException>().having((e) => e.qrInvalido, 'qr', isTrue),
      ),
    );
    final punto = await repo().puntoPorQr(
      const CodigoQrPunto('RB-X', secreto: 's', idPunto: 7),
    );
    expect(punto.idPunto, 7);
  });

  test('el escaneo manda la versión del modelo', () async {
    responder = (_) => {'id_escaneo': 1, 'puntos_otorgados': 5};
    final r = await repo().registrarEscaneo(foto: foto, resultado: _ia);

    expect(r.puntos, 5);
    expect(subidas.single, startsWith('u1/escaneos/'));
    expect(llamadas.single.$2['p_modelo_version'], '1.0.0');
  });
}
