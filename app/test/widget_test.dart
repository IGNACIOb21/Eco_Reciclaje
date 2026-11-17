import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:recircula/data/comunas_demo.dart';
import 'package:recircula/data/mock_puntos.dart';
import 'package:recircula/main.dart';
import 'package:recircula/models/nivel.dart';
import 'package:recircula/models/usuario.dart';
import 'package:recircula/repositories/cuenta_repository_mock.dart';
import 'package:recircula/repositories/puntos_repository_mock.dart';
import 'package:recircula/repositories/usuario_repository.dart';
import 'package:recircula/repositories/usuario_repository_mock.dart';
import 'package:recircula/screens/escanear_screen.dart';
import 'package:recircula/screens/bienvenida_screen.dart';
import 'package:recircula/screens/iniciar_sesion_screen.dart';
import 'package:recircula/screens/registro_cuenta_screen.dart';
import 'package:recircula/state/perfil_local_controller.dart';
import 'package:recircula/state/primer_inicio_controller.dart';
import 'package:recircula/state/tema_controller.dart';
import 'package:recircula/state/usuario_controller.dart';
import 'package:recircula/theme/app_theme.dart';
import 'package:recircula/utils/busqueda.dart';
import 'package:recircula/utils/geo.dart';
import 'package:recircula/widgets/tarjeta_cercana.dart';

void _usarTamanoDeTelefono(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

class _UsuarioRepositoryFijo implements UsuarioRepository {
  final int puntos;
  final int? acumulados;
  final List<Nivel>? niveles;
  String? nombre = 'Test';
  String alias = 'Usuario Rebin';
  final String? correo;

  /// Con [sinConexion] en true, obtenerOCrear falla como sin red.
  bool sinConexion = false;
  _UsuarioRepositoryFijo(
    this.puntos, {
    this.correo,
    this.acumulados,
    this.niveles,
  });

  @override
  Future<Usuario> obtenerOCrear() async {
    if (sinConexion) throw Exception('sin conexión');
    return Usuario(
      id: 'test',
      correo: correo,
      nombre: nombre,
      alias: alias,
      fechaRegistro: DateTime(2026, 9, 15),
      puntosTotales: puntos,
      puntosAcumulados: acumulados,
      niveles: niveles,
    );
  }

  @override
  Future<Usuario> guardarDatos({required String alias, String? nombre}) async {
    this.nombre = nombre;
    this.alias = alias;
    return obtenerOCrear();
  }
}

class _UsuarioRepositoryConError implements UsuarioRepository {
  @override
  Future<Usuario> obtenerOCrear() async => throw Exception('sin conexión');

  @override
  Future<Usuario> guardarDatos({required String alias, String? nombre}) async =>
      throw Exception('sin conexión');
}

/// Lo que dice la lista del mapa bajo "Cerca de ti" con [n] puntos.
String _conteo(int n) => switch (n) {
  0 => '0 puntos',
  1 => '1 punto · arrastra para ver más',
  _ => '$n puntos · arrastra para ver más',
};

/// Texto del widget `Text` con esa key.
String? _texto(WidgetTester tester, String key) =>
    tester.widget<Text>(find.byKey(Key(key))).data;

Future<PerfilLocalController> _montarApp(
  WidgetTester tester, {
  UsuarioRepository? usuarioRepository,
  bool primerInicioCompletado = true,
  Map<String, Object> valoresIniciales = const {},
}) async {
  _usarTamanoDeTelefono(tester);
  SharedPreferences.setMockInitialValues({
    'primer_inicio_completado': primerInicioCompletado,
    // Las láminas de presentación tienen su propio test.
    'onboarding_visto': true,
    ...valoresIniciales,
  });
  final perfil = await PerfilLocalController.cargar();
  final primerInicio = await PrimerInicioController.cargar();
  final tema = await TemaController.cargar();
  final usuario = UsuarioController(
    usuarioRepository ?? UsuarioRepositoryMock(),
  )..cargar();
  await tester.pumpWidget(
    RecirculaApp(
      perfilLocal: perfil,
      usuario: usuario,
      primerInicio: primerInicio,
      tema: tema,
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
  testWidgets('Inicio es el mapa y muestra el saldo y el nivel', (
    tester,
  ) async {
    await _montarApp(tester);

    // Inicio es el mapa: el saldo junto al buscador y el nivel arriba de la
    // lista de puntos (sin saludo, como en el rediseño).
    expect(find.byKey(const Key('inicio-saldo')), findsOneWidget);
    expect(find.byKey(const Key('inicio-nivel')), findsOneWidget);
    expect(find.text('Cerca de ti'), findsOneWidget);
  });

  testWidgets(
    'El mapa (Inicio) muestra los puntos y abre la ficha al tocar uno',
    (tester) async {
      await _montarApp(tester);

      expect(find.byIcon(Icons.tune), findsOneWidget);
      expect(find.text(_conteo(_puntosEnRadioPorDefecto())), findsOneWidget);

      // Tocar un punto de la lista hace lo mismo que tocar su pin: la lista
      // pasa a ser la vista previa del punto.
      await tester.tap(find.byType(TarjetaCercana).first);
      await tester.pumpAndSettle();
      expect(find.byType(TarjetaCercana), findsNothing);
      expect(find.text('Cómo llegar'), findsOneWidget);

      // "Volver" regresa a la lista.
      await tester.tap(find.byKey(const Key('mapa-volver-lista')));
      await tester.pumpAndSettle();
      expect(find.byType(TarjetaCercana), findsWidgets);

      await tester.tap(find.byType(TarjetaCercana).first);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Ver ficha'));
      await tester.tap(find.text('Ver ficha'));
      await tester.pumpAndSettle();

      // "Cómo llegar" está en la vista previa, no se repite en la ficha.
      expect(find.text('Cómo llegar'), findsNothing);
      expect(find.text('Reportar estado'), findsOneWidget);
    },
  );

  testWidgets('El botón de escanear abre el escáner con el modelo de Joaquín', (
    tester,
  ) async {
    await _montarApp(tester);

    await tester.tap(find.byKey(const Key('barra-escanear')));
    // Sin pumpAndSettle: el botón "respira" unos 14 s.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // El modelo se carga recién al primer escaneo: abrir no lo necesita.
    expect(find.byType(EscanearScreen), findsOneWidget);
    expect(find.text('Tomar foto'), findsOneWidget);
    expect(find.text('Elegir de la galería'), findsOneWidget);
  });

  testWidgets('El buscador del mapa filtra por comuna sin tildes', (
    tester,
  ) async {
    await _montarApp(tester);

    final enRadio = mockPuntos
        .where(
          (p) =>
              distanciaKm(centroDefectoLat, centroDefectoLng, p.lat, p.lng) <=
              5,
        )
        .toList();
    final esperados = filtrarPuntos(enRadio, 'nunoa').length;
    expect(esperados, greaterThan(0));
    expect(esperados, lessThan(enRadio.length));

    await tester.enterText(find.byType(TextField).first, 'nunoa');
    await tester.pumpAndSettle();
    expect(find.text('$esperados puntos para «nunoa»'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'zzzz');
    await tester.pumpAndSettle();
    expect(find.text('0 puntos para «zzzz»'), findsOneWidget);
    expect(find.textContaining('Ningún punto coincide'), findsOneWidget);

    await tester.tap(find.byTooltip('Limpiar búsqueda'));
    await tester.pumpAndSettle();
    expect(find.text(_conteo(enRadio.length)), findsOneWidget);
  });

  testWidgets('El filtro de comuna en Filtros reduce los puntos mostrados', (
    tester,
  ) async {
    await _montarApp(tester);

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

    expect(find.text(_conteo(conteoLasCondes)), findsOneWidget);
  });

  testWidgets('Limpiar en Filtros vuelve a mostrar el estado sin filtros', (
    tester,
  ) async {
    await _montarApp(tester);

    final conteoInicial = _puntosEnRadioPorDefecto();

    await tester.tap(find.byIcon(Icons.tune));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ChoiceChip, 'Macul'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Aplicar filtros'));
    await tester.pumpAndSettle();

    expect(find.text(_conteo(conteoInicial)), findsNothing);

    await tester.tap(find.byIcon(Icons.tune));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Limpiar'));
    await tester.pumpAndSettle();

    expect(find.text(_conteo(conteoInicial)), findsOneWidget);
  });

  testWidgets('Personalizar el nombre se refleja en Perfil y se persiste', (
    tester,
  ) async {
    final controller = await _montarApp(tester);

    await tester.tap(find.byIcon(Icons.person_outline));
    await tester.pumpAndSettle();
    expect(find.text('Usuario anónimo'), findsOneWidget);

    // Ajustes ya no repite la opción: se abre desde el avatar.
    expect(find.text('Personalizar perfil'), findsNothing);
    await tester.tap(find.byKey(const Key('perfil-personalizar')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Camila');
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();

    expect(find.text('Camila'), findsOneWidget);
    expect(controller.perfil.nombre, 'Camila');

    final prefs = await SharedPreferences.getInstance();
    expect(
      prefs.getString('perfil_local_${controller.clave}'),
      contains('Camila'),
    );
  });

  testWidgets(
    'Perfil muestra puntos, nivel y fecha de alta del usuario remoto',
    (tester) async {
      await _montarApp(tester, usuarioRepository: _UsuarioRepositoryFijo(720));

      await tester.tap(find.byIcon(Icons.person_outline));
      await tester.pumpAndSettle();

      expect(_texto(tester, 'perfil-nivel-nombre'), 'Pro');
      expect(_texto(tester, 'perfil-nivel-avance'), '720 / 1500');
      expect(
        find.text('Te faltan 780 Rebin Points para Experto'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Reciclando desde septiembre 2026'),
        findsOneWidget,
      );
      final barra = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(barra.value, closeTo((720 - 600) / (1500 - 600), 0.001));
    },
  );

  testWidgets(
    'El nivel usa los umbrales de la nube y lo acumulado, no el saldo',
    (tester) async {
      await _montarApp(
        tester,
        usuarioRepository: _UsuarioRepositoryFijo(
          40,
          acumulados: 120,
          niveles: const [
            Nivel('Novato', 0),
            Nivel('Aprendiz', 100),
            Nivel('Pro', 300),
          ],
        ),
      );

      await tester.tap(find.byIcon(Icons.person_outline));
      await tester.pumpAndSettle();

      expect(_texto(tester, 'perfil-nivel-nombre'), 'Aprendiz');
      expect(_texto(tester, 'perfil-nivel-avance'), '120 / 300');
      // Arriba a la derecha va el saldo, que los canjes sí descuentan.
      expect(_texto(tester, 'perfil-saldo'), '40');
    },
  );

  testWidgets('Sin conexión el Perfil muestra la última copia de los puntos', (
    tester,
  ) async {
    final repo = _UsuarioRepositoryFijo(720);
    // Primera vez con conexión: se guarda la copia en el teléfono.
    SharedPreferences.setMockInitialValues({});
    final controller = UsuarioController(repo);
    await controller.cargar();
    final prefs = await SharedPreferences.getInstance();
    final copia = prefs.getString('resumen_puntos');
    expect(copia, contains('"acumulado":720'));

    // Siguiente arranque, sin red.
    repo.sinConexion = true;
    await _montarApp(
      tester,
      usuarioRepository: repo,
      valoresIniciales: {'resumen_puntos': copia!},
    );
    await tester.tap(find.byIcon(Icons.person_outline));
    await tester.pumpAndSettle();

    expect(_texto(tester, 'perfil-nivel-nombre'), 'Pro');
    expect(_texto(tester, 'perfil-nivel-avance'), '720 / 1500');
    expect(find.textContaining('Sin conexión · datos del'), findsOneWidget);
  });

  testWidgets('Perfil ofrece reintentar si no se pudo cargar el usuario', (
    tester,
  ) async {
    await _montarApp(tester, usuarioRepository: _UsuarioRepositoryConError());

    await tester.tap(find.byIcon(Icons.person_outline));
    await tester.pumpAndSettle();

    expect(find.text('No pudimos cargar tus Rebin Points.'), findsOneWidget);
    expect(find.text('Reintentar'), findsOneWidget);
  });

  testWidgets('La app parte en el modo claro y el interruptor Modo Eco lo '
      'cambia', (tester) async {
    await _montarApp(tester);

    await tester.tap(find.byIcon(Icons.person_outline));
    await tester.pumpAndSettle();

    final eco = find.byKey(const Key('perfil-modo-eco'));
    await tester.scrollUntilVisible(eco, 200);
    ThemeData temaActual() => Theme.of(tester.element(eco));
    expect(
      temaActual().scaffoldBackgroundColor,
      AppTheme.light.scaffoldBackgroundColor,
    );
    // Ya no hay selector de temas: solo claro y Eco.
    expect(find.text('Tema'), findsNothing);

    await tester.tap(eco);
    await tester.pumpAndSettle();
    expect(
      temaActual().scaffoldBackgroundColor,
      AppTheme.eco.scaffoldBackgroundColor,
    );
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('tema_app'), 'eco');

    await tester.tap(eco);
    await tester.pumpAndSettle();
    expect(prefs.getString('tema_app'), 'claro');
  });

  testWidgets('Quien había elegido un tema que ya no existe vuelve al claro', (
    tester,
  ) async {
    await _montarApp(tester, valoresIniciales: {'tema_app': 'nordico'});
    final fondo = Theme.of(tester.element(find.byType(Scaffold).first))
        .scaffoldBackgroundColor;
    expect(fondo, AppTheme.light.scaffoldBackgroundColor);
  });

  testWidgets('Quien ya había elegido el modo claro lo conserva', (
    tester,
  ) async {
    await _montarApp(tester, valoresIniciales: {'modo_eco': false});
    final fondo = Theme.of(tester.element(find.byType(Scaffold).first))
        .scaffoldBackgroundColor;
    expect(fondo, AppTheme.light.scaffoldBackgroundColor);
  });

  testWidgets('El tema elegido se mantiene al cambiar de cuenta', (
    tester,
  ) async {
    final perfil = await _montarApp(
      tester,
      valoresIniciales: {'tema_app': 'claro'},
    );
    Color fondo() =>
        Theme.of(tester.element(find.byType(Scaffold).first))
            .scaffoldBackgroundColor;
    expect(fondo(), AppTheme.light.scaffoldBackgroundColor);

    // Lo que pasa al cerrar o iniciar sesión: el perfil local cambia de cuenta.
    await perfil.cambiarClave('otra-cuenta');
    await tester.pumpAndSettle();

    expect(fondo(), AppTheme.light.scaffoldBackgroundColor);
  });

  testWidgets('Comunidad permite unirse al grupo de la comuna y publicar', (
    tester,
  ) async {
    await _montarApp(tester);

    await tester.tap(find.byIcon(Icons.groups_outlined).first);
    await tester.pumpAndSettle();
    // Los grupos son la cuarta pestaña de Comunidad.
    await tester.tap(find.text('Grupos'));
    await tester.pumpAndSettle();

    // Sin Supabase (test) los grupos vienen de ComunidadesRepositoryMock.
    expect(find.text('Comunidades en Ñuñoa'), findsOneWidget);
    expect(find.text('Vecinos de Ñuñoa'), findsOneWidget);

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
    // Los grupos son la cuarta pestaña de Comunidad.
    await tester.tap(find.text('Grupos'));
    await tester.pumpAndSettle();

    expect(find.text('Aún no hay una comunidad en La Reina'), findsOneWidget);

    await tester.tap(find.text('Crear comunidad de La Reina'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Crear'));
    await tester.pumpAndSettle();

    expect(find.text('Vecinos de La Reina'), findsOneWidget);
    // Quien la crea queda como organizador.
    expect(find.text('Organizas'), findsOneWidget);
  });

  testWidgets(
    'Primer inicio: abre directo en el mapa, sin bienvenida ni inicio de sesión',
    (tester) async {
      await _montarApp(tester, primerInicioCompletado: false);

      expect(find.text('Inicia sesión'), findsNothing);
      expect(find.text('Omitir'), findsNothing);
      expect(find.text('Cerca de ti'), findsOneWidget);

      // El permiso de ubicación se pide una sola vez, sobre el mapa.
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('permisos_solicitados'), isTrue);
      expect(prefs.getBool('primer_inicio_completado'), isTrue);
    },
  );

  testWidgets(
    'Iniciar sesión en el primer inicio salta el alias y va a los permisos',
    (tester) async {
      _usarTamanoDeTelefono(tester);
      SharedPreferences.setMockInitialValues({'onboarding_visto': true});
      final perfil = await PerfilLocalController.cargar();
      final primerInicio = await PrimerInicioController.cargar();
      final usuario = UsuarioController(UsuarioRepositoryMock())..cargar();
      // Una cuenta ya registrada en el mock.
      final cuenta = CuentaRepositoryMock();
      await cuenta.enviarCodigo('test@rebin.cl');
      await cuenta.verificarCodigo(
        'test@rebin.cl',
        CuentaRepositoryMock.codigoValido,
      );
      await cuenta.crearContrasena('Clave123!');

      await tester.pumpWidget(
        UsuarioScope(
          controller: usuario,
          child: PerfilLocalScope(
            controller: perfil,
            child: PrimerInicioScope(
              controller: primerInicio,
              child: MaterialApp(
                theme: AppTheme.light,
                home: BienvenidaScreen(cuentaRepositorio: cuenta),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).at(0), 'test@rebin.cl');
      await tester.enterText(find.byType(TextField).at(1), 'Clave123!');
      await tester.tap(find.widgetWithText(FilledButton, 'Iniciar sesión'));
      await tester.pumpAndSettle();

      expect(find.text('¡Bienvenido a Rebin!'), findsNothing);
      expect(find.text('Activa tu ubicación'), findsOneWidget);
    },
  );

  testWidgets(
    'Cerrar sesión vuelve a Inicio como invitado, sin bienvenida ni permisos',
    (tester) async {
      await _montarApp(
        tester,
        usuarioRepository: _UsuarioRepositoryFijo(40, correo: 'test@rebin.cl'),
      );
      await tester.tap(find.byIcon(Icons.person_outline));
      await tester.pumpAndSettle();
      final cerrar = find.widgetWithText(ListTile, 'Cerrar sesión');
      await tester.scrollUntilVisible(cerrar, 200);
      await tester.tap(cerrar);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Cerrar sesión'));
      // Sin pumpAndSettle: el botón central de la barra "respira" unos 14 s y
      // el aviso (4 s) ya se habría ido cuando el test lo mire.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Cerraste sesión'), findsOneWidget);
      expect(find.text('Omitir'), findsNothing);
      expect(find.text('¡Bienvenido a Rebin!'), findsNothing);
      expect(find.text('Activa tu ubicación'), findsNothing);
      // Vuelve a la pestaña Inicio.
      expect(find.text('Cerca de ti'), findsOneWidget);
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
    final iniciar = find.widgetWithText(ListTile, 'Iniciar sesión');
    await tester.scrollUntilVisible(iniciar, 200);
    await tester.tap(iniciar);
    await tester.pumpAndSettle();

    // Abre en la pestaña "Inicia sesión", con "Regístrate" al lado.
    expect(find.text('Regístrate'), findsOneWidget);
    expect(find.text('Inicia sesión'), findsOneWidget);

    await tester.enterText(find.byType(TextField).at(0), 'camila@gmail.com');
    await tester.enterText(find.byType(TextField).at(1), 'Recicla#2026');
    await tester.tap(find.widgetWithText(FilledButton, 'Iniciar sesión'));
    await tester.pumpAndSettle();
    expect(find.text('Correo o contraseña incorrectos.'), findsOneWidget);

    // La X cierra sin cambiar nada.
    await tester.tap(find.byTooltip('Cerrar'));
    await tester.pumpAndSettle();
    expect(find.text('Regístrate'), findsNothing);
  });

  testWidgets('Iniciar sesión aparece aunque el usuario no cargue', (
    tester,
  ) async {
    await _montarApp(tester, usuarioRepository: _UsuarioRepositoryConError());
    await tester.tap(find.byIcon(Icons.person_outline));
    await tester.pumpAndSettle();
    final iniciar = find.widgetWithText(ListTile, 'Iniciar sesión');
    await tester.scrollUntilVisible(iniciar, 200);
    expect(iniciar, findsOneWidget);
    expect(find.widgetWithText(ListTile, 'Cerrar sesión'), findsOneWidget);
  });

  testWidgets(
    'Cerrar sesión sin correo vinculado avisa que está deshabilitado',
    (tester) async {
      await _montarApp(tester);
      await tester.tap(find.byIcon(Icons.person_outline));
      await tester.pumpAndSettle();
      final cerrar = find.widgetWithText(ListTile, 'Cerrar sesión');
      await tester.scrollUntilVisible(cerrar, 200);
      expect(
        find.text('Disponible con una cuenta con correo vinculado'),
        findsOneWidget,
      );

      await tester.tap(cerrar);
      await tester.pumpAndSettle();
      expect(
        find.textContaining('no tiene un correo vinculado'),
        findsOneWidget,
      );
      await tester.tap(find.text('Entendido'));
      await tester.pumpAndSettle();
      // Sigue en el Perfil, con la misma sesión.
      expect(cerrar, findsOneWidget);
    },
  );

  testWidgets('La pestaña Regístrate lleva a crear la cuenta', (tester) async {
    _usarTamanoDeTelefono(tester);
    SharedPreferences.setMockInitialValues({});
    final perfil = await PerfilLocalController.cargar();
    final usuario = UsuarioController(UsuarioRepositoryMock())..cargar();
    await tester.pumpWidget(
      UsuarioScope(
        controller: usuario,
        child: PerfilLocalScope(
          controller: perfil,
          child: MaterialApp(
            theme: AppTheme.light,
            home: IniciarSesionScreen(repositorio: CuentaRepositoryMock()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Regístrate'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Crear cuenta'));
    await tester.pumpAndSettle();
    expect(find.text('Enviar código'), findsOneWidget);
  });
}
