import 'package:flutter/material.dart';

import '../models/material_type.dart';
import '../models/punto_reciclaje.dart';
import '../theme/app_theme.dart';
import '../utils/snackbars.dart';
import '../widgets/estado_badge.dart';
import '../widgets/map_pin.dart';
import '../widgets/rating_stars.dart';

class PuntoDetailScreen extends StatelessWidget {
  final PuntoReciclaje punto;

  const PuntoDetailScreen({super.key, required this.punto});

  @override
  Widget build(BuildContext context) {
    final colores = context.colores;
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 160,
            backgroundColor: colores.fondoMapa,
            foregroundColor: colores.texto,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: colores.fondoMapa,
                child: Center(
                  child: MapPin(materiales: punto.materiales, onTap: () {}),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Estado y calificación van primero: son lo que el usuario
                  // necesita decidir si vale la pena ir.
                  Row(
                    children: [
                      EstadoBadge(estado: punto.estado),
                      const SizedBox(width: 10),
                      RatingStars(
                        calificacion: punto.calificacionPromedio,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${punto.calificacionPromedio.toStringAsFixed(1)} (${punto.numCalificaciones})',
                        style: TextStyle(
                          color: colores.textoSecundario,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    punto.nombre,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.place_outlined,
                        size: 18,
                        color: colores.textoSecundario,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${punto.direccion}, ${punto.comuna}',
                          style: TextStyle(color: colores.textoSecundario),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  if (punto.fuente == FuentePunto.osm)
                    // Texto secundario, no un chip como las otras fuentes:
                    // el origen OSM es informativo, no una insignia de
                    // confianza como "oficial" o "comunidad".
                    Text(
                      'Fuente: OpenStreetMap',
                      style: TextStyle(
                        color: colores.textoSecundario,
                        fontSize: 12,
                      ),
                    )
                  else
                    Chip(
                      label: Text(
                        punto.fuente == FuentePunto.oficial
                            ? 'Fuente oficial (MMA)'
                            : 'Agregado por la comunidad',
                      ),
                      avatar: Icon(
                        punto.fuente == FuentePunto.oficial
                            ? Icons.verified_outlined
                            : Icons.groups_outlined,
                        size: 18,
                      ),
                    ),
                  const SizedBox(height: 24),
                  const Text(
                    'Materiales aceptados',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final material in punto.materiales)
                        Chip(
                          avatar: Icon(
                            material.icono,
                            size: 16,
                            color: material.color,
                          ),
                          label: Text(material.etiqueta),
                        ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  // "Cómo llegar" es la acción primaria; "Reportar estado" queda
                  // secundaria, debajo.
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () =>
                          mostrarProximamente(context, 'Cómo llegar'),
                      icon: const Icon(Icons.directions),
                      label: const Text('Cómo llegar'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          mostrarProximamente(context, 'Reportar estado'),
                      icon: const Icon(Icons.flag_outlined),
                      label: const Text('Reportar estado'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
