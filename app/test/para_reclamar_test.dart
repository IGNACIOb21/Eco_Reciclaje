import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recircula/models/reto.dart';
import 'package:recircula/models/usuario.dart';
import 'package:recircula/repositories/gamificacion_repository_mock.dart';
import 'package:recircula/repositories/retos_repository.dart';
import 'package:recircula/repositories/retos_repository_mock.dart';
import 'package:recircula/repositories/usuario_repository.dart';
import 'package:recircula/screens/para_reclamar_screen.dart';
import 'package:recircula/state/perfil_local_controller.dart';
import 'package:recircula/state/usuario_controller.dart';
import 'package:recircula/theme/app_theme.dart';
import 'package:recircula/widgets/resumen_inicio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _UsuarioFijo implements UsuarioRepository {
  @override
  Future<Usuario> obtenerOCrear() async => Usuario(
    id: 'test',
    alias: 'Usuario Rebin',
    fechaRegistro: DateTime(2026, 9, 15),
    puntosTotales: 524,
  );

  @override
  Future<Usuario> guardarDatos({required String alias, String? nombre}) =>
      obtenerOCrear();
}

/// Retos sin nada que reclamar.
class _RetosVacios implements RetosRepository {
  @override
  Future<Retos> retos() async => const Retos(misiones: [], logros: []);

  @override
  Future<int> reclamarMision(String idMision) async => 0;

  @override
  Future<int> reclamarLogro(String idLogro) async => 0;
}

Future<UsuarioController> _usuario() async {
  SharedPreferences.setMockInitialValues({});
  final u = UsuarioController(_UsuarioFijo());
  await u.cargar();
  return u;
}

/// El reflejo dorado corre en bucle y `pumpAndSettle` nunca terminaría: los
/// tests lo apagan como lo haría "reducir animaciones" del sistema.
void _sinAnimaciones(WidgetTester tester) {
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      const FakeAccessibilityFeatures(disableAnimations: true);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
}

Future<void> _montarPantalla(
  WidgetTester tester,
  RetosRepository retos,
  GamificacionRepositoryMock gam,
) async {
  _sinAnimaciones(tester);
  final usuario = await _usuario();
  await tester.pumpWidget(
    UsuarioScope(
      controller: usuario,
      child: MaterialApp(
        theme: AppTheme.light,
        home: ParaReclamarScreen(retos: retos, gamificacion: gam),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Lista logros y misiones listas, y reclamar pasa el logro a '
      'Ya reclamadas', (tester) async {
    await _montarPantalla(
      tester,
      RetosRepositoryMock(),
      GamificacionRepositoryMock(),
    );
    // Vidriero alcanzó el nivel II sin reclamar y la misión m1 está lista.
    expect(find.text('Insignia Vidriero II'), findsOneWidget);
    expect(find.text('Recicla 3 materiales distintos'), findsOneWidget);
    expect(find.text('Reclamar +10 Rebin Points'), findsNWidgets(2));

    await tester.tap(find.byKey(const Key('reclamar-logro-l1')));
    await tester.pumpAndSettle();
    expect(find.text('Insignia Vidriero II'), findsNothing);
    // Ya reclamadas queda abajo: el nivel I seguía ahí y ahora suma el II.
    await tester.scrollUntilVisible(
      find.byKey(const Key('reclamada-l1-1')),
      200,
    );
    expect(find.byKey(const Key('reclamada-l1-0')), findsOneWidget);
  });

  testWidgets('Abrir la sorpresa muestra +3 y no se puede abrir de nuevo', (
    tester,
  ) async {
    final gam = GamificacionRepositoryMock();
    await _montarPantalla(tester, _RetosVacios(), gam);
    expect(find.text('Aparece algunos días, sin aviso.'), findsOneWidget);

    await tester.tap(find.byKey(const Key('abrir-sorpresa')));
    await tester.pumpAndSettle();
    expect(find.text('+3 Rebin Points'), findsOneWidget);
    expect(find.byKey(const Key('abrir-sorpresa')), findsNothing);
    expect(gam.sorpresaAbierta, isTrue);
  });

  testWidgets('Sin sorpresa hoy no se muestra su tarjeta', (tester) async {
    await _montarPantalla(
      tester,
      _RetosVacios(),
      GamificacionRepositoryMock(sorpresaDisponible: false),
    );
    expect(find.byKey(const Key('sorpresa-hoy')), findsNothing);
    expect(find.byKey(const Key('para-reclamar-vacio')), findsOneWidget);
  });

  Future<void> montarInicio(
    WidgetTester tester,
    RetosRepository retos,
    GamificacionRepositoryMock gam,
  ) async {
    _sinAnimaciones(tester);
    final perfil = await PerfilLocalController.cargar();
    final usuario = await _usuario();
    await tester.pumpWidget(
      PerfilLocalScope(
        controller: perfil,
        child: UsuarioScope(
          controller: usuario,
          child: MaterialApp(
            theme: AppTheme.light,
            home: Scaffold(
              body: SingleChildScrollView(
                child: ResumenInicio(gamificacion: gam, retos: retos),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('Inicio muestra la píldora con cuántas cosas hay por reclamar', (
    tester,
  ) async {
    // 1 logro + 1 misión lista + 1 sorpresa por abrir.
    await montarInicio(
      tester,
      RetosRepositoryMock(),
      GamificacionRepositoryMock(),
    );
    expect(find.text('3 para reclamar'), findsOneWidget);

    await tester.tap(find.byKey(const Key('inicio-para-reclamar')));
    await tester.pumpAndSettle();
    expect(find.text('Para reclamar'), findsOneWidget);
  });

  testWidgets('Sin nada por reclamar la píldora de Inicio no aparece', (
    tester,
  ) async {
    await montarInicio(
      tester,
      _RetosVacios(),
      GamificacionRepositoryMock(sorpresaDisponible: false),
    );
    expect(find.byKey(const Key('inicio-para-reclamar')), findsNothing);
    expect(find.textContaining('para reclamar'), findsNothing);
  });
}
