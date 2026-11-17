import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/movimiento.dart';
import 'presionable.dart';

/// Chip de filtro o selección. Seleccionado = fondo suave + borde verde +
/// check: nunca se distingue solo por color. Mide al menos 44 de alto.
class ChipRebin extends StatelessWidget {
  final String texto;
  final bool seleccionado;
  final VoidCallback? onTap;

  /// Círculo o ícono a la izquierda (por ejemplo el del material). Se oculta
  /// cuando el chip está seleccionado y se muestra el check.
  final Widget? inicio;

  const ChipRebin({
    super.key,
    required this.texto,
    required this.seleccionado,
    required this.onTap,
    this.inicio,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    return Semantics(
      selected: seleccionado,
      child: Presionable(
        onTap: onTap,
        child: AnimatedContainer(
          duration: Movimiento.dur(context, const Duration(milliseconds: 150)),
          constraints: const BoxConstraints(minHeight: 44),
          padding: EdgeInsets.only(
            left: inicio != null || seleccionado ? 6 : 16,
            right: 16,
          ),
          decoration: BoxDecoration(
            color: seleccionado ? c.primarioSuave : c.superficie,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: seleccionado ? c.primarioTexto : c.borde,
              width: seleccionado ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (seleccionado)
                Padding(
                  padding: const EdgeInsets.only(left: 6, right: 6),
                  child: Icon(Icons.check, size: 18, color: c.primarioTexto),
                )
              else if (inicio != null) ...[
                inicio!,
                const SizedBox(width: 8),
              ],
              Text(
                texto,
                style: TextStyle(
                  color: c.texto,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
