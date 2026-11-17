import 'package:flutter_test/flutter_test.dart';

import 'package:recircula/models/actividad_puntos.dart';
import 'package:recircula/models/movimiento_punto.dart';

ActividadPuntos _act(String tipo, int cantidad) =>
    ActividadPuntos.desdeMovimiento(
      MovimientoPunto(
        tipo: tipo,
        cantidad: cantidad,
        fecha: DateTime(2026, 10, 9),
      ),
    );

void main() {
  test('un canje descuenta y su cancelación se lee como devolución', () {
    expect(_act('canje', -67).texto, 'Canjeaste un beneficio');
    expect(_act('canje', 67).texto, 'Te devolvimos los Rebin Points de un canje');
  });

  test('una acción con puntos negativos se lee como reversión', () {
    expect(_act('reporte', 3).texto, 'Reportaste el estado de un punto');
    expect(_act('reporte', -3).texto, 'Se revirtieron Rebin Points de una acción');
  });

  test('las demás acciones no cambian', () {
    expect(_act('racha', 1).texto, 'Mantuviste tu racha diaria');
    expect(_act('valoracion', 2).texto, 'Calificaste un punto');
  });
}
