import 'info_clase.dart';

/// Umbrales de confianza del modelo (los mismos de `config.py`:
/// UMBRAL_SEGURO y UMBRAL_DUDOSO).
const double umbralSeguro = 0.95;
const double umbralDudoso = 0.60;

enum Confianza {
  /// 95 % o más: se muestra el resultado sin pedir confirmación.
  segura,

  /// Entre 60 % y 95 %: "Creo que es X".
  dudosa,

  /// Menos de 60 %: el modelo no está seguro.
  baja,
}

Confianza nivelDeConfianza(double probabilidad) {
  if (probabilidad >= umbralSeguro) return Confianza.segura;
  if (probabilidad >= umbralDudoso) return Confianza.dudosa;
  return Confianza.baja;
}

class PrediccionEscaneo {
  /// Clase tal como viene en labels.txt (por ejemplo `glass`).
  final String clase;
  final double probabilidad;

  const PrediccionEscaneo(this.clase, this.probabilidad);

  InfoClase get info => infoDeClase(clase);
}

class ResultadoEscaneo {
  /// Las mejores predicciones, de mayor a menor probabilidad.
  final List<PrediccionEscaneo> top;

  /// Duración de la inferencia del modelo (sin decodificar la foto).
  final int milisegundosInferencia;

  const ResultadoEscaneo(this.top, this.milisegundosInferencia);

  PrediccionEscaneo get mejor => top.first;
  Confianza get confianza => nivelDeConfianza(mejor.probabilidad);
}
