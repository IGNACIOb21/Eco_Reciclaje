import 'package:flutter/material.dart';

import '../models/material_type.dart';
import '../models/punto_reciclaje.dart';
import '../theme/app_theme.dart';
import 'estado_badge.dart';
import 'rating_stars.dart';

class PuntoCard extends StatelessWidget {
  final PuntoReciclaje punto;
  final double distanciaKm;
  final VoidCallback onTap;

  const PuntoCard({
    super.key,
    required this.punto,
    required this.distanciaKm,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              _IconosMateriales(materiales: punto.materiales),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      punto.nombre,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${punto.comuna} · ${distanciaKm.toStringAsFixed(1)} km',
                      style: TextStyle(
                        color: context.colores.textoSecundario,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        RatingStars(
                          calificacion: punto.calificacionPromedio,
                          size: 14,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '(${punto.numCalificaciones})',
                          style: TextStyle(
                            color: context.colores.textoSecundario,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              EstadoBadge(estado: punto.estado),
            ],
          ),
        ),
      ),
    );
  }
}

class _IconosMateriales extends StatelessWidget {
  final List<TipoMaterial> materiales;

  const _IconosMateriales({required this.materiales});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      height: 44,
      child: Stack(
        children: [
          for (var i = 0; i < materiales.length.clamp(0, 3); i++)
            Positioned(
              left: i * 10.0,
              child: Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: materiales[i].color,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Icon(materiales[i].icono, size: 13, color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}
