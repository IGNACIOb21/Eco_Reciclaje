import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recircula/models/estado_punto.dart';
import 'package:recircula/models/material_type.dart';
import 'package:recircula/models/punto_reciclaje.dart';
import 'package:recircula/theme/app_theme.dart';
import 'package:recircula/utils/busqueda.dart';
import 'package:recircula/widgets/tarjeta_cercana.dart';

PuntoReciclaje _punto({
  String nombre = 'Campana de vidrio Plaza Ñuñoa',
  List<TipoMaterial> materiales = const [TipoMaterial.vidrio],
  int calificaciones = 12,
}) => PuntoReciclaje(
  id: 'p1',
  nombre: nombre,
  comuna: 'Ñuñoa',
  direccion: 'Av. Irarrázaval 3400',
  lat: -33.45,
  lng: -70.6,
  fuente: FuentePunto.oficial,
  materiales: materiales,
  estado: EstadoPunto.disponible,
  calificacionPromedio: 4.4,
  numCalificaciones: calificaciones,
);

Future<void> _montar(WidgetTester tester, PuntoReciclaje p) =>
    tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: TarjetaCercana(punto: p, distanciaKm: 0.22, onTap: () {}),
        ),
      ),
    );

void main() {
  test('La distancia corta usa metros bajo 1 km y coma decimal', () {
    expect(distanciaCorta(0.22), '220 m');
    expect(distanciaCorta(0.001), '10 m');
    expect(distanciaCorta(1.25), '1,3 km');
  });

  test('El buscador también encuentra por material', () {
    final puntos = [
      _punto(),
      _punto(nombre: 'Punto Limpio', materiales: [TipoMaterial.pilas]),
    ];
    expect(filtrarPuntos(puntos, 'pilas').single.nombre, 'Punto Limpio');
    expect(filtrarPuntos(puntos, 'vidrio'), hasLength(1));
  });

  testWidgets('La fila muestra distancia, estado y calificación', (
    tester,
  ) async {
    await _montar(tester, _punto());

    expect(find.text('Campana de vidrio Plaza Ñuñoa'), findsOneWidget);
    expect(find.text('220 m · Disponible', findRichText: true), findsOneWidget);
    expect(find.text('4,4'), findsOneWidget);
  });

  testWidgets('Sin calificaciones no muestra la nota', (tester) async {
    await _montar(tester, _punto(calificaciones: 0));
    expect(find.text('4,4'), findsNothing);
  });

  testWidgets('Con varios materiales muestra el ícono de reciclaje', (
    tester,
  ) async {
    await _montar(
      tester,
      _punto(materiales: [TipoMaterial.papel, TipoMaterial.plastico]),
    );
    expect(find.byIcon(Icons.recycling), findsOneWidget);
  });
}
