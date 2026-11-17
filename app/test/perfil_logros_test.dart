import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recircula/theme/app_themes.dart';
import 'package:recircula/models/usuario.dart';
import 'package:recircula/repositories/retos_repository_mock.dart';
import 'package:recircula/repositories/usuario_repository.dart';
import 'package:recircula/screens/guia_reciclaje_screen.dart';
import 'package:recircula/screens/perfil_screen.dart';
import 'package:recircula/screens/retos_screen.dart';
import 'package:recircula/services/haptica.dart';
import 'package:recircula/state/perfil_local_controller.dart';
import 'package:recircula/state/tema_controller.dart';
import 'package:recircula/state/usuario_controller.dart';
import 'package:recircula/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _UsuarioFijo implements UsuarioRepository {
  @override
  Future<Usuario> obtenerOCrear() async => Usuario(
    id: 'test',
    alias: 'Cata',
    fechaRegistro: DateTime(2026, 3, 1),
    puntosTotales: 500,
    puntosAcumulados: 524,
    racha: 6,
    objetosEscaneados: 38,
    reportesHechos: 12,
  );

  @override
  Future<Usuario> guardarDatos({required String alias, String? nombre}) =>
      obtenerOCrear();
}

Future<TemaController> _montar(
  WidgetTester tester, {
  Map<String, Object> valores = const {},
}) async {
  SharedPreferences.setMockInitialValues(valores);
  final perfil = await PerfilLocalController.cargar();
  final tema = await TemaController.cargar();
  final usuario = UsuarioController(_UsuarioFijo());
  await usuario.cargar();
  await tester.pumpWidget(
    PerfilLocalScope(
      controller: perfil,
      child: UsuarioScope(
        controller: usuario,
        child: TemaScope(
          controller: tema,
          child: MaterialApp(
            theme: AppTheme.light,
            home: PerfilScreen(retos: RetosRepositoryMock()),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return tema;
}

String? _texto(WidgetTester tester, String key) =>
    tester.widget<Text>(find.byKey(Key(key))).data;

void main() {
  testWidgets('Cabecera de nivel con saldo, avance y escalera de 5 niveles', (
    tester,
  ) async {
    await _montar(tester);

    // Sin la palabra "NIVEL" arriba del nombre; el saldo va con un bonsái.
    expect(find.textContaining('NIVEL'), findsNothing);
    expect(find.byKey(const Key('perfil-bonsai')), findsOneWidget);
    expect(_texto(tester, 'perfil-nivel-nombre'), 'Aprendiz');
    expect(_texto(tester, 'perfil-saldo'), '500');
    expect(_texto(tester, 'perfil-nivel-avance'), '524 / 600');
    expect(find.text('Te faltan 76 Rebin Points para Pro'), findsOneWidget);
    final escalera = find.byKey(const Key('perfil-escalera'));
    for (final n in ['Novato', 'Aprendiz', 'Pro', 'Experto', 'Maestro']) {
      expect(
        find.descendant(of: escalera, matching: find.text(n)),
        findsOneWidget,
      );
    }
    // Nunca kilos: objetos, reportes y días de racha.
    expect(find.text('objetos reciclados'), findsOneWidget);
    expect(find.text('38'), findsOneWidget);
    expect(find.text('días de racha'), findsOneWidget);
    expect(find.textContaining('kg'), findsNothing);
  });

  testWidgets('Las insignias son los logros reales, los conseguidos primero', (
    tester,
  ) async {
    await _montar(tester);

    // El mock tiene Vidriero (I, con el II por reclamar), Papelero I y
    // Racha I conseguidos; Guardián y Vecino aún no.
    expect(find.text('Vidriero I'), findsOneWidget);
    expect(find.text('¡Por reclamar!'), findsOneWidget);
    expect(find.text('Papelero I'), findsOneWidget);
    expect(find.byKey(const Key('perfil-insignia-l4')), findsOneWidget);
    expect(find.text('Lleva 3 más'), findsOneWidget);
    // Solo 4 de 5.
    expect(find.byKey(const Key('perfil-insignia-l5')), findsNothing);
  });

  testWidgets('"Ver todas" abre Retos en la pestaña Logros', (tester) async {
    await _montar(tester);

    await tester.tap(find.byKey(const Key('perfil-ver-insignias')));
    await tester.pumpAndSettle();

    expect(find.byType(RetosScreen), findsOneWidget);
    expect(find.byKey(const Key('logro-l1')), findsOneWidget);
    expect(find.byKey(const Key('mision-m1')), findsNothing);
  });

  testWidgets('Perfil no muestra la cifra de reportes', (tester) async {
    await _montar(tester);

    expect(find.byKey(const Key('perfil-stat-reportes')), findsNothing);
    expect(find.byKey(const Key('perfil-stat-reciclados')), findsOneWidget);
    expect(find.byKey(const Key('perfil-racha')), findsOneWidget);
  });

  testWidgets('Modo Eco cambia el tema y apagarlo vuelve al claro', (
    tester,
  ) async {
    final tema = await _montar(tester, valores: {'tema_app': 'claro'});

    final eco = find.byKey(const Key('perfil-modo-eco'));
    await tester.scrollUntilVisible(eco, 200);
    await tester.ensureVisible(eco);
    await tester.pumpAndSettle();
    await tester.tap(eco);
    await tester.pumpAndSettle();
    expect(tema.tema, TemaApp.eco);

    await tester.tap(eco);
    await tester.pumpAndSettle();
    expect(tema.tema, TemaApp.claro);
  });

  testWidgets('Vibración se apaga y se guarda', (tester) async {
    await _montar(tester);

    final vibracion = find.byKey(const Key('perfil-vibracion'));
    await tester.scrollUntilVisible(vibracion, 200);
    await tester.ensureVisible(vibracion);
    await tester.pumpAndSettle();
    await tester.tap(vibracion);
    await tester.pumpAndSettle();

    expect(Haptica.activa, isFalse);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('vibracion'), isFalse);
    await Haptica.guardar(true);
  });

  testWidgets('El Perfil abre la Guía de reciclaje', (tester) async {
    await _montar(tester);

    final guia = find.byKey(const Key('perfil-guia'));
    await tester.scrollUntilVisible(guia, 200);
    await tester.ensureVisible(guia);
    await tester.pumpAndSettle();
    await tester.tap(guia);
    await tester.pumpAndSettle();

    expect(find.byType(GuiaReciclajeScreen), findsOneWidget);
  });
}
