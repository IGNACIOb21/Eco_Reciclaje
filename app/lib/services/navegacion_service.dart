import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Modos de transporte de Google Maps (`travelmode` de la URL de rutas).
enum ModoTransporte { transporte, caminando, auto, bicicleta }

extension ModoTransporteInfo on ModoTransporte {
  String get parametro => switch (this) {
    ModoTransporte.transporte => 'transit',
    ModoTransporte.caminando => 'walking',
    ModoTransporte.auto => 'driving',
    ModoTransporte.bicicleta => 'bicycling',
  };

  String get etiqueta => switch (this) {
    ModoTransporte.transporte => 'Micro / Metro',
    ModoTransporte.caminando => 'A pie',
    ModoTransporte.auto => 'Auto',
    ModoTransporte.bicicleta => 'Bici',
  };

  IconData get icono => switch (this) {
    ModoTransporte.transporte => Icons.directions_transit_outlined,
    ModoTransporte.caminando => Icons.directions_walk,
    ModoTransporte.auto => Icons.directions_car_outlined,
    ModoTransporte.bicicleta => Icons.directions_bike,
  };
}

/// URL universal de rutas de Google Maps. Sin [origenLat]/[origenLng] Google
/// Maps parte desde la ubicación actual del teléfono.
Uri urlComoLlegar({
  required double destinoLat,
  required double destinoLng,
  required ModoTransporte modo,
  double? origenLat,
  double? origenLng,
}) {
  return Uri.https('www.google.com', '/maps/dir/', {
    'api': '1',
    if (origenLat != null && origenLng != null)
      'origin': '$origenLat,$origenLng',
    'destination': '$destinoLat,$destinoLng',
    'travelmode': modo.parametro,
  });
}

/// Abre la ruta en la app de Google Maps (o en el navegador si no está
/// instalada). Devuelve false si no hubo nada que pudiera abrirla.
Future<bool> abrirComoLlegar({
  required double destinoLat,
  required double destinoLng,
  required ModoTransporte modo,
  double? origenLat,
  double? origenLng,
}) async {
  final url = urlComoLlegar(
    destinoLat: destinoLat,
    destinoLng: destinoLng,
    modo: modo,
    origenLat: origenLat,
    origenLng: origenLng,
  );
  try {
    return await launchUrl(url, mode: LaunchMode.externalApplication);
  } catch (_) {
    return false;
  }
}
