import 'package:flutter/material.dart';

/// Niveles de elevación del diseño. Una sola sombra por capa y desenfoque de
/// 20 como máximo, para no perder cuadros en equipos modestos. En Modo Eco la
/// elevación es tono (superficie y superficieAlta), así que no hay sombras.
///
/// - 0: plano, solo borde.
/// - 1: tarjeta.
/// - 2: lo que flota (hoja, pin activo).
/// - 3: lo que va encima (celebración).
class Elevacion {
  Elevacion._();

  static List<BoxShadow> nivel(int nivel, {required Brightness brillo}) {
    if (brillo == Brightness.dark || nivel <= 0) return const [];
    return switch (nivel) {
      1 => const [
        BoxShadow(
          color: Color(0x1A1E2B22),
          offset: Offset(0, 1),
          blurRadius: 2,
        ),
      ],
      2 => const [
        BoxShadow(
          color: Color(0x1F1E2B22),
          offset: Offset(0, 4),
          blurRadius: 12,
        ),
      ],
      _ => const [
        BoxShadow(
          color: Color(0x291E2B22),
          offset: Offset(0, 8),
          blurRadius: 20,
        ),
      ],
    };
  }
}

extension ElevacionDeContexto on BuildContext {
  /// Sombras del nivel pedido según el tema actual.
  List<BoxShadow> sombra(int nivel) =>
      Elevacion.nivel(nivel, brillo: Theme.of(this).brightness);
}
