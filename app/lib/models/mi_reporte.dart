import 'tipo_reporte.dart';

/// Una fila de `app_mis_reportes`: un reporte propio y cómo va su alerta.
class MiReporte {
  final int idPunto;
  final String punto;
  final TipoReporte? tipo;
  final String? comentario;
  final DateTime fecha;

  /// recibida / en_atencion / resuelta; null si el reporte no genera alerta
  /// ("todo en orden").
  final String? estadoAlerta;

  /// null mientras la alerta no se resuelve.
  final bool? fueFundada;

  const MiReporte({
    required this.idPunto,
    required this.punto,
    required this.tipo,
    required this.fecha,
    this.comentario,
    this.estadoAlerta,
    this.fueFundada,
  });

  factory MiReporte.fromSupabaseRow(Map<String, dynamic> fila) {
    return MiReporte(
      idPunto: fila['id_punto'] as int,
      punto: fila['punto'] as String,
      tipo: TipoReporte.desdeCodigo(fila['tipo_reporte'] as String),
      comentario: fila['comentario'] as String?,
      fecha: DateTime.parse(fila['fecha'] as String),
      estadoAlerta: fila['estado_alerta'] as String?,
      fueFundada: fila['fue_fundada'] as bool?,
    );
  }

  /// Texto corto del avance para mostrar al ciudadano.
  String get avance {
    if (estadoAlerta == null) return 'Registrado';
    return switch (estadoAlerta) {
      'recibida' => 'Recibido por la entidad',
      'en_atencion' => 'En atención',
      'resuelta' => fueFundada == false ? 'Cerrado sin cambios' : 'Resuelto',
      _ => 'Enviado',
    };
  }
}
