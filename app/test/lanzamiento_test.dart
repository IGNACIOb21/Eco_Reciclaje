import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recircula/theme/app_theme.dart';
import 'package:recircula/widgets/barra_navegacion.dart';
import 'package:recircula/widgets/lanzamiento.dart';
import 'package:recircula/widgets/logo_app.dart';
import 'package:recircula/widgets/personas_reciclando.dart';

Widget _app(Widget hijo) =>
    MaterialApp(theme: AppTheme.light, home: hijo);

void main() {
  group('Lanzamiento', () {
    testWidgets('muestra el logo de la app y personas reciclando, sin '
        'enredaderas', (tester) async {
      await tester.pumpWidget(
        _app(const Lanzamiento(child: Scaffold(body: Text('app lista')))),
      );
      await tester.pump(const Duration(milliseconds: 1200));

      final logo = tester.widget<CustomPaint>(
        find.byKey(const Key('lanzamiento-logo')),
      );
      expect(logo.painter, isA<LogoAppPainter>());
      final fondo = tester.widget<CustomPaint>(
        find.byKey(const Key('lanzamiento-personas')),
      );
      expect(fondo.painter, isA<PersonasReciclandoPainter>());
      await tester.pumpAndSettle(const Duration(milliseconds: 100));
    });

    testWidgets('muestra la marca y luego deja ver la app', (tester) async {
      await tester.pumpWidget(
        _app(const Lanzamiento(child: Scaffold(body: Text('app lista')))),
      );
      expect(find.text('rebin'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 1000));
      expect(find.text('rebin'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 1400));
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('rebin'), findsNothing);
      expect(find.text('app lista'), findsOneWidget);
    });

    testWidgets('espera los datos y no pasa del máximo', (tester) async {
      final listo = ValueNotifier<bool>(false);
      await tester.pumpWidget(
        _app(
          Lanzamiento(
            datos: listo,
            datosListos: () => listo.value,
            child: const Scaffold(body: Text('app lista')),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 2400));
      await tester.pump(const Duration(milliseconds: 1000));
      // Sin datos, la marca sigue ahí (respirando).
      expect(find.text('rebin'), findsOneWidget);

      listo.value = true;
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('rebin'), findsNothing);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('a los 4 s entra aunque los datos no lleguen', (tester) async {
      await tester.pumpWidget(
        _app(
          Lanzamiento(
            datosListos: () => false,
            child: const Scaffold(body: Text('app lista')),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 2400));
      await tester.pump(const Duration(milliseconds: 1700));
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('rebin'), findsNothing);
      await tester.pumpWidget(const SizedBox());
    });

  });

  group('BarraNavegacion', () {
    const destinos = [
      DestinoBarra(
        icono: Icons.home_outlined,
        iconoActivo: Icons.home,
        etiqueta: 'Inicio',
      ),
      DestinoBarra(
        icono: Icons.groups_outlined,
        iconoActivo: Icons.groups,
        etiqueta: 'Comunidad',
      ),
      DestinoBarra(
        icono: Icons.miscellaneous_services_outlined,
        iconoActivo: Icons.miscellaneous_services,
        etiqueta: 'Servicios',
      ),
      DestinoBarra(
        icono: Icons.person_outline,
        iconoActivo: Icons.person,
        etiqueta: 'Perfil',
      ),
    ];

    testWidgets('el botón de escanear está al centro y responde', (
      tester,
    ) async {
      var escaneos = 0;
      final elegidos = <int>[];
      await tester.pumpWidget(
        _app(
          Scaffold(
            bottomNavigationBar: BarraNavegacion(
              destinos: destinos,
              indice: 0,
              onSeleccion: elegidos.add,
              onEscanear: () => escaneos++,
            ),
          ),
        ),
      );

      final centro = tester.getCenter(find.byKey(const Key('barra-escanear')));
      expect(centro.dx, closeTo(tester.view.physicalSize.width / tester.view.devicePixelRatio / 2, 1));

      await tester.tap(find.byKey(const Key('barra-escanear')));
      expect(escaneos, 1);

      await tester.tap(find.text('Servicios'));
      await tester.tap(find.text('Comunidad'));
      expect(elegidos, [2, 1]);
      await tester.pumpAndSettle();
    });
  });
}
