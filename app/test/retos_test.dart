import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recircula/models/reto.dart';
import 'package:recircula/repositories/retos_repository_mock.dart';
import 'package:recircula/screens/retos_screen.dart';
import 'package:recircula/theme/app_theme.dart';

void main() {
  _sinMisiones();

  test('El nivel de un logro sale del avance y los escalones', () {
    const logro = Logro(
      id: 'x',
      nombre: 'X',
      descripcion: '',
      icono: Icons.star,
      color: Colors.green,
      actual: 20,
      escalones: [
        EscalonLogro(10, 5),
        EscalonLogro(20, 10),
        EscalonLogro(50, 20),
      ],
    );
    expect(logro.nivel, 2);
    expect(logro.metaActual, 50);
    expect(logro.completo, isFalse);
  });

  testWidgets('Reclamar una misión lista la marca como reclamada', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: RetosScreen(repositorio: RetosRepositoryMock()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('1 de 5 completadas'), findsOneWidget);

    await tester.tap(find.byKey(const Key('reclamar-m1')));
    await tester.pumpAndSettle();
    expect(find.textContaining('2 de 5 completadas'), findsOneWidget);
    expect(find.text('+10 Rebin Points'), findsOneWidget);
  });

  test('Un logro alcanzado sin reclamar queda reclamable', () {
    const logro = Logro(
      id: 'x',
      nombre: 'X',
      descripcion: '',
      icono: Icons.star,
      color: Colors.green,
      actual: 20,
      escalones: [
        EscalonLogro(10, 5),
        EscalonLogro(20, 10),
        EscalonLogro(50, 20),
      ],
      nivelReclamado: 1,
    );
    expect(logro.nivel, 1);
    expect(logro.reclamable, isTrue);
    expect(logro.puntosSiguiente, 10);
    expect(logro.copyWith(nivelReclamado: 2).reclamable, isFalse);
  });

  testWidgets('Reclamar un logro sube su nivel y quita el botón', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: RetosScreen(repositorio: RetosRepositoryMock()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Logros'));
    await tester.pumpAndSettle();

    final boton = find.byKey(const Key('reclamar-logro-l1'));
    expect(boton, findsOneWidget);
    await tester.tap(boton);
    await tester.pumpAndSettle();
    expect(boton, findsNothing);
    expect(find.text('II'), findsOneWidget);
  });
}

class _SinMisiones extends RetosRepositoryMock {
  @override
  Future<Retos> retos() async {
    final r = await super.retos();
    return Retos(misiones: const [], logros: r.logros);
  }
}

void _sinMisiones() {
  testWidgets('Sin misiones en la base muestra un aviso, no "0 de 0"', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: RetosScreen(repositorio: _SinMisiones()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('misiones-vacio')), findsOneWidget);
    expect(find.text('Pronto habrá misiones'), findsOneWidget);
    expect(find.textContaining('de 0'), findsNothing);
  });
}
