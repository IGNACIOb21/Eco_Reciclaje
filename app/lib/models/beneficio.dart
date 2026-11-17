/// Un beneficio canjeable (fila de `app_beneficios`). [canjeados] son las
/// veces que lo canjeó esta cuenta (sin los cancelados).
class Beneficio {
  final int id;
  final String nombre;
  final String? descripcion;
  final int costo;
  final String tipo;
  final String entidad;
  final DateTime vigenciaFin;

  /// null = sin tope por persona.
  final int? tope;

  /// null = sin control de stock.
  final int? stock;
  final int canjeados;

  const Beneficio({
    required this.id,
    required this.nombre,
    required this.costo,
    required this.tipo,
    required this.entidad,
    required this.vigenciaFin,
    this.descripcion,
    this.tope,
    this.stock,
    this.canjeados = 0,
  });

  factory Beneficio.fromSupabaseRow(Map<String, dynamic> fila) {
    return Beneficio(
      id: fila['id_beneficio'] as int,
      nombre: fila['nombre'] as String,
      descripcion: fila['descripcion'] as String?,
      costo: fila['costo_en_puntos'] as int,
      tipo: fila['tipo'] as String,
      entidad: fila['entidad'] as String,
      vigenciaFin: DateTime.parse(fila['vigencia_fin'] as String),
      tope: (fila['tope_por_usuario'] as num?)?.toInt(),
      stock: (fila['stock'] as num?)?.toInt(),
      canjeados: (fila['canjeados'] as num?)?.toInt() ?? 0,
    );
  }

  bool get esSorteo => tipo == 'sorteo';

  /// true cuando ya canjeó el máximo permitido por persona.
  bool get topeAlcanzado => tope != null && canjeados >= tope!;
}
