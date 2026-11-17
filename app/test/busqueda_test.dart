import 'package:flutter_test/flutter_test.dart';
import 'package:recircula/utils/busqueda.dart';

void main() {
  test('normalizarBusqueda quita tildes, eñes y mayúsculas', () {
    expect(normalizarBusqueda('  Ñuñoa Peñalolén '), 'nunoa penalolen');
  });
}
