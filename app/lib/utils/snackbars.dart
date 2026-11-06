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
