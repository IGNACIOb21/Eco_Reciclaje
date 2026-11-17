import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:recircula/models/material_type.dart';
import 'package:recircula/models/postulacion_servicio.dart';
import 'package:recircula/repositories/recolectores_repository.dart';
import 'package:recircula/repositories/recolectores_repository_mock.dart';
import 'package:recircula/screens/mis_postulaciones_screen.dart';
import 'package:recircula/screens/postular_servicio_screen.dart';
import 'package:recircula/screens/servicios_screen.dart';
import 'package:recircula/theme/app_theme.dart';

RecolectoresRepositoryMock _repo() =>
    RecolectoresRepositoryMock(latencia: Duration.zero);

Widget _app(Widget home) => MaterialApp(theme: AppTheme.light, home: home);

/// Pantalla alta para que ListView construya todas las tarjetas y campos
/// (es perezoso y en 600 px las de abajo no existirían en el árbol).
void _pantallaAlta(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 3200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  group('Servicios', () {
    testWidgets('lista los recolectores y filtra por material', (tester) async {
      _pantallaAlta(tester);
      _pantallaAlta(tester);
      await tester.pumpWidget(_app(ServiciosScreen(repositorio: _repo())));
      await tester.pumpAndSettle();

      expect(find.text('Aceite Circular Ñuñoa'), findsOneWidget);
      expect(find.text('EcoPilas Macul'), findsOneWidget);

      await tester.tap(find.widgetWithText(FilterChip, 'Pilas'));
      await tester.pumpAndSettle();

      expect(find.text('EcoPilas Macul'), findsOneWidget);
      expect(find.text('Aceite Circular Ñuñoa'), findsNothing);

      // Se pueden combinar: aceite + pilas muestra ambos.
      final aceite = find.widgetWithText(FilterChip, 'Aceite usado');
      await tester.ensureVisible(
        aceite,
      ); // el chip está en un scroll horizontal
      await tester.tap(aceite);
      await tester.pumpAndSettle();
      expect(find.text('EcoPilas Macul'), findsOneWidget);
      expect(find.text('Aceite Circular Ñuñoa'), findsOneWidget);
    });

    testWidgets('al tocar una tarjeta abre la ficha con horario y contacto', (
      tester,
    ) async {
      _pantallaAlta(tester);
      await tester.pumpWidget(_app(ServiciosScreen(repositorio: _repo())));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Aceite Circular Ñuñoa'));
      await tester.pumpAndSettle();

      expect(find.text('Horario de atención'), findsOneWidget);
      expect(find.text('9:00-18:00'), findsOneWidget);
      expect(find.text('Contacto'), findsOneWidget);
      expect(find.byTooltip('Copiar contacto'), findsOneWidget);
    });

    testWidgets('la ficha de un recolector con entidad lista sus puntos', (
      tester,
    ) async {
      _pantallaAlta(tester);
      await tester.pumpWidget(_app(ServiciosScreen(repositorio: _repo())));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Recicladora El Roble'));
      await tester.tap(find.text('Recicladora El Roble'));
      await tester.pumpAndSettle();

      expect(find.text('Sus puntos de reciclaje'), findsOneWidget);
      expect(find.text('Centro de acopio El Roble'), findsOneWidget);
      expect(find.text('Av. Larraín 1234'), findsOneWidget);
    });

    testWidgets('si falla la carga muestra el error y permite reintentar', (
      tester,
    ) async {
      _pantallaAlta(tester);
      await tester.pumpWidget(
        _app(
          ServiciosScreen(
            repositorio: RecolectoresRepositoryMock(
              forzarError: true,
              latencia: Duration.zero,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No pudimos cargar los recolectores.'), findsOneWidget);
      expect(find.text('Reintentar'), findsOneWidget);
    });
  });

  group('Postular un servicio', () {
    testWidgets('sin completar el formulario muestra el primer problema', (
      tester,
    ) async {
      _pantallaAlta(tester);
      await tester.pumpWidget(
        _app(PostularServicioScreen(repositorio: _repo())),
      );

      await tester.tap(find.byKey(const Key('postular-enviar')));
      await tester.pump();
      expect(
        find.text('El nombre debe tener al menos 3 caracteres.'),
        findsOneWidget,
      );

      await tester.enterText(
        find.byKey(const Key('postular-nombre')),
        'Mi servicio',
      );
      await tester.tap(find.byKey(const Key('postular-enviar')));
      await tester.pump();
      expect(
        find.text('Indica un contacto (teléfono, correo o red social).'),
        findsOneWidget,
      );
    });

    testWidgets('un horario mal escrito se avisa antes de enviar', (
      tester,
    ) async {
      _pantallaAlta(tester);
      final repo = _repo();
      await tester.pumpWidget(_app(PostularServicioScreen(repositorio: repo)));
      await tester.enterText(
        find.byKey(const Key('postular-nombre')),
        'Mi servicio',
      );
      await tester.enterText(
        find.byKey(const Key('postular-contacto')),
        '+56 9 1111 2222',
      );
      await tester.tap(find.widgetWithText(FilterChip, 'Aceite usado'));
      await tester.pump();
      await tester.tap(find.byKey(const Key('postular-comunas')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ñuñoa'));
      await tester.tap(find.text('Listo'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('postular-horario')),
        'todo el dia',
      );
      await tester.ensureVisible(find.byKey(const Key('postular-enviar')));
      await tester.tap(find.byKey(const Key('postular-enviar')));
      await tester.pump();

      expect(find.textContaining('Cada línea del horario'), findsOneWidget);
      expect(await repo.misPostulaciones(), isEmpty);
    });

    testWidgets('con datos válidos envía la postulación y se cierra', (
      tester,
    ) async {
      _pantallaAlta(tester);
      final repo = _repo();
      bool? resultado;
      await tester.pumpWidget(
        _app(
          Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () async {
                  resultado = await Navigator.of(context).push<bool>(
                    MaterialPageRoute(
                      builder: (_) => PostularServicioScreen(repositorio: repo),
                    ),
                  );
                },
                child: const Text('abrir'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('postular-nombre')),
        'Mi servicio',
      );
      await tester.enterText(
        find.byKey(const Key('postular-contacto')),
        '+56 9 1111 2222',
      );
      await tester.enterText(
        find.byKey(const Key('postular-horario')),
        'lun-vie: 9:00-18:00',
      );
      await tester.tap(find.widgetWithText(FilterChip, 'Aceite usado'));
      await tester.pump();
      await tester.tap(find.byKey(const Key('postular-comunas')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ñuñoa'));
      await tester.tap(find.text('Listo'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('postular-enviar')));
      await tester.tap(find.byKey(const Key('postular-enviar')));
      await tester.pumpAndSettle();

      expect(resultado, isTrue);
      final propias = await repo.misPostulaciones();
      expect(propias.single.nombre, 'Mi servicio');
      expect(propias.single.estado, EstadoPostulacion.pendiente);
    });

    testWidgets(
      'el servidor rechaza la cuarta pendiente y se muestra el motivo',
      (tester) async {
        _pantallaAlta(tester);
        _pantallaAlta(tester);
        final repo = _repo();
        for (var i = 0; i < 3; i++) {
          await repo.postular(
            PostulacionServicio(
              nombre: 'Servicio $i',
              contacto: '123',
              comunas: const ['Macul'],
              materiales: const [TipoMaterial.aceite],
            ),
          );
        }
        await tester.pumpWidget(
          _app(PostularServicioScreen(repositorio: repo)),
        );
        await tester.enterText(
          find.byKey(const Key('postular-nombre')),
          'Cuarto servicio',
        );
        await tester.enterText(
          find.byKey(const Key('postular-contacto')),
          '+56 9 1111 2222',
        );
        await tester.tap(find.widgetWithText(FilterChip, 'Pilas'));
        await tester.pump();
        await tester.tap(find.byKey(const Key('postular-comunas')));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Macul'));
        await tester.tap(find.text('Listo'));
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.byKey(const Key('postular-enviar')));
        await tester.tap(find.byKey(const Key('postular-enviar')));
        await tester.pumpAndSettle();

        expect(
          find.text(
            const PostulacionException(
              MotivoErrorPostulacion.limitePostulaciones,
            ).mensaje,
          ),
          findsOneWidget,
        );
      },
    );
  });

  group('Mis postulaciones', () {
    testWidgets('muestra el estado de cada una y el motivo de un rechazo', (
      tester,
    ) async {
      _pantallaAlta(tester);
      await tester.pumpWidget(
        _app(MisPostulacionesScreen(repositorio: _RepoConHistorial())),
      );
      await tester.pumpAndSettle();

      expect(find.text('En revisión'), findsOneWidget);
      expect(find.text('Publicado'), findsOneWidget);
      expect(find.text('Rechazado'), findsOneWidget);
      expect(find.text('Motivo: Contacto inválido'), findsOneWidget);
    });

    testWidgets('sin postulaciones lo dice', (tester) async {
      _pantallaAlta(tester);
      _pantallaAlta(tester);
      await tester.pumpWidget(
        _app(MisPostulacionesScreen(repositorio: _repo())),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Todavía no has postulado ningún servicio.'),
        findsOneWidget,
      );
    });
  });
}

class _RepoConHistorial extends RecolectoresRepositoryMock {
  _RepoConHistorial() : super(latencia: Duration.zero);

  @override
  Future<List<MiPostulacion>> misPostulaciones() async => [
    MiPostulacion(
      id: '1',
      nombre: 'Uno',
      estado: EstadoPostulacion.pendiente,
      fecha: DateTime(2026, 10, 8),
    ),
    MiPostulacion(
      id: '2',
      nombre: 'Dos',
      estado: EstadoPostulacion.activo,
      fecha: DateTime(2026, 10, 7),
    ),
    MiPostulacion(
      id: '3',
      nombre: 'Tres',
      estado: EstadoPostulacion.rechazado,
      motivoRechazo: 'Contacto inválido',
      fecha: DateTime(2026, 10, 6),
    ),
  ];
}
