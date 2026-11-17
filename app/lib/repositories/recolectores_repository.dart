import '../models/material_type.dart';
import '../models/postulacion_servicio.dart';
import '../models/recolector_particular.dart';

/// Acceso a los servicios de terceros (recolectores particulares). Las
/// pantallas dependen solo de esta interfaz, nunca de la fuente de datos
/// concreta (ver regla de repositorios en CLAUDE.md).
abstract class RecolectoresRepository {
  /// Servicios publicados. [comuna] y [materiales] filtran; sin ellos, todos.
  Future<List<RecolectorParticular>> obtenerRecolectores({
    String? comuna,
    List<TipoMaterial> materiales = const [],
  });

  /// Envía una postulación. Queda en revisión hasta que el panel la resuelva.
  /// Lanza [PostulacionException] si el servidor la rechaza.
  Future<void> postular(PostulacionServicio postulacion);

  /// Las postulaciones de esta cuenta, la más reciente primero.
  Future<List<MiPostulacion>> misPostulaciones();
}

enum MotivoErrorPostulacion {
  nombreInvalido,
  contactoInvalido,
  descripcionInvalida,
  horarioInvalido,
  comunasInvalidas,
  materialesInvalidos,
  limitePostulaciones,
  sinSesion,
  sinConexion,
  desconocido,
}

class PostulacionException implements Exception {
  final MotivoErrorPostulacion motivo;
  final Object? causa;

  const PostulacionException(this.motivo, [this.causa]);

  String get mensaje => switch (motivo) {
    MotivoErrorPostulacion.nombreInvalido =>
      'El nombre debe tener entre 3 y 100 caracteres.',
    MotivoErrorPostulacion.contactoInvalido =>
      'Indica un contacto válido (teléfono, correo o red social).',
    MotivoErrorPostulacion.descripcionInvalida =>
      'La descripción no puede superar los 500 caracteres.',
    MotivoErrorPostulacion.horarioInvalido =>
      'No se entendió el horario. Usa una línea "día: horas" por cada tramo.',
    MotivoErrorPostulacion.comunasInvalidas =>
      'Elige entre 1 y 10 comunas de cobertura.',
    MotivoErrorPostulacion.materialesInvalidos =>
      'Elige entre 1 y 10 materiales que recoges.',
    MotivoErrorPostulacion.limitePostulaciones =>
      'Ya tienes 3 postulaciones en revisión. Espera a que las resolvamos.',
    MotivoErrorPostulacion.sinSesion =>
      'Necesitas una sesión activa para postular. Reabre la app.',
    MotivoErrorPostulacion.sinConexion =>
      'No hay conexión. Revisa tu internet e inténtalo de nuevo.',
    MotivoErrorPostulacion.desconocido =>
      'Algo salió mal. Inténtalo de nuevo en unos minutos.',
  };

  @override
  String toString() => 'PostulacionException($motivo, $causa)';
}
