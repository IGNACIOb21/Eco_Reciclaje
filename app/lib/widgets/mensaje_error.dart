import 'package:flutter/material.dart';

/// Mensaje de error en línea de los formularios de cuenta.
class MensajeError extends StatelessWidget {
  final String texto;

  const MensajeError({super.key, required this.texto});

  @override
  Widget build(BuildContext context) {
    final error = Theme.of(context).colorScheme.error;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.error_outline, color: error, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Text(texto, style: TextStyle(color: error)),
        ),
      ],
    );
  }
}
