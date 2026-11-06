import '../models/filtros_mapa.dart';
import '../models/punto_reciclaje.dart';

/// Acceso a los puntos de reciclaje. Las pantallas dependen solo de esta
/// interfaz, nunca de Supabase directo (ver regla de repositorios en
/// CLAUDE.md).
abstract class PuntosRepository {
  Future<List<PuntoReciclaje>> obtenerPuntos({
    required double miLat,
    required double miLng,
    required FiltrosMapa filtros,
  });
}
