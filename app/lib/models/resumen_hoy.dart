/// Estado de un día de la semana de racha, como lo devuelve `app_resumen_hoy`.
enum EstadoDia {
  hecho,
  congelado,
  hoy,
  pendiente,
  futuro;

  /// Un valor que la app no conoce cae en [pendiente] (nunca rompe la vista).
  static EstadoDia fromSupabase(String? valor) => switch (valor) {
    'hecho' => hecho,
    'congelado' => congelado,
    'hoy' => hoy,
    'futuro' => futuro,
    _ => pendiente,
  };
}

class DiaRacha {
  final DateTime fecha;
  final EstadoDia estado;

  const DiaRacha(this.fecha, this.estado);
}

/// Meta diaria, racha y congeladores del día (RPC `app_resumen_hoy`). La app
/// solo lo muestra: el progreso lo calcula la base.
class ResumenHoy {
  final bool metaCumplida;
  final int metaActual;
  final int metaObjetivo;
  final int racha;
  final int rachaMaxima;

  /// Lunes a domingo.
  final List<DiaRacha> semana;
  final int congeladores;
  final int maxCongeladores;
  final int costoCongelador;

  const ResumenHoy({
    required this.metaCumplida,
    required this.metaActual,
    required this.metaObjetivo,
    required this.racha,
    required this.rachaMaxima,
    required this.semana,
    required this.congeladores,
    required this.maxCongeladores,
    required this.costoCongelador,
  });

  factory ResumenHoy.fromJson(Map<String, dynamic> json) {
    final meta = json['meta'] as Map<String, dynamic>;
    final racha = json['racha'] as Map<String, dynamic>;
    final congeladores = json['congeladores'] as Map<String, dynamic>;
    return ResumenHoy(
      metaCumplida: meta['cumplida'] as bool? ?? false,
      metaActual: (meta['actual'] as num).toInt(),
      metaObjetivo: (meta['objetivo'] as num).toInt(),
      racha: (racha['actual'] as num).toInt(),
      rachaMaxima: (racha['maxima'] as num).toInt(),
      semana: [
        for (final d in (racha['semana'] as List? ?? const []))
          DiaRacha(
            DateTime.parse((d as Map<String, dynamic>)['fecha'] as String),
            EstadoDia.fromSupabase(d['estado'] as String?),
          ),
      ],
      congeladores: (congeladores['tienes'] as num).toInt(),
      maxCongeladores: (congeladores['maximo'] as num).toInt(),
      costoCongelador: (congeladores['costo'] as num).toInt(),
    );
  }
}
