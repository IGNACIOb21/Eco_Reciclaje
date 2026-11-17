import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:recircula/models/beneficio.dart';
import 'package:recircula/models/mi_canje.dart';
import 'package:recircula/models/usuario.dart';
import 'package:recircula/repositories/beneficios_repository.dart';
import 'package:recircula/repositories/beneficios_repository_mock.dart';
import 'package:recircula/repositories/usuario_repository.dart';
import 'package:recircula/screens/beneficios_screen.dart';
import 'package:recircula/screens/mis_canjes_screen.dart';
import 'package:recircula/state/usuario_controller.dart';
import 'package:recircula/theme/app_theme.dart';

class _UsuarioFijo implements UsuarioRepository {
  final int puntos;
  final String? correo;
  _UsuarioFijo(this.puntos, {this.correo = 'ana@example.com'});

  @override
  Future<Usuario> obtenerOCrear() async => Usuario(
    id: 'x',
    alias: 'ana',
    correo: correo,
    fechaRegistro: DateTime(2026, 9, 1),
    puntosTotales: puntos,
  );

  @override
  Future<Usuario> guardarDatos({required String alias, String? nombre}) =>
      obtenerOCrear();
}

Beneficio _b(int id, int costo, {int? tope, int canjeados = 0, int? stock}) =>
    Beneficio(
      id: id,
      nombre: 'Beneficio $id',
      costo: costo,
      tipo: 'descuento',
      entidad: 'Municipalidad Demo',
      vigenciaFin: DateTime(2026, 12, 31),
      tope: tope,
      canjeados: canjeados,
      stock: stock,
    );

Future<void> _montar(
  WidgetTester tester,
  BeneficiosRepository repo, {
  UsuarioRepository? usuario,
}) async {
  tester.view.physicalSize = const Size(800, 3600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final controller = UsuarioController(usuario ?? _UsuarioFijo(100))..cargar();
  await tester.pumpWidget(
    UsuarioScope(
      controller: controller,
      child: MaterialApp(
        theme: AppTheme.light,
        home: BeneficiosScreen(repositorio: repo),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  test('Beneficio y MiCanje se arman desde las filas de las funciones', () {
    final b = Beneficio.fromSupabaseRow({
      'id_beneficio': 3,
      'nombre': 'Entrada',
      'descripcion': null,
      'costo_en_puntos': 30,
      'tipo': 'sorteo',
      'entidad': 'Muni',
      'vigencia_fin': '2026-12-31',
      'tope_por_usuario': 1,
      'stock': null,
      'canjeados': 1,
    });
    expect(b.esSorteo, true);
    expect(b.topeAlcanzado, true);
    expect(b.stock, isNull);

    final c = MiCanje.fromSupabaseRow({
      'id_canje': 9,
      'codigo_canje': 'ABCD2345',
      'estado': 'cancelado',
      'beneficio': 'Entrada',
      'entidad': 'Muni',
      'costo': 30,
      'fecha_generacion': '2026-10-09T10:00:00+00:00',
      'fecha_validacion': null,
    });
    expect(c.pendiente, false);
    expect(c.etiquetaEstado, contains('devolvimos'));
  });

  testWidgets('Canjear pide confirmación, descuenta y muestra el código', (
    tester,
  ) async {
    final repo = BeneficiosRepositoryMock(
      catalogo: [_b(1, 40), _b(2, 500)],
      saldo: 60,
    );
    await _montar(tester, repo);

    expect(find.text('Tu saldo: 100 Rebin Points'), findsOneWidget);
    expect(find.text('Te faltan 400 Rebin Points'), findsOneWidget);
    final caro = tester.widget<FilledButton>(
      find.byKey(const Key('canjear-2')),
    );
    expect(caro.onPressed, isNull);

    await tester.tap(find.byKey(const Key('canjear-1')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Se descontarán 40 Rebin Points'), findsOneWidget);
    await tester.tap(find.byKey(const Key('canje-confirmar')));
    await tester.pumpAndSettle();

    expect(repo.ultimoCanjeado, 1);
    expect(find.byKey(const Key('canje-codigo')), findsOneWidget);
    expect(find.text('ABCD2345'), findsOneWidget);
    expect(find.textContaining('Te quedan 60 Rebin Points'), findsOneWidget);
  });

  testWidgets('Cancelar la confirmación no canjea', (tester) async {
    final repo = BeneficiosRepositoryMock(catalogo: [_b(1, 40)]);
    await _montar(tester, repo);
    await tester.tap(find.byKey(const Key('canjear-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(repo.ultimoCanjeado, isNull);
  });

  testWidgets('Un invitado ve el catálogo pero no puede canjear', (
    tester,
  ) async {
    final repo = BeneficiosRepositoryMock(catalogo: [_b(1, 40)]);
    await _montar(tester, repo, usuario: _UsuarioFijo(500, correo: null));
    expect(
      find.textContaining('necesitas una cuenta con correo'),
      findsOneWidget,
    );
    expect(find.text('Necesitas una cuenta'), findsOneWidget);
    final boton = tester.widget<FilledButton>(
      find.byKey(const Key('canjear-1')),
    );
    expect(boton.onPressed, isNull);
  });

  testWidgets('Con el tope alcanzado el botón lo dice y no deja canjear', (
    tester,
  ) async {
    final repo = BeneficiosRepositoryMock(
      catalogo: [_b(1, 40, tope: 1, canjeados: 1)],
    );
    await _montar(tester, repo);
    expect(find.text('Ya lo canjeaste'), findsOneWidget);
    final boton = tester.widget<FilledButton>(
      find.byKey(const Key('canjear-1')),
    );
    expect(boton.onPressed, isNull);
  });

  testWidgets('El rechazo del servidor se muestra y no rompe la pantalla', (
    tester,
  ) async {
    final repo = BeneficiosRepositoryMock(
      catalogo: [_b(1, 40, stock: 1)],
      error: const CanjeException(MotivoErrorCanje.sinStock),
    );
    await _montar(tester, repo);
    await tester.tap(find.byKey(const Key('canjear-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('canje-confirmar')));
    await tester.pumpAndSettle();
    expect(find.text('Este beneficio se agotó.'), findsOneWidget);
  });

  testWidgets('Sin beneficios lo explica', (tester) async {
    await _montar(tester, BeneficiosRepositoryMock());
    expect(
      find.textContaining('no hay beneficios disponibles'),
      findsOneWidget,
    );
  });

  testWidgets('Mis canjes muestra el código solo de los pendientes', (
    tester,
  ) async {
    final repo = BeneficiosRepositoryMock(
      canjes: [
        MiCanje(
          id: 1,
          codigo: 'PEND2345',
          estado: 'pendiente',
          beneficio: 'Descuento',
          entidad: 'Muni',
          costo: 40,
          fecha: DateTime(2026, 10, 9),
        ),
        MiCanje(
          id: 2,
          codigo: 'VALI2345',
          estado: 'validado',
          beneficio: 'Entrada',
          entidad: 'Muni',
          costo: 30,
          fecha: DateTime(2026, 10, 8),
        ),
      ],
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: MisCanjesScreen(repositorio: repo),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('PEND2345'), findsOneWidget);
    expect(find.text('VALI2345'), findsNothing);
    expect(find.text('Entregado'), findsOneWidget);
  });
}
