import 'package:flutter/material.dart';

import '../models/filtros_mapa.dart';
import '../models/material_type.dart';
import '../models/punto_reciclaje.dart';
import '../repositories/puntos_repository.dart';
import '../screens/punto_detail_screen.dart';
import '../theme/app_theme.dart';
import '../utils/geo.dart' as geo;
import 'como_llegar.dart';
import 'punto_card.dart';

/// Los puntos más cercanos a ([lat], [lng]) que reciben [material] (busca a
/// 5 km y, si no hay, a 25 km), con "Cómo llegar" al primero.
class PuntosQueReciben extends StatefulWidget {
  final TipoMaterial material;
  final double lat;
  final double lng;
  final PuntosRepository repositorio;
  final int maximo;

  /// Si se conoce: id del punto actual, que no se recomienda.
  final String? excluir;

  /// true si [lat]/[lng] son una posición por defecto y no el GPS: se avisa.
  final bool sinGps;

  const PuntosQueReciben({
    super.key,
    required this.material,
    required this.lat,
    required this.lng,
    required this.repositorio,
    this.maximo = 3,
    this.excluir,
    this.sinGps = false,
  });

  @override
  State<PuntosQueReciben> createState() => _PuntosQueRecibenState();
}

class _PuntosQueRecibenState extends State<PuntosQueReciben> {
  late Future<List<(PuntoReciclaje, double)>> _puntos = _buscar();

  @override
  void didUpdateWidget(PuntosQueReciben anterior) {
    super.didUpdateWidget(anterior);
    if (anterior.material != widget.material ||
        anterior.lat != widget.lat ||
        anterior.lng != widget.lng) {
      _puntos = _buscar();
    }
  }

  Future<List<(PuntoReciclaje, double)>> _buscar() async {
    for (final radio in [5.0, 25.0]) {
      final puntos = await widget.repositorio.obtenerPuntos(
        miLat: widget.lat,
        miLng: widget.lng,
        filtros: FiltrosMapa(
          materiales: {widget.material},
          distanciaMaximaKm: radio,
        ),
      );
      final otros = puntos.where((p) => p.id != widget.excluir).toList();
      if (otros.isNotEmpty) {
        return [
          for (final p in otros.take(widget.maximo))
            (p, geo.distanciaKm(widget.lat, widget.lng, p.lat, p.lng)),
        ];
      }
    }
    return const [];
  }

  @override
  Widget build(BuildContext context) {
    final colores = context.colores;
    return FutureBuilder<List<(PuntoReciclaje, double)>>(
      future: _puntos,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final puntos = snapshot.data ?? const [];
        if (snapshot.hasError || puntos.isEmpty) {
          return Text(
            snapshot.hasError
                ? 'No pudimos buscar puntos cercanos. Revisa el mapa para '
                      'encontrar uno de ${widget.material.etiqueta}.'
                : 'No encontramos un punto de ${widget.material.etiqueta} '
                      'cerca. Revisa el mapa para buscar uno más lejos.',
            style: TextStyle(color: colores.textoSecundario),
          );
        }
        return Column(
          key: const Key('puntos-que-reciben'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.sinGps)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  'Sin tu ubicación, las distancias se calculan desde el '
                  'centro de Santiago.',
                  key: const Key('puntos-sin-gps'),
                  style: TextStyle(
                    color: colores.textoSecundario,
                    fontSize: 12,
                  ),
                ),
              ),
            for (final (punto, km) in puntos)
              PuntoCard(
                punto: punto,
                distanciaKm: km,
                margen: const EdgeInsets.symmetric(vertical: 6),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => PuntoDetailScreen(punto: punto),
                  ),
                ),
              ),
            const SizedBox(height: 8),
            ComoLlegar(
              punto: puntos.first.$1,
              origenLat: widget.sinGps ? null : widget.lat,
              origenLng: widget.sinGps ? null : widget.lng,
            ),
          ],
        );
      },
    );
  }
}
