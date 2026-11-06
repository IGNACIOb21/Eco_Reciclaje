import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../models/punto_reciclaje.dart';
import '../theme/app_theme.dart';
import 'map_pin.dart';

/// Mapa real con tiles de OpenStreetMap (gratis, sin API key). El centro
/// inicial de cámara es fijo (no depende de si hay GPS disponible o no) —
/// arrastrar/zoom/rotar quedan habilitados por defecto (`InteractiveFlag.all`).
class MapaOsm extends StatelessWidget {
  final List<PuntoReciclaje> puntos;
  final PuntoReciclaje? seleccionado;
  final LatLng centroInicial;

  /// Posición GPS en vivo del usuario; null si no hay permiso.
  final LatLng? miUbicacion;
  final ValueChanged<PuntoReciclaje> onTapPin;

  const MapaOsm({
    super.key,
    required this.puntos,
    required this.onTapPin,
    required this.centroInicial,
    this.seleccionado,
    this.miUbicacion,
  });

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      options: MapOptions(
        initialCenter: centroInicial,
        initialZoom: 14,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all,
        ),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.recircula',
        ),
        MarkerLayer(
          markers: [
            for (final punto in puntos)
              Marker(
                point: LatLng(punto.lat, punto.lng),
                width: 44,
                height: 44,
                child: MapPin(
                  materiales: punto.materiales,
                  seleccionado: seleccionado?.id == punto.id,
                  onTap: () => onTapPin(punto),
                ),
              ),
          ],
        ),
        if (miUbicacion != null)
          MarkerLayer(
            markers: [
              Marker(
                point: miUbicacion!,
                width: 26,
                height: 26,
                child: const _MarcadorUsuario(),
              ),
            ],
          ),
        const RichAttributionWidget(
          attributions: [TextSourceAttribution('© OpenStreetMap contributors')],
        ),
      ],
    );
  }
}

/// Punto "Estás aquí": círculo azul con borde blanco y halo.
class _MarcadorUsuario extends StatelessWidget {
  const _MarcadorUsuario();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Estás aquí',
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.azul.withValues(alpha: 0.2),
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: AppTheme.azul,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2.5),
          ),
        ),
      ),
    );
  }
}
