import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recircula/theme/app_theme.dart';
import 'package:recircula/theme/elevacion.dart';
import 'package:recircula/widgets/anillo_meta.dart';
import 'package:recircula/widgets/barra_nivel.dart';
import 'package:recircula/widgets/boton_app.dart';
import 'package:recircula/widgets/chip_rebin.dart';
import 'package:recircula/widgets/contador_puntos.dart';
import 'package:recircula/widgets/puntos_que_vuelan.dart';
import 'package:recircula/widgets/toast_rebin.dart';

Widget _envolver(Widget hijo, {ThemeData? tema, bool reducir = false}) =>
    MaterialApp(
      theme: tema ?? AppTheme.light,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: reducir),
        child: child!,
      ),
      home: Scaffold(body: Center(child: hijo)),
    );

void main() {
  group('BotonApp', () {
    testWidgets('las 5 variantes se dibujan y responden al toque', (
      tester,
    ) async {
      for (final v in VarianteBoton.values) {
        var toques = 0;
        await tester.pumpWidget(
          _envolver(
            BotonApp(texto: v.name, variante: v, onPressed: () => toques++),
          ),
        );
        await tester.tap(find.text(v.name));
        await tester.pumpAndSettle();
        expect(toques, 1, reason: v.name);
      }
    });

    testWidgets('el peligro usa la terracota y el terciario no tiene relleno', (
      tester,
    ) async {
      final c = AppTheme.light.extension<ColoresApp>()!;
      await tester.pumpWidget(
        _envolver(
          BotonApp(
            texto: 'Eliminar',
            variante: VarianteBoton.peligro,
            onPressed: () {},
          ),
        ),
      );
      var deco =
          tester
                  .widget<AnimatedContainer>(find.byType(AnimatedContainer))
                  .decoration
              as BoxDecoration;
      expect(deco.color, c.alerta);

      await tester.pumpWidget(
        _envolver(
          BotonApp(
            texto: 'Ahora no',
            variante: VarianteBoton.terciario,
            onPressed: () {},
          ),
        ),
      );
      deco =
          tester
                  .widget<AnimatedContainer>(find.byType(AnimatedContainer))
                  .decoration
              as BoxDecoration;
      expect(deco.color, Colors.transparent);
    });

    testWidgets(
      'dentro de un Row el botón de Material no pide ancho infinito',
      (tester) async {
        await tester.pumpWidget(
          _envolver(
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton(onPressed: () {}, child: const Text('Unirse')),
                OutlinedButton(onPressed: () {}, child: const Text('Salir')),
              ],
            ),
          ),
        );
        expect(tester.takeException(), isNull);
        expect(find.text('Unirse'), findsOneWidget);
      },
    );
  });

  group('ContadorPuntos', () {
    testWidgets('rueda hasta el valor nuevo', (tester) async {
      await tester.pumpWidget(_envolver(const ContadorPuntos(puntos: 524)));
      expect(find.text('524'), findsOneWidget);
      await tester.pumpWidget(_envolver(const ContadorPuntos(puntos: 529)));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('524'), findsNothing);
      await tester.pumpAndSettle();
      expect(find.text('529'), findsOneWidget);
    });

    testWidgets('con reducir animaciones salta al valor final', (tester) async {
      await tester.pumpWidget(
        _envolver(const ContadorPuntos(puntos: 524), reducir: true),
      );
      await tester.pumpWidget(
        _envolver(const ContadorPuntos(puntos: 529), reducir: true),
      );
      await tester.pump();
      expect(find.text('529'), findsOneWidget);
    });

    testWidgets('se anuncia como región viva', (tester) async {
      final semantica = tester.ensureSemantics();
      await tester.pumpWidget(_envolver(const ContadorPuntos(puntos: 524)));
      expect(find.bySemanticsLabel('524 Rebin Points'), findsOneWidget);
      semantica.dispose();
    });
  });

  group('PuntosQueVuelan', () {
    testWidgets('avisa al llegar y quita la píldora', (tester) async {
      final origen = GlobalKey(), destino = GlobalKey();
      var llego = false;
      await tester.pumpWidget(
        _envolver(
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(key: origen, width: 20, height: 20),
              const SizedBox(height: 200),
              SizedBox(key: destino, width: 20, height: 20),
              Builder(
                builder: (context) => TextButton(
                  onPressed: () => PuntosQueVuelan.lanzar(
                    context,
                    desde: origen,
                    hasta: destino,
                    texto: '+5',
                    alLlegar: () => llego = true,
                  ),
                  child: const Text('volar'),
                ),
              ),
            ],
          ),
        ),
      );
      await tester.tap(find.text('volar'));
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('+5'), findsOneWidget);
      expect(llego, isFalse);
      await tester.pump(const Duration(milliseconds: 700));
      expect(llego, isTrue);
      expect(find.text('+5'), findsNothing);
    });

    testWidgets('con reducir animaciones llega al instante', (tester) async {
      final origen = GlobalKey(), destino = GlobalKey();
      var llego = false;
      await tester.pumpWidget(
        _envolver(
          reducir: true,
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(key: origen, width: 20, height: 20),
              SizedBox(key: destino, width: 20, height: 20),
              Builder(
                builder: (context) => TextButton(
                  onPressed: () => PuntosQueVuelan.lanzar(
                    context,
                    desde: origen,
                    hasta: destino,
                    texto: '+5',
                    alLlegar: () => llego = true,
                  ),
                  child: const Text('volar'),
                ),
              ),
            ],
          ),
        ),
      );
      await tester.tap(find.text('volar'));
      await tester.pump();
      expect(llego, isTrue);
      expect(find.text('+5'), findsNothing);
    });
  });

  group('BarraNivel y AnilloMeta', () {
    testWidgets('la barra anuncia su porcentaje', (tester) async {
      final semantica = tester.ensureSemantics();
      await tester.pumpWidget(
        _envolver(const SizedBox(width: 300, child: BarraNivel(progreso: 0.5))),
      );
      expect(find.bySemanticsLabel('Avance de nivel'), findsOneWidget);
      semantica.dispose();
    });

    testWidgets('la barra sigue estable al subir el progreso', (tester) async {
      await tester.pumpWidget(
        _envolver(const SizedBox(width: 300, child: BarraNivel(progreso: 0.5))),
      );
      await tester.pumpWidget(
        _envolver(const SizedBox(width: 300, child: BarraNivel(progreso: 0.7))),
      );
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'el anillo muestra la etiqueta y dice si la meta está completa',
      (tester) async {
        final semantica = tester.ensureSemantics();
        await tester.pumpWidget(
          _envolver(const AnilloMeta(progreso: 0, etiqueta: '0/1')),
        );
        expect(find.text('0/1'), findsOneWidget);
        expect(find.bySemanticsLabel('Meta de hoy pendiente'), findsOneWidget);
        await tester.pumpWidget(
          _envolver(const AnilloMeta(progreso: 1, etiqueta: '1/1')),
        );
        await tester.pumpAndSettle();
        expect(find.bySemanticsLabel('Meta de hoy completa'), findsOneWidget);
        semantica.dispose();
      },
    );
  });

  group('ChipRebin y ToastRebin', () {
    testWidgets('seleccionado muestra el check y no solo cambia de color', (
      tester,
    ) async {
      await tester.pumpWidget(
        _envolver(
          ChipRebin(texto: 'Vidrio', seleccionado: false, onTap: () {}),
        ),
      );
      expect(find.byIcon(Icons.check), findsNothing);
      await tester.pumpWidget(
        _envolver(ChipRebin(texto: 'Vidrio', seleccionado: true, onTap: () {})),
      );
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.check), findsOneWidget);
    });

    testWidgets('el chip mide al menos 44 de alto', (tester) async {
      await tester.pumpWidget(
        _envolver(
          ChipRebin(texto: 'Vidrio', seleccionado: false, onTap: () {}),
        ),
      );
      expect(
        tester.getSize(find.byType(ChipRebin)).height,
        greaterThanOrEqualTo(44),
      );
    });

    testWidgets('el aviso aparece y se va solo', (tester) async {
      await tester.pumpWidget(
        _envolver(
          Builder(
            builder: (context) => TextButton(
              onPressed: () => ToastRebin.mostrar(
                context,
                '¡Bien!',
                textoDorado: '+5 Rebin Points',
                duracion: const Duration(seconds: 1),
              ),
              child: const Text('avisar'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('avisar'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(
        find.textContaining('+5 Rebin Points', findRichText: true),
        findsOneWidget,
      );
      await tester.pump(const Duration(seconds: 2));
      expect(
        find.textContaining('+5 Rebin Points', findRichText: true),
        findsNothing,
      );
    });
  });

  group('Elevacion', () {
    test('en Modo Eco no hay sombras y en claro crecen con el nivel', () {
      expect(Elevacion.nivel(2, brillo: Brightness.dark), isEmpty);
      expect(Elevacion.nivel(0, brillo: Brightness.light), isEmpty);
      final e1 = Elevacion.nivel(1, brillo: Brightness.light).single;
      final e3 = Elevacion.nivel(3, brillo: Brightness.light).single;
      expect(e3.blurRadius, greaterThan(e1.blurRadius));
      expect(e3.blurRadius, lessThanOrEqualTo(20));
    });
  });
}
