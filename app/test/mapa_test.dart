import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:recircula/data/mock_puntos.dart';
import 'package:recircula/models/filtros_mapa.dart';
import 'package:recircula/models/punto_reciclaje.dart';
import 'package:recircula/repositories/acciones_repository_mock.dart';
import 'package:recircula/repositories/puntos_repository.dart';
import 'package:recircula/screens/mapa_screen.dart';
import 'package:recircula/theme/app_theme.dart';
import 'package:recircula/widgets/map_rebin.dart';

/// Repositorio cuyas respuestas controla el test: cada consulta queda
/// pendiente hasta que se completa a mano, para mirar el mapa "mientras carga".
class _RepoControlado implements PuntosRepository {
  final consultas = <Completer<List<PuntoReciclaje>>>[];

  @override
  Future<List<PuntoReciclaje>> obtenerPuntos({
    required double miLat,
    required double miLng,
    required FiltrosMapa filtros,
  }) {
    final c = Completer<List<PuntoReciclaje>>();
    consultas.add(c);
    return c.future;
  }
}

/// Los tests usan la fuente "Ahem" (cada letra mide como el tamaño de la
/// fuente), así que las filas con texto se desbordan aunque quepan en un
/// teléfono real. Se ignoran solo esos avisos para no ocultar fallos reales.
void _ignorarDesbordes() {
  final original = FlutterError.onError;
  FlutterError.onError = (detalles) {
    if (detalles.exceptionAsString().contains('overflowed')) return;
    original?.call(detalles);
  };
  addTearDown(() => FlutterError.onError = original);
}

void main() {
  testWidgets('el mapa sigue montado mientras se recargan los puntos', (
    tester,
  ) async {
    _ignorarDesbordes();
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repo = _RepoControlado();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: MapaScreen(repositorio: repo),
      ),
    );

    // Primera carga pendiente: el mapa ya está y la lista muestra el
    // esqueleto (antes se reemplazaba el mapa entero por un indicador).
    expect(find.byType(MapRebin), findsOneWidget);
    expect(find.text('Buscando puntos cerca…'), findsOneWidget);
    expect(find.byKey(const Key('mapa-esqueleto')), findsOneWidget);
    final estadoMapa = tester.state(find.byType(MapRebin));

    repo.consultas.first.complete(mockPuntos.take(3).toList());
    await tester.pump();
    expect(find.byKey(const Key('mapa-esqueleto')), findsNothing);
    expect(tester.state(find.byType(MapRebin)), same(estadoMapa));

    // Cambiar un filtro lanza otra consulta: el mapa NO se destruye ni se
    // recrea (misma instancia) y los puntos anteriores siguen a la vista.
    await tester.tap(find.text('Vidrio').first);
    await tester.pump();
    expect(repo.consultas, hasLength(2));
    expect(find.byType(MapRebin), findsOneWidget);
    expect(tester.state(find.byType(MapRebin)), same(estadoMapa));
    expect(find.text('3 puntos · arrastra para ver más'), findsOneWidget);

    repo.consultas.last.complete(mockPuntos.take(1).toList());
    await tester.pump();
    expect(tester.state(find.byType(MapRebin)), same(estadoMapa));
    expect(find.text('1 punto · arrastra para ver más'), findsOneWidget);

    // Desmontar apaga el GPS y suelta el mapa.
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('si falla la consulta el mapa queda y aparece el aviso', (
    tester,
  ) async {
    _ignorarDesbordes();
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repo = _RepoControlado();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: MapaScreen(repositorio: repo),
      ),
    );
    final estadoMapa = tester.state(find.byType(MapRebin));

    repo.consultas.first.completeError(Exception('sin red'));
    await tester.pump();

    expect(
      find.text('No pudimos cargar los puntos de reciclaje.'),
      findsOneWidget,
    );
    expect(tester.state(find.byType(MapRebin)), same(estadoMapa));

    await tester.tap(find.text('Reintentar'));
    await tester.pump();
    expect(repo.consultas, hasLength(2));

    await tester.pumpWidget(const SizedBox());
  });

  group('estados de la lista', () {
    Future<_RepoControlado> montar(WidgetTester tester) async {
      _ignorarDesbordes();
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.75;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repo = _RepoControlado();
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: MapaScreen(
            repositorio: repo,
            acciones: AccionesRepositoryMock(),
          ),
        ),
      );
      return repo;
    }

    testWidgets('sin puntos invita a cambiar los filtros', (tester) async {
      final repo = await montar(tester);
      repo.consultas.first.complete(const []);
      await tester.pump();

      expect(find.text('Aún no hay puntos por aquí'), findsOneWidget);
      // Eco Reciclaje no tiene sugerencias de puntos: no ofrece agregar uno.
      expect(find.text('Agregar un punto'), findsNothing);
      expect(find.text('Cambiar filtros'), findsOneWidget);
    });

    testWidgets('con filtros y sin puntos ofrece limpiarlos', (tester) async {
      final repo = await montar(tester);
      repo.consultas.first.complete(mockPuntos.take(2).toList());
      await tester.pump();

      await tester.tap(find.text('Vidrio').first);
      await tester.pump();
      repo.consultas.last.complete(const []);
      await tester.pump();
      // Al cambiar el filtro la lista quedó vacía.
      expect(find.text('Ningún punto con estos filtros'), findsOneWidget);

      await tester.ensureVisible(find.text('Limpiar filtros'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Limpiar filtros'));
      await tester.pump();
      expect(repo.consultas, hasLength(3));
    });

    testWidgets('si falla una recarga quedan los puntos y un aviso', (
      tester,
    ) async {
      final repo = await montar(tester);
      repo.consultas.first.complete(mockPuntos.take(3).toList());
      await tester.pump();

      await tester.tap(find.text('Vidrio').first);
      await tester.pump();
      repo.consultas.last.completeError(Exception('sin red'));
      await tester.pump();

      // El mapa no se tapa: la lista avisa y deja reintentar.
      expect(
        find.text('No pudimos cargar los puntos de reciclaje.'),
        findsNothing,
      );
      expect(find.byKey(const Key('mapa-aviso-sin-conexion')), findsOneWidget);
      expect(find.text('3 puntos · arrastra para ver más'), findsOneWidget);

      await tester.tap(
        find.descendant(
          of: find.byKey(const Key('mapa-aviso-sin-conexion')),
          matching: find.text('Reintentar'),
        ),
      );
      await tester.pump();
      expect(repo.consultas, hasLength(3));
    });
  });
}
