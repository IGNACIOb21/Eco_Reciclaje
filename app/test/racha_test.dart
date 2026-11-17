import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recircula/models/usuario.dart';
import 'package:recircula/repositories/gamificacion_repository_mock.dart';
import 'package:recircula/repositories/usuario_repository.dart';
import 'package:recircula/screens/racha_screen.dart';
import 'package:recircula/state/usuario_controller.dart';
import 'package:recircula/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _UsuarioFijo implements UsuarioRepository {
  final int puntos;

  _UsuarioFijo([this.puntos = 524]);

  @override
  Future<Usuario> obtenerOCrear() async => Usuario(
    id: 'test',
    alias: 'Usuario Rebin',
    fechaRegistro: DateTime(2026, 9, 15),
    puntosTotales: puntos,
  );

  @override
  Future<Usuario> guardarDatos({required String alias, String? nombre}) =>
      obtenerOCrear();
}

Future<void> _montar(
  WidgetTester tester,
  GamificacionRepositoryMock repo, {
  int saldo = 524,
}) async {
  SharedPreferences.setMockInitialValues({});
  final usuario = UsuarioController(_UsuarioFijo(saldo));
  await usuario.cargar();
  await tester.pumpWidget(
    UsuarioScope(
      controller: usuario,
      child: MaterialApp(
        theme: AppTheme.light,
        home: RachaScreen(repositorio: repo),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Muestra los días, la mejor racha y la semana con sus estados', (
    tester,
  ) async {
    final semantica = tester.ensureSemantics();
    await _montar(tester, GamificacionRepositoryMock());
    expect(find.text('6 días'), findsOneWidget);
    expect(find.text('Tu mejor racha: 12 días'), findsOneWidget);
    expect(find.byKey(const Key('racha-dia-0-hecho')), findsOneWidget);
    expect(find.byKey(const Key('racha-dia-2-congelado')), findsOneWidget);
    expect(find.byKey(const Key('racha-dia-3-hoy')), findsOneWidget);
    expect(find.byKey(const Key('racha-dia-4-futuro')), findsOneWidget);
    expect(find.bySemanticsLabel('miércoles: congelado'), findsOneWidget);
    expect(find.text('Tienes 1 guardado.'), findsOneWidget);
    semantica.dispose();
  });

  testWidgets('Canjear con saldo suma un congelador', (tester) async {
    final repo = GamificacionRepositoryMock();
    await _montar(tester, repo);
    await tester.tap(find.text('Canjear otro por 20 Rebin Points'));
    await tester.pumpAndSettle();
    expect(find.text('Usa 20 de tus 524 Rebin Points.'), findsOneWidget);

    await tester.tap(find.text('Canjear'));
    await tester.pumpAndSettle();
    expect(repo.congeladores, 2);
    expect(find.text('Tienes 2 guardados.'), findsOneWidget);
    expect(find.text('Ya tienes el máximo (2)'), findsOneWidget);
    expect(find.text('Guardaste un congelador'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('Sin saldo avisa y no suma el congelador', (tester) async {
    final repo = GamificacionRepositoryMock(saldo: 5);
    await _montar(tester, repo);
    await tester.tap(find.text('Canjear otro por 20 Rebin Points'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Canjear'));
    await tester.pumpAndSettle();
    expect(find.text('Te faltan Rebin Points para canjearlo'), findsOneWidget);
    expect(repo.congeladores, 1);
  });

  testWidgets('Sin congeladores en la base (máximo 0) no se muestran', (
    tester,
  ) async {
    await _montar(
      tester,
      GamificacionRepositoryMock(congeladores: 0, maxCongeladores: 0),
    );
    expect(find.text('Congelar racha'), findsNothing);
    expect(find.byKey(const Key('racha-congeladores')), findsNothing);
    expect(find.textContaining('Ya tienes el máximo'), findsNothing);
  });

  testWidgets('Con el máximo el botón está deshabilitado', (tester) async {
    await _montar(tester, GamificacionRepositoryMock(congeladores: 2));
    final boton = find.text('Ya tienes el máximo (2)');
    expect(boton, findsOneWidget);
    await tester.tap(boton);
    await tester.pumpAndSettle();
    expect(find.textContaining('Usa 20'), findsNothing);
  });

  testWidgets('El recordatorio se guarda y avisa que aún no hay avisos', (
    tester,
  ) async {
    await _montar(tester, GamificacionRepositoryMock());
    await tester.scrollUntilVisible(
      find.byKey(const Key('racha-recordatorio')),
      200,
    );
    expect(find.text('Pronto: aún no enviamos avisos'), findsOneWidget);
    await tester.tap(find.byKey(const Key('racha-recordatorio')));
    await tester.pumpAndSettle();
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('recordatorio_racha'), isFalse);
  });

  testWidgets('Sin congeladores dice "uno", no "otro"', (tester) async {
    await _montar(tester, GamificacionRepositoryMock(congeladores: 0));
    expect(find.text('No tienes ninguno guardado.'), findsOneWidget);
    expect(find.text('Canjear uno por 20 Rebin Points'), findsOneWidget);
  });

  testWidgets('Si el saldo no alcanza, lo dice y no deja canjear', (
    tester,
  ) async {
    await _montar(
      tester,
      GamificacionRepositoryMock(congeladores: 0),
      saldo: 15,
    );
    final boton = find.text('Te faltan 5 Rebin Points para uno');
    expect(boton, findsOneWidget);
    await tester.tap(boton);
    await tester.pumpAndSettle();
    expect(find.textContaining('Usa 20'), findsNothing);
  });

  testWidgets('Con la racha en cero el aviso no dice "0 días"', (tester) async {
    await _montar(tester, GamificacionRepositoryMock(racha: 0));
    await tester.scrollUntilVisible(
      find.textContaining('Hoy puede brotar tu planta'),
      200,
    );
    expect(find.textContaining('va en 0'), findsNothing);
    expect(find.textContaining('Hoy puede brotar tu planta'), findsOneWidget);
  });
}
