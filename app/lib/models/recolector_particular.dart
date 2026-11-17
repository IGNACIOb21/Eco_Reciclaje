import '../utils/horario_texto.dart';
import 'material_type.dart';

/// Punto de reciclaje propio de un recolector (los de su entidad). Solo
/// lo necesario para listarlo en la ficha.
class PuntoServicio {
  final String id;
  final String nombre;
  final String direccion;
  final double lat;
  final double lng;

  const PuntoServicio({
    required this.id,
    required this.nombre,
    required this.direccion,
    required this.lat,
    required this.lng,
  });

  factory PuntoServicio.fromJson(Map<String, dynamic> json) => PuntoServicio(
    id: json['id'] as String,
    nombre: json['nombre'] as String,
    direccion: (json['direccion'] as String?) ?? '',
    lat: (json['lat'] as num).toDouble(),
    lng: (json['lng'] as num).toDouble(),
  );
}

/// Servicio de terceros: empresa o persona que retira o recibe materiales
/// reciclables (ej. aceite usado, pilas, tetra pak). Viene de la función
/// `app_servicios` (ver backend/remoto/20261011100000_servicios_terceros.sql).
class RecolectorParticular {
  final String id;
  final String nombre;
  final List<TipoMaterial> materiales;
  final List<String> comunas;
  final String descripcion;
  final String contacto;
  final bool retiraADomicilio;

  /// Horario de atención: día o rango → horas (ej. `lun-vie` → `9:00-18:00`).
  final Map<String, String> horario;

  /// Puntos de reciclaje de su entidad; vacío si es un particular sin entidad.
  final List<PuntoServicio> puntos;

  const RecolectorParticular({
    required this.id,
    required this.nombre,
    required this.materiales,
    required this.comunas,
    required this.descripcion,
    required this.contacto,
    required this.retiraADomicilio,
    this.horario = const {},
    this.puntos = const [],
  });

  /// Arma el servicio desde una fila de `app_servicios`. Un código de
  /// material que la app no conoce se descarta (como en PuntoReciclaje).
  factory RecolectorParticular.fromSupabaseRow(Map<String, dynamic> fila) {
    final horario = fila['horario'];
    return RecolectorParticular(
      id: fila['id'] as String,
      nombre: fila['nombre'] as String,
      materiales: ((fila['materiales'] as List?) ?? const [])
          .map((c) => MaterialTypeInfo.fromCodigo(c as String))
          .nonNulls
          .toList(),
      comunas: ((fila['comunas'] as List?) ?? const [])
          .map((c) => c as String)
          .toList(),
      descripcion: (fila['descripcion'] as String?) ?? '',
      contacto: fila['contacto'] as String,
      retiraADomicilio: fila['retira_a_domicilio'] as bool,
      horario: horario is Map
          ? ordenarHorario({
              for (final e in horario.entries) '${e.key}': '${e.value}',
            })
          : const {},
      puntos: ((fila['puntos'] as List?) ?? const [])
          .map((p) => PuntoServicio.fromJson(p as Map<String, dynamic>))
          .toList(),
    );
  }

  /// Comunas en una línea para la tarjeta ("Ñuñoa, Providencia").
  String get comunasTexto => comunas.join(', ');
}
