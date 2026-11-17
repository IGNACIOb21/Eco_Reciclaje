import 'material_type.dart';

/// Datos que una persona envía para postular su servicio de recolección. Queda
/// pendiente hasta que el panel lo apruebe o lo rechace con un motivo.
class PostulacionServicio {
  final String nombre;
  final String contacto;
  final List<String> comunas;
  final List<TipoMaterial> materiales;
  final String descripcion;
  final bool retiraADomicilio;
  final Map<String, String> horario;

  const PostulacionServicio({
    required this.nombre,
    required this.contacto,
    required this.comunas,
    required this.materiales,
    this.descripcion = '',
    this.retiraADomicilio = false,
    this.horario = const {},
  });
}

enum EstadoPostulacion { pendiente, activo, rechazado, inactivo }

extension EstadoPostulacionInfo on EstadoPostulacion {
  static EstadoPostulacion fromCodigo(String codigo) => switch (codigo) {
    'activo' => EstadoPostulacion.activo,
    'rechazado' => EstadoPostulacion.rechazado,
    'inactivo' => EstadoPostulacion.inactivo,
    _ => EstadoPostulacion.pendiente,
  };

  String get etiqueta => switch (this) {
    EstadoPostulacion.pendiente => 'En revisión',
    EstadoPostulacion.activo => 'Publicado',
    EstadoPostulacion.rechazado => 'Rechazado',
    EstadoPostulacion.inactivo => 'Despublicado',
  };
}

/// Una postulación propia, tal como la devuelve `app_mis_postulaciones`.
class MiPostulacion {
  final String id;
  final String nombre;
  final EstadoPostulacion estado;
  final String? motivoRechazo;
  final DateTime fecha;

  const MiPostulacion({
    required this.id,
    required this.nombre,
    required this.estado,
    required this.fecha,
    this.motivoRechazo,
  });

  factory MiPostulacion.fromSupabaseRow(Map<String, dynamic> fila) {
    return MiPostulacion(
      id: fila['id'] as String,
      nombre: fila['nombre'] as String,
      estado: EstadoPostulacionInfo.fromCodigo(fila['estado'] as String),
      motivoRechazo: fila['motivo_rechazo'] as String?,
      fecha: DateTime.parse(fila['fecha_registro'] as String),
    );
  }
}
