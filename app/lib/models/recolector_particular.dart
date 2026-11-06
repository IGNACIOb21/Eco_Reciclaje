import 'material_type.dart';

/// Persona o pequeño negocio que junta materiales reciclables fuera de los
/// puntos oficiales (ej. aceite usado, pilas, tetra pak). Todavía no existe
/// como entidad en el modelo de datos (docs/modelo-bd.pdf) — es contenido
/// nuevo, por ahora solo de maqueta (ver TODO en recolectores_repository.dart).
class RecolectorParticular {
  final String id;
  final String nombre;
  final List<TipoMaterial> materiales;
  final String comuna;
  final String descripcion;
  final String contacto;
  final bool retiraADomicilio;

  const RecolectorParticular({
    required this.id,
    required this.nombre,
    required this.materiales,
    required this.comuna,
    required this.descripcion,
    required this.contacto,
    required this.retiraADomicilio,
  });
}
