import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recircula/theme/app_theme.dart';
import 'package:recircula/widgets/barra_sistema_solida.dart';

void main() {
  testWidgets('Ninguna pantalla queda bajo la barra de navegación de Android', (
    tester,
  ) async {
    // Barra de 3 botones de 48 px, como en un teléfono con Android 15.
    tester.view.padding = const FakeViewPadding(bottom: 48);
    tester.view.viewPadding = const FakeViewPadding(bottom: 48);
    addTearDown(tester.view.reset);

    double? margenVisto;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.eco,
        builder: (context, child) => BarraSistemaSolida(child: child!),
        home: Builder(
          builder: (context) {
            margenVisto = MediaQuery.viewPaddingOf(context).bottom;
            return const Scaffold(
              body: Align(
                alignment: Alignment.bottomCenter,
                child: Text('Botón de abajo'),
              ),
            );
          },
        ),
      ),
    );

    final altoPantalla =
        tester.view.physicalSize.height / tester.view.devicePixelRatio;
    final franja = 48 / tester.view.devicePixelRatio;

    // La app termina sobre la franja y las pantallas ya no ven el margen.
    expect(margenVisto, 0);
    expect(
      tester.getBottomLeft(find.text('Botón de abajo')).dy,
      lessThanOrEqualTo(altoPantalla - franja),
    );
  });
}
