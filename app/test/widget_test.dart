import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:recircula/data/comunas_demo.dart';
import 'package:recircula/data/mock_puntos.dart';
import 'package:recircula/main.dart';
import 'package:recircula/models/usuario.dart';
import 'package:recircula/repositories/cuenta_repository_mock.dart';
import 'package:recircula/repositories/puntos_repository_mock.dart';
import 'package:recircula/repositories/usuario_repository.dart';
import 'package:recircula/repositories/usuario_repository_mock.dart';
import 'package:recircula/screens/registro_cuenta_screen.dart';
import 'package:recircula/state/perfil_local_controller.dart';
import 'package:recircula/state/usuario_controller.dart';
import 'package:recircula/theme/app_theme.dart';
import 'package:recircula/utils/geo.dart';
import 'package:recircula/widgets/punto_card.dart';

void _usarTamanoDeTelefono(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

class _UsuarioRepositoryFijo implements UsuarioRepository {
  final int puntos;
  String? nombre;
  String alias = 'Usuario Rebin';
  _UsuarioRepositoryFijo(this.puntos, {this.nombre = 'Test'});

  @override
  Future<Usuario> obtenerOCrear() async => Usuario(
    id: 'test',
    nombre: nombre,
    alias: alias,
    fechaRegistro: DateTime(2026, 9, 15),
    puntosTotales: puntos,
  );

  @override
  Future<Usuario> guardarDatos({
    required String nombre,
    required String alias,
  }) async {
    this.nombre = nombre;
    this.alias = alias;
    return obtenerOCrear();
  }
}

class _UsuarioRepositoryConError implements UsuarioRepository {
  @override
  Future<Usuario> obtenerOCrear() async => throw Exception('sin conexión');

  @override
  Future<Usuario> guardarDatos({
    required String nombre,
    required String alias,
  }) async => throw Exception('sin conexión');
}

Future<PerfilLocalController> _montarApp(
  WidgetTester tester, {
  UsuarioRepository? usuarioRepository,
}) async {
  _usarTamanoDeTelefono(tester);
  SharedPreferences.setMockInitialValues({});
  final perfil = await PerfilLocalController.cargar();
  final usuario = UsuarioController(
    usuarioRepository ?? UsuarioRepositoryMock(),
  )..cargar();
  await tester.pumpWidget(
    RecirculaApp(
      perfilLocal: perfil,
      usuario: usuario,
      puntosRepository: PuntosRepositoryMock(),
    ),
  );
  await tester.pumpAndSettle();
  return perfil;
}

/// Puntos dentro del radio por defecto (5 km) desde el centro por defecto
/// (Plaza Ñuñoa), replicando el filtro que aplica MapaScreen.
int _puntosEnRadioPorDefecto({String? comuna}) {
  return mockPuntos.where((p) {
    if (comuna != null && p.comuna != comuna) return false;
    return distanciaKm(centroDefectoLat, centroDefectoLng, p.lat, p.lng) <= 5;
  }).length;
}

void main() {
  testWidgets('Inicio muestra el saludo anónimo y el resumen del mapa', (
    tester,
  ) async {
    await _montarApp(tester);

    expect(find.text('Mapa de reciclaje'), findsOneWidget);
    expect(find.text('¡Hola!'), findsOneWidget);
  });

  testWidgets('El tab Mapa muestra los puntos y abre la ficha al tocar uno', (
    tester,
  ) async {
    await _montarApp(tester);

    await tester.tap(find.byIcon(Icons.map_outlined));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.tune), findsOneWidget);
    expect(
      find.text('${_puntosEnRadioPorDefecto()} puntos cerca de ti'),
      findsOneWidget,
    );

    await tester.tap(find.byType(PuntoCard).first);
    await tester.pumpAndSettle();

    expect(find.text('Cómo llegar'), findsOneWidget);
    expect(find.text('Reportar estado'), findsOneWidget);
  });

  testWidgets('El filtro de comuna en Filtros reduce los puntos mostrados', (
    tester,
  ) async {
    await _montarApp(tester);

    await tester.tap(find.byIcon(Icons.map_outlined));
    await tester.pumpAndSettle();

    final conteoInicial = _puntosEnRadioPorDefecto();
    final conteoLasCondes = _puntosEnRadioPorDefecto(comuna: 'Las Condes');
    expect(conteoLasCondes, lessThan(conteoInicial));

    await tester.tap(find.byIcon(Icons.tune));
    await tester.pumpAndSettle();

    expect(find.text('Filtros'), findsOneWidget);
    expect(find.text('Comuna'), findsOneWidget);

    await tester.tap(find.widgetWithText(ChoiceChip, 'Las Condes'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Aplicar filtros'));
    await tester.pumpAndSettle();

    expect(find.text('$conteoLasCondes puntos cerca de ti'), findsOneWidget);
  });

  testWidgets('Limpiar en Filtros vuelve a mostrar el estado sin filtros', (
    tester,
  ) async {
    await _montarApp(tester);

    await tester.tap(find.byIcon(Icons.map_outlined));
    await tester.pumpAndSettle();

    final conteoInicial = _puntosEnRadioPorDefecto();

    await tester.tap(find.byIcon(Icons.tune));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ChoiceChip, 'Macul'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Aplicar filtros'));
    await tester.pumpAndSettle();

    expect(find.text('$conteoInicial puntos cerca de ti'), findsNothing);

    await tester.tap(find.byIcon(Icons.tune));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Limpiar'));
    await tester.pumpAndSettle();

    expect(find.text('$conteoInicial puntos cerca de ti'), findsOneWidget);
  });

  testWidgets(
    'Personalizar el nombre se refleja en Perfil e Inicio y se persiste',
    (tester) async {
      final controller = await _montarApp(tester);

      await tester.tap(find.byIcon(Icons.person_outline));
      await tester.pumpAndSettle();
      expect(find.text('Usuario anónimo'), findsOneWidget);

      await tester.tap(find.text('Personalizar perfil'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Camila');
      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();

      expect(find.text('Camila'), findsOneWidget);
      expect(controller.perfil.nombre, 'Camila');

      await tester.tap(find.byIcon(Icons.home_outlined));
      await tester.pumpAndSettle();
      expect(find.text('Hola, Camila'), findsOneWidget);

      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs.getString('perfil_local_${controller.clave}'),
        contains('Camila'),
      );
    },
  );

  testWidgets(
    'Perfil muestra puntos, nivel y fecha de alta del usuario remoto',
    (tester) async {
      await _montarApp(tester, usuarioRepository: _UsuarioRepositoryFijo(158));

      await tester.tap(find.byIcon(Icons.person_outline));
      await tester.pumpAndSettle();

      expect(find.text('Nivel Recicla-Pro'), findsOneWidget);
      expect(find.text('158/200 pts'), findsOneWidget);
      expect(
        find.textContaining('Reciclando desde septiembre 2026'),
        findsOneWidget,
      );
      final barra = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(barra.value, closeTo((158 - 130) / (200 - 130), 0.001));
    },
  );

  testWidgets('Perfil ofrece reintentar si no se pudo cargar el usuario', (
    tester,
  ) async {
    await _montarApp(tester, usuarioRepository: _UsuarioRepositoryConError());

    await tester.tap(find.byIcon(Icons.person_outline));
    await tester.pumpAndSettle();

    expect(find.text('No pudimos cargar tus puntos.'), findsOneWidget);
    expect(find.text('Reintentar'), findsOneWidget);
  });

  testWidgets('El switch de Modo Eco cambia el tema de toda la app', (
    tester,
  ) async {
    await _montarApp(tester);

    await tester.tap(find.byIcon(Icons.person_outline));
    await tester.pumpAndSettle();

    ThemeData temaActual() => Theme.of(tester.element(find.text('Modo Eco')));
    expect(
      temaActual().scaffoldBackgroundColor,
      AppTheme.light.scaffoldBackgroundColor,
    );

    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();

    expect(
      temaActual().scaffoldBackgroundColor,
      AppTheme.eco.scaffoldBackgroundColor,
    );
    expect(temaActual().brightness, Brightness.dark);
  });

  testWidgets('Comunidad permite unirse al grupo de la comuna y publicar', (
    tester,
  ) async {
    await _montarApp(tester);

    await tester.tap(find.byIcon(Icons.groups_outlined).first);
    await tester.pumpAndSettle();

    expect(find.text('Vecinos Reciclan Ñuñoa'), findsOneWidget);
    expect(
      find.text('Únete a la comunidad para publicar anuncios.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Unirse'));
    await tester.pumpAndSettle();
    expect(find.text('Miembro'), findsOneWidget);

    await tester.enterText(
      find.byType(TextField),
      'El sábado juntamos vidrio en la plaza',
    );
    await tester.tap(find.byIcon(Icons.send));
    await tester.pumpAndSettle();
    expect(find.text('El sábado juntamos vidrio en la plaza'), findsOneWidget);
    expect(find.text('Usuario anónimo (tú)'), findsOneWidget);
  });

  testWidgets('Comunidad ofrece crear grupo cuando la comuna no tiene uno', (
    tester,
  ) async {
    final controller = await _montarApp(tester);
    await controller.actualizar(controller.perfil.copyWith(comuna: 'La Reina'));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.groups_outlined).first);
    await tester.pumpAndSettle();

    expect(find.text('Aún no hay una comunidad en La Reina'), findsOneWidget);

    await tester.tap(find.text('Crear comunidad de La Reina'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Crear'));
    await tester.pumpAndSettle();

    expect(find.text('Vecinos de La Reina'), findsOneWidget);
    expect(find.text('Miembro'), findsOneWidget);
    expect(controller.perfil.comunidadUnidaId, 'local-la-reina');
  });

  testWidgets(
    'Una cuenta nueva pasa por la bienvenida: nombre y alias obligatorios',
    (tester) async {
      final repo = _UsuarioRepositoryFijo(0, nombre: null);
      final controller = await _montarApp(tester, usuarioRepository: repo);

      expect(find.text('¡Bienvenido a Rebin!'), findsOneWidget);

      // Sin datos no avanza.
      await tester.tap(find.text('Continuar'));
      await tester.pumpAndSettle();
      expect(find.text('Ingresa tu nombre'), findsOneWidget);
      expect(find.text('Elige un alias'), findsOneWidget);

      await tester.enterText(find.byType(TextFormField).at(0), 'Camila Rojas');
      await tester.enterText(find.byType(TextFormField).at(1), 'cami_recicla');
      await tester.tap(find.text('Continuar'));
      await tester.pumpAndSettle();

      // Los permisos se pueden rechazar.
      expect(find.text('Activa tu ubicación'), findsOneWidget);
      await tester.tap(find.text('Ahora no'));
      await tester.pumpAndSettle();
      expect(find.text('Recibe avisos'), findsOneWidget);
      await tester.tap(find.text('Ahora no, empezar'));
      await tester.pumpAndSettle();

      expect(repo.nombre, 'Camila Rojas');
      expect(repo.alias, 'cami_recicla');
      expect(controller.perfil.nombre, 'cami_recicla');
      expect(find.text('Hola, cami_recicla'), findsOneWidget);
    },
  );

  testWidgets('Un invitado vincula su cuenta: correo, código y contraseña', (
    tester,
  ) async {
    await _montarApp(tester);
    await tester.tap(find.byIcon(Icons.person_outline));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('Crea una cuenta'), 200);
    await tester.tap(find.text('Crea una cuenta'));
    await tester.pumpAndSettle();

    // 1. Correo: formato inválido no avanza.
    await tester.enterText(find.byType(TextField), 'camila@gmail');
    await tester.tap(find.text('Enviar código'));
    await tester.pumpAndSettle();
    expect(find.text('Ese no parece un correo válido.'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'camila@gmail.com');
    await tester.tap(find.text('Enviar código'));
    await tester.pumpAndSettle();

    // 2. Código: uno incorrecto se rechaza.
    expect(find.text('Revisa tu correo'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '00000000');
    await tester.pump();
    await tester.tap(find.text('Verificar'));
    await tester.pumpAndSettle();
    expect(find.textContaining('El código no coincide'), findsOneWidget);

    await tester.enterText(
      find.byType(TextField),
      CuentaRepositoryMock.codigoValido,
    );
    await tester.pump();
    await tester.tap(find.text('Verificar'));
    await tester.pumpAndSettle();

    // 3. Contraseña: se muestran las reglas y el botón espera a cumplirlas.
    expect(find.text('Crea tu contraseña'), findsOneWidget);
    for (final regla in [
      'Mínimo 8 caracteres',
      'Una letra mayúscula',
      'Una letra minúscula',
      'Un número',
      'Un carácter especial o símbolo',
    ]) {
      expect(find.text(regla), findsOneWidget);
    }
    final crear = find.widgetWithText(FilledButton, 'Crear cuenta');
    await tester.enterText(find.byType(TextField).at(0), 'Recicla 2026#');
    await tester.enterText(find.byType(TextField).at(1), 'Recicla 2026#');
    await tester.pump();
    expect(find.text('No puede tener espacios'), findsOneWidget);
    expect(tester.widget<FilledButton>(crear).onPressed, isNull);

    await tester.enterText(find.byType(TextField).at(0), 'Recicla#2026');
    await tester.enterText(find.byType(TextField).at(1), 'Recicla#2026');
    await tester.pump();
    expect(tester.widget<FilledButton>(crear).onPressed, isNotNull);
    await tester.tap(crear);
    await tester.pumpAndSettle();

    expect(find.text('¡Listo! Tu cuenta quedó creada'), findsOneWidget);
  });

  testWidgets('Registro rechaza un dominio que no recibe correos', (
    tester,
  ) async {
    _usarTamanoDeTelefono(tester);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: RegistroCuentaScreen(
          repositorio: CuentaRepositoryMock(),
          verificarDominio: (_) async => false,
        ),
      ),
    );
    await tester.enterText(find.byType(TextField), 'camila@gmial.com');
    await tester.tap(find.text('Enviar código'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('no existe o no recibe correos'),
      findsOneWidget,
    );
    expect(find.text('Revisa tu correo'), findsNothing);
  });

  testWidgets('Iniciar sesión muestra error con credenciales inválidas', (
    tester,
  ) async {
    await _montarApp(tester);
    await tester.tap(find.byIcon(Icons.person_outline));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('¿Ya tienes cuenta? Inicia sesión'),
      200,
    );
    await tester.tap(find.text('¿Ya tienes cuenta? Inicia sesión'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).at(0), 'camila@gmail.com');
    await tester.enterText(find.byType(TextField).at(1), 'Recicla#2026');
    await tester.tap(find.widgetWithText(FilledButton, 'Entrar'));
    await tester.pumpAndSettle();
    expect(find.text('Correo o contraseña incorrectos.'), findsOneWidget);
  });
}
