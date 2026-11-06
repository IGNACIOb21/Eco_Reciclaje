/// Fila del ledger `movimientos_puntos` del usuario (esquema remoto).
/// `tipo` es el enum `tipo_referencia_movimiento`: deposito / escaneo /
/// reporte / valoracion / sugerencia / racha / canje / ajuste. Los canjes
/// llegan con `cantidad` negativa.
class MovimientoPunto {
  final String tipo;
  final int cantidad;
  final DateTime fecha;

  const MovimientoPunto({
    required this.tipo,
    required this.cantidad,
    required this.fecha,
  });

  factory MovimientoPunto.fromSupabaseRow(Map<String, dynamic> fila) {
    return MovimientoPunto(
      tipo: fila['tipo_referencia'] as String,
      cantidad: fila['cantidad'] as int,
      fecha: DateTime.parse(fila['fecha'] as String),
    );
  }
}
