import 'dart:math' as math;

const double _radioTierraKm = 6371;

/// Distancia en línea recta entre dos coordenadas (fórmula de Haversine).
double distanciaKm(double lat1, double lng1, double lat2, double lng2) {
  final dLat = _radianes(lat2 - lat1);
  final dLng = _radianes(lng2 - lng1);
  final a =
      math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(_radianes(lat1)) *
          math.cos(_radianes(lat2)) *
          math.sin(dLng / 2) *
          math.sin(dLng / 2);
  final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  return _radioTierraKm * c;
}

double _radianes(double grados) => grados * math.pi / 180;
