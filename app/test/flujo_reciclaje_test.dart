import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:recircula/models/etiqueta_modelo.dart';
import 'package:recircula/models/material_type.dart';
import 'package:recircula/models/punto_qr.dart';
import 'package:recircula/repositories/puntos_repository_mock.dart';
import 'package:recircula/repositories/reciclaje_repository_mock.dart';
import 'package:recircula/screens/camara_foto_screen.dart';
import 'package:recircula/screens/escaner_qr_screen.dart';
import 'package:recircula/screens/flujo_reciclaje_screen.dart';
import 'package:recircula/services/camara_service.dart';
import 'package:recircula/services/clasificacion_service.dart';
import 'package:recircula/services/voz_service.dart';
import 'package:recircula/theme/app_theme.dart';
import 'package:recircula/widgets/resultado_clasificacion.dart';

/// Guarda lo que se diría en vez de hablar.
class _VozFalsa extends VozService {
  final dichas = <String>[];
  bool _hablando = false;
  var detenciones = 0;

  _VozFalsa() : super.silenciosa();

  @override
  bool get hablando => _hablando;

  @override
  Future<void> decir(String texto) async {
    dichas.add(texto);
    _hablando = true;
    notifyListeners();
  }

  @override
  Future<void> detener() async {
    detenciones++;
    _hablando = false;
    notifyListeners();
  }
}

/// Cámara que "toma" una foto sin abrir nada. Cada apertura usa el siguiente
/// valor de [fotos] (true = toma una foto, false = la cierra sin foto); sin
/// más valores, la cierra.
class _CamaraFalsa extends CamaraService {
  final List<bool> fotos;
  int aperturas = 0;
  String? ultimoTitulo;
  String? ultimoTextoSalir;

  _CamaraFalsa({List<bool>? fotos}) : fotos = fotos ?? [true];

  @override
  Future<bool> asegurarPermiso(BuildContext context) async => true;

  @override
  Future<File?> tomarFotoEnApp(
    BuildContext context, {
    required String titulo,
    required int paso,
    required int total,
    required String explicacion,
    VozService? voz,
    ValueListenable<AvisoCamara?>? aviso,
    String? textoSalir,
    ValueListenable<bool>? cerrar,
  }) async {
    aperturas++;
    ultimoTitulo = '$titulo · Paso $paso de $total';
    ultimoTextoSalir = textoSalir;
    if (fotos.isEmpty || !fotos.removeAt(0)) return null;
    return File('no_existe_foto_$aperturas.jpg');
  }
}

/// Devuelve siempre el mismo resultado (null = no hay modelo).
class _ClasificadorFalso extends ClasificacionService {
  final ResultadoClasificacion? resultado;
  _ClasificadorFalso(this.resultado) : super(cargar: () async => null);

  @override
  Future<ResultadoClasificacion?> clasificar(File foto) async => resultado;
}

ResultadoClasificacion _ia(TipoMaterial? material, {double confianza = 0.9}) =>
    ResultadoClasificacion(
      etiqueta: material == null
          ? EtiquetaModelo.noReciclable
          : EtiquetaModelo.deMaterial(material),
      confianza: confianza,
      modeloVersion: '0.1.0',
      reconocido: confianza >= 0.7,
    );

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
);

const _qr = 'rebin://punto/RB-ABC1234567?s=secreto';

Future<ReciclajeRepositoryMock> _montar(
  WidgetTester tester,
  ResultadoClasificacion? r, {
  PuntoQr? punto,
  String? qr = _qr,
  _CamaraFalsa? camara,
  bool escanearAlEntrar = false,
  VozService? voz,
  Future<Position?> Function()? ubicar,
  // La fuente de los tests es más ancha que la real: las tarjetas de puntos
  // necesitan más espacio que en el teléfono.
  double ancho = 1080,
}) async {
  SharedPreferences.setMockInitialValues({});
  tester.view.physicalSize = Size(ancho, 2340);
  tester.view.devicePixelRatio = 2.75;
  addTearDown(tester.view.reset);
  final repo = ReciclajeRepositoryMock(espera: Duration.zero, punto: punto);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: FlujoReciclajeScreen(
        reciclajes: repo,
        puntos: PuntosRepositoryMock(),
        camara: camara ?? _CamaraFalsa(),
        clasificador: _ClasificadorFalso(r),
        voz: voz ?? VozService.silenciosa(),
        leerQr: (_) async => qr,
        ubicar: ubicar ?? () async => _gps,
        escanearAlEntrar: escanearAlEntrar,
      ),
    ),
  );
  return repo;
}

/// El ListView no construye lo que está fuera de la pantalla: baja hasta
/// encontrarlo.
Future<Finder> _ver(WidgetTester tester, Finder f) async {
  await tester.scrollUntilVisible(
    f,
    200,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
  return f;
}

Future<void> _tocar(WidgetTester tester, Finder f) async {
  await tester.tap(await _ver(tester, f));
  await tester.pumpAndSettle();
}

/// Voz que no suena y anota lo que se le pide decir.
class _VozGrabadora extends VozService {
  final dichos = <String>[];
  _VozGrabadora() : super.silenciosa();

  @override
  Future<void> decir(String texto) async => dichos.add(texto);
}

void main() {
  testWidgets('Cada paso tiene su título, el paso y un Play que lo explica', (
    tester,
  ) async {
    final voz = _VozGrabadora();
    final camara = _CamaraFalsa();
    await _montar(tester, _ia(TipoMaterial.plastico), voz: voz, camara: camara);
    final play = find.byKey(const Key('reciclar-paso-audio'));

    // Paso 1
    expect(find.text('Escaneo de QR del punto'), findsOneWidget);
    expect(find.text('Paso 1 de 3'), findsOneWidget);
    await tester.tap(play);
    expect(
      voz.dichos.last,
      contains('escanea el código QR pegado en el contenedor'),
    );

    // Paso 2: la cámara del artículo, con su encabezado.
    await _tocar(tester, find.byKey(const Key('reciclar-escanear-qr')));
    expect(camara.ultimoTitulo, 'Foto del artículo · Paso 2 de 3');

    // Paso 3: con la foto pasa directo a confirmar.
    expect(find.text('Paso 3 de 3'), findsOneWidget);
    expect(find.text('Confirmar'), findsWidgets);
    await tester.tap(play);
    expect(voz.dichos.last, contains('Revisa el punto y la categoría'));
  });

  testWidgets(
    'La flecha de la cámara del QR vuelve a donde estaba la persona',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => FlujoReciclajeScreen(
                    reciclajes: ReciclajeRepositoryMock(espera: Duration.zero),
                    puntos: PuntosRepositoryMock(),
                    camara: _CamaraFalsa(),
                    clasificador: _ClasificadorFalso(null),
                    voz: VozService.silenciosa(),
                    leerQr: (_) async => EscanerQrScreen.volver,
                    escanearAlEntrar: true,
                  ),
                ),
              ),
              child: const Text('Pestaña anterior'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Pestaña anterior'));
      await tester.pumpAndSettle();

      // Salió de la cámara y del flujo completo.
      expect(find.byType(FlujoReciclajeScreen), findsNothing);
      expect(find.text('Pestaña anterior'), findsOneWidget);
    },
  );

  testWidgets('Desde el botón de escanear va del QR a la foto y a confirmar', (
    tester,
  ) async {
    await _montar(tester, _ia(TipoMaterial.plastico), escanearAlEntrar: true);
    await tester.pumpAndSettle();

    // Sin tocar nada: el QR ya se leyó y la cámara del artículo tomó la foto.
    expect(find.text('Paso 3 de 3'), findsOneWidget);
    expect(find.text('Punto de prueba (RB-ABC1234567)'), findsOneWidget);
    expect(find.byKey(const Key('reciclar-articulo')), findsOneWidget);
  });

  testWidgets(
    'Si cierra la cámara del QR, queda en el paso 1 para reintentar',
    (tester) async {
      await _montar(tester, null, qr: null, escanearAlEntrar: true);
      await tester.pumpAndSettle();

      expect(find.text('Paso 1 de 3'), findsOneWidget);
      expect(find.byKey(const Key('reciclar-escanear-qr')), findsOneWidget);
    },
  );

  testWidgets('Confirmar registra el artículo como plástico por defecto', (
    tester,
  ) async {
    final camara = _CamaraFalsa();
    final repo = await _montar(
      tester,
      _ia(TipoMaterial.vidrio),
      camara: camara,
    );
    await _tocar(tester, find.byKey(const Key('reciclar-escanear-qr')));

    // Paso 3: el punto, la categoría por defecto y la IA desactivada (aunque
    // haya un clasificador, por ahora no se usa).
    expect(find.text('Paso 3 de 3'), findsOneWidget);
    expect(find.text('Punto de prueba (RB-ABC1234567)'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const Key('reciclar-articulo')),
        matching: find.text('Plástico'),
      ),
      findsOneWidget,
    );
    expect(find.byKey(const Key('reciclar-ia-desactivada')), findsOneWidget);
    expect(find.text('Desactivado por ahora'), findsOneWidget);

    await _tocar(tester, find.byKey(const Key('reciclar-confirmar')));
    final enviado = repo.depositos.single;
    expect(enviado.material, TipoMaterial.plastico);
    // Elegida, no del modelo: la base la deja en revisión.
    expect(enviado.modeloVersion, isNull);
    expect(
      await _ver(
        tester,
        find.text('En revisión: la categoría la elegiste tú y no la IA.'),
      ),
      findsOneWidget,
    );
    expect(find.byKey(const Key('reciclar-resumen')), findsOneWidget);
    expect(find.byKey(const Key('reciclar-otro')), findsOneWidget);
    expect(find.byKey(const Key('reciclar-terminar')), findsOneWidget);
  });

  testWidgets('Sin GPS no confirma hasta poder leer la ubicación', (
    tester,
  ) async {
    // Al leer el QR y al tomar la foto no hay GPS; al reintentar, sí.
    final posiciones = <Position?>[null, null, _gps];
    final repo = await _montar(
      tester,
      _ia(TipoMaterial.plastico),
      ubicar: () async => posiciones.removeAt(0),
    );
    await _tocar(tester, find.byKey(const Key('reciclar-escanear-qr')));
    await _tocar(tester, find.byKey(const Key('reciclar-confirmar')));

    expect(find.textContaining('No pudimos leer tu ubicación'), findsOneWidget);
    expect(repo.depositos, isEmpty);
    await _ver(tester, find.byKey(const Key('reciclar-confirmar')));
    expect(
      tester
          .widget<ElevatedButton>(find.byKey(const Key('reciclar-confirmar')))
          .onPressed,
      isNull,
    );

    await _tocar(tester, find.text('Reintentar ubicación'));
    await _tocar(tester, find.byKey(const Key('reciclar-confirmar')));
    expect(repo.depositos, hasLength(1));
  });

  testWidgets('Reciclar otro artículo vuelve a la cámara y los suma', (
    tester,
  ) async {
    final camara = _CamaraFalsa(fotos: [true, true]);
    final repo = await _montar(tester, null, camara: camara);
    await _tocar(tester, find.byKey(const Key('reciclar-escanear-qr')));
    await _tocar(tester, find.byKey(const Key('reciclar-confirmar')));

    await _tocar(tester, find.byKey(const Key('reciclar-otro')));
    expect(camara.aperturas, 2);
    expect(camara.ultimoTextoSalir, 'Ver resumen');
    await _tocar(tester, find.byKey(const Key('reciclar-confirmar')));

    expect(repo.depositos, hasLength(2));
    expect(find.textContaining('2 artículos en'), findsOneWidget);
  });

  testWidgets('"Tomar otra foto" cambia la foto sin registrar nada', (
    tester,
  ) async {
    final camara = _CamaraFalsa(fotos: [true, true]);
    final repo = await _montar(tester, null, camara: camara);
    await _tocar(tester, find.byKey(const Key('reciclar-escanear-qr')));
    await _tocar(tester, find.byKey(const Key('reciclar-otra-foto')));

    expect(camara.aperturas, 2);
    expect(find.byKey(const Key('reciclar-articulo')), findsOneWidget);
    expect(repo.depositos, isEmpty);
  });

  testWidgets('Si cierra la cámara del artículo sin registrar nada, sale', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => FlujoReciclajeScreen(
                  reciclajes: ReciclajeRepositoryMock(espera: Duration.zero),
                  puntos: PuntosRepositoryMock(),
                  camara: _CamaraFalsa(fotos: [false]),
                  clasificador: _ClasificadorFalso(null),
                  voz: VozService.silenciosa(),
                  leerQr: (_) async => _qr,
                  ubicar: () async => _gps,
                  escanearAlEntrar: true,
                ),
              ),
            ),
            child: const Text('Pestaña anterior'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Pestaña anterior'));
    await tester.pumpAndSettle();

    expect(find.byType(FlujoReciclajeScreen), findsNothing);
    expect(find.text('Pestaña anterior'), findsOneWidget);
  });

  testWidgets('Un QR que no es de Rebin no avanza', (tester) async {
    await _montar(tester, _ia(TipoMaterial.plastico), qr: 'https://otro.cl');
    await _tocar(tester, find.byKey(const Key('reciclar-escanear-qr')));

    expect(find.text(FlujoReciclajeScreen.qrInvalido), findsOneWidget);
    expect(find.textContaining('QR inválido'), findsOneWidget);
    expect(find.text('Paso 1 de 3'), findsOneWidget);
  });

  testWidgets('Un punto con el QR dañado no recibe depósitos', (tester) async {
    final camara = _CamaraFalsa();
    final repo = await _montar(
      tester,
      _ia(TipoMaterial.plastico),
      camara: camara,
      punto: const PuntoQr(
        qr: CodigoQrPunto('RB-ABC1234567'),
        idPunto: 1,
        nombre: 'Punto',
        lat: 0,
        lng: 0,
        materiales: {TipoMaterial.plastico},
        estadoQr: 'dañado',
        recibeDepositos: false,
      ),
    );
    await _tocar(tester, find.byKey(const Key('reciclar-escanear-qr')));

    // La cámara del artículo se abrió mientras se buscaba el punto, pero la
    // foto se descarta y queda el aviso del paso 1.
    expect(find.textContaining('faltante o dañado'), findsOneWidget);
    expect(find.text('Paso 1 de 3'), findsOneWidget);
    expect(repo.depositos, isEmpty);
  });

  group('Resultado de la clasificación', () {
    Future<void> montar(
      WidgetTester tester,
      ResultadoClasificacion r,
      VozService voz,
    ) async {
      SharedPreferences.setMockInitialValues({});
      tester.view.physicalSize = const Size(1600, 2340);
      tester.view.devicePixelRatio = 2.75;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: ListView(
              children: [ResultadoClasificacionVista(resultado: r, voz: voz)],
            ),
          ),
        ),
      );
    }

    testWidgets('la tarjeta, su Play y "Escuchar de nuevo" dicen la '
        'descripción; el altavoz solo la corta', (tester) async {
      final voz = _VozFalsa();
      final r = _ia(TipoMaterial.latas);
      await montar(tester, r, voz);
      await voz.decir(r.frase);
      await tester.pumpAndSettle();
      final descripcion = voz.dichas.single;
      expect(descripcion, startsWith('Latas. Envases de aluminio'));

      // El Play toma el color de la categoría.
      final play = tester.widget<IconButton>(
        find.byKey(const Key('resultado-play')),
      );
      expect(play.color, TipoMaterial.latas.color);

      // Sonando: el altavoz corta el audio y queda inactivo.
      await _tocar(tester, find.byKey(const Key('resultado-voz')));
      expect(voz.detenciones, 1);
      expect(voz.hablando, isFalse);
      expect(
        tester
            .widget<IconButton>(find.byKey(const Key('resultado-voz')))
            .onPressed,
        isNull,
      );

      await _tocar(tester, find.byKey(const Key('resultado-play')));
      await _tocar(tester, find.byKey(const Key('resultado-tarjeta')));
      await _tocar(tester, find.byKey(const Key('resultado-repetir')));
      expect(voz.dichas, [for (var i = 0; i < 4; i++) descripcion]);
    });

    testWidgets('no repite la guía: sin "¿En qué se transforma?" ni "Qué no '
        'se recicla"', (tester) async {
      await montar(tester, _ia(TipoMaterial.plastico), _VozFalsa());
      expect(find.text('¡Es reciclable!'), findsOneWidget);
      expect(find.text('¿En qué se transforma?'), findsNothing);
      expect(find.text('Qué no se recicla'), findsNothing);
    });
  });

  group('Código QR', () {
    test('lee el formato del panel y el código solo', () {
      final qr = CodigoQrPunto.leer(_qr)!;
      expect(qr.codigo, 'RB-ABC1234567');
      expect(qr.secreto, 'secreto');
      expect(CodigoQrPunto.leer('RB-ABC1234567')!.secreto, isNull);
      expect(CodigoQrPunto.leer('https://rebin.cl'), isNull);
      expect(CodigoQrPunto.leer('rebin://otro/RB-1'), isNull);
      expect(CodigoQrPunto.leer('hola'), isNull);
    });

    test('lee el formato completo: id, ubicación y nombre', () {
      final qr = CodigoQrPunto.leer(
        'rebin://punto/RB-ABC1234567?s=secreto&id=42&lat=-33.437200'
        '&lng=-70.650600&n=Punto%20Plaza%20%C3%91u%C3%B1oa&otro=1',
      )!;
      expect(qr.codigo, 'RB-ABC1234567');
      expect(qr.secreto, 'secreto');
      expect(qr.idPunto, 42);
      expect(qr.lat, -33.4372);
      expect(qr.lng, -70.6506);
      expect(qr.nombre, 'Punto Plaza Ñuñoa');
    });

    test('rechaza campos mal formados', () {
      const base = 'rebin://punto/RB-ABC1234567?s=x';
      expect(CodigoQrPunto.leer('$base&id=abc'), isNull);
      expect(CodigoQrPunto.leer('$base&id=0'), isNull);
      expect(CodigoQrPunto.leer('$base&lat=-33.4'), isNull);
      expect(CodigoQrPunto.leer('$base&lat=-95&lng=-70'), isNull);
      expect(CodigoQrPunto.leer('$base&lat=a&lng=b'), isNull);
      expect(CodigoQrPunto.leer('$base&n=%E0%A4'), isNull);
    });

    test('recupera el flujo solo con un QR de Rebin', () {
      final foto = File('x.jpg');
      final repo = ReciclajeRepositoryMock();
      final puntos = PuntosRepositoryMock();
      expect(
        FlujoReciclajeScreen.desdePendiente(
          FlujoReciclajeScreen.pendientePara(_qr),
          foto,
          reciclajes: repo,
          puntos: puntos,
        ),
        isNotNull,
      );
      expect(
        FlujoReciclajeScreen.desdePendiente(
          {'flujo': 'reporte'},
          foto,
          reciclajes: repo,
          puntos: puntos,
        ),
        isNull,
      );
    });
  });
}
