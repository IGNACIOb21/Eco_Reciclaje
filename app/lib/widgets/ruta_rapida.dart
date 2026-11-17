import 'package:flutter/material.dart';

/// Ruta con un fundido corto (150 ms) en vez del deslizamiento de Material
/// (unos 300 ms): para las cámaras de "Reciclar", que se encadenan una tras
/// otra y así se sienten inmediatas.
Route<T> rutaRapida<T>(WidgetBuilder builder) => PageRouteBuilder<T>(
  transitionDuration: const Duration(milliseconds: 150),
  reverseTransitionDuration: const Duration(milliseconds: 120),
  pageBuilder: (context, _, _) => builder(context),
  transitionsBuilder: (context, animacion, _, hijo) =>
      FadeTransition(opacity: animacion, child: hijo),
);
