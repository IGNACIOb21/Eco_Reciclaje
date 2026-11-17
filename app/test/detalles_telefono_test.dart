import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recircula/models/usuario.dart';
import 'package:recircula/repositories/retos_repository_mock.dart';
import 'package:recircula/repositories/usuario_repository.dart';
import 'package:recircula/screens/perfil_screen.dart';
import 'package:recircula/state/perfil_local_controller.dart';
import 'package:recircula/state/tema_controller.dart';
import 'package:recircula/state/usuario_controller.dart';
import 'package:recircula/theme/app_themes.dart';
import 'package:recircula/theme/app_theme.dart';
import 'package:recircula/widgets/boton_app.dart';
import 'package:recircula/widgets/brillo_recompensa.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Falla las primeras [fallas] veces con [error] y después responde.
class _UsuarioQueFalla implements UsuarioRepository {
  int fallas;
  final Object error;
  int llamadas = 0;

  _UsuarioQueFalla(this.fallas, this.error);

  @override
  Future<Usuario> obtenerOCrear() async {
    llamadas++;
    if (fallas > 0) {
      fallas--;
      throw error;
    }
    return Usuario(
      id: 'u',
      alias: 'Cata',
      fechaRegistro: DateTime(2026, 3, 1),
      puntosTotales: 15,
    );
  }

  @override
  Future<Usuario> guardarDatos({required String alias, String? nombre}) =>
      obtenerOCrear();
}

void main() {
  group('Reintento del token recién emitido (PGRST303)', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('lo reconoce aunque venga envuelto', () {
      expect(
        esTokenDelFuturo(Exception('ParallelWaitError: PGRST303')),
        isTrue,
      );
      expect(esTokenDelFuturo(Exception('JWT issued at future')), isTrue);
      expect(esTokenDelFuturo(Exception('sin conexión')), isFalse);
    });

    test('reintenta una vez y carga al usuario', () async {
      final repo = _UsuarioQueFalla(
        1,
        Exception('JWT issued at future (PGRST303)'),
      );
      final c = UsuarioController(repo);
      await c.cargar();
      expect(repo.llamadas, 2);
      expect(c.usuario?.puntosTotales, 15);
      expect(c.error, isNull);
    });

    test('otro error no se reintenta', () async {
      final repo = _UsuarioQueFalla(1, Exception('sin conexión'));
      final c = UsuarioController(repo);
      await c.cargar();
      expect(repo.llamadas, 1);
      expect(c.error, isNotNull);
    });
  });

  testWidgets('El botón con reflejo ocupa todo el ancho que le dan', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 300,
              child: BrilloRecompensa(
                child: BotonApp(
                  texto: 'Abrir',
                  variante: VarianteBoton.recompensa,
                  onPressed: () {},
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(tester.getSize(find.byType(BotonApp)).width, 300);
  });

  test('Las pestañas usan el verde legible en todos los temas', () {
    for (final tema in TemaApp.values) {
      final colores = tema.datos.extension<ColoresApp>()!;
      expect(
        tema.datos.tabBarTheme.labelColor,
        colores.primarioTexto,
        reason: tema.nombre,
      );
    }
  });

  testWidgets('Con letra al 200 % las cifras del Perfil van una bajo otra', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});
    final usuario = UsuarioController(_UsuarioQueFalla(0, Exception()));
    await usuario.cargar();
    await tester.pumpWidget(
      PerfilLocalScope(
        controller: await PerfilLocalController.cargar(),
        child: UsuarioScope(
          controller: usuario,
          child: TemaScope(
            controller: await TemaController.cargar(),
            child: MaterialApp(
              theme: AppTheme.light,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: const TextScaler.linear(2)),
                child: child!,
              ),
              home: PerfilScreen(retos: RetosRepositoryMock()),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const Key('perfil-racha')),
      200,
    );

    final reciclados = tester.getTopLeft(
      find.byKey(const Key('perfil-stat-reciclados')),
    );
    final reportes = tester.getTopLeft(
      find.byKey(const Key('perfil-racha')),
    );
    expect(reportes.dy, greaterThan(reciclados.dy));
    expect(reportes.dx, reciclados.dx);
    expect(tester.takeException(), isNull);
  });
}
