import 'package:flutter/material.dart';

/// Snackbar estándar para funciones que todavía no están implementadas.
void mostrarProximamente(BuildContext context, String funcion) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('$funcion — próximamente'),
      behavior: SnackBarBehavior.floating,
    ),
  );
}

/// Snackbar flotante con un mensaje cualquiera (confirmaciones, avisos).
void mostrarSnackbar(BuildContext context, String mensaje) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(mensaje), behavior: SnackBarBehavior.floating),
  );
}
