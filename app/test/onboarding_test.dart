import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recircula/models/perfil_local.dart';
import 'package:recircula/repositories/usuario_repository_mock.dart';
import 'package:recircula/screens/bienvenida_screen.dart';
import 'package:recircula/state/perfil_local_controller.dart';
import 'package:recircula/state/primer_inicio_controller.dart';
import 'package:recircula/state/usuario_controller.dart';
import 'package:recircula/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Monta la bienvenida de una instalación nueva. Con [animaciones] en false
/// simula "reducir animaciones" (las esquinas no respiran y pumpAndSettle
/// termina).
Future<(PerfilLocalController, PrimerInicioController)> _montar(
  WidgetTester tester, {
  bool animaciones = false,
}) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 2.75;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  SharedPreferences.setMockInitialValues({});
  final perfil = await PerfilLocalController.cargar();
  final primerInicio = await PrimerInicioController.cargar();
  final usuario = UsuarioController(UsuarioRepositoryMock());
  await tester.pumpWidget(
    UsuarioScope(
      controller: usuario,
      child: PerfilLocalScope(
        controller: perfil,
        child: PrimerInicioScope(
          controller: primerInicio,
          child: MaterialApp(
            theme: AppTheme.light,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(disableAnimations: !animaciones),
              child: child!,
            ),
            home: const BienvenidaScreen(),
          ),
        ),
      ),
    ),
  );
  return (perfil, primerInicio);
}

void main() {
  testWidgets('Una instalación nueva parte en la primera lámina', (
    tester,
  ) async {
    await _montar(tester);
    await tester.pumpAndSettle();

    expect(find.text('Apunta y sabrás si se recicla'), findsOneWidget);
    expect(find.text('Saltar'), findsOneWidget);
    expect(find.text('Siguiente'), findsOneWidget);
    // Todavía no el acceso.
    expect(find.text('Omitir'), findsNothing);

    await tester.tap(find.text('Siguiente'));
    await tester.pumpAndSettle();
    expect(find.text('Encuentra dónde dejarlo'), findsOneWidget);
  });

  testWidgets('Saltar lleva a la última lámina para elegir avatar', (
    tester,
  ) async {
    await _montar(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('onboarding-saltar')));
    await tester.pumpAndSettle();

    expect(find.text('Haz crecer tu planta'), findsOneWidget);
    expect(find.text('Empezar'), findsOneWidget);
    expect(find.text('Saltar'), findsNothing);
    expect(find.byKey(const Key('onboarding-avatar-0')), findsOneWidget);
  });

  testWidgets('Empezar guarda el avatar y abre el acceso una sola vez', (
    tester,
  ) async {
    final (perfil, primerInicio) = await _montar(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('onboarding-saltar')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('onboarding-avatar-2')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Empezar'));
    await tester.pumpAndSettle();

    // Sigue el acceso de siempre.
    expect(find.text('Omitir'), findsOneWidget);
    expect(perfil.perfil.avatarIcono, AvatarIcono.sol);
    expect(perfil.perfil.avatarColorIndex, 2);
    expect(primerInicio.onboardingVisto, isTrue);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('onboarding_visto'), isTrue);
    // El primer inicio no se completa hasta pasar por el acceso.
    expect(primerInicio.completado, isFalse);
  });

  testWidgets('Con animaciones, las láminas se dibujan sin errores', (
    tester,
  ) async {
    await _montar(tester, animaciones: true);
    // Las esquinas respiran en bucle: se avanzan unos cuadros a mano.
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Apunta y sabrás si se recicla'), findsOneWidget);

    Future<void> avanzar() async {
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    await tester.tap(find.text('Siguiente'));
    await avanzar();
    await tester.tap(find.text('Siguiente'));
    await avanzar();
    expect(find.text('Haz crecer tu planta'), findsOneWidget);
  });
}
