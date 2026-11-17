import 'material_type.dart';

/// Un punto nuevo sugerido por otra persona y aún sin revisar, que se puede
/// confirmar si estás cerca (fila de `app_sugerencias_cercanas`).
class SugerenciaCercana {
  final int id;
  final String nombre;
  final double lat;
  final double lng;
  final String comuna;
  final List<TipoMaterial> materiales;
  final int confirmaciones;
  final bool esMia;
  final bool yaConfirmada;

  const SugerenciaCercana({
    required this.id,
    required this.nombre,
    required this.lat,
    required this.lng,
    required this.comuna,
    required this.materiales,
    required this.confirmaciones,
    required this.esMia,
    required this.yaConfirmada,
  });

  factory SugerenciaCercana.fromSupabaseRow(Map<String, dynamic> fila) {
    return SugerenciaCercana(
      id: fila['id_sugerencia'] as int,
      nombre: fila['nombre'] as String,
      lat: (fila['lat'] as num).toDouble(),
      lng: (fila['lng'] as num).toDouble(),
      comuna: fila['comuna'] as String,
      materiales: ((fila['materiales'] as List?) ?? const [])
          .map((c) => MaterialTypeInfo.fromCodigo(c as String))
          .nonNulls
          .toList(),
      confirmaciones: fila['confirmaciones'] as int,
      esMia: fila['es_mia'] as bool,
      yaConfirmada: fila['ya_confirmada'] as bool,
    );
  }

  SugerenciaCercana confirmada(int total) => SugerenciaCercana(
    id: id,
    nombre: nombre,
    lat: lat,
    lng: lng,
    comuna: comuna,
    materiales: materiales,
    confirmaciones: total,
    esMia: esMia,
    yaConfirmada: true,
  );
}
