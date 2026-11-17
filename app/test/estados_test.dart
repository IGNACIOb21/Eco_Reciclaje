import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recircula/theme/app_theme.dart';
import 'package:recircula/widgets/esqueleto.dart';
import 'package:recircula/widgets/estado_pantalla.dart';

void main() {
  testWidgets('El esqueleto late y se anuncia como "Cargando"', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(body: EsqueletoLista()),
      ),
    );
    final opacidad = tester.widget<FadeTransition>(
      find.descendant(
        of: find.byType(Esqueleto),
        matching: find.byType(FadeTransition),
      ),
    );
    final antes = opacidad.opacity.value;
    await tester.pump(const Duration(milliseconds: 450));
    expect(opacidad.opacity.value, isNot(antes));
    expect(find.bySemanticsLabel('Cargando'), findsOneWidget);
  });

  testWidgets('Con "reducir animaciones" el esqueleto queda quieto', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: Scaffold(body: EsqueletoLista()),
        ),
      ),
    );
    // Sin animación en bucle, pumpAndSettle termina.
    await tester.pumpAndSettle();
    expect(find.byType(BloqueEsqueleto), findsWidgets);
  });

  testWidgets('El estado vacío muestra su acción y la ejecuta', (tester) async {
    var tocado = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: EstadoPantalla(
            icono: Icons.inbox_outlined,
            titulo: 'Nada por aquí',
            texto: 'Explicación',
            accion: 'Hacer algo',
            onAccion: () => tocado = true,
            accionSecundaria: 'Otra cosa',
            onAccionSecundaria: () {},
          ),
        ),
      ),
    );
    expect(find.text('Nada por aquí'), findsOneWidget);
    expect(find.text('Otra cosa'), findsOneWidget);
    await tester.tap(find.text('Hacer algo'));
    await tester.pumpAndSettle();
    expect(tocado, isTrue);
  });
}
