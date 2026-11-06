import 'material_type.dart';

enum OrdenPuntos { distancia, calificacion, nombre }

extension OrdenPuntosInfo on OrdenPuntos {
  String get etiqueta => switch (this) {
    OrdenPuntos.distancia => 'Distancia',
    OrdenPuntos.calificacion => 'Calificación',
    OrdenPuntos.nombre => 'Nombre',
  };
}

/// Estado de la pantalla de filtros. Materiales/distancia/disponibilidad/
/// calificación ya estaban en el diseño (filtros.png); comuna es el primer
/// filtro nuevo que se suma sobre esa base — los que se agreguen después
/// se integran también aquí.
class FiltrosMapa {
  final String? comuna;
  final Set<TipoMaterial> materiales;
  final double distanciaMaximaKm;
  final bool soloDisponibles;
  final int calificacionMinima;
  final OrdenPuntos ordenarPor;

  const FiltrosMapa({
    this.comuna,
    this.materiales = const {},
    this.distanciaMaximaKm = 5,
    this.soloDisponibles = false,
    this.calificacionMinima = 0,
    this.ordenarPor = OrdenPuntos.distancia,
  });

  bool get tieneFiltrosActivos =>
      comuna != null ||
      materiales.isNotEmpty ||
      soloDisponibles ||
      calificacionMinima > 0 ||
      distanciaMaximaKm < 5;

  FiltrosMapa copyWith({
    String? comuna,
    bool limpiarComuna = false,
    Set<TipoMaterial>? materiales,
    double? distanciaMaximaKm,
    bool? soloDisponibles,
    int? calificacionMinima,
    OrdenPuntos? ordenarPor,
  }) {
    return FiltrosMapa(
      comuna: limpiarComuna ? null : (comuna ?? this.comuna),
      materiales: materiales ?? this.materiales,
      distanciaMaximaKm: distanciaMaximaKm ?? this.distanciaMaximaKm,
      soloDisponibles: soloDisponibles ?? this.soloDisponibles,
      calificacionMinima: calificacionMinima ?? this.calificacionMinima,
      ordenarPor: ordenarPor ?? this.ordenarPor,
    );
  }
}
