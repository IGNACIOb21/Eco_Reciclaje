import 'package:flutter/material.dart';

import '../models/perfil_local.dart';

class AvatarUsuario extends StatelessWidget {
  final AvatarIcono icono;
  final Color color;
  final double tamano;

  const AvatarUsuario({
    super.key,
    required this.icono,
    required this.color,
    this.tamano = 48,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: tamano,
      height: tamano,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        shape: BoxShape.circle,
      ),
      child: Icon(icono.icono, color: color, size: tamano * 0.54),
    );
  }
}
