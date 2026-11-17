/// Un canje propio (fila de `app_mis_canjes`). Con el [codigo] la persona se
/// presenta ante la entidad para retirar el beneficio.
class MiCanje {
  final int id;
  final String codigo;
  final String estado;
  final String beneficio;
  final String entidad;
  final int costo;
  final DateTime fecha;
  final DateTime? fechaValidacion;

  const MiCanje({
    required this.id,
    required this.codigo,
    required this.estado,
    required this.beneficio,
    required this.entidad,
    required this.costo,
    required this.fecha,
    this.fechaValidacion,
  });

  factory MiCanje.fromSupabaseRow(Map<String, dynamic> fila) {
    return MiCanje(
      id: fila['id_canje'] as int,
      codigo: fila['codigo_canje'] as String,
      estado: fila['estado'] as String,
      beneficio: fila['beneficio'] as String,
      entidad: fila['entidad'] as String,
      costo: (fila['costo'] as num).toInt(),
      fecha: DateTime.parse(fila['fecha_generacion'] as String),
      fechaValidacion: fila['fecha_validacion'] == null
          ? null
          : DateTime.parse(fila['fecha_validacion'] as String),
    );
  }

  bool get pendiente => estado == 'pendiente';

  String get etiquetaEstado => switch (estado) {
    'pendiente' => 'Por retirar',
    'validado' => 'Entregado',
    'cancelado' => 'Cancelado (te devolvimos los Rebin Points)',
    _ => estado,
  };
}

/// Resultado de canjear: el código de un solo uso y cuánto saldo queda.
class ResultadoCanje {
  final String codigo;
  final int costo;
  final int saldo;

  const ResultadoCanje({
    required this.codigo,
    required this.costo,
    required this.saldo,
  });
}
