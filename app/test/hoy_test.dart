import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recircula/models/resumen_hoy.dart';
import 'package:recircula/models/usuario.dart';
import 'package:recircula/repositories/gamificacion_repository.dart';
import 'package:recircula/repositories/gamificacion_repository_mock.dart';
import 'package:recircula/repositories/usuario_repository.dart';
import 'package:recircula/state/perfil_local_controller.dart';
import 'package:recircula/state/usuario_controller.dart';
import 'package:recircula/theme/app_theme.dart';
import 'package:recircula/widgets/resumen_inicio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _UsuarioFijo implements UsuarioRepository {
  final int acumulados;
  _UsuarioFijo(this.acumulados);

  @override
  Future<Usuario> obtenerOCrear() async => Usuario(
    id: 'test',
    alias: 'Usuario Rebin',
    fechaRegistro: DateTime(2026, 9, 15),
    puntosTotales: acumulados,
    puntosAcumulados: acumulados,
  );

  @override
  Future<Usuario> guardarDatos({required String alias, String? nombre}) =>
      obtenerOCrear();
}

class _GamificacionConError implements GamificacionRepository {
  @override
  Future<ResumenHoy> resumenHoy() async => throw Exception('sin conexión');

  @override
  Future<CompraCongelador> comprarCongelador() async =>
      throw Exception('sin conexión');

  @override
  Future<SorpresaHoy> sorpresaHoy() async => throw Exception('sin conexión');

  @override
  Future<int> abrirSorpresa() async => throw Exception('sin conexión');
}

Future<void> _montar(
  WidgetTester tester,
  GamificacionRepository repo, {
  int acumulados = 524,
  Listenable? recarga,
}) async {
  SharedPreferences.setMockInitialValues({});
  final perfil = await PerfilLocalController.cargar();
  final usuario = UsuarioController(_UsuarioFijo(acumulados));
  await usuario.cargar();
  await tester.pumpWidget(
    PerfilLocalScope(
      controller: perfil,
      child: UsuarioScope(
        controller: usuario,
        child: MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: ResumenInicio(
              gamificacion: repo,
              recarga: recarga,
              ahora: () => DateTime(2026, 10, 15),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('ResumenHoy.fromJson', () {
    test('lee la meta, la racha y los cinco estados de la semana', () {
      final r = ResumenHoy.fromJson({
        'meta': {'cumplida': true, 'actual': 1, 'objetivo': 1},
        'racha': {
          'actual': 6,
          'maxima': 12,
          'semana': [
            for (final (i, e) in [
              'hecho',
              'congelado',
              'hoy',
              'pendiente',
              'futuro',
              'raro',
              'futuro',
            ].indexed)
              {'fecha': '2026-10-${12 + i}', 'estado': e},
          ],
        },
        'congeladores': {'tienes': 1, 'maximo': 2, 'costo': 20},
      });
      expect(r.metaCumplida, isTrue);
      expect(r.racha, 6);
      expect(r.rachaMaxima, 12);
      expect(r.congeladores, 1);
      expect(r.costoCongelador, 20);
      expect(r.semana.map((d) => d.estado), [
        EstadoDia.hecho,
        EstadoDia.congelado,
        EstadoDia.hoy,
        EstadoDia.pendiente,
        EstadoDia.futuro,
        // Un estado desconocido cae en pendiente.
        EstadoDia.pendiente,
        EstadoDia.futuro,
      ]);
      expect(r.semana.first.fecha, DateTime(2026, 10, 12));
    });
  });

  testWidgets('Meta pendiente: muestra 0/1, la racha y el consejo', (
    tester,
  ) async {
    await _montar(tester, GamificacionRepositoryMock());
    expect(find.text('jueves 15 de octubre'), findsOneWidget);
    expect(find.text('Recicla 1 cosa'), findsOneWidget);
    expect(find.text('Tu meta de hoy'), findsOneWidget);
    expect(find.text('0/1'), findsOneWidget);
    expect(find.text('Racha de 6 días'), findsOneWidget);
    expect(find.text('Tu planta crece contigo'), findsOneWidget);
    expect(find.text('Aprendiz · 524 / 600'), findsOneWidget);
    expect(find.text('Te faltan 76 para Pro'), findsOneWidget);
    expect(find.text('Escanea algo para completar la meta.'), findsOneWidget);
  });

  testWidgets('Meta cumplida: muestra 1/1 y el mensaje de mañana', (
    tester,
  ) async {
    await _montar(tester, GamificacionRepositoryMock(metaCumplida: true));
    expect(find.text('1/1'), findsOneWidget);
    expect(find.text('¡Lista por hoy!'), findsOneWidget);
    expect(
      find.text('Volviste a reciclar hoy. Mañana sigue tu racha.'),
      findsOneWidget,
    );
  });

  testWidgets('Sin racha invita a empezar; cerca del nivel lo avisa', (
    tester,
  ) async {
    await _montar(
      tester,
      GamificacionRepositoryMock(racha: 0),
      acumulados: 590,
    );
    expect(find.text('Empieza tu racha'), findsOneWidget);
    expect(
      find.text(
        'Escanea algo para completar la meta. Estás a 10 Rebin Points de Pro.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('Si el repositorio falla, Inicio sigue mostrando el nivel', (
    tester,
  ) async {
    await _montar(tester, _GamificacionConError());
    expect(find.byKey(const Key('inicio-hoy')), findsNothing);
    expect(find.byKey(const Key('inicio-consejo')), findsNothing);
    expect(find.byKey(const Key('inicio-nivel')), findsOneWidget);
    expect(find.text('Aprendiz · 524 / 600'), findsOneWidget);
  });

  testWidgets('Tocar la tarjeta de racha abre Tu racha', (tester) async {
    await _montar(tester, GamificacionRepositoryMock());
    await tester.tap(find.byKey(const Key('hoy-racha')));
    await tester.pumpAndSettle();
    expect(find.text('Tu racha'), findsOneWidget);
    expect(find.text('Una hoja por cada día que reciclas'), findsOneWidget);
  });

  testWidgets('Un aviso de recarga vuelve a leer la meta', (tester) async {
    final repo = GamificacionRepositoryMock();
    final recarga = ValueNotifier<int>(0);
    await _montar(tester, repo, recarga: recarga);
    expect(find.text('0/1'), findsOneWidget);
    // El mock cambia de estado en memoria al "reciclar".
    repo.metaCumplida = true;
    recarga.value++;
    await tester.pumpAndSettle();
    expect(find.text('1/1'), findsOneWidget);
  });
}
