import 'package:flutter/material.dart';

import '../theme/app_radius.dart';

/// Cápsula reutilizable (ícono opcional + texto) sobre fondo redondeado.
/// Cubre los badges de estado, etiquetas de actividad y contadores que antes
/// se armaban a mano con `Container` + `BoxDecoration` repetidos.
class Pill extends StatelessWidget {
  final IconData? icono;
  final String texto;
  final Color color;
  final Color? fondo;
  final double alphaFondo;
  final EdgeInsetsGeometry padding;
  final double? fontSize;
  final FontWeight fontWeight;
  final double iconSize;
  final double gap;

  const Pill({
    super.key,
    this.icono,
    required this.texto,
    required this.color,
    this.fondo,
    this.alphaFondo = 0.18,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    this.fontSize,
    this.fontWeight = FontWeight.w600,
    this.iconSize = 16,
    this.gap = 6,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: fondo ?? color.withValues(alpha: alphaFondo),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icono != null) ...[
            Icon(icono, size: iconSize, color: color),
            SizedBox(width: gap),
          ],
          Text(
            texto,
            style: TextStyle(
              color: color,
              fontWeight: fontWeight,
              fontSize: fontSize,
            ),
          ),
        ],
      ),
    );
  }
}
