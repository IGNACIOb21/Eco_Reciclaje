import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recircula/models/comunidad_hoy.dart';
import 'package:recircula/repositories/comunidad_repository_mock.dart';
import 'package:recircula/repositories/retos_repository_mock.dart';
import 'package:recircula/repositories/usuario_repository_mock.dart';
import 'package:recircula/screens/comunidad_screen.dart';
import 'package:recircula/state/perfil_local_controller.dart';
import 'package:recircula/state/usuario_controller.dart';
import 'package:recircula/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Mock sin meta definida para el mes.
class _SinMeta extends ComunidadRepositoryMock {
  @override
  Future<MetaComuna> metaComuna(String comuna) async => MetaComuna(
    comuna: comuna,
    objetivo: null,
    actual: 12,
    vecinos: 3,
    tuAporte: 0,
    diasRestantes: 9,
  );
}

Future<void> _montar(
  WidgetTester tester, {
  ComunidadRepositoryMock? repo,
}) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 2.75;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  SharedPreferences.setMockInitialValues({});
  final perfil = await PerfilLocalController.cargar();
  final usuario = UsuarioController(UsuarioRepositoryMock());
  await tester.pumpWidget(
    PerfilLocalScope(
      controller: perfil,
      child: UsuarioScope(
        controller: usuario,
        child: MaterialApp(
          theme: AppTheme.light,
          home: ComunidadScreen(
            repositorio: repo ?? ComunidadRepositoryMock(),
            retos: RetosRepositoryMock(),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  test('"hace cuánto" en palabras', () {
    final ahora = DateTime(2026, 10, 21, 12);
    expect(
      haceCuanto(ahora.subtract(const Duration(minutes: 20)), ahora),
      'hace 20 min',
    );
    expect(
      haceCuanto(ahora.subtract(const Duration(hours: 3)), ahora),
      'hace 3 h',
    );
    expect(haceCuanto(ahora.subtract(const Duration(days: 1)), ahora), 'ayer');
  });

  testWidgets('Hay cuatro pestañas y Grupos sigue ahí', (tester) async {
    await _montar(tester);
    for (final t in ['Hoy', 'Actividad', 'Ranking', 'Grupos']) {
      expect(find.widgetWithText(Tab, t), findsOneWidget);
    }
  });

  testWidgets('Hoy muestra la meta de la comuna en objetos, nunca en kg', (
    tester,
  ) async {
    await _montar(tester);

    expect(
      find.text('Juntos, 2.500 objetos reciclados este mes'),
      findsOneWidget,
    );
    expect(find.text('1.710 objetos'), findsOneWidget);
    expect(find.text('Tú aportaste 38 objetos este mes.'), findsOneWidget);
    expect(find.textContaining('kg'), findsNothing);
    // La misión más avanzada de la semana. Eco Reciclaje no tiene
    // sugerencias de puntos: no aparece el acceso a confirmarlas.
    expect(find.byKey(const Key('comunidad-mision')), findsOneWidget);
    expect(find.text('Por confirmar cerca de ti'), findsNothing);
  });

  testWidgets('Sin meta del mes lo dice y muestra lo reciclado', (
    tester,
  ) async {
    await _montar(tester, repo: _SinMeta());

    expect(find.text('Aún no hay una meta este mes'), findsOneWidget);
    expect(
      find.text('Este mes los vecinos reciclaron 12 objetos.'),
      findsOneWidget,
    );
  });

  testWidgets('Actividad lista lo último del barrio', (tester) async {
    await _montar(tester);
    await tester.tap(find.widgetWithText(Tab, 'Actividad'));
    await tester.pumpAndSettle();

    expect(find.text('Lo último en tu barrio'), findsOneWidget);
    expect(
      find.textContaining('se reciclaron 9 objetos', findRichText: true),
      findsOneWidget,
    );
  });

  testWidgets('Ranking destaca tu fila y permite salir y volver', (
    tester,
  ) async {
    final repo = ComunidadRepositoryMock();
    await _montar(tester, repo: repo);
    await tester.tap(find.widgetWithText(Tab, 'Ranking'));
    await tester.pumpAndSettle();

    expect(find.text('Tú (tú)'), findsOneWidget);
    await tester.tap(find.text('Salir del ranking'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Salir'));
    await tester.pumpAndSettle();

    expect(repo.oculto, isTrue);
    expect(find.text('Tú (tú)'), findsNothing);
    expect(find.text('Volver a aparecer en el ranking'), findsOneWidget);
  });
}
