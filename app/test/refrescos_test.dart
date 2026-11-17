import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:recircula/widgets/map_rebin.dart';
import 'package:recircula/main.dart';
import 'package:recircula/models/beneficio.dart';
import 'package:recircula/models/estado_punto.dart';
import 'package:recircula/models/filtros_mapa.dart';
import 'package:recircula/models/material_type.dart';
import 'package:recircula/models/punto_reciclaje.dart';
import 'package:recircula/models/usuario.dart';
import 'package:recircula/repositories/acciones_repository_mock.dart';
import 'package:recircula/repositories/beneficios_repository_mock.dart';
import 'package:recircula/repositories/puntos_repository.dart';
import 'package:recircula/repositories/puntos_repository_mock.dart';
import 'package:recircula/repositories/usuario_repository.dart';
import 'package:recircula/screens/beneficios_screen.dart';
import 'package:recircula/screens/punto_detail_screen.dart';
import 'package:recircula/state/perfil_local_controller.dart';
import 'package:recircula/state/primer_inicio_controller.dart';
import 'package:recircula/state/tema_controller.dart';
import 'package:recircula/state/usuario_controller.dart';
import 'package:recircula/theme/app_theme.dart';

void _pantallaAlta(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

/// Usuario cuyo saldo sube en cada lectura, para comprobar que se vuelve a leer.
class _UsuarioCambiante implements UsuarioRepository {
  int lecturas = 0;

  @override
  Future<Usuario> obtenerOCrear() async {
    lecturas++;
    return Usuario(
      id: 'x',
      alias: 'ana',
      nombre: 'Ana',
      correo: 'ana@example.com',
      fechaRegistro: DateTime(2026, 9, 1),
      puntosTotales: 100 + (lecturas - 1) * 50,
    );
  }

  @override
  Future<Usuario> guardarDatos({required String alias, String? nombre}) =>
      obtenerOCrear();
}

PuntoReciclaje _punto({
  EstadoPunto estado = EstadoPunto.disponible,
  double promedio = 0,
  int n = 0,
}) => PuntoReciclaje(
  id: '12',
  nombre: 'Punto Demo',
  comuna: 'Ñuñoa',
  direccion: 'Calle 1',
  lat: -33.45,
  lng: -70.6,
  fuente: FuentePunto.oficial,
  materiales: const [TipoMaterial.vidrio],
  estado: estado,
  calificacionPromedio: promedio,
  numCalificaciones: n,
);

/// Repositorio de puntos que devuelve lo que el servidor "ya cambió".
class _PuntosActualizados implements PuntosRepository {
  final PuntoReciclaje devuelto;
  final bool falla;
  int consultas = 0;
  _PuntosActualizados(this.devuelto, {this.falla = false});

  @override
  Future<List<PuntoReciclaje>> obtenerPuntos({
    required double miLat,
    required double miLng,
    required FiltrosMapa filtros,
  }) async {
    consultas++;
    if (falla) throw Exception('sin conexión');
    return [devuelto];
  }
}

Widget _app(Widget home) => MaterialApp(theme: AppTheme.light, home: home);

void main() {
  testWidgets(
    'la ficha actualiza el promedio y el estado tras reportar y calificar',
    (tester) async {
      _pantallaAlta(tester);
      final puntos = _PuntosActualizados(
        _punto(estado: EstadoPunto.lleno, promedio: 5, n: 1),
      );
      await tester.pumpWidget(
        _app(
          PuntoDetailScreen(
            punto: _punto(),
            acciones: AccionesRepositoryMock(),
            puntos: puntos,
          ),
        ),
      );
      expect(find.text('0.0 (0)'), findsOneWidget);
      expect(find.text('Disponible'), findsOneWidget);

      await tester.tap(find.byKey(const Key('ficha-calificar')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('calificar-estrella-5')));
      await tester.tap(find.byKey(const Key('calificar-enviar')));
      await tester.pumpAndSettle();

      // Una al abrir (pines del mapa del encabezado) y otra al releer el punto.
      expect(puntos.consultas, 2);
      expect(find.text('5.0 (1)'), findsOneWidget);
      expect(find.text('Lleno'), findsOneWidget);
      expect(find.text('Disponible'), findsNothing);
    },
  );

  testWidgets(
    'si no se puede releer el punto, la ficha conserva lo que mostraba',
    (tester) async {
      _pantallaAlta(tester);
      final puntos = _PuntosActualizados(_punto(), falla: true);
      await tester.pumpWidget(
        _app(
          PuntoDetailScreen(
            punto: _punto(promedio: 4, n: 2),
            acciones: AccionesRepositoryMock(),
            puntos: puntos,
          ),
        ),
      );
      await tester.tap(find.byKey(const Key('ficha-calificar')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('calificar-estrella-5')));
      await tester.tap(find.byKey(const Key('calificar-enviar')));
      await tester.pumpAndSettle();

      // Una al abrir (pines del mapa del encabezado) y otra al releer el punto.
      expect(puntos.consultas, 2);
      expect(find.text('4.0 (2)'), findsOneWidget);
      expect(find.textContaining('Gracias por calificar'), findsOneWidget);
    },
  );

  testWidgets('el mapa de la ficha va de borde a borde con 160 de alto', (
    tester,
  ) async {
    _pantallaAlta(tester);
    await tester.pumpWidget(
      _app(
        PuntoDetailScreen(
          punto: _punto(),
          acciones: AccionesRepositoryMock(),
          puntos: _PuntosActualizados(_punto()),
        ),
      ),
    );
    final mapa = tester.getSize(find.byType(MapRebin));
    expect(mapa.width, tester.getSize(find.byType(Scaffold)).width);
    expect(mapa.height, 160);
  });

  testWidgets('Beneficios vuelve a leer el saldo al abrirse', (tester) async {
    _pantallaAlta(tester);
    // UsuarioController guarda una copia de los puntos en el teléfono.
    SharedPreferences.setMockInitialValues({});
    final repo = _UsuarioCambiante();
    final controller = UsuarioController(repo);
    // Como en la app real: la primera carga ya terminó cuando se abre Beneficios.
    await controller.cargar();
    await tester.pumpWidget(
      UsuarioScope(
        controller: controller,
        child: _app(
          BeneficiosScreen(
            repositorio: BeneficiosRepositoryMock(
              catalogo: [
                Beneficio(
                  id: 1,
                  nombre: 'Beneficio',
                  costo: 10,
                  tipo: 'descuento',
                  entidad: 'Muni',
                  vigenciaFin: DateTime(2026, 12, 31),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(repo.lecturas, 2);
    expect(find.text('Tu saldo: 150 Rebin Points'), findsOneWidget);
  });

  testWidgets('pasar a Perfil e Inicio recarga al usuario si pasaron 20 s', (
    tester,
  ) async {
    _pantallaAlta(tester);
    SharedPreferences.setMockInitialValues({'primer_inicio_completado': true});
    final perfil = await PerfilLocalController.cargar();
    final primerInicio = await PrimerInicioController.cargar();
    final tema = await TemaController.cargar();
    final repo = _UsuarioCambiante();
    var ahora = DateTime(2026, 10, 20, 12);
    final usuario = UsuarioController(repo, ahora: () => ahora)..cargar();
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
    final alAbrir = repo.lecturas;

    // Recién leído: cambiar de pestaña no repite las consultas.
    await tester.tap(find.byIcon(Icons.person_outline));
    await tester.pumpAndSettle();
    expect(repo.lecturas, alAbrir);

    ahora = ahora.add(UsuarioController.vigencia);
    await tester.tap(find.byIcon(Icons.home_outlined));
    await tester.pumpAndSettle();
    expect(repo.lecturas, alAbrir + 1);

    ahora = ahora.add(UsuarioController.vigencia);
    await tester.tap(find.byIcon(Icons.person_outline));
    await tester.pumpAndSettle();
    expect(repo.lecturas, alAbrir + 2);
  });
}
