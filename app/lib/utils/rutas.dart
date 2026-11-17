import 'package:flutter/widgets.dart';

/// Avisa a las pantallas que lo pidan (RouteAware) cuando vuelven a quedar a
/// la vista. El MainShell lo usa para celebrar una subida de nivel recién al
/// volver, nunca encima del flujo Reciclar ni de otra pantalla.
final observadorRutas = RouteObserver<ModalRoute<void>>();
