import 'package:flutter/material.dart';

/// Familias tipográficas de la app, empaquetadas en `assets/fonts` (licencia
/// OFL, sin paquetes externos): Poppins (sans serif geométrica) para titulares
/// y Work Sans para el texto corriente.
class Tipografia {
  Tipografia._();

  static const String titulo = 'Poppins';
  static const String texto = 'WorkSans';

  /// Cifras de ancho fijo para contadores y barras de progreso: así el número
  /// no "baila" mientras rueda.
  static const List<FontFeature> cifras = [FontFeature.tabularFigures()];

  /// Aplica las familias al `TextTheme` base de Material 3. Los titulares
  /// (display, headline y titleLarge) van en Poppins bold; el resto en Work
  /// Sans.
  static TextTheme aplicar(TextTheme base) {
    final conTexto = base.apply(fontFamily: texto);
    TextStyle? serif(TextStyle? e) => e?.copyWith(
      fontFamily: titulo,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.4,
    );
    return conTexto.copyWith(
      displayLarge: serif(conTexto.displayLarge),
      displayMedium: serif(conTexto.displayMedium),
      displaySmall: serif(conTexto.displaySmall),
      headlineLarge: serif(conTexto.headlineLarge),
      headlineMedium: serif(conTexto.headlineMedium),
      headlineSmall: serif(conTexto.headlineSmall),
      titleLarge: serif(conTexto.titleLarge),
    );
  }
}
