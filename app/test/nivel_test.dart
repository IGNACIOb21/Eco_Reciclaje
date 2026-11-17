import 'package:flutter_test/flutter_test.dart';
import 'package:recircula/models/nivel.dart';
import 'package:recircula/models/usuario.dart';

void main() {
  test('los umbrales coinciden con la tabla niveles de la base', () {
    expect(Nivel.porDefecto.map((n) => n.puntosMinimos), [
      0,
      200,
      600,
      1500,
      3000,
    ]);
  });

  test('el nivel sale de los puntos acumulados', () {
    expect(Nivel.paraPuntos(199).nombre, 'Novato');
    expect(Nivel.paraPuntos(200).nombre, 'Aprendiz');
    expect(Nivel.paraPuntos(1500).nombre, 'Experto');
    expect(Nivel.paraPuntos(5000).nombre, 'Maestro');
  });

  test('sin acumulados informados se asume el saldo', () {
    final u = Usuario(
      id: 'x',
      alias: 'a',
      fechaRegistro: DateTime(2026),
      puntosTotales: 80,
    );
    expect(u.puntosAcumulados, 80);
  });
}
