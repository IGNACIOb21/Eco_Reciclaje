import '../data/mock_puntos.dart';
import '../models/estado_punto.dart';
import '../models/filtros_mapa.dart';
import '../models/punto_reciclaje.dart';
import '../utils/geo.dart' as geo;
import 'puntos_repository.dart';

/// Fuente de datos mock para el Mapa: útil para demos sin conexión. Se
/// mantiene disponible aunque la app use Supabase por defecto (ver
/// MapaScreen).
class PuntosRepositoryMock implements PuntosRepository {
  @override
  Future<List<PuntoReciclaje>> obtenerPuntos({
    required double miLat,
    required double miLng,
    required FiltrosMapa filtros,
  }) async {
    double distanciaDe(PuntoReciclaje p) =>
        geo.distanciaKm(miLat, miLng, p.lat, p.lng);

    final puntos = mockPuntos.where((p) {
      if (filtros.comuna != null && p.comuna != filtros.comuna) return false;
      if (filtros.materiales.isNotEmpty &&
          !p.materiales.any(filtros.materiales.contains)) {
        return false;
      }
      if (filtros.soloDisponibles && p.estado != EstadoPunto.disponible) {
        return false;
      }
      if (p.calificacionPromedio < filtros.calificacionMinima) return false;
      if (distanciaDe(p) > filtros.distanciaMaximaKm) return false;
      return true;
    }).toList();

    switch (filtros.ordenarPor) {
      case OrdenPuntos.distancia:
        puntos.sort((a, b) => distanciaDe(a).compareTo(distanciaDe(b)));
      case OrdenPuntos.calificacion:
        puntos.sort(
          (a, b) => b.calificacionPromedio.compareTo(a.calificacionPromedio),
        );
      case OrdenPuntos.nombre:
        puntos.sort((a, b) => a.nombre.compareTo(b.nombre));
    }
    return puntos;
  }
}
