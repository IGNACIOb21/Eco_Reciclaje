import 'clase_residuo.dart';

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

class Prediccion {
  /// Clase tal como viene en labels.txt (por ejemplo `glass`).
  final String clase;
  final double probabilidad;

  const Prediccion(this.clase, this.probabilidad);

  InfoClase get info => infoDeClase(clase);
}

class ResultadoClasificacion {
  /// Las mejores predicciones, de mayor a menor probabilidad.
  final List<Prediccion> top;

  /// Duración de la inferencia del modelo (sin decodificar la foto).
  final int milisegundosInferencia;

  const ResultadoClasificacion(this.top, this.milisegundosInferencia);

  Prediccion get mejor => top.first;
  Confianza get confianza => nivelDeConfianza(mejor.probabilidad);
}
