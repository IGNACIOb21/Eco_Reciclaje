import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recircula/data/guia_reciclaje.dart';
import 'package:recircula/models/material_type.dart';
import 'package:recircula/screens/guia_rapida_screen.dart';
import 'package:recircula/screens/guia_reciclaje_screen.dart';
import 'package:recircula/theme/app_theme.dart';

Future<void> _montar(WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(theme: AppTheme.light, home: const GuiaReciclajeScreen()),
  );
  await tester.pumpAndSettle();
}

void main() {
  test('Cada material de la app tiene su guía', () {
    for (final m in TipoMaterial.values) {
      expect(
        guiaReciclaje.where((g) => g.material == m),
        hasLength(1),
        reason: '$m',
      );
    }
  });

  test('Las bolsas (PEBD, 4) no se reciclan', () {
    final pebd = resinasPlastico.firstWhere((r) => r.numero == 4);
    expect(pebd.sigla, 'PEBD');
    expect(pebd.seRecicla, isFalse);
  });

  testWidgets('Parte en plástico con el número del triángulo', (tester) async {
    await _montar(tester);

    expect(find.text('Botellas de bebida y agua (1)'), findsOneWidget);
    expect(find.text('Mira el número del triángulo'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(const Key('resina-4')),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('resina-4')),
        matching: find.text('No se recicla'),
      ),
      findsOneWidget,
    );
    expect(find.text('Según el punto'), findsNothing);
  });

  testWidgets('Cambiar de material cambia la lista', (tester) async {
    await _montar(tester);

    await tester.tap(find.byKey(const Key('guia-chip-vidrio')));
    await tester.pumpAndSettle();

    expect(find.text('Frascos de mermelada y conservas'), findsOneWidget);
    expect(find.text('Botellas de bebida y agua (1)'), findsNothing);
    expect(find.text('Mira el número del triángulo'), findsNothing);
  });

  testWidgets('Tetra Pak no va con el papel', (tester) async {
    await _montar(tester);

    final chip = find.byKey(const Key('guia-chip-tetra_pak'));
    await tester.scrollUntilVisible(
      chip,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(chip);
    await tester.pumpAndSettle();

    expect(find.textContaining('no con el papel'), findsOneWidget);
  });

  testWidgets('"Escuchar las categorías" abre la Guía rápida', (tester) async {
    await _montar(tester);

    final enlace = find.byKey(const Key('guia-escuchar'));
    await tester.scrollUntilVisible(
      enlace,
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(enlace);
    await tester.pumpAndSettle();

    expect(find.byType(GuiaRapidaScreen), findsOneWidget);
  });
}
