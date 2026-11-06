import 'package:flutter/material.dart';

/// Título pequeño de sección, usado en hojas y formularios (filtros,
/// personalizar perfil).
class SeccionTitulo extends StatelessWidget {
  final String texto;

  const SeccionTitulo(this.texto, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      texto,
      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
    );
  }
}
