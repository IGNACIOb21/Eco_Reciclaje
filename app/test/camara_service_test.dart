import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:recircula/models/estado_punto.dart';
import 'package:recircula/models/material_type.dart';
import 'package:recircula/models/punto_reciclaje.dart';
import 'package:recircula/models/tipo_reporte.dart';
import 'package:recircula/repositories/acciones_repository.dart';
import 'package:recircula/screens/realizar_reporte_screen.dart';
import 'package:recircula/services/camara_service.dart';
import 'package:recircula/services/permisos_service.dart';
import 'package:recircula/theme/app_theme.dart';
import 'package:recircula/widgets/permisos_ajustes.dart';

/// Cámara que "toma" siempre el archivo [ruta]. Anota qué reporte pendiente
/// había guardado mientras estaba abierta.
class _PickerFalso extends ImagePicker {
  final String ruta;
  String? pendienteDuranteLaCamara;
  _PickerFalso(this.ruta);

  @override
  Future<XFile?> pickImage({
    required ImageSource source,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
    bool requestFullMetadata = true,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    pendienteDuranteLaCamara = prefs.getString(CamaraService.clavePendiente);
    return XFile(ruta);
  }
}

/// Copia la original a otro archivo, o lanza [error].
class _ProcesadorFalso extends ProcesadorFoto {
  final Object? error;
  const _ProcesadorFalso({this.error});

  @override
  Future<File> procesar(File original) async {
    if (error != null) throw error!;
    return original.copy(
      '${original.parent.path}${Platform.pathSeparator}procesada.jpg',
    );
  }
}

class _SinRepositorio extends Fake implements AccionesRepository {}

/// Bytes con la firma de un JPEG y [largo] bytes en total.
List<int> _jpeg(int largo) => [
  0xFF,
  0xD8,
  0xFF,
  0xE0,
  ...List.filled(largo > 4 ? largo - 4 : 0, 0),
];

/// Compresor y lector de medidas falsos, para probar ProcesadorFoto sin el
/// código nativo.
class _Laboratorio {
  final medidas = <String, (int, int)>{};
  final llamadas = <({int lado, int calidad, int muestreo})>[];

  /// Medidas de cada resultado, en orden (por defecto 1024 × 768).
  List<(int, int)> salidas = [];

  /// Peso de cada resultado, en orden (por defecto 150 KB).
  List<int> pesos = [];
  bool pegado = false;
  bool noJpeg = false;

  ProcesadorFoto get procesador => ProcesadorFoto(
    comprimir: _comprimir,
    medidas: _leer,
    tiempoMaximo: const Duration(milliseconds: 50),
  );

  Future<(int, int)> _leer(File foto) async {
    final m = medidas[foto.path];
    if (m == null) throw StateError('sin medidas');
    return m;
  }

  Future<String?> _comprimir({
    required String origen,
    required String destino,
    required int lado,
    required int calidad,
    required int muestreo,
  }) async {
    final i = llamadas.length;
    llamadas.add((lado: lado, calidad: calidad, muestreo: muestreo));
    if (pegado) return Completer<String?>().future;
    final peso = i < pesos.length ? pesos[i] : 150 * 1024;
    File(destino).writeAsBytesSync(noJpeg ? List.filled(peso, 1) : _jpeg(peso));
    medidas[destino] = i < salidas.length ? salidas[i] : (1024, 768);
    return destino;
  }
}

void main() {
  permisosMain();

  group('calcularCompresion', () {
    test('una foto acostada queda con el lado largo en 1024', () {
      final m = calcularCompresion(4000, 3000);
      expect((m.ancho, m.alto), (1024, 768));
      expect(m.lado, 768);
      // Se decodifica a la mitad (2000 × 1500): el lado corto aún alcanza.
      expect(m.muestreo, 2);
    });

    test('una foto de pie queda con el lado largo en 1024', () {
      final m = calcularCompresion(3000, 4000);
      expect((m.ancho, m.alto), (768, 1024));
      expect(m.lado, 768);
    });

    test('una foto más chica no se agranda', () {
      final m = calcularCompresion(800, 600);
      expect((m.ancho, m.alto), (800, 600));
      expect(m.lado, 600);
      expect(m.muestreo, 1);
      expect(calcularCompresion(1024, 1024).ancho, 1024);
    });

    test('el muestreo nunca deja el lado corto bajo lo pedido', () {
      for (final (w, h) in [(4080, 3060), (8000, 6000), (1600, 1200)]) {
        final m = calcularCompresion(w, h);
        final corto = w < h ? w : h;
        expect(corto ~/ m.muestreo, greaterThanOrEqualTo(m.lado));
      }
    });
  });

  group('detectarFormato', () {
    test('reconoce JPEG, PNG y HEIC por sus primeros bytes', () {
      expect(detectarFormato([0xFF, 0xD8, 0xFF, 0xE0]), FormatoFoto.jpeg);
      expect(
        detectarFormato([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A]),
        FormatoFoto.png,
      );
      expect(
        detectarFormato([0, 0, 0, 0x18, ...ascii.encode('ftypheic')]),
        FormatoFoto.heic,
      );
    });

    test('rechaza lo que no es una foto aunque se llame .jpg', () {
      expect(detectarFormato(ascii.encode('hola mundo, no soy')), isNull);
      expect(
        detectarFormato([0, 0, 0, 0x18, ...ascii.encode('ftypmp42')]),
        isNull,
      );
      expect(detectarFormato([0xFF, 0xD8]), isNull);
      expect(detectarFormato(const []), isNull);
    });
  });

  group('tomarFoto', () {
    late Directory dir;
    late File original;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      dir = await Directory.systemTemp.createTemp('camara_test');
      original = File('${dir.path}/original.jpg')..writeAsBytesSync([1, 2]);
    });
    tearDown(() => dir.delete(recursive: true));

    test('devuelve la foto procesada y borra la original', () async {
      final camara = CamaraService(
        picker: _PickerFalso(original.path),
        procesador: const _ProcesadorFalso(),
      );
      final foto = await camara.tomarFoto();

      expect(foto, isNotNull);
      expect(foto!.path, isNot(original.path));
      expect(foto.existsSync(), isTrue);
      expect(original.existsSync(), isFalse);
    });

    test('si no se puede procesar avisa y también borra la original', () async {
      final camara = CamaraService(
        picker: _PickerFalso(original.path),
        procesador: _ProcesadorFalso(error: StateError('formato raro')),
      );

      await expectLater(
        camara.tomarFoto(),
        throwsA(
          isA<FotoNoProcesadaException>().having(
            (e) => e.motivo,
            'motivo',
            MotivoFotoFallida.general,
          ),
        ),
      );
      expect(original.existsSync(), isFalse);
    });

    test('sin espacio en el teléfono avisa con su propio mensaje', () async {
      final camara = CamaraService(
        picker: _PickerFalso(original.path),
        procesador: const _ProcesadorFalso(
          error: FileSystemException(
            'no se pudo escribir',
            'x',
            OSError('No space left on device', 28),
          ),
        ),
      );

      await expectLater(
        camara.tomarFoto(),
        throwsA(
          isA<FotoNoProcesadaException>()
              .having((e) => e.motivo, 'motivo', MotivoFotoFallida.sinEspacio)
              .having((e) => e.mensaje, 'mensaje', contains('espacio')),
        ),
      );
      expect(original.existsSync(), isFalse);
    });

    test(
      'guarda el reporte pendiente solo mientras la cámara está abierta',
      () async {
        final picker = _PickerFalso(original.path);
        final camara = CamaraService(
          picker: picker,
          procesador: const _ProcesadorFalso(),
        );
        await camara.tomarFoto(pendiente: {'flujo': 'reporte', 'tipo': 'otro'});

        expect(jsonDecode(picker.pendienteDuranteLaCamara!), {
          'flujo': 'reporte',
          'tipo': 'otro',
        });
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString(CamaraService.clavePendiente), isNull);
      },
    );
  });

  test('el reporte pendiente vuelve a armar la pantalla con la foto', () {
    const punto = PuntoReciclaje(
      id: '12',
      nombre: 'Punto Demo',
      comuna: 'Ñuñoa',
      direccion: 'Calle 1',
      lat: -33.45,
      lng: -70.6,
      fuente: FuentePunto.oficial,
      materiales: [TipoMaterial.vidrio],
      estado: EstadoPunto.lleno,
      calificacionPromedio: 4,
      numCalificaciones: 2,
    );
    // Ida y vuelta por JSON, como queda en shared_preferences.
    final pendiente = jsonDecode(
      jsonEncode(
        RealizarReporteScreen.pendientePara(punto, TipoReporte.llenoSaturado),
      ),
    ) as Map<String, Object?>;
    final foto = File('recuperada.jpg');

    final pantalla = RealizarReporteScreen.desdePendiente(
      pendiente,
      foto,
      _SinRepositorio(),
    )!;
    expect(pantalla.punto.id, '12');
    expect(pantalla.punto.nombre, 'Punto Demo');
    expect(pantalla.punto.fuente, FuentePunto.oficial);
    expect(pantalla.tipo, TipoReporte.llenoSaturado);
    expect(pantalla.fotoInicial, foto);
    expect(
      RealizarReporteScreen.desdePendiente(
        {'flujo': 'reciclar'},
        foto,
        _SinRepositorio(),
      ),
      isNull,
    );
  });

  group('ProcesadorFoto', () {
    late Directory dir;
    late _Laboratorio lab;

    setUp(() async {
      dir = await Directory.systemTemp.createTemp('procesador_test');
      lab = _Laboratorio();
    });
    tearDown(() => dir.delete(recursive: true));

    File foto(String nombre, List<int> bytes, [(int, int)? medidas]) {
      final f = File('${dir.path}${Platform.pathSeparator}$nombre')
        ..writeAsBytesSync(bytes);
      if (medidas != null) lab.medidas[f.path] = medidas;
      return f;
    }

    List<String> archivos() =>
        dir.listSync().map((e) => e.uri.pathSegments.last).toList()..sort();

    test('un archivo vacío no llega al compresor', () async {
      final original = foto('vacia.jpg', const []);
      await expectLater(lab.procesador.procesar(original), throwsStateError);
      expect(lab.llamadas, isEmpty);
    });

    test('un archivo que no es foto no llega al compresor', () async {
      final original = foto('falsa.jpg', ascii.encode('esto no es una foto'));
      await expectLater(lab.procesador.procesar(original), throwsStateError);
      expect(lab.llamadas, isEmpty);
    });

    test(
      'una foto normal se comprime una vez a 1024 px y calidad 75',
      () async {
        final original = foto('original.jpg', _jpeg(10), (4000, 3000));
        final resultado = await lab.procesador.procesar(original);

        expect(lab.llamadas, [(lado: 768, calidad: 75, muestreo: 2)]);
        expect(lab.medidas[resultado.path], (1024, 768));
        // La original (la borra CamaraService) y el resultado.
        expect(archivos(), hasLength(2));
      },
    );

    test(
      'un HEIC sin medidas legibles se corrige con una segunda pasada',
      () async {
        final original = foto('iphone.heic', [
          0, 0, 0, 0x18, //
          ...ascii.encode('ftypheic'),
          0, 0, 0, 0,
        ]);
        // Primera pasada con lado 768 en una foto 16:9 → 1365 × 768.
        lab.salidas = [(1365, 768), (1024, 576)];
        final resultado = await lab.procesador.procesar(original);

        expect(lab.llamadas.map((l) => l.lado), [768, 576]);
        expect(lab.medidas[resultado.path], (1024, 576));
        expect(
          archivos(),
          hasLength(2),
          reason: 'la pasada intermedia se borra',
        );
      },
    );

    test('si pesa más de 1 MB se recomprime a calidad 60', () async {
      final original = foto('original.jpg', _jpeg(10), (4000, 3000));
      lab.pesos = [ProcesadorFoto.pesoMaximo + 1, 200 * 1024];
      final resultado = await lab.procesador.procesar(original);

      expect(lab.llamadas.map((l) => l.calidad), [75, 60]);
      expect(resultado.lengthSync(), 200 * 1024);
      expect(archivos(), hasLength(2));
    });

    test('si sigue pesando más de 1 MB falla y no deja archivos', () async {
      final original = foto('original.jpg', _jpeg(10), (4000, 3000));
      lab.pesos = List.filled(5, ProcesadorFoto.pesoMaximo + 1);

      await expectLater(lab.procesador.procesar(original), throwsStateError);
      expect(archivos(), ['original.jpg']);
    });

    test('si el compresor se queda pegado se corta por tiempo', () async {
      final original = foto('original.jpg', _jpeg(10), (4000, 3000));
      lab.pegado = true;

      await expectLater(
        lab.procesador.procesar(original),
        throwsA(isA<TimeoutException>()),
      );
      expect(archivos(), ['original.jpg']);
    });

    test('si el compresor no entrega un JPEG falla', () async {
      final original = foto('original.jpg', _jpeg(10), (4000, 3000));
      lab.noJpeg = true;

      await expectLater(lab.procesador.procesar(original), throwsStateError);
      expect(archivos(), ['original.jpg']);
    });
  });
}

/// Permisos sin el plugin: la cámara queda siempre en [estadoCamara].
class _PermisosFijos extends PermisosService {
  final EstadoPermiso estadoCamara;
  int pedidos = 0;
  _PermisosFijos(this.estadoCamara);

  @override
  Future<EstadoPermiso> estado(PermisoApp p) async => estadoCamara;

  @override
  Future<EstadoPermiso> pedir(PermisoApp p) async {
    pedidos++;
    return estadoCamara;
  }
}

void permisosMain() {
  group('Permiso de cámara', () {
    Future<bool> pedirCon(WidgetTester tester, EstadoPermiso estado) async {
      final permisos = _PermisosFijos(estado);
      late BuildContext contexto;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (c) {
                contexto = c;
                return const SizedBox();
              },
            ),
          ),
        ),
      );
      final concedido = await CamaraService(permisos: permisos)
          .asegurarPermiso(contexto);
      await tester.pump();
      expect(permisos.pedidos, estado == EstadoPermiso.concedido ? 0 : 1);
      return concedido;
    }

    testWidgets('si no lo da, el aviso dice que puede activarlo en el Perfil', (
      tester,
    ) async {
      expect(await pedirCon(tester, EstadoPermiso.pendiente), isFalse);
      expect(
        find.text(CamaraService.avisoSinPermiso(EstadoPermiso.pendiente)),
        findsOneWidget,
      );
      expect(
        find.textContaining('Perfil › Ajustes › Permisos'),
        findsOneWidget,
      );
    });

    testWidgets('bloqueado: ajustes del teléfono o el Perfil', (tester) async {
      expect(await pedirCon(tester, EstadoPermiso.bloqueado), isFalse);
      expect(find.textContaining('ajustes del teléfono'), findsOneWidget);
      expect(
        find.textContaining('Perfil › Ajustes › Permisos'),
        findsOneWidget,
      );
    });

    testWidgets('concedido: sigue sin avisos', (tester) async {
      expect(await pedirCon(tester, EstadoPermiso.concedido), isTrue);
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('Perfil › Ajustes ofrece activar la cámara rechazada', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: PermisosAjustes(
              permisos: _PermisosFijos(EstadoPermiso.pendiente),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final fila = find.widgetWithText(ListTile, 'Cámara');
      expect(fila, findsOneWidget);
      expect(
        find.descendant(of: fila, matching: find.text('Activar')),
        findsOneWidget,
      );
    });
  });
}
