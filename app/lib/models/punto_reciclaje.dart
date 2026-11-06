import 'material_type.dart';
import 'estado_punto.dart';

enum FuentePunto { oficial, comunidad, osm }

extension FuentePuntoInfo on FuentePunto {
  static FuentePunto fromCodigo(String codigo) => switch (codigo) {
    'oficial' => FuentePunto.oficial,
    'osm' => FuentePunto.osm,
    _ => FuentePunto.comunidad,
  };
}

class PuntoReciclaje {
  final String id;
  final String nombre;
  final String comuna;
  final String direccion;
  final double lat;
  final double lng;
  final FuentePunto fuente;
  final List<TipoMaterial> materiales;
  final EstadoPunto estado;
  final double calificacionPromedio;
  final int numCalificaciones;

  const PuntoReciclaje({
    required this.id,
    required this.nombre,
    required this.comuna,
    required this.direccion,
    required this.lat,
    required this.lng,
    required this.fuente,
    required this.materiales,
    required this.estado,
    required this.calificacionPromedio,
    required this.numCalificaciones,
  });

  /// Arma un punto desde una fila devuelta por la RPC `puntos_cercanos` de
  /// Supabase. `comuna` puede venir null (puntos importados de OSM sin
  /// `addr:city`); se muestra un texto explícito en vez de dejarlo vacío.
  factory PuntoReciclaje.fromSupabaseRow(Map<String, dynamic> fila) {
    final materialesFila = (fila['materiales'] as List?) ?? const [];
    return PuntoReciclaje(
      id: fila['id'] as String,
      nombre: fila['nombre'] as String,
      comuna: (fila['comuna'] as String?) ?? 'Comuna sin especificar',
      direccion: (fila['direccion'] as String?) ?? '',
      lat: (fila['lat'] as num).toDouble(),
      lng: (fila['lng'] as num).toDouble(),
      fuente: FuentePuntoInfo.fromCodigo(fila['fuente'] as String),
      materiales: materialesFila
          .map((codigo) => MaterialTypeInfo.fromCodigo(codigo as String))
          .nonNulls
          .toList(),
      estado: EstadoPuntoInfo.fromCodigo(fila['estado_actual'] as String),
      calificacionPromedio: (fila['calificacion_promedio'] as num).toDouble(),
      numCalificaciones: fila['num_calificaciones'] as int,
    );
  }
}
