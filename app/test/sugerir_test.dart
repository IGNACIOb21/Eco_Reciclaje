import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import 'package:recircula/models/material_type.dart';
import 'package:recircula/models/perfil_usuario.dart';
import 'package:recircula/models/sugerencia_cercana.dart';
import 'package:recircula/models/usuario.dart';
import 'package:recircula/repositories/acciones_repository.dart';
import 'package:recircula/repositories/acciones_repository_mock.dart';
import 'package:recircula/repositories/puntos_repository_mock.dart';
import 'package:recircula/screens/confirmar_sugerencias_screen.dart';
import 'package:recircula/screens/mapa_screen.dart';
import 'package:recircula/screens/sugerir_punto_screen.dart';
import 'package:recircula/theme/app_theme.dart';

const _gps = LatLng(-33.4500, -70.5500);
const _centro = LatLng(-33.4000, -70.6000);

Widget _app(Widget home) => MaterialApp(theme: AppTheme.light, home: home);

void _pantallaAlta(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 3600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> _llenarFormulario(WidgetTester tester) async {
  await tester.enterText(
    find.byKey(const Key('sugerir-nombre')),
    'Contenedor Plaza',
  );
  await tester.tap(find.byKey(const Key('sugerir-comuna')));
  await tester.pumpAndSettle();
  await tester.tap(find.text('La Reina').last);
  await tester.pumpAndSettle();
  await tester.tap(find.text('Vidrio'));
  await tester.pump();
}

const _sugerencia = SugerenciaCercana(
  id: 7,
  nombre: 'Punto de la vecina',
  lat: -33.45,
  lng: -70.55,
  comuna: 'La Reina',
  materiales: [TipoMaterial.vidrio],
  confirmaciones: 1,
  esMia: false,
  yaConfirmada: false,
);

void main() {
  testWidgets('Sugerir valida el formulario antes de enviar', (tester) async {
    _pantallaAlta(tester);
    final repo = AccionesRepositoryMock();
    await tester.pumpWidget(
      _app(
        SugerirPuntoScreen(repositorio: repo, centroMapa: _centro, gps: _gps),
      ),
    );
    await tester.tap(find.byKey(const Key('sugerir-enviar')));
    await tester.pump();
    expect(find.textContaining('Ponle un nombre'), findsOneWidget);
    expect(repo.ultimaSugerencia, isNull);
  });

  testWidgets('Sugerir usa el GPS por defecto y envía los datos', (
    tester,
  ) async {
    _pantallaAlta(tester);
    final repo = AccionesRepositoryMock();
    bool? enviada;
    await tester.pumpWidget(
      _app(
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async =>
                enviada = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(
                    builder: (_) => SugerirPuntoScreen(
                      repositorio: repo,
                      centroMapa: _centro,
                      gps: _gps,
                    ),
                  ),
                ),
            child: const Text('abrir'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
    expect(find.text('-33.45000, -70.55000'), findsOneWidget);

    await _llenarFormulario(tester);
    await tester.tap(find.byKey(const Key('sugerir-enviar')));
    await tester.pumpAndSettle();

    expect(enviada, true);
    expect(repo.ultimaSugerencia, 'Contenedor Plaza');
    expect(repo.ultimosMateriales, [TipoMaterial.vidrio]);
    expect(repo.ultimaLat, -33.45);
  });

  testWidgets('Sugerir sin GPS usa el centro del mapa y lo avisa', (
    tester,
  ) async {
    _pantallaAlta(tester);
    final repo = AccionesRepositoryMock();
    await tester.pumpWidget(
      _app(SugerirPuntoScreen(repositorio: repo, centroMapa: _centro)),
    );
    expect(find.textContaining('sin GPS'), findsOneWidget);
    await _llenarFormulario(tester);
    await tester.tap(find.byKey(const Key('sugerir-enviar')));
    await tester.pumpAndSettle();
    expect(repo.ultimaLat, -33.4);
  });

  testWidgets(
    'Sugerir muestra el rechazo del servidor (punto a menos de 30 m)',
    (tester) async {
      _pantallaAlta(tester);
      final repo = AccionesRepositoryMock(
        error: const AccionException(MotivoErrorAccion.puntoCercano),
      );
      await tester.pumpWidget(
        _app(
          SugerirPuntoScreen(repositorio: repo, centroMapa: _centro, gps: _gps),
        ),
      );
      await _llenarFormulario(tester);
      await tester.tap(find.byKey(const Key('sugerir-enviar')));
      await tester.pumpAndSettle();
      expect(find.textContaining('menos de 30 metros'), findsOneWidget);
    },
  );

  testWidgets('Confirmar una sugerencia ajena actualiza la tarjeta', (
    tester,
  ) async {
    _pantallaAlta(tester);
    final repo = AccionesRepositoryMock(sugerencias: [_sugerencia]);
    await tester.pumpWidget(
      _app(ConfirmarSugerenciasScreen(repositorio: repo, ubicacion: _gps)),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('1 confirmación'), findsOneWidget);

    await tester.tap(find.byKey(const Key('confirmar-7')));
    await tester.pumpAndSettle();
    expect(repo.ultimaConfirmada, 7);
    expect(find.text('Confirmado'), findsOneWidget);
  });

  testWidgets('No se confirma la sugerencia propia', (tester) async {
    _pantallaAlta(tester);
    final propia = SugerenciaCercana(
      id: 8,
      nombre: 'Mía',
      lat: -33.45,
      lng: -70.55,
      comuna: 'La Reina',
      materiales: const [TipoMaterial.latas],
      confirmaciones: 0,
      esMia: true,
      yaConfirmada: false,
    );
    final repo = AccionesRepositoryMock(sugerencias: [propia]);
    await tester.pumpWidget(
      _app(ConfirmarSugerenciasScreen(repositorio: repo, ubicacion: _gps)),
    );
    await tester.pumpAndSettle();
    expect(find.text('Tu sugerencia'), findsOneWidget);
    final boton = tester.widget<OutlinedButton>(
      find.byKey(const Key('confirmar-8')),
    );
    expect(boton.onPressed, isNull);
  });

  testWidgets('Sin sugerencias cerca lo explica', (tester) async {
    await tester.pumpWidget(
      _app(
        ConfirmarSugerenciasScreen(
          repositorio: AccionesRepositoryMock(),
          ubicacion: _gps,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('No hay puntos nuevos'), findsOneWidget);
  });

  testWidgets('El Mapa no ofrece sugerir puntos (no existe en esta base)', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final original = FlutterError.onError;
    FlutterError.onError = (d) {
      if (d.exceptionAsString().contains('overflowed')) return;
      original?.call(d);
    };
    addTearDown(() => FlutterError.onError = original);

    await tester.pumpWidget(
      _app(
        MapaScreen(
          repositorio: PuntosRepositoryMock(),
          acciones: AccionesRepositoryMock(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('mapa-menu-puntos')), findsNothing);
  });

  test('la racha viaja del usuario al perfil', () {
    final usuario = Usuario(
      id: 'x',
      alias: 'a',
      fechaRegistro: DateTime(2026),
      puntosTotales: 10,
      racha: 3,
    );
    expect(PerfilUsuario.desdeUsuario(usuario).racha, 3);
    expect(
      PerfilUsuario.desdeUsuario(
        Usuario(
          id: 'y',
          alias: 'b',
          fechaRegistro: DateTime(2026),
          puntosTotales: 0,
        ),
      ).racha,
      0,
    );
  });
}
