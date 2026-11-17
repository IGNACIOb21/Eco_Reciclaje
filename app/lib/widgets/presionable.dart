import 'package:flutter/material.dart';

import '../theme/movimiento.dart';

/// Envuelve cualquier widget tocable para que baje a 96 % mientras se
/// presiona y vuelva con un pequeño rebote al soltar. Con "reducir
/// animaciones" no escala.
class Presionable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final String? etiquetaSemantica;

  const Presionable({
    super.key,
    required this.child,
    this.onTap,
    this.etiquetaSemantica,
  });

  @override
  State<Presionable> createState() => _PresionableState();
}

class _PresionableState extends State<Presionable> {
  bool _presionado = false;

  void _poner(bool valor) {
    if (_presionado != valor && mounted) setState(() => _presionado = valor);
  }

  @override
  Widget build(BuildContext context) {
    final habilitado = widget.onTap != null;
    final escala = _presionado && habilitado && !Movimiento.reducido(context)
        ? Movimiento.escalaPresion
        : 1.0;
    return Semantics(
      button: true,
      enabled: habilitado,
      label: widget.etiquetaSemantica,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _poner(true),
        onTapUp: (_) => _poner(false),
        onTapCancel: () => _poner(false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: escala,
          // Baja rápido (100 ms) y vuelve con rebote (320 ms).
          duration: _presionado
              ? const Duration(milliseconds: 100)
              : const Duration(milliseconds: 320),
          curve: _presionado ? Movimiento.entrar : Movimiento.rebote,
          child: widget.child,
        ),
      ),
    );
  }
}
