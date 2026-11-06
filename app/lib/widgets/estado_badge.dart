import 'package:flutter/material.dart';

import '../models/estado_punto.dart';
import 'pill.dart';

class EstadoBadge extends StatelessWidget {
  final EstadoPunto estado;

  const EstadoBadge({super.key, required this.estado});

  @override
  Widget build(BuildContext context) {
    return Pill(
      icono: estado.icono,
      texto: estado.etiqueta,
      color: estado.color,
      alphaFondo: 0.12,
      fontSize: 13,
    );
  }
}
