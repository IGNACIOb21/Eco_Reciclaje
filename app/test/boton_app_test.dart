import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recircula/theme/app_theme.dart';
import 'package:recircula/widgets/boton_app.dart';

Widget _envolver(Widget hijo, {ThemeData? tema}) => MaterialApp(
  theme: tema ?? AppTheme.light,
  home: Scaffold(body: Center(child: hijo)),
);

void main() {
  testWidgets('BotonApp llama a onPressed al tocarlo', (tester) async {
    var toques = 0;
    await tester.pumpWidget(
      _envolver(BotonApp(texto: 'Cómo llegar', onPressed: () => toques++)),
    );
    await tester.tap(find.text('Cómo llegar'));
    await tester.pumpAndSettle();
    expect(toques, 1);
  });

  testWidgets('BotonApp no responde si está cargando ni sin acción', (
    tester,
  ) async {
    var toques = 0;
    await tester.pumpWidget(
      _envolver(
        BotonApp(
          texto: 'Reclamar',
          textoCargando: 'Reclamando…',
          estado: EstadoBoton.cargando,
          onPressed: () => toques++,
        ),
      ),
    );
    expect(find.text('Reclamando…'), findsOneWidget);
    await tester.tap(find.text('Reclamando…'));
    await tester.pump(const Duration(milliseconds: 100));
    expect(toques, 0);

    await tester.pumpWidget(
      _envolver(const BotonApp(texto: 'Sin acción', onPressed: null)),
    );
    await tester.tap(find.text('Sin acción'));
    await tester.pump();
    expect(toques, 0);
  });

  testWidgets('BotonApp muestra el check y el texto de éxito', (tester) async {
    await tester.pumpWidget(
      _envolver(
        BotonApp(
          texto: 'Reclamar',
          textoExito: '+10 sumados',
          estado: EstadoBoton.exito,
          variante: VarianteBoton.recompensa,
          onPressed: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('+10 sumados'), findsOneWidget);
    expect(find.byIcon(Icons.check), findsOneWidget);
  });

  test('los dos temas definen todos los tokens nuevos', () {
    for (final tema in [AppTheme.light, AppTheme.eco]) {
      final c = tema.extension<ColoresApp>()!;
      expect(c.primarioTexto, isNot(c.fondo));
      expect(c.recompensaTexto, isNot(c.fondo));
      expect(c.alerta, isNot(c.fondo));
    }
  });

  test('el texto de titulares usa Poppins y el resto Work Sans', () {
    final t = AppTheme.light.textTheme;
    expect(t.titleLarge?.fontFamily, 'Poppins');
    expect(t.bodyMedium?.fontFamily, 'WorkSans');
  });
}
