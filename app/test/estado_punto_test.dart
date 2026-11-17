import 'package:flutter_test/flutter_test.dart';

import 'package:recircula/models/estado_punto.dart';
import 'package:recircula/models/punto_reciclaje.dart';

void main() {
  // Valores que puede devolver `app_puntos_cercanos` en `estado_actual`
  // (backend/remoto/20261014100000_estado_visible_puntos.sql).
  const delServidor = {
    'disponible': EstadoPunto.disponible,
    'lleno': EstadoPunto.lleno,
    'danado': EstadoPunto.danado,
    'fuera_de_uso': EstadoPunto.fueraDeUso,
    'mal_mantenimiento': EstadoPunto.malMantenimiento,
    'sin_senalizacion': EstadoPunto.sinSenalizacion,
  };

  test('cada estado que produce el SQL se traduce al estado de la app', () {
    for (final MapEntry(key: codigo, value: estado) in delServidor.entries) {
      expect(EstadoPuntoInfo.fromCodigo(codigo), estado, reason: codigo);
      expect(estado.codigo, codigo, reason: 'ida y vuelta de $codigo');
    }
  });

  test('un código desconocido se muestra como disponible, no rompe', () {
    expect(EstadoPuntoInfo.fromCodigo('algo_nuevo'), EstadoPunto.disponible);
  });

  test('una fila con estado de reporte llega al punto', () {
    for (final MapEntry(key: codigo, value: estado) in delServidor.entries) {
      final punto = PuntoReciclaje.fromSupabaseRow({
        'id': '1',
        'nombre': 'Punto',
        'comuna': 'Ñuñoa',
        'direccion': '',
        'lat': -33.45,
        'lng': -70.6,
        'fuente': 'oficial',
        'estado_actual': codigo,
        'calificacion_promedio': 0,
        'num_calificaciones': 0,
        'materiales': ['vidrio'],
      });
      expect(punto.estado, estado, reason: codigo);
    }
  });
}
