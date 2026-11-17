import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import '../config/env.dart';
import '../models/punto_reciclaje.dart';
import '../theme/app_theme.dart';
import 'pin_bitmap.dart';

/// Maneja la cámara de un [MapRebin] desde la pantalla que lo contiene.
///
/// [value] es el rumbo de la cámara en grados (0 = norte arriba), para la
/// brújula propia de la pantalla; la nativa de Mapbox se apaga porque quedaba
/// bajo el buscador y casi no se veía. [apuntarAlNorte] gira el mapa de
/// vuelta y [centrarEn] lleva la cámara a un punto.
class MapaRebinController extends ValueNotifier<double> {
  MapaRebinController() : super(0);

  _MapRebinState? _estado;

  void apuntarAlNorte() => _estado?._apuntarAlNorte();

  /// Centra la cámara en ([lat], [lng]). [zoom] null deja el zoom actual;
  /// [margenInferior] (píxeles lógicos) corre el centro hacia arriba para que
  /// el punto no quede tapado por una hoja inferior.
  void centrarEn(
    double lat,
    double lng, {
    double? zoom,
    double margenInferior = 0,
  }) =>
      _estado?._centrarEn(lat, lng, zoom: zoom, margenInferior: margenInferior);
}

/// Mapa de Mapbox (Free Tier, solo token público) con los puntos de reciclaje
/// como marcadores de `PointAnnotationManager` y el indicador pulsante de la
/// ubicación del usuario.
///
/// La cámara arranca en [centroInicial] y se mueve sola una única vez, cuando
/// llega la primera posición GPS; después el usuario la maneja libremente.
class MapRebin extends StatefulWidget {
  final List<PuntoReciclaje> puntos;
  final PuntoReciclaje? seleccionado;

  /// Centro inicial como (lat, lng).
  final ({double lat, double lng}) centroInicial;

  /// Posición GPS en vivo del usuario; null sin permiso (no se muestra el
  /// indicador ni se centra en él).
  final ({double lat, double lng})? miUbicacion;
  final ValueChanged<PuntoReciclaje> onTapPin;

  /// Centro visible cada vez que la cámara se detiene (ej. para ubicar una
  /// sugerencia de punto cuando no hay GPS).
  final ValueChanged<({double lat, double lng})>? onCentroCambiado;

  /// Recibe el rumbo de la cámara (brújula) y permite moverla desde afuera.
  final MapaRebinController? controller;

  /// Zoom con el que arranca la cámara (14 en el mapa general; la ficha usa
  /// uno más cercano para mostrar el entorno del punto).
  final double zoomInicial;

  const MapRebin({
    super.key,
    required this.puntos,
    required this.onTapPin,
    required this.centroInicial,
    this.seleccionado,
    this.miUbicacion,
    this.onCentroCambiado,
    this.controller,
    this.zoomInicial = 14,
  });

  /// Estilo base según el tema. Hoy ambos temas usan Streets; para que el
  /// Modo Eco tenga su propio mapa (verde bosque, sin negro/gris) basta con
  /// crear un estilo en Mapbox Studio y devolver su URL `mapbox://styles/…`.
  static String estiloPara({required bool eco}) => MapboxStyles.MAPBOX_STREETS;

  @override
  State<MapRebin> createState() => _MapRebinState();
}

class _MapRebinState extends State<MapRebin> {
  MapboxMap? _mapa;
  PointAnnotationManager? _marcadores;
  Cancelable? _tapMarcadores;

  // id de la anotación de Mapbox → punto, para resolver los toques.
  final Map<String, PuntoReciclaje> _puntoPorAnotacion = {};
  bool _centradoEnUsuario = false;
  String? _estiloActual;

  // Evita que una tanda de marcadores más lenta pise a una más nueva.
  int _version = 0;

  final String _token = Env.mapboxAccessToken;

  @override
  void initState() {
    super.initState();
    if (_token.isNotEmpty) MapboxOptions.setAccessToken(_token);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final estilo = _estiloDelTema();
    if (_mapa != null && estilo != _estiloActual) {
      _estiloActual = estilo;
      _mapa!.loadStyleURI(estilo);
    }
  }

  @override
  void didUpdateWidget(MapRebin anterior) {
    super.didUpdateWidget(anterior);
    if (anterior.puntos != widget.puntos ||
        anterior.seleccionado?.id != widget.seleccionado?.id) {
      _dibujarMarcadores();
    }
    if ((anterior.miUbicacion == null) != (widget.miUbicacion == null)) {
      _configurarUbicacion();
    }
    if (anterior.miUbicacion == null && widget.miUbicacion != null) {
      _centrarEnUsuario();
    }
  }

  @override
  void dispose() {
    _tapMarcadores?.cancel();
    if (widget.controller?._estado == this) widget.controller!._estado = null;
    super.dispose();
  }

  // Modo Eco usa Brightness.dark (ver AppTheme.eco).
  String _estiloDelTema() =>
      MapRebin.estiloPara(eco: Theme.of(context).brightness == Brightness.dark);

  Future<void> _alCrearMapa(MapboxMap mapa) async {
    _mapa = mapa;
    final inicio = widget.miUbicacion ?? widget.centroInicial;
    _centradoEnUsuario = widget.miUbicacion != null;
    await mapa.setCamera(
      CameraOptions(
        center: _punto(inicio.lat, inicio.lng),
        zoom: widget.zoomInicial,
      ),
    );
    await mapa.scaleBar.updateSettings(ScaleBarSettings(enabled: false));
    await mapa.compass.updateSettings(CompassSettings(enabled: false));
    widget.controller?._estado = this;
    await _configurarUbicacion();

    _marcadores = await mapa.annotations.createPointAnnotationManager();
    _tapMarcadores = _marcadores!.tapEvents(
      onTap: (anotacion) {
        final punto = _puntoPorAnotacion[anotacion.id];
        if (punto != null) widget.onTapPin(punto);
      },
    );
    await _dibujarMarcadores();
  }

  /// Indicador pulsante "Estás aquí". Solo con permiso de ubicación: el
  /// mapa nunca lo pide por su cuenta (eso es del primer inicio o Ajustes).
  Future<void> _configurarUbicacion() async {
    final mapa = _mapa;
    if (mapa == null) return;
    await mapa.location.updateSettings(
      LocationComponentSettings(
        enabled: widget.miUbicacion != null,
        pulsingEnabled: true,
        pulsingColor: AppTheme.azul.toARGB32(),
        showAccuracyRing: true,
      ),
    );
  }

  /// Vuelve a dibujar todos los marcadores. Con unas decenas de puntos es
  /// más simple y barato que actualizar uno por uno, y las imágenes de los
  /// pines salen de la caché de [PinBitmaps].
  Future<void> _dibujarMarcadores() async {
    final manager = _marcadores;
    if (manager == null) return;
    final version = ++_version;
    final pixelRatio = MediaQuery.devicePixelRatioOf(context);

    final opciones = <PointAnnotationOptions>[];
    for (final punto in widget.puntos) {
      final seleccionado = widget.seleccionado?.id == punto.id;
      opciones.add(
        PointAnnotationOptions(
          geometry: _punto(punto.lat, punto.lng),
          image: await PinBitmaps.de(
            punto.materiales,
            seleccionado: seleccionado,
            pixelRatio: pixelRatio,
          ),
          symbolSortKey: seleccionado ? 1 : 0,
        ),
      );
    }
    if (!mounted || version != _version) return;

    await manager.deleteAll();
    final creadas = await manager.createMulti(opciones);
    if (!mounted || version != _version) return;
    _puntoPorAnotacion.clear();
    for (var i = 0; i < creadas.length; i++) {
      final anotacion = creadas[i];
      if (anotacion != null) {
        _puntoPorAnotacion[anotacion.id] = widget.puntos[i];
      }
    }
  }

  void _centrarEnUsuario() {
    final ubicacion = widget.miUbicacion;
    if (_centradoEnUsuario || ubicacion == null || _mapa == null) return;
    _centradoEnUsuario = true;
    _mapa!.flyTo(
      CameraOptions(center: _punto(ubicacion.lat, ubicacion.lng), zoom: 15),
      MapAnimationOptions(duration: 800),
    );
  }

  void _apuntarAlNorte() {
    _mapa?.flyTo(CameraOptions(bearing: 0), MapAnimationOptions(duration: 400));
  }

  void _centrarEn(
    double lat,
    double lng, {
    double? zoom,
    double margenInferior = 0,
  }) {
    _mapa?.flyTo(
      CameraOptions(
        center: _punto(lat, lng),
        zoom: zoom,
        padding: MbxEdgeInsets(
          top: 0,
          left: 0,
          bottom: margenInferior,
          right: 0,
        ),
      ),
      MapAnimationOptions(duration: 600),
    );
  }

  Future<void> _avisarCentro() async {
    final mapa = _mapa;
    final aviso = widget.onCentroCambiado;
    if (mapa == null || aviso == null) return;
    final centro = (await mapa.getCameraState()).center.coordinates;
    if (mounted) {
      aviso((lat: centro.lat.toDouble(), lng: centro.lng.toDouble()));
    }
  }

  // Mapbox usa (longitud, latitud), al revés que el resto de la app.
  static Point _punto(double lat, double lng) =>
      Point(coordinates: Position(lng, lat));

  @override
  Widget build(BuildContext context) {
    if (_token.isEmpty) return const _SinToken();
    _estiloActual ??= _estiloDelTema();
    return MapWidget(
      key: const ValueKey('mapa-rebin'),
      // Como textura, Flutter dibuja el mapa en su orden normal. Con el modo por
      // defecto (capa nativa SurfaceView) el mapa de Inicio reaparecía encima de
      // cualquier pantalla abierta sobre él (ej. el escáner de QR) al salir de la
      // app y volver, y dejaba a la vista la cámara sin botones.
      textureView: true,
      // ignore: experimental_member_use
      androidHostingMode: AndroidPlatformViewHostingMode.TLHC_HC,
      styleUri: _estiloActual!,
      onMapCreated: _alCrearMapa,
      onMapIdleListener: (_) => _avisarCentro(),
      onCameraChangeListener: (evento) =>
          widget.controller?.value = evento.cameraState.bearing,
    );
  }
}

/// Sin `MAPBOX_ACCESS_TOKEN` en `.env` no se intenta cargar el mapa (Mapbox
/// fallaría igual); la lista de puntos sigue funcionando debajo.
class _SinToken extends StatelessWidget {
  const _SinToken();

  @override
  Widget build(BuildContext context) {
    final colores = context.colores;
    return ColoredBox(
      color: colores.fondoMapa,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            'Falta MAPBOX_ACCESS_TOKEN en app/.env para mostrar el mapa.',
            textAlign: TextAlign.center,
            style: TextStyle(color: colores.textoSecundario),
          ),
        ),
      ),
    );
  }
}
