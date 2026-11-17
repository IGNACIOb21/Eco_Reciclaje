import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:recircula/models/etiqueta_modelo.dart';
import 'package:recircula/models/material_type.dart';
import 'package:recircula/services/clasificacion_service.dart';
import 'package:recircula/services/descripciones_categorias.dart';
import 'package:recircula/services/modelo_residuos.dart';

/// Motor que devuelve siempre la misma salida float32 y guarda la entrada.
class _MotorFalso implements MotorInferencia {
  final List<double> salidaFija;
  Uint8List? ultimaEntrada;

  _MotorFalso(this.salidaFija);

  static const lado = 4;

  @override
  DescripcionTensor get entrada =>
      DescripcionTensor(forma: [1, lado, lado, 3], tipo: TipoTensor.float32);

  @override
  DescripcionTensor get salida => DescripcionTensor(
    forma: [1, salidaFija.length],
    tipo: TipoTensor.float32,
  );

  @override
  Future<Uint8List> ejecutar(Uint8List datos) async {
    ultimaEntrada = datos;
    return Float32List.fromList(salidaFija).buffer.asUint8List();
  }

  @override
  Future<void> cerrar() async {}
}

/// Assets en memoria; los que faltan fallan como en la app.
class _Bundle extends CachingAssetBundle {
  final Map<String, Uint8List> archivos;
  _Bundle(this.archivos);

  @override
  Future<ByteData> load(String key) async {
    final datos = archivos[key];
    if (datos == null) throw FlutterError('Unable to load asset: "$key".');
    return ByteData.sublistView(datos);
  }
}

Uint8List _texto(String s) => Uint8List.fromList(utf8.encode(s));

/// PNG de 8×4: mitad izquierda roja, mitad derecha azul.
Future<Uint8List> _png() async {
  final grabadora = ui.PictureRecorder();
  final lienzo = ui.Canvas(grabadora);
  lienzo.drawRect(
    const ui.Rect.fromLTWH(0, 0, 4, 4),
    ui.Paint()..color = const ui.Color(0xFFFF0000),
  );
  lienzo.drawRect(
    const ui.Rect.fromLTWH(4, 0, 4, 4),
    ui.Paint()..color = const ui.Color(0xFF0000FF),
  );
  final imagen = await grabadora.endRecording().toImage(8, 4);
  final datos = await imagen.toByteData(format: ui.ImageByteFormat.png);
  return datos!.buffer.asUint8List();
}

void main() {
  group('Etiquetas del modelo', () {
    test('acepta el código de la base y variantes comunes', () {
      expect(EtiquetaModelo.de('plastico')!.material, TipoMaterial.plastico);
      expect(EtiquetaModelo.de('Papel y cartón')!.material, TipoMaterial.papel);
      expect(EtiquetaModelo.de('tetrapak')!.material, TipoMaterial.tetraPak);
      expect(EtiquetaModelo.de('Tetra Pak')!.material, TipoMaterial.tetraPak);
      expect(EtiquetaModelo.de('No reciclable')!.reciclable, isFalse);
      expect(EtiquetaModelo.de('gato'), isNull);
    });

    test('las 7 categorías por foto más "No reciclable", sin aceite', () {
      expect(EtiquetaModelo.todas, hasLength(8));
      expect(
        EtiquetaModelo.todas.map((e) => e.material),
        isNot(contains(TipoMaterial.aceite)),
      );
    });
  });

  group('Preparar la entrada', () {
    test('recorta el centro y deja RGB', () {
      // 4×2 RGBA: columnas con valor 0, 10, 20, 30.
      final rgba = Uint8List.fromList([
        for (var y = 0; y < 2; y++)
          for (var x = 0; x < 4; x++) ...[x * 10, x * 10, x * 10, 255],
      ]);
      final rgb = recortarCentroRgb(
        rgba,
        ancho: 4,
        alto: 2,
        anchoRecorte: 2,
        altoRecorte: 2,
      );
      expect(rgb, [10, 10, 10, 20, 20, 20, 10, 10, 10, 20, 20, 20]);
    });

    test('float32 en el rango pedido, uint8 tal cual e int8 cuantizado', () {
      final rgb = Uint8List.fromList([0, 255, 51]);
      const forma = [1, 1, 1, 3];
      final f = tensorDeEntrada(
        rgb,
        const DescripcionTensor(forma: forma, tipo: TipoTensor.float32),
        minimo: -1,
        maximo: 1,
      ).buffer.asFloat32List();
      expect(f[0], closeTo(-1, 1e-6));
      expect(f[1], closeTo(1, 1e-6));
      expect(f[2], closeTo(-0.6, 1e-6));

      expect(
        tensorDeEntrada(
          rgb,
          const DescripcionTensor(forma: forma, tipo: TipoTensor.uint8),
        ),
        [0, 255, 51],
      );

      final q = tensorDeEntrada(
        rgb,
        const DescripcionTensor(
          forma: forma,
          tipo: TipoTensor.int8,
          escala: 1,
          puntoCero: -128,
        ),
      ).buffer.asInt8List();
      expect(q, [-128, 127, -77]);
    });
  });

  group('Leer la salida', () {
    test('descuantiza uint8', () {
      final v = valoresDeSalida(
        Uint8List.fromList([0, 128, 255]),
        const DescripcionTensor(
          forma: [1, 3],
          tipo: TipoTensor.uint8,
          escala: 1 / 255,
        ),
      );
      expect(v[0], 0);
      expect(v[2], closeTo(1, 1e-6));
    });

    test('normaliza probabilidades y aplica softmax a logits', () {
      expect(aProbabilidades([1, 3]), [0.25, 0.75]);
      final p = aProbabilidades([0, 0], sonLogits: true);
      expect(p, [0.5, 0.5]);
      final caliente = aProbabilidades([0.9, 0.1], temperatura: 2);
      expect(caliente[0], lessThan(0.9));
      expect(caliente[0] + caliente[1], closeTo(1, 1e-9));
    });

    test('lee modelo.json con valores por defecto', () {
      final c = ConfigModelo.fromJson({
        'version': '1.2.0',
        'rango_entrada': [-1, 1],
        'salida': 'logits',
        'umbral_confianza': 0.6,
      });
      expect(c.version, '1.2.0');
      expect(c.rangoEntrada, (-1.0, 1.0));
      expect(c.salidaEnLogits, isTrue);
      expect(c.umbralConfianza, 0.6);
      expect(const ConfigModelo().umbralConfianza, 0.7);
    });
  });

  group('Cargar el modelo', () {
    test('sin model.tflite la app sigue sin IA', () async {
      expect(await ModeloResiduos.cargar(bundle: _Bundle({})), isNull);
      final servicio = ClasificacionService(
        cargar: () => ModeloResiduos.cargar(bundle: _Bundle({})),
      );
      expect(await servicio.disponible, isFalse);
      expect(await servicio.clasificar(File('x.jpg')), isNull);
    });

    test('labels.txt con otra cantidad de clases deja la app sin IA', () async {
      final modelo = await ModeloResiduos.cargar(
        bundle: _Bundle({
          ModeloResiduos.rutaModelo: Uint8List(4),
          ModeloResiduos.rutaEtiquetas: _texto('plastico\nvidrio\n'),
        }),
        crearMotor: (_) async => _MotorFalso([0.2, 0.3, 0.5]),
      );
      expect(modelo, isNull);
    });

    test('carga labels.txt y modelo.json', () async {
      final modelo = await ModeloResiduos.cargar(
        bundle: _Bundle({
          ModeloResiduos.rutaModelo: Uint8List(4),
          ModeloResiduos.rutaEtiquetas: _texto('plastico\nvidrio\npapel\n'),
          ModeloResiduos.rutaConfig: _texto('{"version": "0.1.0"}'),
        }),
        crearMotor: (_) async => _MotorFalso([0.2, 0.3, 0.5]),
      );
      expect(modelo!.etiquetas, ['plastico', 'vidrio', 'papel']);
      expect(modelo.config.version, '0.1.0');
    });
  });

  testWidgets('Clasifica una foto: categoría, confianza y umbral', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final dir = await Directory.systemTemp.createTemp('rebin_ia');
      addTearDown(() => dir.delete(recursive: true));
      final foto = File('${dir.path}/foto.png')..writeAsBytesSync(await _png());
      final motor = _MotorFalso([0.1, 0.8, 0.1]);

      ClasificacionService servicio(double umbral) => ClasificacionService(
        cargar: () async => ModeloResiduos(
          config: ConfigModelo(version: '0.1.0', umbralConfianza: umbral),
          etiquetas: const ['plastico', 'vidrio', 'papel'],
          motor: motor,
        ),
      );

      final r = (await servicio(0.7).clasificar(foto))!;
      expect(r.material, TipoMaterial.vidrio);
      expect(r.confianza, closeTo(0.8, 1e-6));
      expect(r.reconocido, isTrue);
      expect(r.modeloVersion, '0.1.0');
      expect(r.elegidoPorPersona, isFalse);
      expect(r.alternativas.first.etiqueta, 'vidrio');
      // 4×4 píxeles × 3 canales × 4 bytes (float32).
      expect(motor.ultimaEntrada!.length, 4 * 4 * 3 * 4);
      // El centro de la foto: columnas rojas a la izquierda, azules a la
      // derecha (canal R del primer píxel ~255, del último ~0).
      final f = motor.ultimaEntrada!.buffer.asFloat32List();
      expect(f[0], greaterThan(200));
      expect(f[f.length - 3], lessThan(55));

      final dudoso = (await servicio(0.9).clasificar(foto))!;
      expect(dudoso.reconocido, isFalse);
    });
  });

  test('una categoría elegida a mano va sin modelo y con confianza 0', () {
    final r = ResultadoClasificacion.elegida(
      EtiquetaModelo.deMaterial(TipoMaterial.latas),
    );
    expect(r.elegidoPorPersona, isTrue);
    expect(r.confianza, 0);
    expect(r.codigoCategoria, 'latas');
    expect(r.frase, startsWith('Latas. Envases de aluminio'));
    expect(r.frase, contains('contenedor de Latas'));
  });

  test('la voz dice que no se recicla y adónde va', () {
    final r = ResultadoClasificacion.elegida(EtiquetaModelo.noReciclable);
    expect(r.frase, startsWith('Este objeto no es reciclable. Va a la basura'));
  });

  test('los nombres de las categorías son los mismos en toda la app', () {
    expect(TipoMaterial.values.map((m) => m.etiqueta), [
      'Vidrio',
      'Papel y cartón',
      'Plástico',
      'Metal',
      'Pilas',
      'Latas',
      'Tetra Pak',
      'Aceite usado',
    ]);
    for (final e in EtiquetaModelo.todas) {
      if (e.material != null) expect(e.nombre, e.material!.etiqueta);
    }
    for (final m in TipoMaterial.values) {
      expect(m.descripcion, contains(m.etiqueta));
      expect(m.productosResultantes, isNotEmpty);
      expect(m.partesNoReciclables, isNotEmpty);
    }
  });

  test('latas y vidrio dicen que se reciclan por completo', () {
    expect(
      TipoMaterial.latas.partesNoReciclables,
      startsWith(seReciclaCompleto),
    );
    expect(
      TipoMaterial.vidrio.partesNoReciclables,
      startsWith(seReciclaCompleto),
    );
    expect(
      seReciclaCompleto,
      'Este material se recicla por completo, siempre '
      'que esté limpio, seco y libre de contenido.',
    );
    expect(
      TipoMaterial.papel.partesNoReciclables,
      isNot(contains(seReciclaCompleto)),
    );
  });

  group('Descripciones de la base', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('usa la de la base y guarda una copia', () async {
      final d = DescripcionesCategorias(
        leer: () async => [
          {
            'codigo': 'latas',
            'nombre': 'Latas',
            'descripcion': 'Texto nuevo.',
            'destino_reutilizacion': 'Productos nuevos.',
            'partes_no_reciclables': null,
          },
          {'codigo': 'desconocido', 'descripcion': 'x'},
          {'codigo': 'vidrio', 'descripcion': '  '},
        ],
      );
      await d.cargar();
      expect(d.descripcion(TipoMaterial.latas), 'Texto nuevo.');
      expect(d.productos(TipoMaterial.latas), 'Productos nuevos.');
      // Sin texto en la base, el de la app.
      expect(
        d.partesNoReciclables(TipoMaterial.latas),
        TipoMaterial.latas.partesNoReciclables,
      );
      expect(
        d.descripcion(TipoMaterial.vidrio),
        TipoMaterial.vidrio.descripcion,
      );

      // Sin conexión, la próxima vez usa la copia del teléfono.
      final sinRed = DescripcionesCategorias(
        leer: () async => throw Exception('sin red'),
      );
      await sinRed.cargar();
      expect(sinRed.descripcion(TipoMaterial.latas), 'Texto nuevo.');
    });

    test('sin base usa el texto de la app', () async {
      final d = DescripcionesCategorias(leer: () async => null);
      await d.cargar();
      expect(d.descripcion(TipoMaterial.pilas), TipoMaterial.pilas.descripcion);
    });
  });
}
