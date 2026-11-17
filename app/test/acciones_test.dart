import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';

import 'package:recircula/models/aviso_punto.dart';
import 'package:recircula/models/estado_punto.dart';
import 'package:recircula/models/material_type.dart';
import 'package:recircula/models/mi_reporte.dart';
import 'package:recircula/models/opiniones_punto.dart';
import 'package:recircula/models/punto_reciclaje.dart';
import 'package:recircula/models/tipo_reporte.dart';
import 'package:recircula/repositories/acciones_repository.dart';
import 'package:recircula/repositories/acciones_repository_mock.dart';
import 'package:recircula/screens/calificar_screen.dart';
import 'package:recircula/screens/mis_reportes_screen.dart';
import 'package:recircula/state/mis_reportes_controller.dart';
import 'package:recircula/screens/punto_detail_screen.dart';
import 'package:recircula/screens/foto_fallida_screen.dart';
import 'package:recircula/screens/realizar_reporte_screen.dart';
import 'package:recircula/screens/reportar_estado_screen.dart';
import 'package:recircula/services/camara_service.dart';
import 'package:recircula/theme/app_theme.dart';
import 'package:recircula/utils/fechas.dart';

const _punto = PuntoReciclaje(
  id: '12',
  nombre: 'Punto Limpio Demo',
  comuna: 'La Reina',
  direccion: 'Calle 1',
  lat: -33.4,
  lng: -70.5,
  fuente: FuentePunto.oficial,
  materiales: [TipoMaterial.vidrio],
  estado: EstadoPunto.disponible,
  calificacionPromedio: 4,
  numCalificaciones: 3,
);

/// Cámara que "toma" una foto sin abrir nada.
class _CamaraFalsa extends CamaraService {
  @override
  Future<bool> asegurarPermiso(BuildContext context) async => true;

  @override
  Future<File?> tomarFoto({Map<String, Object?>? pendiente}) async =>
      File('no_existe_foto_reporte.jpg');
}

/// Cámara cuya primera foto no se puede comprimir; las siguientes sí.
class _CamaraQueFalla extends _CamaraFalsa {
  int fallos = 1;
  int intentos = 0;

  @override
  Future<File?> tomarFoto({Map<String, Object?>? pendiente}) async {
    intentos++;
    if (fallos > 0) {
      fallos--;
      throw const FotoNoProcesadaException();
    }
    return super.tomarFoto(pendiente: pendiente);
  }
}

/// Elige [codigo], abre el paso 2 y toma la foto.
Future<void> _hastaLaFoto(WidgetTester tester, String codigo) async {
  await tester.tap(find.byKey(Key('reportar-$codigo')));
  // La casilla entra con una animación de tamaño.
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('reportar-realizar')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('reportar-foto')));
  await tester.pumpAndSettle();
}

Widget _app(Widget home) => MaterialApp(theme: AppTheme.light, home: home);

void _pantallaAlta(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 3600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

/// Abre [pantalla] sobre una ruta anterior para poder leer lo que devuelve.
Widget _conResultado(
  Widget Function(AccionesRepository) pantalla,
  AccionesRepository repo,
  void Function(ResultadoAccion?) alCerrar,
) => _app(
  Builder(
    builder: (context) => Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () async => alCerrar(
            await Navigator.of(context).push<ResultadoAccion>(
              MaterialPageRoute(builder: (_) => pantalla(repo)),
            ),
          ),
          child: const Text('abrir'),
        ),
      ),
    ),
  ),
);

void main() {
  test('los 11 tipos de reporte coinciden con el enum de la base', () {
    expect(TipoReporte.values.map((t) => t.codigo).toList(), [
      'lleno_saturado',
      'sucio_residuos_afuera',
      'dañado_destruido',
      'fuera_de_servicio',
      'sin_senalizacion',
      'qr_faltante_danado',
      'categorias_incorrectas',
      'horario_incorrecto',
      'ubicacion_incorrecta',
      'todo_en_orden',
      'otro',
    ]);
    expect(TipoReporte.desdeCodigo('otro'), TipoReporte.otro);
    expect(TipoReporte.desdeCodigo('inexistente'), isNull);
  });

  test('MiReporte se arma desde una fila de app_mis_reportes', () {
    final r = MiReporte.fromSupabaseRow({
      'id_reporte': 1,
      'id_punto': 12,
      'punto': 'Punto Limpio Demo',
      'tipo_reporte': 'lleno_saturado',
      'comentario': null,
      'fecha': '2026-10-09T10:00:00+00:00',
      'estado_alerta': 'resuelta',
      'fue_fundada': false,
    });
    expect(r.tipo, TipoReporte.llenoSaturado);
    expect(r.avance, 'Cerrado sin cambios');
    expect(
      MiReporte.fromSupabaseRow({
        'id_punto': 1,
        'punto': 'x',
        'tipo_reporte': 'todo_en_orden',
        'fecha': '2026-10-09T10:00:00+00:00',
      }).avance,
      'Registrado',
    );
  });

  testWidgets('Reportar envía el tipo elegido y devuelve los puntos', (
    tester,
  ) async {
    _pantallaAlta(tester);
    final repo = AccionesRepositoryMock();
    ResultadoAccion? resultado;
    await tester.pumpWidget(
      _conResultado(
        (r) => ReportarEstadoScreen(
          punto: _punto,
          repositorio: r,
          camara: _CamaraFalsa(),
        ),
        repo,
        (r) => resultado = r,
      ),
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();

    await _hastaLaFoto(tester, 'lleno_saturado');
    await tester.enterText(
      find.byKey(const Key('reportar-comentario')),
      'rebalsa',
    );
    await tester.tap(find.byKey(const Key('reportar-enviar')));
    await tester.pumpAndSettle();

    expect(repo.ultimoTipo, TipoReporte.llenoSaturado);
    expect(repo.ultimoComentario, 'rebalsa');
    expect(repo.ultimaFoto?.path, 'no_existe_foto_reporte.jpg');
    expect(resultado?.puntos, 3);
    expect(find.byType(ReportarEstadoScreen), findsNothing);
  });

  testWidgets(
    'La casilla aparece al elegir, se asocia al último y se va al desmarcar',
    (tester) async {
      _pantallaAlta(tester);
      await tester.pumpWidget(
        _app(
          ReportarEstadoScreen(
            punto: _punto,
            repositorio: AccionesRepositoryMock(),
          ),
        ),
      );
      expect(find.byKey(const Key('reportar-realizar')), findsNothing);
      expect(find.byKey(const Key('reportar-comentario')), findsNothing);
      expect(find.byKey(const Key('reportar-enviar')), findsNothing);

      await tester.tap(find.byKey(const Key('reportar-lleno_saturado')));
      await tester.pumpAndSettle();
      expect(find.text('Realizar Lleno o saturado'), findsOneWidget);

      await tester.tap(find.byKey(const Key('reportar-fuera_de_servicio')));
      await tester.pumpAndSettle();
      expect(find.text('Realizar Fuera de servicio'), findsOneWidget);

      await tester.tap(find.byKey(const Key('reportar-todo_en_orden')));
      await tester.pumpAndSettle();
      expect(find.text('Realizar reporte de estado del punto'), findsOneWidget);

      await tester.tap(find.byKey(const Key('reportar-fuera_de_servicio')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('reportar-fuera_de_servicio')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('reportar-realizar')), findsNothing);
    },
  );

  testWidgets('Sin foto no se envía; en "Otro" el comentario es obligatorio', (
    tester,
  ) async {
    _pantallaAlta(tester);
    final repo = AccionesRepositoryMock();
    await tester.pumpWidget(
      _app(
        RealizarReporteScreen(
          punto: _punto,
          tipo: TipoReporte.otro,
          repositorio: repo,
          camara: _CamaraFalsa(),
        ),
      ),
    );
    final enviar = find.byKey(const Key('reportar-enviar'));
    expect(tester.widget<ElevatedButton>(enviar).onPressed, isNull);
    expect(find.text('Toma la foto para enviar'), findsOneWidget);

    await tester.tap(find.byKey(const Key('reportar-foto')));
    await tester.pumpAndSettle();
    expect(tester.widget<ElevatedButton>(enviar).onPressed, isNotNull);

    await tester.tap(enviar);
    await tester.pump();
    expect(find.text('Cuéntanos qué pasa en el comentario.'), findsWidgets);
    expect(repo.ultimoTipo, isNull);
  });

  testWidgets('Foto fallida: muestra el fallo y "Reintentar" abre la cámara', (
    tester,
  ) async {
    _pantallaAlta(tester);
    final camara = _CamaraQueFalla();
    await tester.pumpWidget(
      _app(
        RealizarReporteScreen(
          punto: _punto,
          tipo: TipoReporte.llenoSaturado,
          repositorio: AccionesRepositoryMock(),
          camara: camara,
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('reportar-foto')));
    await tester.pumpAndSettle();

    expect(find.byType(FotoFallidaScreen), findsOneWidget);
    expect(
      find.text('No pudimos procesar la foto, tómala de nuevo.'),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('foto-fallida-reintentar')));
    await tester.pumpAndSettle();

    expect(camara.intentos, 2);
    expect(find.byType(FotoFallidaScreen), findsNothing);
    final enviar = find.byKey(const Key('reportar-enviar'));
    expect(tester.widget<ElevatedButton>(enviar).onPressed, isNotNull);
  });

  testWidgets('Foto fallida: "Salir" cierra el reporte sin enviar nada', (
    tester,
  ) async {
    _pantallaAlta(tester);
    final repo = AccionesRepositoryMock();
    ResultadoAccion? resultado;
    await tester.pumpWidget(
      _conResultado(
        (r) => ReportarEstadoScreen(
          punto: _punto,
          repositorio: r,
          camara: _CamaraQueFalla(),
        ),
        repo,
        (r) => resultado = r,
      ),
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
    await _hastaLaFoto(tester, 'lleno_saturado');
    expect(find.byType(FotoFallidaScreen), findsOneWidget);

    await tester.tap(find.byKey(const Key('foto-fallida-salir')));
    await tester.pumpAndSettle();

    expect(find.byType(FotoFallidaScreen), findsNothing);
    expect(find.byType(RealizarReporteScreen), findsNothing);
    expect(find.byType(ReportarEstadoScreen), findsNothing);
    expect(find.text('abrir'), findsOneWidget);
    expect(resultado, isNull);
    expect(repo.ultimoTipo, isNull);
  });

  testWidgets('Reportar muestra el error del servidor y deja reintentar', (
    tester,
  ) async {
    _pantallaAlta(tester);
    final repo = AccionesRepositoryMock(
      error: const AccionException(MotivoErrorAccion.reporteRepetido),
    );
    await tester.pumpWidget(
      _app(
        ReportarEstadoScreen(
          punto: _punto,
          repositorio: repo,
          camara: _CamaraFalsa(),
        ),
      ),
    );
    await _hastaLaFoto(tester, 'lleno_saturado');
    await tester.tap(find.byKey(const Key('reportar-enviar')));
    await tester.pumpAndSettle();

    expect(find.textContaining('Ya reportaste esto'), findsOneWidget);
    expect(find.byType(RealizarReporteScreen), findsOneWidget);
  });

  testWidgets('Calificar exige estrellas y envía la puntuación', (
    tester,
  ) async {
    _pantallaAlta(tester);
    final repo = AccionesRepositoryMock();
    ResultadoAccion? resultado;
    await tester.pumpWidget(
      _conResultado(
        (r) => CalificarScreen(punto: _punto, repositorio: r),
        repo,
        (r) => resultado = r,
      ),
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('calificar-enviar')));
    await tester.pump();
    expect(find.text('Elige entre 1 y 5 estrellas.'), findsOneWidget);

    await tester.tap(find.byKey(const Key('calificar-estrella-4')));
    await tester.tap(find.text('Limpio'));
    await tester.tap(find.byKey(const Key('calificar-enviar')));
    await tester.pumpAndSettle();

    expect(repo.ultimaPuntuacion, 4);
    expect(resultado?.puntos, 2);
  });

  final misReportes = [
    MiReporte(
      idPunto: 12,
      punto: 'Punto Limpio Demo',
      tipo: TipoReporte.danadoDestruido,
      fecha: DateTime(2026, 10, 9),
      comentario: 'Tapa rota',
      estadoAlerta: 'en_atencion',
    ),
    MiReporte(
      idPunto: 13,
      punto: 'Parque Almagro',
      tipo: TipoReporte.danadoDestruido,
      fecha: DateTime(2026, 10, 1),
      estadoAlerta: 'recibida',
    ),
  ];

  testWidgets('Mis reportes: una tarjeta por tipo y abre su historial', (
    tester,
  ) async {
    _pantallaAlta(tester);
    final repo = AccionesRepositoryMock(reportes: misReportes);
    await tester.pumpWidget(_app(MisReportesScreen(repositorio: repo)));
    await tester.pumpAndSettle();

    // Solo las tarjetas por tipo; los reportes sueltos no se listan.
    expect(find.text('Tus reportes'), findsNothing);
    expect(find.text('Punto Limpio Demo'), findsNothing);

    // Todos los tipos, con o sin reportes.
    for (final tipo in TipoReporte.values) {
      final tarjeta = find.byKey(Key('mis-reportes-${tipo.codigo}'));
      await tester.scrollUntilVisible(tarjeta, 200);
      expect(
        find.descendant(of: tarjeta, matching: find.text(tipo.etiqueta)),
        findsOneWidget,
      );
    }
    final danado = find.byKey(const Key('mis-reportes-dañado_destruido'));
    await tester.scrollUntilVisible(danado, -200);
    expect(
      find.descendant(
        of: danado,
        matching: find.text('2 reportes · último: En atención'),
      ),
      findsOneWidget,
    );

    await tester.tap(danado);
    await tester.pumpAndSettle();
    expect(find.byType(ReportesDeTipoScreen), findsOneWidget);
    expect(find.text('Punto Limpio Demo'), findsOneWidget);
    expect(find.text('Parque Almagro'), findsOneWidget);
    expect(find.textContaining('"Tapa rota"'), findsOneWidget);
  });

  testWidgets('Mis reportes: un tipo sin reportes avisa y no abre nada', (
    tester,
  ) async {
    _pantallaAlta(tester);
    final repo = AccionesRepositoryMock(reportes: misReportes);
    await tester.pumpWidget(_app(MisReportesScreen(repositorio: repo)));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing, reason: 'no avisa al abrir');
    final fuera = find.byKey(const Key('mis-reportes-fuera_de_servicio'));
    await tester.scrollUntilVisible(fuera, 200);
    await tester.tap(fuera);
    await tester.pumpAndSettle();
    expect(find.text('Sin reportes en Fuera de servicio'), findsOneWidget);
    expect(find.byType(ReportesDeTipoScreen), findsNothing);

    await tester.tap(find.text('Cerrar'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.byType(MisReportesScreen), findsOneWidget);
  });

  test('MisReportesController agrupa por tipo', () async {
    final c = MisReportesController(
      AccionesRepositoryMock(reportes: misReportes),
    );
    await c.cargar();
    expect(c.reportesDe(TipoReporte.danadoDestruido), hasLength(2));
    expect(c.reportesDe(TipoReporte.horarioIncorrecto), isEmpty);
    expect(c.resumenDe(TipoReporte.horarioIncorrecto), 'Sin reportes');
    expect(
      MisReportesController.sinReportesEn(TipoReporte.horarioIncorrecto),
      'Sin reportes en Horario incorrecto',
    );

    final caido = MisReportesController(
      AccionesRepositoryMock(
        error: const AccionException(MotivoErrorAccion.sinConexion),
      ),
    );
    await caido.cargar();
    expect(caido.error, isNotNull);
  });

  testWidgets('La ficha abre Reportar y Calificar y avisa los puntos', (
    tester,
  ) async {
    _pantallaAlta(tester);
    final repo = AccionesRepositoryMock();
    await tester.pumpWidget(
      _app(
        PuntoDetailScreen(
          punto: _punto,
          acciones: repo,
          camara: _CamaraFalsa(),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('ficha-reportar')));
    await tester.pumpAndSettle();
    await _hastaLaFoto(tester, 'lleno_saturado');
    await tester.tap(find.byKey(const Key('reportar-enviar')));
    await tester.pumpAndSettle();
    expect(find.text('Gracias por avisar. +3 Rebin Points'), findsOneWidget);

    await tester.pump(const Duration(seconds: 5));
    await tester.tap(find.byKey(const Key('ficha-calificar')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('calificar-estrella-5')));
    await tester.tap(find.byKey(const Key('calificar-enviar')));
    await tester.pumpAndSettle();
    expect(find.text('Gracias por calificar. +2 Rebin Points'), findsOneWidget);
  });

  group('Información del punto', () {
    Position posicion(double lat, double lng) => Position(
      latitude: lat,
      longitude: lng,
      timestamp: DateTime(2026, 10, 15),
      accuracy: 8,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
    );

    test('el paso 2 dice qué se reporta, salvo en Todo en orden', () {
      expect(
        TipoReporte.llenoSaturado.tituloReporte,
        'Reporte: Lleno o saturado',
      );
      expect(TipoReporte.otro.tituloReporte, 'Reporte: Otro problema');
      expect(TipoReporte.todoEnOrden.tituloReporte, 'Realizar reporte');
    });

    test('los 5 motivos piden 20 caracteres y solo uno permite ubicación', () {
      for (final t in TipoReporte.values) {
        final info = t.grupo == GrupoReporte.informacionPunto;
        expect(t.minimoComentario, info ? 20 : (t == TipoReporte.otro ? 3 : 0));
        expect(t.ayudaComentario != null, info, reason: t.codigo);
        expect(t.permiteUbicacion, t == TipoReporte.ubicacionIncorrecta);
      }
    });

    testWidgets('con menos de 20 caracteres no se envía', (tester) async {
      _pantallaAlta(tester);
      final repo = AccionesRepositoryMock();
      await tester.pumpWidget(
        _app(
          RealizarReporteScreen(
            punto: _punto,
            tipo: TipoReporte.horarioIncorrecto,
            repositorio: repo,
            camara: _CamaraFalsa(),
          ),
        ),
      );
      expect(find.text('Mínimo 20 caracteres'), findsOneWidget);
      expect(find.byKey(const Key('reportar-ubicacion')), findsNothing);
      await tester.tap(find.byKey(const Key('reportar-foto')));
      await tester.pumpAndSettle();
      final campo = find.byKey(const Key('reportar-comentario'));
      final enviar = find.byKey(const Key('reportar-enviar'));

      await tester.enterText(campo, 'cierra antes');
      await tester.tap(enviar);
      await tester.pump();
      expect(
        find.text('Escribe al menos 20 caracteres para describir el problema.'),
        findsOneWidget,
      );
      expect(repo.ultimoTipo, isNull);

      await tester.enterText(campo, 'abre de lunes a viernes de 9 a 14');
      await tester.tap(enviar);
      await tester.pumpAndSettle();
      expect(repo.ultimoTipo, TipoReporte.horarioIncorrecto);
      expect(repo.ultimaUbicacion, isNull);
    });

    Future<AccionesRepositoryMock> abrirUbicacion(
      WidgetTester tester,
      Position? gps,
    ) async {
      _pantallaAlta(tester);
      final repo = AccionesRepositoryMock();
      await tester.pumpWidget(
        _app(
          RealizarReporteScreen(
            punto: _punto,
            tipo: TipoReporte.ubicacionIncorrecta,
            repositorio: repo,
            camara: _CamaraFalsa(),
            ubicar: () async => gps,
          ),
        ),
      );
      await tester.tap(find.byKey(const Key('reportar-foto')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('reportar-comentario')),
        'está en la esquina, frente al supermercado',
      );
      expect(find.byKey(const Key('reportar-ubicacion-aviso')), findsNothing);
      await tester.ensureVisible(find.byKey(const Key('reportar-ubicacion')));
      await tester.tap(find.byKey(const Key('reportar-ubicacion')));
      await tester.pumpAndSettle();
      return repo;
    }

    testWidgets('"Usar mi ubicación actual" muestra el aviso y la envía', (
      tester,
    ) async {
      // ~110 m al norte del pin.
      final repo = await abrirUbicacion(tester, posicion(-33.399, -70.5));
      expect(find.byKey(const Key('reportar-ubicacion-aviso')), findsOneWidget);
      expect(find.text(RealizarReporteScreen.avisoUbicacion), findsOneWidget);
      expect(find.textContaining('Ubicación lista: a 111 m'), findsOneWidget);

      await tester.tap(find.byKey(const Key('reportar-enviar')));
      await tester.pumpAndSettle();
      expect(repo.ultimaUbicacion?.latitude, -33.399);
    });

    testWidgets('a más de 500 m del pin se desmarca y no envía la ubicación', (
      tester,
    ) async {
      final repo = await abrirUbicacion(tester, posicion(-33.41, -70.5));
      expect(find.byKey(const Key('reportar-ubicacion-aviso')), findsNothing);
      expect(find.textContaining('Estás a 1112 m del punto'), findsOneWidget);

      await tester.tap(find.byKey(const Key('reportar-enviar')));
      await tester.pumpAndSettle();
      expect(repo.ultimoTipo, TipoReporte.ubicacionIncorrecta);
      expect(repo.ultimaUbicacion, isNull);
    });

    testWidgets('sin GPS avisa y deja enviar sin ubicación', (tester) async {
      await abrirUbicacion(tester, null);
      expect(find.byKey(const Key('reportar-ubicacion-aviso')), findsNothing);
      expect(
        find.textContaining('No pudimos obtener tu ubicación'),
        findsOneWidget,
      );
    });
  });

  group('Avisos del punto', () {
    Map<String, dynamic> fila(Object? avisos) => {
      'id': '12',
      'nombre': 'Punto',
      'comuna': 'La Reina',
      'direccion': '',
      'lat': -33.4,
      'lng': -70.5,
      'fuente': 'oficial',
      'materiales': ['vidrio'],
      'estado_actual': 'disponible',
      'calificacion_promedio': 4,
      'num_calificaciones': 3,
      'avisos': avisos,
    };

    test('se leen de app_puntos_cercanos y se ignoran los desconocidos', () {
      expect(
        PuntoReciclaje.fromSupabaseRow(fila(['horario', 'qr', 'nuevo_aviso']))
            .avisos,
        [AvisoPunto.horario, AvisoPunto.qr],
      );
      // Base anterior a 20261015150000: sin la columna.
      expect(PuntoReciclaje.fromSupabaseRow(fila(null)).avisos, isEmpty);
    });

    testWidgets('la ficha muestra los avisos', (tester) async {
      _pantallaAlta(tester);
      final punto = PuntoReciclaje.fromSupabaseRow(fila(['ubicacion', 'qr']));
      await tester.pumpWidget(
        _app(
          PuntoDetailScreen(
            punto: punto,
            acciones: AccionesRepositoryMock(),
            camara: _CamaraFalsa(),
          ),
        ),
      );
      await tester.pump();
      expect(find.byKey(const Key('aviso-ubicacion')), findsOneWidget);
      expect(find.byKey(const Key('aviso-qr')), findsOneWidget);
      expect(find.textContaining('QR no disponible'), findsOneWidget);
      expect(find.byKey(const Key('aviso-horario')), findsNothing);
    });
  });

  group('Calificaciones', () {
    testWidgets('cada calificación parte de cero y exige estrellas', (
      tester,
    ) async {
      _pantallaAlta(tester);
      final repo = AccionesRepositoryMock();
      await tester.pumpWidget(
        _app(CalificarScreen(punto: _punto, repositorio: repo)),
      );
      await tester.pumpAndSettle();
      expect(find.text('Calificar punto'), findsOneWidget);
      expect(find.byIcon(Icons.star), findsNothing);

      await tester.tap(find.byKey(const Key('calificar-enviar')));
      await tester.pump();
      expect(find.text('Elige entre 1 y 5 estrellas.'), findsOneWidget);
      expect(repo.ultimaPuntuacion, isNull);

      await tester.tap(find.byKey(const Key('calificar-estrella-4')));
      await tester.tap(find.byKey(const Key('calificar-enviar')));
      await tester.pumpAndSettle();
      expect(repo.ultimaPuntuacion, 4);
    });

    testWidgets('el límite por punto y el bloqueo muestran su mensaje', (
      tester,
    ) async {
      _pantallaAlta(tester);
      await tester.pumpWidget(
        _app(
          CalificarScreen(
            punto: _punto,
            repositorio: AccionesRepositoryMock(
              error: const AccionException(
                MotivoErrorAccion.calificacionRepetida,
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.byKey(const Key('calificar-estrella-5')));
      await tester.tap(find.byKey(const Key('calificar-enviar')));
      await tester.pumpAndSettle();
      expect(
        find.text('Ya calificaste este punto hoy. Vuelve mañana.'),
        findsOneWidget,
      );
      expect(
        const AccionException(MotivoErrorAccion.calificacionesBloqueadas)
            .mensaje,
        contains('muchas calificaciones seguidas'),
      );
    });

    testWidgets('las etiquetas opuestas se bloquean entre sí', (tester) async {
      _pantallaAlta(tester);
      await tester.pumpWidget(
        _app(
          CalificarScreen(punto: _punto, repositorio: AccionesRepositoryMock()),
        ),
      );
      await tester.pumpAndSettle();
      FilterChip chip(String e) =>
          tester.widget<FilterChip>(find.byKey(Key('calificar-etiqueta-$e')));

      await tester.tap(find.byKey(const Key('calificar-etiqueta-Limpio')));
      await tester.pump();
      expect(chip('Limpio').selected, isTrue);
      expect(chip('Sucio').onSelected, isNull, reason: 'Sucio bloqueada');
      expect(chip('Poco seguro').onSelected, isNotNull);

      await tester.tap(find.byKey(const Key('calificar-etiqueta-Limpio')));
      await tester.pump();
      expect(chip('Sucio').onSelected, isNotNull, reason: 'se desbloquea');
    });

    testWidgets('la ficha muestra etiquetas y opiniones', (tester) async {
      _pantallaAlta(tester);
      final repo = AccionesRepositoryMock(
        opinionesDelPunto: OpinionesPunto(
          etiquetas: const [
            EtiquetaContada('Limpio', 8),
            EtiquetaContada('Seguro', 5),
          ],
          opiniones: [
            Opinion(
              alias: 'Ana',
              puntuacion: 5,
              comentario: 'Siempre limpio, buen acceso',
              fecha: DateTime.now().subtract(const Duration(days: 2)),
            ),
          ],
        ),
      );
      await tester.pumpWidget(
        _app(
          PuntoDetailScreen(
            punto: _punto,
            acciones: repo,
            camara: _CamaraFalsa(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
      await tester.ensureVisible(find.byKey(const Key('ficha-opiniones')));
      expect(find.text('Limpio (8)'), findsOneWidget);
      expect(find.text('Seguro (5)'), findsOneWidget);
      expect(find.text('Ana · hace 2 días'), findsOneWidget);
      expect(find.text('Siempre limpio, buen acceso'), findsOneWidget);
    });

    test('opiniones desde app_opiniones_punto y hace cuánto', () {
      final o = OpinionesPunto.fromSupabase({
        'etiquetas': [
          {'etiqueta': 'Limpio', 'cantidad': 3},
        ],
        'opiniones': [
          {
            'alias': 'Pedro',
            'puntuacion': 3,
            'comentario': 'De noche está oscuro',
            'fecha': '2026-10-01T10:00:00+00:00',
          },
        ],
      });
      expect(o.etiquetas.single.cantidad, 3);
      expect(o.opiniones.single.alias, 'Pedro');
      final hoy = DateTime(2026, 10, 16);
      expect(haceTiempo(DateTime(2026, 10, 16), ahora: hoy), 'hoy');
      expect(haceTiempo(DateTime(2026, 10, 15), ahora: hoy), 'ayer');
      expect(haceTiempo(DateTime(2026, 10, 2), ahora: hoy), 'hace 2 semanas');
      expect(haceTiempo(DateTime(2026, 6, 1), ahora: hoy), 'hace 4 meses');
    });
  });
}
