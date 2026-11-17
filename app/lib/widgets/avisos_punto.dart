import 'package:flutter/material.dart';

import '../models/aviso_punto.dart';
import '../theme/app_theme.dart';

/// Lista de [AvisoPunto] de un punto, con el color de alerta del tema. Sin
/// avisos no ocupa espacio.
class AvisosPunto extends StatelessWidget {
  final List<AvisoPunto> avisos;

  const AvisosPunto({super.key, required this.avisos});

  @override
  Widget build(BuildContext context) {
    if (avisos.isEmpty) return const SizedBox.shrink();
    final colores = context.colores;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final aviso in avisos)
          Container(
            key: Key('aviso-${aviso.codigo}'),
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: colores.alerta.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colores.alerta.withValues(alpha: 0.5)),
            ),
            child: Row(
              children: [
                Icon(aviso.icono, color: colores.alerta),
                const SizedBox(width: 8),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: aviso.titulo,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        TextSpan(text: ' · ${aviso.detalle}'),
                      ],
                    ),
                    style: TextStyle(color: colores.texto, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
