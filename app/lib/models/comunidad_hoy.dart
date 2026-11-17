/// Meta del mes de una comuna (`app_comunidad_hoy`), en objetos reciclados
/// (depósitos aprobados en puntos de la comuna; la base no guarda peso).
class MetaComuna {
  final String comuna;

  /// null si el panel no definió una meta este mes.
  final int? objetivo;
  final int actual;
  final int vecinos;
  final int tuAporte;
  final int diasRestantes;

  /// Primer día del mes de la meta.
  final DateTime? mes;

  const MetaComuna({
    required this.comuna,
    required this.objetivo,
    required this.actual,
    required this.vecinos,
    required this.tuAporte,
    required this.diasRestantes,
    this.mes,
  });

  double get progreso => objetivo == null || objetivo == 0
      ? 0
      : (actual / objetivo!).clamp(0.0, 1.0).toDouble();

  factory MetaComuna.fromJson(Map<String, dynamic> j) => MetaComuna(
    comuna: j['comuna'] as String? ?? '',
    objetivo: (j['objetivo'] as num?)?.toInt(),
    actual: (j['actual'] as num?)?.toInt() ?? 0,
    vecinos: (j['vecinos'] as num?)?.toInt() ?? 0,
    tuAporte: (j['tu_aporte'] as num?)?.toInt() ?? 0,
    diasRestantes: (j['dias_restantes'] as num?)?.toInt() ?? 0,
    mes: j['mes'] == null ? null : DateTime.tryParse(j['mes'] as String),
  );
}

enum TipoActividad { reporte, puntoNuevo, reciclaje, otro }

/// Un hecho reciente en la comuna (`app_actividad_comuna`). Los depósitos van
/// sin nombre ("Vecinos") y quien se ocultó figura como "Un vecino".
class ActividadComuna {
  final TipoActividad tipo;
  final String alias;
  final String texto;
  final DateTime fecha;

  const ActividadComuna({
    required this.tipo,
    required this.alias,
    required this.texto,
    required this.fecha,
  });

  factory ActividadComuna.fromJson(Map<String, dynamic> j) => ActividadComuna(
    tipo: switch (j['tipo']) {
      'reporte' => TipoActividad.reporte,
      'punto_nuevo' => TipoActividad.puntoNuevo,
      'reciclaje' => TipoActividad.reciclaje,
      _ => TipoActividad.otro,
    },
    alias: j['alias'] as String? ?? 'Un vecino',
    texto: j['texto'] as String? ?? '',
    fecha: DateTime.parse(j['fecha'] as String).toLocal(),
  );
}

/// Una fila del ranking semanal (`app_ranking_semana`): solo alias y puntos.
class PuestoRanking {
  final int posicion;
  final String alias;
  final int puntos;
  final bool esTuyo;

  const PuestoRanking({
    required this.posicion,
    required this.alias,
    required this.puntos,
    required this.esTuyo,
  });

  factory PuestoRanking.fromJson(Map<String, dynamic> j) => PuestoRanking(
    posicion: (j['posicion'] as num).toInt(),
    alias: j['alias'] as String? ?? '',
    puntos: (j['puntos'] as num).toInt(),
    esTuyo: j['es_tuyo'] as bool? ?? false,
  );
}

/// "hace 20 min", "hace 3 h", "ayer", "hace 4 días".
String haceCuanto(DateTime fecha, DateTime ahora) {
  final d = ahora.difference(fecha);
  if (d.inMinutes < 1) return 'recién';
  if (d.inMinutes < 60) return 'hace ${d.inMinutes} min';
  if (d.inHours < 24) return 'hace ${d.inHours} h';
  if (d.inDays == 1) return 'ayer';
  return 'hace ${d.inDays} días';
}
