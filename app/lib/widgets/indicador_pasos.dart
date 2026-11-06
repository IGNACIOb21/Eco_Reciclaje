import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Barra de progreso por pasos (bienvenida, registro de cuenta).
class IndicadorPasos extends StatelessWidget {
  final int paso;
  final int total;

  const IndicadorPasos({super.key, required this.paso, required this.total});

  @override
  Widget build(BuildContext context) {
    final colores = context.colores;
    return Row(
      children: [
        for (var i = 0; i < total; i++) ...[
          if (i > 0) const SizedBox(width: 6),
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              height: 5,
              decoration: BoxDecoration(
                color: i <= paso ? colores.primario : colores.superficieAlta,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Texto de un botón que pasa a spinner mientras [ocupado].
class TextoBoton extends StatelessWidget {
  final String texto;
  final bool ocupado;

  const TextoBoton({super.key, required this.texto, required this.ocupado});

  @override
  Widget build(BuildContext context) {
    if (!ocupado) return Text(texto);
    return const SizedBox(
      width: 20,
      height: 20,
      child: CircularProgressIndicator(strokeWidth: 2.5),
    );
  }
}
