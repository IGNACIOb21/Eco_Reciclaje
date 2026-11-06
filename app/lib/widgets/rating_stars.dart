import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class RatingStars extends StatelessWidget {
  final double calificacion;
  final double size;

  const RatingStars({super.key, required this.calificacion, this.size = 16});

  @override
  Widget build(BuildContext context) {
    final acento = context.colores.acento;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final relleno = calificacion - i;
        IconData icono;
        if (relleno >= 1) {
          icono = Icons.star;
        } else if (relleno >= 0.5) {
          icono = Icons.star_half;
        } else {
          icono = Icons.star_border;
        }
        return Icon(icono, size: size, color: acento);
      }),
    );
  }
}
