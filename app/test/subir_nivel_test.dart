import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recircula/main.dart';
import 'package:recircula/models/nivel.dart';
import 'package:recircula/models/usuario.dart';
import 'package:recircula/repositories/puntos_repository_mock.dart';
import 'package:recircula/repositories/usuario_repository.dart';
import 'package:recircula/screens/celebracion_nivel_screen.dart';
import 'package:recircula/state/perfil_local_controller.dart';
import 'package:recircula/state/primer_inicio_controller.dart';
import 'package:recircula/state/tema_controller.dart';
import 'package:recircula/state/usuario_controller.dart';
import 'package:recircula/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Usuario cuyos puntos acumulados cambia el test entre cargas.
class _UsuarioVariable implements UsuarioRepository {
  int acumulados;
  String id;
  bool sinConexion = false;

  _UsuarioVariable(this.acumulados, {this.id = 'cata'});

  @override
  Future<Usuario> obtenerOCrear() async {
    if (sinConexion) throw Exception('sin conexión');
    return Usuario(
      id: id,
      alias: 'Cata',
      fechaRegistro: DateTime(2026, 3, 1),
      puntosTotales: acumulados,
      puntosAcumulados: acumulados,
    );
  }

  @override
  Future<Usuario> guardarDatos({required String alias, String? nombre}) =>
      obtenerOCrear();
}

void main() {
  group('UsuarioController detecta la subida de nivel', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('la primera carga de una cuenta no celebra lo que ya tenía', () async {
      final c = UsuarioController(_UsuarioVariable(700));
      await c.cargar();
      expect(c.nivelPorCelebrar, isNull);
    });

    test('al pasar de Aprendiz a Pro avisa una sola vez', () async {
      final repo = _UsuarioVariable(594);
      final c = UsuarioController(repo);
      await c.cargar();

      repo.acumulados = 600;
      await c.cargar();
      expect(c.nivelPorCelebrar, const Nivel('Pro', 600));

      c.celebracionMostrada();
      expect(c.nivelPorCelebrar, isNull);
      await c.cargar();
      expect(c.nivelPorCelebrar, isNull);
    });

    test('el nivel visto se guarda en el teléfono entre arranques', () async {
      final repo = _UsuarioVariable(594);
      await UsuarioController(repo).cargar();

      // Otro arranque, ya con más puntos.
      repo.acumulados = 650;
      final c = UsuarioController(repo);
      await c.cargar();
      expect(c.nivelPorCelebrar?.nombre, 'Pro');
    });

    test('otra cuenta en el mismo teléfono no hereda el nivel', () async {
      await UsuarioController(_UsuarioVariable(0, id: 'otra')).cargar();
      final c = UsuarioController(_UsuarioVariable(700));
      await c.cargar();
      expect(c.nivelPorCelebrar, isNull);
    });

    test('sin conexión no celebra con la copia guardada', () async {
      final repo = _UsuarioVariable(594);
      final c = UsuarioController(repo);
      await c.cargar();
      repo.sinConexion = true;
      await c.cargar();
      expect(c.nivelPorCelebrar, isNull);
    });
  });

  group('Pantalla de celebración', () {
    Future<void> montar(WidgetTester tester, Nivel nivel, int acumulado) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: child!,
          ),
          home: CelebracionNivelScreen(
            nivel: nivel,
            niveles: Nivel.porDefecto,
            acumulado: acumulado,
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('dice el nivel, sus puntos y cuánto falta para el siguiente', (
      tester,
    ) async {
      await montar(tester, const Nivel('Pro', 600), 600);

      expect(find.text('¡Subiste a Pro!'), findsOneWidget);
      expect(find.text('nivel 3'), findsOneWidget);
      expect(find.textContaining('600 Rebin Points.'), findsOneWidget);
      expect(find.text('Próximo: Experto'), findsOneWidget);
      expect(find.textContaining('Te faltan 900 Rebin Points'), findsOneWidget);
    });

    testWidgets('en Maestro no hay siguiente nivel', (tester) async {
      await montar(tester, const Nivel('Maestro', 3000), 3100);

      expect(find.text('¡Subiste a Maestro!'), findsOneWidget);
      expect(find.text('Nivel máximo'), findsOneWidget);
    });
  });

  testWidgets('El MainShell celebra al subir de nivel y "Seguir" la cierra', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({
      'primer_inicio_completado': true,
      'onboarding_visto': true,
    });
    final repo = _UsuarioVariable(594);
    final usuario = UsuarioController(repo);
    await usuario.cargar();
    await tester.pumpWidget(
      RecirculaApp(
        perfilLocal: await PerfilLocalController.cargar(),
        usuario: usuario,
        primerInicio: await PrimerInicioController.cargar(),
        tema: await TemaController.cargar(),
        puntosRepository: PuntosRepositoryMock(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(CelebracionNivelScreen), findsNothing);

    // Un depósito o un reclamo lo dejan en 600: llega Pro.
    repo.acumulados = 600;
    await usuario.cargar();
    await tester.pumpAndSettle();
    expect(find.text('¡Subiste a Pro!'), findsOneWidget);

    await tester.tap(find.byKey(const Key('celebracion-seguir')));
    await tester.pumpAndSettle();
    expect(find.byType(CelebracionNivelScreen), findsNothing);
    expect(usuario.nivelPorCelebrar, isNull);
  });

  testWidgets('Con otra pantalla encima, celebra recién al volver', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({
      'primer_inicio_completado': true,
      'onboarding_visto': true,
    });
    final repo = _UsuarioVariable(594);
    final usuario = UsuarioController(repo);
    await usuario.cargar();
    await tester.pumpWidget(
      RecirculaApp(
        perfilLocal: await PerfilLocalController.cargar(),
        usuario: usuario,
        primerInicio: await PrimerInicioController.cargar(),
        tema: await TemaController.cargar(),
        puntosRepository: PuntosRepositoryMock(),
      ),
    );
    await tester.pumpAndSettle();

    // Una pantalla encima, como el flujo Reciclar.
    final navegador = tester.state<NavigatorState>(find.byType(Navigator));
    navegador.push(
      MaterialPageRoute<void>(
        builder: (_) => const Scaffold(body: Text('Encima')),
      ),
    );
    await tester.pumpAndSettle();

    repo.acumulados = 600;
    await usuario.cargar();
    await tester.pumpAndSettle();
    expect(find.byType(CelebracionNivelScreen), findsNothing);
    expect(usuario.nivelPorCelebrar, isNotNull);

    navegador.pop();
    await tester.pumpAndSettle();
    expect(find.text('¡Subiste a Pro!'), findsOneWidget);
  });
}
