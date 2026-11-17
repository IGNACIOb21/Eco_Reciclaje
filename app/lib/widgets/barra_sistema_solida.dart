import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';

/// Fondo sólido bajo la barra de navegación de Android (|||  O  <) en toda la
/// app: es la única parte con color plateado bajo la píldora de pestañas.
///
/// Desde Android 15 las apps se dibujan de borde a borde: la barra del sistema
/// queda transparente y el color de `SystemChrome` se ignora. Cualquier
/// pantalla abierta encima (la ficha de un punto, reportar, calificar, hojas
/// inferiores…) metía sus botones bajo la barra. Este widget va en
/// `MaterialApp.builder`: reserva el alto de la barra con una franja del color
/// de superficie y le quita ese margen al resto de la app, así ninguna
/// pantalla queda debajo.
class BarraSistemaSolida extends StatelessWidget {
  final Widget child;

  const BarraSistemaSolida({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final alto = media.viewPadding.bottom;
    final colores = context.colores;
    final oscuro = Theme.of(context).brightness == Brightness.dark;

    // El teclado se mide desde el borde de la pantalla: como la app ya
    // termina sobre la franja, se le descuenta ese alto.
    final contenido = MediaQuery(
      data: media.copyWith(
        padding: media.padding.copyWith(bottom: 0),
        viewPadding: media.viewPadding.copyWith(bottom: 0),
        viewInsets: media.viewInsets.copyWith(
          bottom: math.max(0, media.viewInsets.bottom - alto),
        ),
      ),
      child: child,
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        // En Android 14 o anterior sí se aplica; en 15+ lo cubre la franja.
        systemNavigationBarColor: colores.superficie,
        systemNavigationBarDividerColor: colores.superficie,
        systemNavigationBarIconBrightness: oscuro
            ? Brightness.light
            : Brightness.dark,
        systemNavigationBarContrastEnforced: false,
      ),
      child: Column(
        children: [
          Expanded(child: contenido),
          if (alto > 0)
            ColoredBox(
              color: colores.superficie,
              child: SizedBox(height: alto, width: double.infinity),
            ),
        ],
      ),
    );
  }
}
