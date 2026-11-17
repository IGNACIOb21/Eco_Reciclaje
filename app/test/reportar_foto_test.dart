import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:recircula/models/tipo_reporte.dart';
import 'package:recircula/repositories/acciones_repository.dart';
import 'package:recircula/repositories/acciones_repository_supabase.dart';
import 'package:recircula/services/camara_service.dart';

/// Repositorio con Storage y RPC falsos: anota cada subida y cada llamada, y
/// la RPC responde con [errorRpc] mientras no sea null.
class _Banco {
  final subidas = <String>[];
  final llamadas = <Map<String, dynamic>>[];
  Object? errorSubida;
  PostgrestException? errorRpc;

  late final repo = AccionesRepositorySupabase(
    uid: () => 'u1',
    subir: (ruta, foto) async {
      if (errorSubida != null) throw errorSubida!;
      subidas.add(ruta);
    },
    rpc: (funcion, params) async {
      llamadas.add(params);
      if (errorRpc != null) throw errorRpc!;
      return {'puntos': 3};
    },
  );

  Future<ResultadoAccion> reportar(File? foto) => repo.reportarEstado(
    idPunto: '12',
    tipo: TipoReporte.llenoSaturado,
    foto: foto,
  );
}

PostgrestException _rechazo(String mensaje, {String code = 'P0001'}) =>
    PostgrestException(message: mensaje, code: code);

void main() {
  group('Reportar con foto', () {
    test('sube la foto y manda su ruta a la RPC', () async {
      final b = _Banco();
      final r = await b.reportar(File('rebin_1.jpg'));

      expect(r.puntos, 3);
      expect(b.subidas, hasLength(1));
      expect(b.subidas.single, startsWith('u1/'));
      expect(b.llamadas.single['p_foto_ruta'], b.subidas.single);
    });

    test(
      'si la RPC rechaza, reintentar con la misma foto no la sube de nuevo',
      () async {
        final b = _Banco()..errorRpc = _rechazo('limite_diario_reportes');
        final foto = File('rebin_1.jpg');

        for (var i = 0; i < 3; i++) {
          await expectLater(
            b.reportar(foto),
            throwsA(
              isA<AccionException>().having(
                (e) => e.motivo,
                'motivo',
                MotivoErrorAccion.limiteDiarioReportes,
              ),
            ),
          );
        }
        b.errorRpc = null;
        await b.reportar(foto);

        expect(b.subidas, hasLength(1), reason: 'una sola foto en Storage');
        expect(b.llamadas.map((p) => p['p_foto_ruta']).toSet(), {
          b.subidas.single,
        });
      },
    );

    test('una foto nueva sí se sube', () async {
      final b = _Banco()..errorRpc = _rechazo('reporte_repetido');
      await expectLater(
        b.reportar(File('rebin_1.jpg')),
        throwsA(isA<AccionException>()),
      );
      await expectLater(
        b.reportar(File('rebin_2.jpg')),
        throwsA(isA<AccionException>()),
      );

      expect(b.subidas, hasLength(2));
    });

    test(
      'si la base dice foto_invalida, el siguiente intento sube otra',
      () async {
        final b = _Banco()..errorRpc = _rechazo('foto_invalida');
        final foto = File('rebin_1.jpg');
        await expectLater(b.reportar(foto), throwsA(isA<AccionException>()));
        b.errorRpc = null;
        await b.reportar(foto);

        expect(b.subidas, hasLength(2));
      },
    );

    test('tras un envío aceptado no se reusa la ruta', () async {
      final b = _Banco();
      final foto = File('rebin_1.jpg');
      await b.reportar(foto);
      await b.reportar(foto);

      expect(b.subidas, hasLength(2));
    });

    test('si la foto no se puede subir, no se envía el reporte', () async {
      final b = _Banco()..errorSubida = const StorageException('denegado');

      await expectLater(
        b.reportar(File('rebin_1.jpg')),
        throwsA(
          isA<AccionException>()
              .having((e) => e.motivo, 'motivo', MotivoErrorAccion.fotoNoSubida)
              .having((e) => e.mensaje, 'mensaje', contains('subir la foto')),
        ),
      );
      expect(b.llamadas, isEmpty);
    });

    test('sin conexión al subir avisa sin conexión', () async {
      final b = _Banco()..errorSubida = const SocketException('sin red');

      await expectLater(
        b.reportar(File('rebin_1.jpg')),
        throwsA(
          isA<AccionException>().having(
            (e) => e.motivo,
            'motivo',
            MotivoErrorAccion.sinConexion,
          ),
        ),
      );
      expect(b.llamadas, isEmpty);
    });

    test('sin foto no se llama a nada', () async {
      final b = _Banco();

      await expectLater(
        b.reportar(null),
        throwsA(
          isA<AccionException>().having(
            (e) => e.motivo,
            'motivo',
            MotivoErrorAccion.fotoObligatoria,
          ),
        ),
      );
      expect(b.subidas, isEmpty);
      expect(b.llamadas, isEmpty);
    });

    test(
      'la ubicación propuesta va en p_lat, p_lng, precisión y simulada',
      () async {
        final b = _Banco();
        await b.repo.reportarEstado(
          idPunto: '12',
          tipo: TipoReporte.ubicacionIncorrecta,
          comentario: 'está en la esquina, frente al supermercado',
          foto: File('rebin_1.jpg'),
          ubicacion: Position(
            latitude: -33.399,
            longitude: -70.5,
            timestamp: DateTime(2026, 10, 15),
            accuracy: 8,
            altitude: 0,
            altitudeAccuracy: 0,
            heading: 0,
            headingAccuracy: 0,
            speed: 0,
            speedAccuracy: 0,
          ),
        );
        final p = b.llamadas.single;
        expect(p['p_lat'], -33.399);
        expect(p['p_lng'], -70.5);
        expect(p['p_precision_gps'], 8);
        expect(p['p_ubicacion_simulada'], isFalse);

        await b.reportar(File('rebin_2.jpg'));
        expect(b.llamadas.last.containsKey('p_lat'), isFalse);
      },
    );

    test('ubicacion_lejana tiene su mensaje', () async {
      final b = _Banco()..errorRpc = _rechazo('ubicacion_lejana');
      await expectLater(
        b.reportar(File('rebin_1.jpg')),
        throwsA(
          isA<AccionException>()
              .having(
                (e) => e.motivo,
                'motivo',
                MotivoErrorAccion.ubicacionLejana,
              )
              .having((e) => e.mensaje, 'mensaje', contains('500 m')),
        ),
      );
    });

    test('foto_obligatoria y el duplicado 23505 tienen su mensaje', () async {
      final b = _Banco()..errorRpc = _rechazo('foto_obligatoria');
      await expectLater(
        b.reportar(File('rebin_1.jpg')),
        throwsA(
          isA<AccionException>().having(
            (e) => e.motivo,
            'motivo',
            MotivoErrorAccion.fotoObligatoria,
          ),
        ),
      );

      b.errorRpc = _rechazo('duplicate key value', code: '23505');
      await expectLater(
        b.reportar(File('rebin_2.jpg')),
        throwsA(
          isA<AccionException>().having(
            (e) => e.motivo,
            'motivo',
            MotivoErrorAccion.fotoInvalida,
          ),
        ),
      );
    });
  });

  group('esRestoDeCamara', () {
    test('reconoce los archivos de la cámara', () {
      expect(esRestoDeCamara('rebin_1760462400000000.jpg'), isTrue);
      expect(
        esRestoDeCamara('3f2a9c1e-5b7d-4e2a-9f1c-0a1b2c3d4e5f8123456789.jpg'),
        isTrue,
      );
      expect(esRestoDeCamara('scaled_foto.jpg'), isTrue);
    });

    test('no toca otros archivos de la caché', () {
      expect(esRestoDeCamara('portada.jpg'), isFalse);
      expect(esRestoDeCamara('mapa_estilo.png'), isFalse);
      expect(esRestoDeCamara('rebin_datos.json'), isFalse);
      expect(
        esRestoDeCamara('3f2a9c1e-5b7d-4e2a-9f1c-0a1b2c3d4e5f.db'),
        isFalse,
      );
    });
  });
}
