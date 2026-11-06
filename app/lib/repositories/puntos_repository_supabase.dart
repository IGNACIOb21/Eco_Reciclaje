import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/filtros_mapa.dart';
import '../models/material_type.dart';
import '../models/punto_reciclaje.dart';
import '../services/supabase_service.dart';
import 'puntos_repository.dart';

/// Llama a la RPC `puntos_cercanos` (PostGIS) en vez de traer toda la tabla
/// y filtrar en el cliente: el filtrado por comuna/materiales/disponibilidad/
/// calificación y el radio ya los resuelve la función en Postgres (ver
/// backend/supabase/migrations/20260908232413_puntos_reciclaje.sql). El
/// orden pedido por el usuario (distancia/calificación/nombre) se aplica acá
/// porque la RPC siempre devuelve ordenado por distancia.
class PuntosRepositorySupabase implements PuntosRepository {
  final SupabaseClient _cliente;

  PuntosRepositorySupabase({SupabaseClient? cliente})
    : _cliente = cliente ?? SupabaseService.cliente;

  @override
  Future<List<PuntoReciclaje>> obtenerPuntos({
    required double miLat,
    required double miLng,
    required FiltrosMapa filtros,
  }) async {
    final filas = await _cliente.rpc(
      'puntos_cercanos',
      params: {
        'p_lat': miLat,
        'p_lng': miLng,
        'radio_km': filtros.distanciaMaximaKm,
        'comuna_filtro': filtros.comuna,
        'materiales_filtro': filtros.materiales.isEmpty
            ? null
            : filtros.materiales.map((m) => m.codigo).nonNulls.toList(),
        'solo_disponibles': filtros.soloDisponibles,
        'calificacion_minima': filtros.calificacionMinima,
      },
    );

    final puntos = (filas as List)
        .map(
          (fila) =>
              PuntoReciclaje.fromSupabaseRow(fila as Map<String, dynamic>),
        )
        .toList();

    switch (filtros.ordenarPor) {
      case OrdenPuntos.distancia:
        break; // La RPC ya devuelve ordenado por distancia.
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
