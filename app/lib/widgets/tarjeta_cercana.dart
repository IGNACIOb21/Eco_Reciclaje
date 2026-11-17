import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/material_type.dart';
import '../models/estado_punto.dart';
import '../models/punto_reciclaje.dart';
import '../theme/app_theme.dart';

/// "220 m" bajo 1 km (redondeado a 10 m) y "1,2 km" desde ahí.
String distanciaCorta(double km) {
  if (km < 1) return '${math.max(10, (km * 100).round() * 10)} m';
  return '${km.toStringAsFixed(1).replaceAll('.', ',')} km';
}

/// Fila de un punto en la hoja "Cerca de ti" del mapa (pág. 6 del rediseño):
/// material, nombre, distancia y estado, y la calificación a la derecha. Solo
/// para la lista del mapa: `PuntoCard` sigue igual donde se usa (flujo
/// Reciclar).
class TarjetaCercana extends StatelessWidget {
  final PuntoReciclaje punto;
  final double distanciaKm;
  final VoidCallback onTap;

  const TarjetaCercana({
    super.key,
    required this.punto,
    required this.distanciaKm,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colores = context.colores;
    final p = punto;
    final calificado = p.numCalificaciones > 0;
    final nota = p.calificacionPromedio.toStringAsFixed(1).replaceAll('.', ',');
    return Semantics(
      button: true,
      label:
          '${p.nombre}. ${distanciaCorta(distanciaKm)}. ${p.estado.etiqueta}'
          '${calificado ? '. $nota estrellas' : ''}',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Material(
          color: colores.fondo,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  _IconoMateriales(materiales: p.materiales),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.nombre,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: '${distanciaCorta(distanciaKm)} · ',
                              ),
                              TextSpan(
                                text: p.estado.etiqueta,
                                style: TextStyle(color: p.estado.color),
                              ),
                            ],
                          ),
                          style: TextStyle(
                            color: colores.textoSecundario,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (calificado) ...[
                    const SizedBox(width: 8),
                    Icon(Icons.star, size: 16, color: colores.texto),
                    const SizedBox(width: 2),
                    Text(
                      nota,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Un material: círculo de su color con su ícono. Varios: anillo dividido en
/// sus colores con el ícono de reciclaje al centro, como los pines del mapa.
class _IconoMateriales extends StatelessWidget {
  final List<TipoMaterial> materiales;

  const _IconoMateriales({required this.materiales});

  @override
  Widget build(BuildContext context) {
    final colores = context.colores;
    if (materiales.length <= 1) {
      final m = materiales.isEmpty ? null : materiales.first;
      final color = m?.color ?? colores.textoSecundario;
      final oscuro =
          ThemeData.estimateBrightnessForColor(color) == Brightness.dark;
      return Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        child: Icon(
          m?.icono ?? Icons.recycling,
          size: 22,
          color: oscuro ? Colors.white : const Color(0xFF1E2B22),
        ),
      );
    }
    final colorDe = [for (final m in materiales.take(4)) m.color];
    final paso = 1 / colorDe.length;
    return Container(
      width: 44,
      height: 44,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: SweepGradient(
          colors: [
            for (final c in colorDe) ...[c, c],
          ],
          stops: [
            for (var i = 0; i < colorDe.length; i++) ...[
              i * paso,
              (i + 1) * paso,
            ],
          ],
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: colores.superficie,
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.recycling, size: 18, color: colores.texto),
      ),
    );
  }
}
