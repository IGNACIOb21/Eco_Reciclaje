import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:recircula/models/material_type.dart';
import 'package:recircula/screens/guia_rapida_screen.dart';
import 'package:recircula/services/voz_service.dart';
import 'package:recircula/theme/app_theme.dart';

/// Guarda lo que se diría en vez de hablar.
class _VozFalsa extends VozService {
  final dichas = <String>[];
  var detenciones = 0;

  _VozFalsa() : super.silenciosa();

  @override
  Future<void> decir(String texto) async => dichas.add(texto);

  @override
  Future<void> detener() async => detenciones++;
}

Future<void> _montar(WidgetTester tester, VozService voz) async {
  SharedPreferences.setMockInitialValues({});
  tester.view.physicalSize = const Size(1080, 2340);
  tester.view.devicePixelRatio = 2.75;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: GuiaRapidaScreen(voz: voz),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _tocar(WidgetTester tester, Finder f) async {
  await tester.scrollUntilVisible(
    f,
    200,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
  await tester.tap(f);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('lista las 8 categorías', (tester) async {
    await _montar(tester, _VozFalsa());
    for (final material in TipoMaterial.values) {
      await tester.scrollUntilVisible(
        find.byKey(Key('guia-${material.codigo}')),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text(material.etiqueta), findsOneWidget);
    }
  });

  testWidgets('una categoría explica qué es, en qué se transforma y qué no '
      'se recicla, cada texto con su audio', (tester) async {
    final voz = _VozFalsa();
    await _montar(tester, voz);
    const m = TipoMaterial.plastico;
    await _tocar(tester, find.byKey(const Key('guia-plastico')));

    expect(find.text(m.descripcion), findsOneWidget);
    expect(find.text(m.productosResultantes), findsOneWidget);
    expect(find.text(m.partesNoReciclables), findsOneWidget);

    await _tocar(
      tester,
      find.byKey(const Key('guia-plastico-descripcion-audio')),
    );
    expect(voz.dichas.last, 'Plástico. ${m.descripcion}');
    await _tocar(
      tester,
      find.byKey(const Key('guia-plastico-productos-audio')),
    );
    expect(voz.dichas.last, '¿En qué se transforma? ${m.productosResultantes}');
    await _tocar(tester, find.byKey(const Key('guia-plastico-partes-audio')));
    expect(voz.dichas.last, 'Qué no se recicla. ${m.partesNoReciclables}');

    // Cerrar la categoría corta el audio.
    final antes = voz.detenciones;
    await _tocar(tester, find.text('Plástico').first);
    expect(voz.detenciones, antes + 1);
  });
}
