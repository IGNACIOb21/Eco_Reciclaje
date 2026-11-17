import 'package:flutter/widgets.dart';

/// Sistema de movimiento de la app: una curva para entrar, otra para salir y
/// duraciones por tipo de cambio. Todo respeta "reducir animaciones" del
/// sistema (ver [reducido]).
class Movimiento {
  Movimiento._();

  /// Para lo que aparece o se asienta: arranca rápido y frena suave.
  static const Curve entrar = Cubic(0.20, 0.0, 0.0, 1.0);

  /// Para lo que se va: arranca lento y acelera.
  static const Curve salir = Cubic(0.40, 0.0, 1.0, 1.0);

  /// Rebote corto con pequeño sobreimpulso (botones al soltar, íconos que
  /// aparecen). Equivale al resorte masa 1, rigidez 380, amortiguación 26.
  static const Curve rebote = Cubic(0.34, 1.4, 0.64, 1.0);

  /// Resorte único de la app: masa 1, rigidez 380, amortiguación 26. Para lo
  /// que se lanza con la velocidad del gesto (hoja del mapa, botón al soltar).
  static const SpringDescription resorte = SpringDescription(
    mass: 1,
    stiffness: 380,
    damping: 26,
  );

  static const Duration micro = Duration(milliseconds: 120);
  static const Duration transicion = Duration(milliseconds: 280);
  static const Duration celebracion = Duration(milliseconds: 650);

  /// Salir dura un 10 % menos que entrar.
  static const Duration transicionSalir = Duration(milliseconds: 250);

  /// Botón de escanear: respira 100 % ↔ 104 % en bucle.
  static const Duration respirar = Duration(milliseconds: 2400);

  /// Reflejo sobre una recompensa pendiente.
  static const Duration brillo = Duration(milliseconds: 2800);

  /// Pausa entre elementos de una lista que entra en cascada; máximo 6.
  static const Duration cascada = Duration(milliseconds: 40);

  /// Escala de un botón mientras está presionado.
  static const double escalaPresion = 0.96;

  static bool reducido(BuildContext context) =>
      MediaQuery.maybeOf(context)?.disableAnimations ?? false;

  /// Devuelve [d], o casi cero si el usuario pidió reducir animaciones.
  static Duration dur(BuildContext context, Duration d) =>
      reducido(context) ? const Duration(milliseconds: 1) : d;
}
