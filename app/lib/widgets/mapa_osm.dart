import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../models/punto_reciclaje.dart';
import '../theme/app_theme.dart';
import 'map_pin.dart';

/// Mapa real con tiles de OpenStreetMap (gratis, sin API key). El centro
/// inicial de cámara es fijo (no depende de si hay GPS disponible o no).
/// Arrastrar y hacer zoom están habilitados; rotar no, porque la app no tiene
/// cómo volver al norte y un mapa girado deja esquinas sin tiles.
///
/// Los tiles que fallan (red inestable o el límite de uso del servidor
/// público de OSM) se reintentan solos con espera creciente: si no, quedan
/// como cuadrados grises hasta que el usuario sale y vuelve a esa zona.
class MapaOsm extends StatefulWidget {
  final List<PuntoReciclaje> puntos;
  final PuntoReciclaje? seleccionado;
  final LatLng centroInicial;

  /// Posición GPS en vivo del usuario; null si no hay permiso.
  final LatLng? miUbicacion;
  final ValueChanged<PuntoReciclaje> onTapPin;

  /// Avisa el centro de la cámara cada vez que el usuario mueve el mapa.
  final ValueChanged<LatLng>? onCentroCambiado;

  const MapaOsm({
    super.key,
    required this.puntos,
    required this.onTapPin,
    required this.centroInicial,
    this.seleccionado,
    this.miUbicacion,
    this.onCentroCambiado,
  });

  @override
  State<MapaOsm> createState() => _MapaOsmState();
}

class _MapaOsmState extends State<MapaOsm> {
  /// Reintentos seguidos sin que el usuario mueva el mapa; al llegar al tope
  /// se espera a que arrastre o haga zoom para volver a intentar.
  static const _maxReintentos = 5;

  final _reset = StreamController<void>.broadcast();
  Timer? _temporizador;
  int _reintentos = 0;

  @override
  void dispose() {
    _temporizador?.cancel();
    _reset.close();
    super.dispose();
  }

  void _tileFallo(TileImage tile, Object error, StackTrace? _) {
    debugPrint('Mapa: el tile ${tile.coordinates} no cargó ($error)');
    if (_reintentos >= _maxReintentos) return;
    // Un solo reintento pendiente aunque fallen muchos tiles a la vez.
    _temporizador ??= Timer(Duration(seconds: 3 * (_reintentos + 1)), () {
      _temporizador = null;
      if (!mounted || _reset.isClosed) return;
      _reintentos++;
      _reset.add(null); // vuelve a pedir los tiles que fallaron
    });
  }

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      options: MapOptions(
        initialCenter: widget.centroInicial,
        initialZoom: 14,
        minZoom: 4,
        maxZoom: 19,
        // Color de fondo cálido, no el gris por defecto, para que un hueco
        // momentáneo de tiles no parezca un fallo de la pantalla.
        backgroundColor: const Color(0xFFEFEBE0),
        interactionOptions: InteractionOptions(
          flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
        ),
        // Si el usuario mueve el mapa, se le devuelven los reintentos.
        onPositionChanged: (camara, hayGesto) {
          if (hayGesto) _reintentos = 0;
          widget.onCentroCambiado?.call(camara.center);
        },
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.recircula',
          maxNativeZoom: 19,
          // Más tiles de margen: menos pedidos al servidor al mover el mapa.
          keepBuffer: 4,
          panBuffer: 1,
          // Un tile que falló no se queda gris para siempre.
          evictErrorTileStrategy:
              EvictErrorTileStrategy.notVisibleRespectMargin,
          errorTileCallback: _tileFallo,
          reset: _reset.stream,
        ),
        MarkerLayer(
          markers: [
            for (final punto in widget.puntos)
              Marker(
                point: LatLng(punto.lat, punto.lng),
                width: 44,
                height: 44,
                child: MapPin(
                  materiales: punto.materiales,
                  seleccionado: widget.seleccionado?.id == punto.id,
                  onTap: () => widget.onTapPin(punto),
                ),
              ),
          ],
        ),
        if (widget.miUbicacion != null)
          MarkerLayer(
            markers: [
              Marker(
                point: widget.miUbicacion!,
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
