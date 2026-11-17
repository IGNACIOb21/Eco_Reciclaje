import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../data/comunas_demo.dart';
import '../models/filtros_mapa.dart';
import '../models/material_type.dart';
import '../models/punto_reciclaje.dart';
import '../repositories/acciones_repository.dart';
import '../repositories/puntos_repository.dart';
import '../repositories/puntos_repository_supabase.dart';
import '../services/ubicacion_service.dart';
import '../theme/app_theme.dart';
import '../utils/busqueda.dart';
import '../utils/geo.dart' as geo;
import '../utils/snackbars.dart';
import '../widgets/avisos_punto.dart';
import '../widgets/como_llegar.dart';
import '../widgets/esqueleto.dart';
import '../widgets/estado_pantalla.dart';
import '../widgets/estado_badge.dart';
import '../widgets/map_rebin.dart';
import '../widgets/tarjeta_cercana.dart';
import '../widgets/rating_stars.dart';
import 'filtros_screen.dart';
import 'punto_detail_screen.dart';

class MapaScreen extends StatefulWidget {
  final PuntosRepository? repositorio;

  /// false mientras la pestaña Mapa no está a la vista: se apaga el GPS.
  final bool activo;

  // Solo para tests: inyecta un repositorio de acciones en vez del real.
  final AccionesRepository? acciones;

  /// Widget opcional que va en la cabecera de la lista deslizable, bajo el
  /// asa. Inicio lo usa para el saludo, los Rebin Points y el nivel.
  final Widget? cabecera;

  /// Widget opcional a la derecha del buscador. Inicio pone ahí el saldo de
  /// Rebin Points.
  final Widget? junto;

  /// Materiales que otra pantalla pide mostrar (ej. "Ver dónde reciclarlo"
  /// desde Escanear): cada cambio reemplaza el filtro de materiales.
  final ValueListenable<Set<TipoMaterial>>? materialesPedidos;

  const MapaScreen({
    super.key,
    this.repositorio,
    this.activo = true,
    this.acciones,
    this.cabecera,
    this.junto,
    this.materialesPedidos,
  });

  @override
  State<MapaScreen> createState() => _MapaScreenState();
}

class _MapaScreenState extends State<MapaScreen> with WidgetsBindingObserver {
  late final PuntosRepository _repositorio =
      widget.repositorio ?? PuntosRepositorySupabase();

  FiltrosMapa _filtros = const FiltrosMapa();

  // Texto del buscador. Filtra en el teléfono los puntos ya cargados (son
  // pocas decenas); el resultado se guarda para no entregarle al mapa una
  // lista nueva en cada setState (ej. cada lectura del GPS), lo que le haría
  // redibujar todos los marcadores.
  final _busquedaController = TextEditingController();
  String _busqueda = '';
  List<PuntoReciclaje>? _filtradosDe;
  String? _filtradosPara;
  List<PuntoReciclaje> _filtrados = const [];
  PuntoReciclaje? _seleccionado;
  late Future<List<PuntoReciclaje>> _puntosFuture;

  // Últimos puntos recibidos: mientras se recarga (filtro, GPS) se siguen
  // mostrando en vez de vaciar el mapa.
  List<PuntoReciclaje> _ultimosPuntos = const [];

  // Referencia para "distancia a mí" (GPS si está disponible, si no Plaza
  // Ñuñoa). Independiente de la cámara del mapa: el usuario puede arrastrar y
  // hacer zoom libremente sin que eso cambie las distancias mostradas. También
  // es el centro que se manda a la RPC app_puntos_cercanos.
  double _miUbicacionLat = centroDefectoLat;
  double _miUbicacionLng = centroDefectoLng;

  // Posición GPS en vivo (marcador "Estás aquí"); null sin permiso.
  ({double lat, double lng})? _gps;
  bool _buscandoGps = false;

  // Alto de la lista de puntos cercanos, como fracción de la pantalla. La
  // inicial y la mínima son 20 % más bajas que antes (0.32 y 0.15); al
  // deslizarla hacia arriba sigue llegando al 85 %.
  static const _hojaInicial = 0.256;
  static const _hojaMinima = 0.12;
  static const _hojaMaxima = 0.85;

  // Alto actual de la lista: la brújula y "Mi ubicación" van pegadas a su borde superior y se
  // esconde cuando la lista sube por sobre su alto inicial.
  final _altoHoja = ValueNotifier<double>(_hojaInicial);
  final _mapa = MapaRebinController();

  // Con un punto seleccionado la lista se convierte en su vista previa, que
  // necesita más alto que la lista general.
  static const _hojaVistaPrevia = 0.6;
  final _hoja = DraggableScrollableController();

  StreamSubscription<Position>? _seguimiento;

  // Centro con el que se pidieron los puntos: solo se vuelven a pedir al
  // alejarse más de esto, no en cada actualización del GPS.
  static const _kmParaRecargar = 0.3;
  double _cargadoLat = centroDefectoLat;
  double _cargadoLng = centroDefectoLng;

  // El GPS (alta precisión) solo corre con la pestaña a la vista y la app en
  // primer plano: es lo que más batería gasta.
  bool _enPrimerPlano = true;
  bool get _debeSeguir => widget.activo && _enPrimerPlano;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Los primeros puntos se piden en la última posición conocida (sin
    // esperar al GPS): cuando llega la actual, solo se vuelven a pedir si
    // quedó a más de _kmParaRecargar.
    final ultima = ultimaUbicacionConocida;
    if (ultima != null) {
      _miUbicacionLat = ultima.latitude;
      _miUbicacionLng = ultima.longitude;
    }
    final pedidos = widget.materialesPedidos;
    if (pedidos != null && pedidos.value.isNotEmpty) {
      _filtros = _filtros.copyWith(materiales: pedidos.value);
    }
    pedidos?.addListener(_alPedirMateriales);
    _puntosFuture = _cargarPuntos();
    _actualizarGps();
  }

  void _alPedirMateriales() {
    final pedidos = widget.materialesPedidos;
    if (pedidos != null) _cambiarMateriales(pedidos.value);
  }

  @override
  void didUpdateWidget(MapaScreen anterior) {
    super.didUpdateWidget(anterior);
    if (anterior.activo != widget.activo) _actualizarGps();
    if (anterior.materialesPedidos != widget.materialesPedidos) {
      anterior.materialesPedidos?.removeListener(_alPedirMateriales);
      widget.materialesPedidos?.addListener(_alPedirMateriales);
    }
  }

  @override
  void dispose() {
    widget.materialesPedidos?.removeListener(_alPedirMateriales);
    WidgetsBinding.instance.removeObserver(this);
    _seguimiento?.cancel();
    _busquedaController.dispose();
    _altoHoja.dispose();
    _mapa.dispose();
    _hoja.dispose();
    super.dispose();
  }

  // Al volver a la app (ej. tras activar el permiso en Ajustes) se retoma el
  // seguimiento; al salir se apaga.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // `inactive` (ej. bajar la barra de notificaciones) no cuenta como salir.
    if (state == AppLifecycleState.inactive) return;
    _enPrimerPlano = state == AppLifecycleState.resumed;
    _actualizarGps();
  }

  void _actualizarGps() {
    if (_debeSeguir) {
      if (_seguimiento == null) _cargarUbicacion();
    } else {
      _seguimiento?.cancel();
      _seguimiento = null;
    }
  }

  Future<List<PuntoReciclaje>> _cargarPuntos() {
    _cargadoLat = _miUbicacionLat;
    _cargadoLng = _miUbicacionLng;
    return _repositorio
        .obtenerPuntos(
          miLat: _miUbicacionLat,
          miLng: _miUbicacionLng,
          filtros: _filtros,
        )
        .then((puntos) => _ultimosPuntos = puntos);
  }

  Future<void> _cargarUbicacion() async {
    if (_buscandoGps) return;
    _buscandoGps = true;
    // Mientras llega la posición actual, la última conocida ya sirve para
    // "Mi ubicación".
    final ultima = ultimaUbicacionConocida;
    if (_gps == null && ultima != null) _moverA(ultima);
    // El seguimiento parte de inmediato: no depende de que la primera
    // lectura responda (bajo techo puede tardar o fallar). Si termina (sin
    // permiso o sin GPS) se suelta, para reintentar al volver a la app.
    _seguimiento ??= seguirUbicacion().listen(
      (p) => _moverA(p),
      onError: (Object e) => debugPrint('Mapa: seguimiento GPS ($e)'),
      onDone: () => _seguimiento = null,
    );
    final posicion = await obtenerUbicacionActual();
    _buscandoGps = false;
    if (posicion == null || !mounted || !_debeSeguir) return;
    // Recarga solo si quedó a más de _kmParaRecargar de donde se pidieron
    // los puntos (el centro por defecto o la última posición conocida).
    _moverA(posicion);
  }

  void _moverA(Position posicion, {bool recargar = false}) {
    if (!mounted) return;
    ultimaUbicacionConocida = posicion;
    setState(() {
      _miUbicacionLat = posicion.latitude;
      _miUbicacionLng = posicion.longitude;
      _gps = (lat: posicion.latitude, lng: posicion.longitude);
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

  Future<void> _abrirFicha(PuntoReciclaje punto) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PuntoDetailScreen(
          punto: punto,
          puntos: _repositorio,
          puntosCercanos: _ultimosPuntos,
        ),
      ),
    );
    if (!mounted) return;
    // Al volver, la lista refleja lo que se reportó o calificó en la ficha.
    setState(() {
      _puntosFuture = _cargarPuntos().then((puntos) {
        final id = _seleccionado?.id;
        if (id != null && mounted) {
          final vigente = puntos.where((p) => p.id == id).firstOrNull;
          if (vigente != null) _seleccionado = vigente;
        }
        return puntos;
      });
    });
  }

  /// Lo mismo al tocar un pin o un punto de la lista: el pin queda
  /// resaltado, el mapa se centra en él (por sobre la hoja) y la lista se
  /// convierte en la vista previa del punto ("Cómo llegar" y "Ver ficha").
  void _seleccionar(PuntoReciclaje punto) {
    setState(() => _seleccionado = punto);
    _moverHoja(_hojaVistaPrevia);
    final alto = MediaQuery.sizeOf(context).height;
    _mapa.centrarEn(
      punto.lat,
      punto.lng,
      margenInferior: alto * _hojaVistaPrevia,
    );
  }

  /// Lleva el mapa al punto azul (la posición GPS), por sobre la hoja.
  Future<void> _irAMiUbicacion() async {
    final gps = _gps;
    if (gps == null) {
      // El aviso depende del estado real del teléfono, no de un ajuste de
      // la app: con el permiso dado, solo falta que llegue la posición.
      final estado = await estadoUbicacion();
      if (!mounted) return;
      mostrarSnackbar(context, switch (estado) {
        EstadoUbicacion.gpsApagado =>
          'Enciende la ubicación del teléfono para ir a tu posición.',
        EstadoUbicacion.sinPermiso =>
          'Activa la ubicación en Perfil › Ajustes para ir a tu posición.',
        EstadoUbicacion.lista =>
          'Buscando tu ubicación… Inténtalo de nuevo en unos segundos.',
      });
      if (estado == EstadoUbicacion.lista) _cargarUbicacion();
      return;
    }
    _mapa.centrarEn(
      gps.lat,
      gps.lng,
      zoom: 15,
      margenInferior: MediaQuery.sizeOf(context).height * _altoHoja.value,
    );
  }

  /// Vuelve de la vista previa a la lista de puntos cercanos.
  void _volverALista() {
    setState(() => _seleccionado = null);
    _moverHoja(_hojaInicial);
  }

  // Alto total del panel (hasta el borde de abajo) y de la píldora que tapa
  // su parte baja. Las alturas del panel en este archivo (_hojaInicial…) se
  // cuentan sobre la zona visible, encima de la píldora; estas funciones las
  // pasan a la fracción del panel completo y de vuelta.
  double _altoTotal = 0;
  double _abajoHoja = 0;

  double _aHoja(double f) {
    if (_altoTotal <= _abajoHoja) return f;
    return (f * (_altoTotal - _abajoHoja) + _abajoHoja) / _altoTotal;
  }

  double _deHoja(double s) {
    if (_altoTotal <= _abajoHoja) return s;
    return (s * _altoTotal - _abajoHoja) / (_altoTotal - _abajoHoja);
  }

  void _moverHoja(double alto) {
    if (!_hoja.isAttached) return;
    _hoja.animateTo(
      _aHoja(alto),
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  List<PuntoReciclaje> _puntosVisibles(List<PuntoReciclaje> puntos) {
    if (!identical(puntos, _filtradosDe) || _busqueda != _filtradosPara) {
      _filtradosDe = puntos;
      _filtradosPara = _busqueda;
      _filtrados = filtrarPuntos(puntos, _busqueda);
    }
    return _filtrados;
  }

  void _buscar(String texto) {
    setState(() {
      _busqueda = texto;
      _seleccionado = null;
    });
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

  void _limpiarFiltros() {
    setState(() {
      _filtros = const FiltrosMapa();
      _puntosFuture = _cargarPuntos();
      _seleccionado = null;
    });
  }

  void _reintentar() {
    setState(() {
      _puntosFuture = _cargarPuntos();
    });
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
    // Con la vista previa abierta, "atrás" vuelve a la lista en vez de salir.
    // Solo mientras el Mapa está activo (visible y en primer plano).
    return PopScope(
      canPop: _seleccionado == null || !widget.activo,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _volverALista();
      },
      child: _construir(context),
    );
  }

  Widget _construir(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<PuntoReciclaje>>(
        future: _puntosFuture,
        builder: (context, snapshot) {
          // El mapa no se desmonta nunca: mientras se recarga (filtros,
          // moverse 300 m) sigue con los puntos anteriores y la carga o el
          // error se muestran encima, así no se vuelven a bajar los tiles ni
          // se pierde la cámara.
          final cargando = snapshot.connectionState == ConnectionState.waiting;
          final conError = snapshot.hasError && !cargando;
          final puntos = _puntosVisibles(snapshot.data ?? _ultimosPuntos);
          final buscando = _busqueda.trim().isNotEmpty;
          final colores = context.colores;
          // Alto de la píldora de pestañas (el MainShell extiende el mapa
          // por detrás de ella): el panel deslizante y sus botones terminan
          // encima, así nunca bajan más que la píldora y siempre se pueden
          // volver a subir. Alrededor de la píldora solo se ve el mapa.
          final abajo = MediaQuery.paddingOf(context).bottom;

          return Stack(
            children: [
              Positioned.fill(
                child: MapRebin(
                  puntos: puntos,
                  seleccionado: _seleccionado,
                  centroInicial: (lat: centroDefectoLat, lng: centroDefectoLng),
                  miUbicacion: _gps,
                  onTapPin: _seleccionar,
                  controller: _mapa,
                ),
              ),
              SafeArea(
                child: _BarraBusqueda(
                  junto: widget.junto,
                  controller: _busquedaController,
                  onBuscar: _buscar,
                  materialesActivos: _filtros.materiales,
                  onMaterialesChanged: _cambiarMateriales,
                ),
              ),
              // Línea de carga en el espacio de 8 sobre el buscador, para no
              // tapar los chips de categorías que van debajo de él. La lista
              // muestra además un esqueleto si aún no hay puntos.
              if (cargando)
                const SafeArea(
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: Padding(
                      padding: EdgeInsets.only(top: 2),
                      child: SizedBox(
                        width: 160,
                        child: LinearProgressIndicator(
                          minHeight: 3,
                          borderRadius: BorderRadius.all(Radius.circular(3)),
                        ),
                      ),
                    ),
                  ),
                ),
              // Sin ningún punto cargado, el error tapa el mapa; si ya había
              // puntos, siguen a la vista y la lista avisa que son los últimos.
              if (conError && _ultimosPuntos.isEmpty)
                Positioned.fill(
                  child: ColoredBox(
                    color: colores.superficie.withValues(alpha: 0.94),
                    child: _MapaError(onReintentar: _reintentar),
                  ),
                ),
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                bottom: abajo,
                child: _BotonesSobreHoja(
                  brujula: _mapa,
                  altoHoja: _altoHoja,
                  altoVisible: _hojaInicial,
                  onNorte: _mapa.apuntarAlNorte,
                  onMiUbicacion: _irAMiUbicacion,
                ),
              ),
              // El panel llega hasta abajo, por detrás de la píldora (su
              // contenido se ve también ahí), pero sus alturas se cuentan
              // desde encima de la píldora: su borde nunca baja más que ella.
              Positioned.fill(
                child: LayoutBuilder(
                  builder: (context, limites) {
                    _altoTotal = limites.maxHeight;
                    _abajoHoja = abajo;
                    return NotificationListener<
                      DraggableScrollableNotification
                    >(
                      onNotification: (n) {
                        _altoHoja.value = _deHoja(n.extent);
                        return false;
                      },
                      child: DraggableScrollableSheet(
                        controller: _hoja,
                        initialChildSize: _aHoja(_hojaInicial),
                        minChildSize: _aHoja(_hojaMinima),
                        maxChildSize: _aHoja(_hojaMaxima),
                        builder: (context, scrollController) {
                          final seleccionado = _seleccionado;
                          return Container(
                            decoration: BoxDecoration(
                              color: colores.superficie,
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(24),
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 16,
                                ),
                              ],
                            ),
                            child: seleccionado != null
                                ? ListView(
                                    controller: scrollController,
                                    padding: EdgeInsets.only(bottom: abajo),
                                    children: [
                                      const _Asa(),
                                      _VistaPreviaPunto(
                                        punto: seleccionado,
                                        distanciaKm: _distanciaDe(seleccionado),
                                        origenLat: _gps?.lat,
                                        origenLng: _gps?.lng,
                                        onVolver: _volverALista,
                                        onVerFicha: () =>
                                            _abrirFicha(seleccionado),
                                      ),
                                    ],
                                  )
                                : ListView.builder(
                                    controller: scrollController,
                                    padding: EdgeInsets.only(bottom: abajo),
                                    // + encabezado, + aviso si la búsqueda no encontró nada.
                                    itemCount:
                                        puntos.length +
                                        (puntos.isEmpty ? 2 : 1),
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
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                            ),
                                            if (widget.cabecera != null)
                                              widget.cabecera!,
                                            if (conError &&
                                                _ultimosPuntos.isNotEmpty)
                                              _AvisoPuntosViejos(
                                                onReintentar: _reintentar,
                                              ),
                                            Padding(
                                              padding:
                                                  const EdgeInsets.fromLTRB(
                                                    16,
                                                    14,
                                                    16,
                                                    4,
                                                  ),
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Expanded(
                                                    child: _TituloLista(
                                                      cargando:
                                                          cargando &&
                                                          puntos.isEmpty,
                                                      busqueda: buscando
                                                          ? _busqueda.trim()
                                                          : null,
                                                      cantidad: puntos.length,
                                                    ),
                                                  ),
                                                  Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      GestureDetector(
                                                        onTap: _abrirFiltros,
                                                        child: Stack(
                                                          clipBehavior:
                                                              Clip.none,
                                                          children: [
                                                            Icon(
                                                              Icons.tune,
                                                              color: colores
                                                                  .textoSecundario,
                                                            ),
                                                            if (_filtros
                                                                .tieneFiltrosActivos)
                                                              Positioned(
                                                                right: -2,
                                                                top: -2,
                                                                child: Container(
                                                                  width: 8,
                                                                  height: 8,
                                                                  decoration: BoxDecoration(
                                                                    color: colores
                                                                        .primario,
                                                                    shape: BoxShape
                                                                        .circle,
                                                                  ),
                                                                ),
                                                              ),
                                                          ],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        );
                                      }
                                      if (puntos.isEmpty) {
                                        return _ListaVacia(
                                          cargando: cargando,
                                          conError: conError,
                                          buscando: buscando,
                                          conFiltros:
                                              _filtros.tieneFiltrosActivos,
                                          onAgregar: _abrirFiltros,
                                          onLimpiarFiltros: _limpiarFiltros,
                                        );
                                      }
                                      final punto = puntos[index - 1];
                                      return TarjetaCercana(
                                        punto: punto,
                                        distanciaKm: _distanciaDe(punto),
                                        onTap: () => _seleccionar(punto),
                                      );
                                    },
                                  ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Botones en la esquina inferior derecha, justo sobre la lista de puntos
/// cercanos: sube y baja con el borde de la lista y se esconden cuando la
/// lista se desliza por sobre su alto inicial. Arriba la brújula (la flecha
/// apunta al norte según el giro del mapa; al tocarla deja el norte arriba) y
/// abajo "Mi ubicación" (lleva el mapa a la posición GPS).
class _BotonesSobreHoja extends StatelessWidget {
  final MapaRebinController brujula;
  final ValueListenable<double> altoHoja;

  /// Alto de la lista (fracción de la pantalla) hasta el que se ven los
  /// botones.
  final double altoVisible;
  final VoidCallback onNorte;
  final VoidCallback onMiUbicacion;

  const _BotonesSobreHoja({
    required this.brujula,
    required this.altoHoja,
    required this.altoVisible,
    required this.onNorte,
    required this.onMiUbicacion,
  });

  @override
  Widget build(BuildContext context) {
    final colores = context.colores;
    return LayoutBuilder(
      builder: (context, restricciones) => ValueListenableBuilder<double>(
        valueListenable: altoHoja,
        builder: (context, alto, botones) {
          final visible = alto <= altoVisible + 0.01;
          return Stack(
            children: [
              Positioned(
                right: 16,
                bottom: alto * restricciones.maxHeight + 12,
                child: IgnorePointer(
                  ignoring: !visible,
                  child: AnimatedOpacity(
                    opacity: visible ? 1 : 0,
                    duration: const Duration(milliseconds: 150),
                    child: botones,
                  ),
                ),
              ),
            ],
          );
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _BotonMapa(
              clave: const Key('mapa-brujula'),
              mensaje: 'Apuntar al norte',
              onTap: onNorte,
              child: ValueListenableBuilder<double>(
                valueListenable: brujula,
                builder: (context, rumbo, _) => Transform.rotate(
                  angle: -rumbo * math.pi / 180,
                  child: Icon(
                    Icons.navigation,
                    color: colores.primario,
                    size: 26,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            _BotonMapa(
              clave: const Key('mapa-mi-ubicacion'),
              mensaje: 'Ir a mi ubicación',
              onTap: onMiUbicacion,
              child: Icon(Icons.my_location, color: colores.primario, size: 24),
            ),
          ],
        ),
      ),
    );
  }
}

/// Botón redondo flotante sobre el mapa.
class _BotonMapa extends StatelessWidget {
  final Key clave;
  final String mensaje;
  final VoidCallback onTap;
  final Widget child;

  const _BotonMapa({
    required this.clave,
    required this.mensaje,
    required this.onTap,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.colores.superficie,
      shape: const CircleBorder(),
      elevation: 4,
      child: InkWell(
        key: clave,
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Tooltip(
          message: mensaje,
          child: SizedBox(width: 48, height: 48, child: Center(child: child)),
        ),
      ),
    );
  }
}

/// Lo que muestra la lista cuando no hay puntos: un esqueleto mientras carga,
/// nada si falló (el aviso de error ya tapa el mapa) y, si no hay ninguno,
/// qué hacer: limpiar los filtros o sugerir un punto.
class _ListaVacia extends StatelessWidget {
  final bool cargando;
  final bool conError;
  final bool buscando;
  final bool conFiltros;
  final VoidCallback onAgregar;
  final VoidCallback onLimpiarFiltros;

  const _ListaVacia({
    required this.cargando,
    required this.conError,
    required this.buscando,
    required this.conFiltros,
    required this.onAgregar,
    required this.onLimpiarFiltros,
  });

  @override
  Widget build(BuildContext context) {
    if (cargando) {
      return const EsqueletoLista(
        key: Key('mapa-esqueleto'),
        filas: 3,
        altoFila: 72,
        conTitulo: false,
        desplazable: false,
      );
    }
    if (conError) return const SizedBox.shrink();
    if (buscando) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Text(
          'Ningún punto coincide con tu búsqueda. '
          'Prueba con otro nombre, calle o comuna.',
          style: TextStyle(color: context.colores.textoSecundario),
        ),
      );
    }
    if (conFiltros) {
      return EstadoPantalla(
        key: const Key('mapa-vacio-filtros'),
        icono: Icons.filter_alt_off_outlined,
        titulo: 'Ningún punto con estos filtros',
        texto: 'Prueba quitando algún material o ampliando la distancia.',
        accion: 'Limpiar filtros',
        onAccion: onLimpiarFiltros,
      );
    }
    return EstadoPantalla(
      key: const Key('mapa-vacio'),
      icono: Icons.add_location_alt_outlined,
      titulo: 'Aún no hay puntos por aquí',
      texto: 'Prueba ampliando la distancia de búsqueda en los filtros.',
      accion: 'Cambiar filtros',
      onAccion: onAgregar,
    );
  }
}

/// La recarga falló pero quedan los puntos de antes: se avisa que pueden no
/// estar al día, sin tapar el mapa.
class _AvisoPuntosViejos extends StatelessWidget {
  final VoidCallback onReintentar;

  const _AvisoPuntosViejos({required this.onReintentar});

  @override
  Widget build(BuildContext context) {
    final colores = context.colores;
    return Container(
      key: const Key('mapa-aviso-sin-conexion'),
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.only(left: 12),
      decoration: BoxDecoration(
        color: colores.advertenciaSuave,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.cloud_off_outlined, size: 20, color: colores.advertencia),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'No pudimos actualizar. Te mostramos los últimos puntos que '
              'cargamos.',
              style: TextStyle(fontSize: 13, color: colores.texto),
            ),
          ),
          TextButton(onPressed: onReintentar, child: const Text('Reintentar')),
        ],
      ),
    );
  }
}

/// Error de carga (sin conexión, Supabase caído, etc.) con opción de
/// reintentar, con el mismo estilo que usa Servicios para su propio error.
class _MapaError extends StatelessWidget {
  final VoidCallback onReintentar;

  const _MapaError({required this.onReintentar});

  @override
  Widget build(BuildContext context) => Center(
    child: EstadoPantalla(
      icono: Icons.wifi_off_outlined,
      titulo: 'No pudimos cargar los puntos de reciclaje.',
      texto: 'Revisa tu conexión e intenta de nuevo.',
      accion: 'Reintentar',
      onAccion: onReintentar,
    ),
  );
}

class _BarraBusqueda extends StatelessWidget {
  final Widget? junto;
  final TextEditingController controller;
  final ValueChanged<String> onBuscar;
  final Set<TipoMaterial> materialesActivos;
  final ValueChanged<Set<TipoMaterial>> onMaterialesChanged;

  const _BarraBusqueda({
    this.junto,
    required this.controller,
    required this.onBuscar,
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
          child: Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
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
                    controller: controller,
                    onChanged: onBuscar,
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      filled: false,
                      border: InputBorder.none,
                      icon: Icon(Icons.search, color: colores.textoSecundario),
                      hintText: 'Buscar punto o material',
                      isDense: true,
                      suffixIcon: controller.text.isEmpty
                          ? null
                          : IconButton(
                              tooltip: 'Limpiar búsqueda',
                              icon: const Icon(Icons.close, size: 18),
                              onPressed: () {
                                controller.clear();
                                onBuscar('');
                                FocusScope.of(context).unfocus();
                              },
                            ),
                    ),
                  ),
                ),
              ),
              if (junto != null) ...[const SizedBox(width: 8), junto!],
            ],
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

/// Encabezado de la lista: "Cerca de ti" con cuántos puntos hay, el
/// resultado de la búsqueda o "Buscando puntos cerca…" mientras carga.
class _TituloLista extends StatelessWidget {
  final bool cargando;
  final String? busqueda;
  final int cantidad;

  const _TituloLista({
    required this.cargando,
    required this.busqueda,
    required this.cantidad,
  });

  @override
  Widget build(BuildContext context) {
    final colores = context.colores;
    final puntos = cantidad == 1 ? '1 punto' : '$cantidad puntos';
    final (titulo, detalle) = cargando
        ? ('Buscando puntos cerca…', null)
        : busqueda != null
        ? ('Resultados', '$puntos para «$busqueda»')
        : (
            'Cerca de ti',
            cantidad == 0 ? puntos : '$puntos · arrastra para ver más',
          );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(titulo, style: Theme.of(context).textTheme.titleLarge),
        if (detalle != null)
          Text(
            detalle,
            key: const Key('mapa-conteo'),
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: colores.textoSecundario, fontSize: 13),
          ),
      ],
    );
  }
}

/// Asa de arrastre de la hoja inferior del mapa.
class _Asa extends StatelessWidget {
  const _Asa();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Center(
        child: Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: context.colores.borde,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }
}

/// Vista previa del punto seleccionado, dentro de la misma hoja que la lista
/// (al tocar un pin o un punto de la lista): estado y calificación primero,
/// "Cómo llegar" como acción primaria y "Ver ficha" como secundaria.
class _VistaPreviaPunto extends StatelessWidget {
  final PuntoReciclaje punto;
  final double distanciaKm;
  final double? origenLat;
  final double? origenLng;
  final VoidCallback onVerFicha;
  final VoidCallback onVolver;

  const _VistaPreviaPunto({
    required this.punto,
    required this.distanciaKm,
    required this.onVerFicha,
    required this.onVolver,
    this.origenLat,
    this.origenLng,
  });

  @override
  Widget build(BuildContext context) {
    final colores = context.colores;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              key: const Key('mapa-volver-lista'),
              onPressed: onVolver,
              icon: const Icon(Icons.arrow_back, size: 18),
              label: const Text('Puntos cercanos'),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: Text(
                  punto.nombre,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              EstadoBadge(estado: punto.estado),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              RatingStars(calificacion: punto.calificacionPromedio, size: 14),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '${punto.comuna} · ${distanciaKm.toStringAsFixed(1)} km',
                  style: TextStyle(
                    color: colores.textoSecundario,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          if (punto.direccion.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(
                  Icons.place_outlined,
                  size: 16,
                  color: colores.textoSecundario,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    punto.direccion,
                    style: TextStyle(color: colores.textoSecundario),
                  ),
                ),
              ],
            ),
          ],
          AvisosPunto(avisos: punto.avisos),
          // Las acciones van antes que los materiales para que se vean sin
          // tener que deslizar la hoja.
          const SizedBox(height: 16),
          ComoLlegar(punto: punto, origenLat: origenLat, origenLng: origenLng),
          const SizedBox(height: 8),
          OutlinedButton(onPressed: onVerFicha, child: const Text('Ver ficha')),
          const SizedBox(height: 16),
          if (punto.materiales.isEmpty)
            Text(
              'Sin categorías registradas',
              style: TextStyle(color: colores.textoSecundario),
            )
          else
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final material in punto.materiales)
                  Chip(
                    visualDensity: VisualDensity.compact,
                    avatar: Icon(
                      material.icono,
                      size: 16,
                      color: material.color,
                    ),
                    label: Text(material.etiqueta),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}
