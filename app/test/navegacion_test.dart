import 'package:flutter_test/flutter_test.dart';
import 'package:recircula/services/navegacion_service.dart';

void main() {
  test(
    'Cómo llegar arma la URL de rutas de Google Maps en transporte público',
    () {
      final url = urlComoLlegar(
        destinoLat: -33.4569,
        destinoLng: -70.5975,
        modo: ModoTransporte.transporte,
      );

      expect(url.host, 'www.google.com');
      expect(url.path, '/maps/dir/');
      expect(url.queryParameters, {
        'api': '1',
        'destination': '-33.4569,-70.5975',
        'travelmode': 'transit',
      });
    },
  );

  test('con la posición del usuario la manda como origen', () {
    final url = urlComoLlegar(
      destinoLat: -33.4569,
      destinoLng: -70.5975,
      modo: ModoTransporte.caminando,
      origenLat: -33.45,
      origenLng: -70.6,
    );

    expect(url.queryParameters['origin'], '-33.45,-70.6');
    expect(url.queryParameters['travelmode'], 'walking');
  });
}
