import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../data/comunas_demo.dart';
import '../models/filtros_mapa.dart';
import '../models/material_type.dart';
import '../models/punto_reciclaje.dart';
import '../repositories/puntos_repository.dart';
import '../repositories/puntos_repository_supabase.dart';
import '../services/ubicacion_service.dart';
import '../theme/app_theme.dart';
import '../utils/geo.dart' as geo;
import '../widgets/estado_badge.dart';
import '../widgets/mapa_osm.dart';
import '../widgets/punto_card.dart';
import '../widgets/rating_stars.dart';
import 'filtros_screen.dart';
import 'punto_detail_screen.dart';

class MapaScreen extends StatefulWidget {
  final PuntosRepository? repositorio;

  const MapaScreen({super.key, this.repositorio});

  @override
  State<MapaScreen> createState() => _MapaScreenState();
}

class _MapaScreenState extends State<MapaScreen> with WidgetsBindingObserver {
  late final PuntosRepository _repositorio =
      widget.repositorio ?? PuntosRepositorySupabase();

  FiltrosMapa _filtros = const FiltrosMapa();
  PuntoReciclaje? _seleccionado;
  late Future<List<PuntoReciclaje>> _puntosFuture;

  // Referencia para "distancia a mí" (GPS si está disponible, si no Plaza
  // Ñuñoa). Independiente de la cámara del mapa: el usuario puede arrastrar y
  // hacer zoom libremente sin que eso cambie las distancias mostradas. También
  // es el centro que se manda a la RPC puntos_cercanos.
  double _miUbicacionLat = centroDefectoLat;
  double _miUbicacionLng = centroDefectoLng;

  // Posición GPS en vivo (marcador "Estás aquí"); null sin permiso.
  LatLng? _gps;
  StreamSubscription<Position>? _seguimiento;

  // Centro con el que se pidieron los puntos: solo se vuelven a pedir al
  // alejarse más de esto, no en cada actualización del GPS.
  static const _kmParaRecargar = 0.3;
  double _cargadoLat = centroDefectoLat;
  double _cargadoLng = centroDefectoLng;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _puntosFuture = _cargarPuntos();
    _cargarUbicacion();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _seguimiento?.cancel();
    super.dispose();
  }

  // Al volver a la app (ej. tras activar el permiso en Ajustes) se intenta
  // de nuevo si todavía no se está siguiendo la ubicación.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _seguimiento == null) {
      _cargarUbicacion();
    }
  }

  Future<List<PuntoReciclaje>> _cargarPuntos() {
    _cargadoLat = _miUbicacionLat;
    _cargadoLng = _miUbicacionLng;
    return _repositorio.obtenerPuntos(
      miLat: _miUbicacionLat,
      miLng: _miUbicacionLng,
      filtros: _filtros,
    );
  }

  Future<void> _cargarUbicacion() async {
    final posicion = await obtenerUbicacionActual();
    if (posicion == null || !mounted) return;
    _moverA(posicion, recargar: true);
    _seguimiento ??= seguirUbicacion().listen(
      (p) => _moverA(p),
      onError: (Object e) => debugPrint('Mapa: seguimiento GPS ($e)'),
    );
  }

  void _moverA(Position posicion, {bool recargar = false}) {
    if (!mounted) return;
    setState(() {
      _miUbicacionLat = posicion.latitude;
      _miUbicacionLng = posicion.longitude;
      _gps = LatLng(posicion.latitude, posicion.longitude);
      final lejos =
          geo.distanciaKm(
            _cargadoLat,
            _cargadoLng,
            _miUbicacionLat,
            _miUbicacionLng,
          ) >
          _kmParaRecargar;
      if (recargar || lejos) _puntosFuture = _cargarPuntos();
    });
  }

  double _distanciaDe(PuntoReciclaje punto) =>
      geo.distanciaKm(_miUbicacionLat, _miUbicacionLng, punto.lat, punto.lng);

  void _abrirFicha(PuntoReciclaje punto) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => PuntoDetailScreen(punto: punto)));
  }

  Future<void> _abrirFiltros() async {
    final resultado = await mostrarFiltrosMapa(context, _filtros);
    if (resultado != null) {
      setState(() {
        _filtros = resultado;
        _puntosFuture = _cargarPuntos();
        _seleccionado = null;
      });
    }
  }

  void _cambiarMateriales(Set<TipoMaterial> materiales) {
    setState(() {
      _filtros = _filtros.copyWith(materiales: materiales);
      _puntosFuture = _cargarPuntos();
      _seleccionado = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<PuntoReciclaje>>(
        future: _puntosFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const _MapaCargando();
          }
          if (snapshot.hasError) {
            return _MapaError(
              onReintentar: () =>
                  setState(() => _puntosFuture = _cargarPuntos()),
            );
          }

          final puntos = snapshot.data ?? const [];
          final colores = context.colores;

          return Stack(
            children: [
              Positioned.fill(
                child: MapaOsm(
                  puntos: puntos,
                  seleccionado: _seleccionado,
                  centroInicial: const LatLng(
                    centroDefectoLat,
                    centroDefectoLng,
                  ),
                  miUbicacion: _gps,
                  onTapPin: (p) => setState(() => _seleccionado = p),
                ),
              ),
              SafeArea(
                child: _BarraBusqueda(
                  materialesActivos: _filtros.materiales,
                  onMaterialesChanged: _cambiarMateriales,
                ),
              ),
              if (_seleccionado != null)
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: MediaQuery.of(context).size.height * 0.34,
                  child: _PreviewPunto(
                    punto: _seleccionado!,
                    distanciaKm: _distanciaDe(_seleccionado!),
                    onVerFicha: () => _abrirFicha(_seleccionado!),
                    onCerrar: () => setState(() => _seleccionado = null),
                  ),
                ),
              DraggableScrollableSheet(
                initialChildSize: 0.32,
                minChildSize: 0.15,
                maxChildSize: 0.85,
                builder: (context, scrollController) {
                  return Container(
                    decoration: BoxDecoration(
                      color: colores.superficie,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
                      boxShadow: const [
                        BoxShadow(color: Colors.black26, blurRadius: 16),
                      ],
                    ),
                    child: ListView.builder(
                      controller: scrollController,
                      padding: EdgeInsets.zero,
                      itemCount: puntos.length + 1,
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return Column(
                            children: [
                              const SizedBox(height: 10),
                              Container(
                                width: 40,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: colores.borde,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  14,
                                  16,
                                  4,
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '${puntos.length} puntos cerca de ti',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 16,
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: _abrirFiltros,
                                      child: Stack(
                                        clipBehavior: Clip.none,
                                        children: [
                                          Icon(
                                            Icons.tune,
                                            color: colores.textoSecundario,
                                          ),
                                          if (_filtros.tieneFiltrosActivos)
                                            Positioned(
                                              right: -2,
                                              top: -2,
                                              child: Container(
                                                width: 8,
                                                height: 8,
                                                decoration: BoxDecoration(
                                                  color: colores.primario,
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        }
                        final punto = puntos[index - 1];
                        return PuntoCard(
                          punto: punto,
                          distanciaKm: _distanciaDe(punto),
                          onTap: () => _abrirFicha(punto),
                        );
                      },
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Estado de carga mientras se resuelve la primera consulta a Supabase (o al
/// repositorio mock). Se ve la barra de búsqueda arriba y un indicador
/// centrado en vez de un mapa vacío, para no sugerir que ya no hay puntos.
class _MapaCargando extends StatelessWidget {
  const _MapaCargando();

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

/// Error de carga (sin conexión, Supabase caído, etc.) con opción de
/// reintentar, con el mismo estilo que usa Servicios para su propio error.
class _MapaError extends StatelessWidget {
  final VoidCallback onReintentar;

  const _MapaError({required this.onReintentar});

  @override
  Widget build(BuildContext context) {
    final colores = context.colores;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.wifi_off_outlined,
              size: 40,
              color: colores.textoSecundario,
            ),
            const SizedBox(height: 12),
            Text(
              'No pudimos cargar los puntos de reciclaje.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: colores.texto,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Revisa tu conexión e intenta de nuevo.',
              textAlign: TextAlign.center,
              style: TextStyle(color: colores.textoSecundario, fontSize: 13),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: onReintentar,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _BarraBusqueda extends StatelessWidget {
  final Set<TipoMaterial> materialesActivos;
  final ValueChanged<Set<TipoMaterial>> onMaterialesChanged;

  const _BarraBusqueda({
    required this.materialesActivos,
    required this.onMaterialesChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colores = context.colores;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: colores.superficie,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 10,
                ),
              ],
            ),
            child: TextField(
              decoration: InputDecoration(
                filled: false,
                border: InputBorder.none,
                icon: Icon(Icons.search, color: colores.textoSecundario),
                hintText: 'Busca un punto de reciclaje',
                isDense: true,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 38,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              ChoiceChip(
                label: const Text('Todos'),
                selected: materialesActivos.isEmpty,
                onSelected: (_) => onMaterialesChanged(const {}),
              ),
              const SizedBox(width: 8),
              for (final material in TipoMaterial.values) ...[
                ChoiceChip(
                  avatar: Icon(material.icono, size: 16, color: material.color),
                  label: Text(material.etiqueta),
                  selected: materialesActivos.contains(material),
                  onSelected: (seleccionado) {
                    final nuevos = {...materialesActivos};
                    if (seleccionado) {
                      nuevos.add(material);
                    } else {
                      nuevos.remove(material);
                    }
                    onMaterialesChanged(nuevos);
                  },
                ),
                const SizedBox(width: 8),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _PreviewPunto extends StatelessWidget {
  final PuntoReciclaje punto;
  final double distanciaKm;
  final VoidCallback onVerFicha;
  final VoidCallback onCerrar;

  const _PreviewPunto({
    required this.punto,
    required this.distanciaKm,
    required this.onVerFicha,
    required this.onCerrar,
  });

  @override
  Widget build(BuildContext context) {
    final colores = context.colores;
    return Material(
      elevation: 6,
      color: colores.superficie,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    punto.nombre,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ),
                EstadoBadge(estado: punto.estado),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: onCerrar,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                RatingStars(calificacion: punto.calificacionPromedio, size: 14),
                const SizedBox(width: 6),
                Text(
                  '${punto.comuna} · ${distanciaKm.toStringAsFixed(1)} km',
                  style: TextStyle(
                    color: colores.textoSecundario,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onVerFicha,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
                child: const Text('Ver ficha'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
