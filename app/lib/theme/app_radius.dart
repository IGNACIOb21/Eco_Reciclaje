/// Escala de radios de borde compartida, tomada de los valores ya en uso en
/// las pantallas. Se usa en código nuevo; los valores sueltos existentes se
/// migran después, no en este cambio.
class AppRadius {
  AppRadius._();

  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double pill = 30;
  static const double sheet = 24;
}
