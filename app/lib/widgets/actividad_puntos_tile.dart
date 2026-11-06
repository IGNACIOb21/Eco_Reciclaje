import 'package:flutter/material.dart';

import '../models/actividad_puntos.dart';
import '../theme/app_theme.dart';

/// Fila del historial de puntos (Inicio y Perfil).
class ActividadPuntosTile extends StatelessWidget {
  final ActividadPuntos actividad;

  const ActividadPuntosTile({super.key, required this.actividad});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: actividad.color.withValues(alpha: 0.18),
                shape: BoxShape.circle,
              ),
              child: Icon(actividad.icono, color: actividad.color, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                actividad.texto,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
            Text(
              actividad.puntos < 0
                  ? '${actividad.puntos}'
                  : '+${actividad.puntos}',
              style: TextStyle(
                color: context.colores.primario,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
