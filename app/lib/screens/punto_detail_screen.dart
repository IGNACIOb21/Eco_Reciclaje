import 'package:flutter/material.dart';

import '../models/filtros_mapa.dart';
import '../models/material_type.dart';
import '../models/opiniones_punto.dart';
import '../models/punto_reciclaje.dart';
import '../repositories/acciones_por_defecto.dart';
import '../repositories/acciones_repository.dart';
import '../repositories/puntos_repository.dart';
import '../repositories/puntos_repository_supabase.dart';
import '../services/camara_service.dart';
import '../state/usuario_controller.dart';
import '../theme/app_theme.dart';
import '../utils/fechas.dart';
import '../utils/geo.dart' as geo;
import '../utils/snackbars.dart';
import '../widgets/avisos_punto.dart';
import '../widgets/estado_badge.dart';
import '../widgets/map_rebin.dart';
import '../widgets/rating_stars.dart';
import 'calificar_screen.dart';
import 'reportar_estado_screen.dart';

class PuntoDetailScreen extends StatefulWidget {
  final PuntoReciclaje punto;

  /// Puntos ya cargados por el mapa, para mostrar sus pines en el encabezado
  /// sin esperar a la red.
  final List<PuntoReciclaje> puntosCercanos;

  // Solo para tests: inyectan repositorios en vez del Supabase real.
  final AccionesRepository? acciones;
  final PuntosRepository? puntos;
  final CamaraService? camara;

  const PuntoDetailScreen({
    super.key,
    required this.punto,
    this.puntosCercanos = const [],
    this.acciones,
    this.puntos,
    this.camara,
  });

  @override
  State<PuntoDetailScreen> createState() => _PuntoDetailScreenState();
}

class _PuntoDetailScreenState extends State<PuntoDetailScreen> {
  // Punto mostrado: cambia al tocar otro pin del mapa del encabezado y se
  // actualiza tras reportar o calificar para que el promedio y el estado
  // reflejen lo que acaba de pasar.
  late PuntoReciclaje punto = widget.punto;

  // Zoom del mapa del encabezado: muestra la cuadra y los alrededores.
  static const _zoomFicha = 16.0;

  // Radio de los puntos que se piden al mover el mapa del encabezado, y
  // cuánto hay que moverlo para volver a pedirlos.
  static const _radioCercanosKm = 3.0;
  static const _kmParaRecargar = 1.0;

  final _mapa = MapaRebinController();
  final _scroll = ScrollController();

  // Pines del encabezado, por id (los del mapa general + los que se piden al
  // mover el mapa).
  late final Map<String, PuntoReciclaje> _cercanos = {
    for (final p in widget.puntosCercanos) p.id: p,
    widget.punto.id: widget.punto,
  };
  late List<PuntoReciclaje> _pines = _cercanos.values.toList();
  ({double lat, double lng})? _cargadosEn;

  PuntosRepository get _repositorio =>
      widget.puntos ?? PuntosRepositorySupabase();

  // Etiquetas más votadas y comentarios del punto mostrado (null mientras
  // se cargan; si fallan, la sección no se muestra).
  OpinionesPunto? _opiniones;
  bool _opinionesFallaron = false;

  @override
  void initState() {
    super.initState();
    _cargarCercanos(punto.lat, punto.lng);
    _cargarOpiniones();
  }

  Future<void> _cargarOpiniones() async {
    final id = punto.id;
    if (_opiniones != null || _opinionesFallaron) {
      setState(() {
        _opiniones = null;
        _opinionesFallaron = false;
      });
    }
    try {
      final repositorio = widget.acciones ?? accionesPorDefecto();
      final o = await repositorio.opiniones(id);
      if (mounted && punto.id == id) setState(() => _opiniones = o);
    } catch (_) {
      if (mounted && punto.id == id) {
        setState(() => _opinionesFallaron = true);
      }
    }
  }

  @override
  void dispose() {
    _mapa.dispose();
    _scroll.dispose();
    super.dispose();
  }

  /// Pide los puntos alrededor de ([lat], [lng]) y los suma a los pines.
  Future<void> _cargarCercanos(double lat, double lng) async {
    _cargadosEn = (lat: lat, lng: lng);
    try {
      final lista = await _repositorio.obtenerPuntos(
        miLat: lat,
        miLng: lng,
        filtros: const FiltrosMapa(distanciaMaximaKm: _radioCercanosKm),
      );
      if (!mounted) return;
      setState(() {
        for (final p in lista) {
          _cercanos[p.id] = p;
        }
        _cercanos[punto.id] = punto;
        _pines = _cercanos.values.toList();
      });
    } catch (_) {
      // Sin conexión: se quedan los pines que ya había.
    }
  }

  /// Al soltar el mapa del encabezado lejos de donde se pidieron los puntos,
  /// se piden los de la zona nueva.
  void _alMoverMapa(({double lat, double lng}) centro) {
    final previo = _cargadosEn;
    if (previo != null &&
        geo.distanciaKm(previo.lat, previo.lng, centro.lat, centro.lng) <
            _kmParaRecargar) {
      return;
    }
    _cargarCercanos(centro.lat, centro.lng);
  }

  /// Tocar otro pin del encabezado cambia la ficha a ese punto sin salir de
  /// la pantalla y recentra el mapa en él.
  void _cambiarA(PuntoReciclaje nuevo) {
    if (nuevo.id == punto.id) return;
    setState(() => punto = nuevo);
    _cargarOpiniones();
    _mapa.centrarEn(nuevo.lat, nuevo.lng, zoom: _zoomFicha);
    if (_scroll.hasClients) {
      _scroll.animateTo(
        0,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  /// Vuelve a leer este punto del servidor (promedio de calificaciones y
  /// estado visible). Si falla, se deja lo que ya se mostraba.
  Future<void> _refrescarPunto() async {
    try {
      final repositorio = widget.puntos ?? PuntosRepositorySupabase();
      final lista = await repositorio.obtenerPuntos(
        miLat: punto.lat,
        miLng: punto.lng,
        filtros: const FiltrosMapa(distanciaMaximaKm: 0.5),
      );
      final nuevo = lista.where((p) => p.id == punto.id).firstOrNull;
      if (nuevo != null && mounted) {
        setState(() {
          punto = nuevo;
          _cercanos[nuevo.id] = nuevo;
          _pines = _cercanos.values.toList();
        });
      }
    } catch (_) {
      // Sin conexión: se conserva lo mostrado.
    }
  }

  /// Abre una pantalla de acción y, si se envió, avisa los puntos ganados,
  /// recarga el usuario para que Inicio y Perfil los muestren y actualiza el
  /// punto.
  Future<void> _abrirAccion(
    BuildContext context,
    Widget Function(AccionesRepository) pantalla,
    String mensajeBase,
  ) async {
    final repositorio = widget.acciones ?? accionesPorDefecto();
    final usuario = context
        .dependOnInheritedWidgetOfExactType<UsuarioScope>()
        ?.notifier;
    final resultado = await Navigator.of(context).push<ResultadoAccion>(
      MaterialPageRoute(builder: (_) => pantalla(repositorio)),
    );
    if (resultado == null || !context.mounted) return;
    mostrarSnackbar(
      context,
      resultado.puntos > 0
          ? '$mensajeBase +${resultado.puntos} Rebin Points'
          : mensajeBase,
    );
    usuario?.cargar();
    _cargarOpiniones();
    await _refrescarPunto();
  }

  @override
  Widget build(BuildContext context) {
    final colores = context.colores;
    return Scaffold(
      body: Column(
        children: [
          // Encabezado: mapa interactivo centrado en el punto, de borde a
          // borde (160 de alto, como el encabezado anterior). Se puede
          // arrastrar para ver otros puntos; tocar uno cambia la ficha.
          // El ancho va explícito: sin él, el Stack toma el ancho de su único
          // hijo no posicionado (el botón de volver) y el mapa queda angosto.
          SizedBox(
            width: double.infinity,
            height: 160,
            child: Stack(
              children: [
                Positioned.fill(
                  child: MapRebin(
                    puntos: _pines,
                    seleccionado: punto,
                    centroInicial: (
                      lat: widget.punto.lat,
                      lng: widget.punto.lng,
                    ),
                    zoomInicial: _zoomFicha,
                    controller: _mapa,
                    onTapPin: _cambiarA,
                    onCentroCambiado: _alMoverMapa,
                  ),
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Material(
                      color: colores.superficie,
                      shape: const CircleBorder(),
                      elevation: 3,
                      child: BackButton(color: colores.texto),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              controller: _scroll,
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
                    AvisosPunto(avisos: punto.avisos),
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
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
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
                    // "Cómo llegar" no va aquí: ya está en la tarjeta que se
                    // abre al tocar el pin. Reportar y calificar son las acciones
                    // de la ficha, con el estilo de botón principal.
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        key: const Key('ficha-reportar'),
                        onPressed: () => _abrirAccion(
                          context,
                          (r) => ReportarEstadoScreen(
                            punto: punto,
                            repositorio: r,
                            camara: widget.camara,
                          ),
                          'Gracias por avisar.',
                        ),
                        icon: const Icon(Icons.flag_outlined),
                        label: const Text('Reportar estado'),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        key: const Key('ficha-calificar'),
                        onPressed: () => _abrirAccion(
                          context,
                          (r) => CalificarScreen(punto: punto, repositorio: r),
                          'Gracias por calificar.',
                        ),
                        icon: const Icon(Icons.star_outline),
                        label: const Text('Calificar este punto'),
                      ),
                    ),
                    if (!_opinionesFallaron) ...[
                      const SizedBox(height: 28),
                      _SeccionOpiniones(opiniones: _opiniones),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// "Opiniones" de la ficha: etiquetas más votadas y comentarios de los
/// últimos 12 meses ([opiniones] null mientras se cargan).
class _SeccionOpiniones extends StatelessWidget {
  final OpinionesPunto? opiniones;

  const _SeccionOpiniones({required this.opiniones});

  @override
  Widget build(BuildContext context) {
    final colores = context.colores;
    final o = opiniones;
    return Column(
      key: const Key('ficha-opiniones'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Opiniones',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
        const SizedBox(height: 10),
        if (o == null)
          const Center(child: CircularProgressIndicator())
        else if (o.estaVacio)
          Text(
            'Todavía nadie opina sobre este punto. ¡Califícalo y sé el primero!',
            style: TextStyle(color: colores.textoSecundario),
          )
        else ...[
          if (o.etiquetas.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final e in o.etiquetas)
                  Chip(label: Text('${e.etiqueta} (${e.cantidad})')),
              ],
            ),
          for (final opinion in o.opiniones)
            Padding(
              padding: const EdgeInsets.only(top: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      RatingStars(
                        calificacion: opinion.puntuacion.toDouble(),
                        size: 14,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '${opinion.alias} · ${haceTiempo(opinion.fecha)}',
                          style: TextStyle(
                            color: colores.textoSecundario,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(opinion.comentario),
                ],
              ),
            ),
        ],
      ],
    );
  }
}
