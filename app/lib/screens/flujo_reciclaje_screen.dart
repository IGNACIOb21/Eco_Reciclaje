import 'dart:io';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../models/etiqueta_modelo.dart';
import '../models/material_type.dart';
import '../models/punto_qr.dart';
import '../repositories/puntos_repository.dart';
import '../repositories/reciclaje_repository.dart';
import '../services/camara_service.dart';
import '../services/clasificacion_service.dart';
import '../services/descripciones_categorias.dart';
import '../services/permisos_service.dart';
import '../services/ubicacion_service.dart';
import '../services/voz_service.dart';
import '../state/usuario_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/encabezado_paso.dart';
import '../widgets/indicador_pasos.dart';
import '../widgets/panel_clasificacion.dart';
import 'camara_foto_screen.dart';
import 'escaner_qr_screen.dart';
import 'foto_fallida_screen.dart';

enum _Paso { qr, foto, confirmar }

/// Un artículo fotografiado en el punto.
class _Articulo {
  final File foto;
  final DateTime horaCaptura;
  Position? gps;
  bool leyendoGps = true;
  Future<Position?>? lecturaGps;

  /// Se intentó confirmar y no hubo GPS.
  bool sinGps = false;
  ResultadoClasificacion? resultado;
  Future<RegistroDeposito>? envio;
  RegistroDeposito? registro;
  String? error;

  _Articulo(this.foto, this.horaCaptura);

  bool get enviando => envio != null && registro == null && error == null;
}

/// Flujo "Reciclar en un punto", con el QR primero (guía de IA, sección 4):
///
/// 1. **QR**: se escanea el QR del contenedor; `app_punto_qr` dice qué punto
///    es y qué recibe. Si no recibe depósitos (no operativo, QR dañado) se
///    avisa antes de sacar fotos.
/// 2. **Foto**: la cámara del artículo se abre sola (mientras se busca el
///    punto), con el aviso de si la persona está cerca.
/// 3. **Confirmar**: el punto, el artículo con su categoría y "Confirmar",
///    que lo registra (`app_registrar_deposito`) con el GPS de alta
///    precisión y la hora de la foto; la base decide aprobado, en revisión o
///    rechazado, y los puntos. Mientras no esté la IA, la categoría es
///    Plástico por defecto y la explicación queda desactivada. Después se
///    puede reciclar otro artículo o terminar.
///
/// Si Android cierra la app con la cámara abierta, al volver se reabre aquí
/// con la foto ([desdePendiente]). Las fotos se borran del teléfono al salir.
class FlujoReciclajeScreen extends StatefulWidget {
  final ReciclajeRepository reciclajes;
  final PuntosRepository puntos;
  final CamaraService? camara;
  final ClasificacionService? clasificador;
  final VozService? voz;
  final PermisosService permisos;

  /// Contenido del QR ya leído y foto ya tomada (al recuperar la foto).
  final String? qrInicial;
  final File? fotoInicial;

  // Solo para tests: el lector QR y el GPS.
  final Future<String?> Function(BuildContext context)? leerQr;
  final Future<Position?> Function()? ubicar;

  const FlujoReciclajeScreen({
    super.key,
    required this.reciclajes,
    required this.puntos,
    this.camara,
    this.clasificador,
    this.voz,
    this.permisos = const PermisosService(),
    this.qrInicial,
    this.fotoInicial,
    this.leerQr,
    this.ubicar,
    this.escanearAlEntrar = false,
  });

  /// Abre el lector de QR apenas se muestra la pantalla (botón de escanear de
  /// la barra): la persona va directo a la cámara. Si la cierra o no da el
  /// permiso, queda en el paso 1 con "Escanear el QR" para reintentar.
  final bool escanearAlEntrar;

  /// Lo que se muestra si el QR leído no tiene el formato de Rebin.
  static const qrInvalido =
      '${EscanerQrScreen.qrInvalido}: este código no es de un punto de Rebin.';

  /// Lo que se guarda al abrir la cámara para volver aquí si Android cierra
  /// la app mientras tanto.
  static Map<String, Object?> pendientePara(String qr) => {
    'flujo': 'reciclar',
    'qr': qr,
  };

  static FlujoReciclajeScreen? desdePendiente(
    Map<String, Object?> pendiente,
    File foto, {
    required ReciclajeRepository reciclajes,
    required PuntosRepository puntos,
  }) {
    if (pendiente['flujo'] != 'reciclar') return null;
    final qr = pendiente['qr'];
    if (qr is! String || CodigoQrPunto.leer(qr) == null) return null;
    return FlujoReciclajeScreen(
      reciclajes: reciclajes,
      puntos: puntos,
      qrInicial: qr,
      fotoInicial: foto,
    );
  }

  @override
  State<FlujoReciclajeScreen> createState() => _FlujoReciclajeScreenState();
}

class _FlujoReciclajeScreenState extends State<FlujoReciclajeScreen> {
  late final CamaraService _camara =
      widget.camara ?? CamaraService(permisos: widget.permisos);
  late final VozService _voz = widget.voz ?? VozService.instancia;

  _Paso _paso = _Paso.qr;
  bool _camaraAbierta = false;

  // Paso 1
  PuntoQr? _punto;
  bool _buscandoPunto = false;
  String? _errorQr;

  /// El punto del QR leído; null si no recibe depósitos o falló la consulta.
  Future<PuntoQr?>? _puntoFuturo;

  /// Cierra la cámara del artículo desde aquí (si el punto no sirve).
  ValueNotifier<bool>? _cierreCamara;

  // Comprobación de cercanía apenas se lee el QR, como aviso sobre la
  // cámara del artículo.
  bool _midiendoCercania = false;
  final _avisoCamara = ValueNotifier<AvisoCamara?>(null);

  // Pasos 2 y 3: el artículo por confirmar y los ya enviados.
  final _enviados = <_Articulo>[];
  _Articulo? _actual;
  bool _confirmando = false;

  @override
  void initState() {
    super.initState();
    DescripcionesCategorias.instancia.cargar();
    final qr = widget.qrInicial;
    if (qr != null) {
      _usarQr(qr, fotoInicial: widget.fotoInicial);
    } else if (widget.escanearAlEntrar) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _escanearQr();
      });
    }
  }

  @override
  void dispose() {
    _avisoCamara.dispose();
    _voz.detener();
    _soltar(_actual?.foto);
    for (final a in _enviados) {
      _soltar(a.foto);
    }
    super.dispose();
  }

  void _soltar(File? foto) {
    if (foto == null) return;
    CamaraService.conservar.remove(foto.path);
    CamaraService.borrar(foto);
  }

  void _avisar(String mensaje) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(behavior: SnackBarBehavior.floating, content: Text(mensaje)),
    );
  }

  // ---------------------------------------------------------------- Paso 1

  Future<void> _escanearQr() async {
    if (_camaraAbierta) return;
    final leer = widget.leerQr;
    if (leer == null && !await _camara.asegurarPermiso(context)) return;
    if (!mounted) return;
    _camaraAbierta = true;
    final contenido =
        await (leer ??
            (c) => EscanerQrScreen.abrir(
              c,
              paso: _Paso.qr.index + 1,
              total: _Paso.values.length,
              explicacion: _explicaciones[_Paso.qr]!,
              voz: _voz,
            ))(context);
    _camaraAbierta = false;
    if (contenido == null || !mounted) return;
    // La flecha de la cámara: de vuelta a la pestaña donde estaba la persona.
    if (contenido == EscanerQrScreen.volver) {
      Navigator.of(context).pop();
      return;
    }
    await _usarQr(contenido);
  }

  Future<void> _usarQr(String contenido, {File? fotoInicial}) async {
    final qr = CodigoQrPunto.leer(contenido);
    if (qr == null) {
      setState(() => _errorQr = FlujoReciclajeScreen.qrInvalido);
      if (fotoInicial != null) _soltar(fotoInicial);
      return;
    }
    if (fotoInicial != null) CamaraService.conservar.add(fotoInicial.path);
    setState(() {
      _buscandoPunto = true;
      _errorQr = null;
    });
    final futuro = _buscarPunto(qr);
    _puntoFuturo = futuro;
    if (fotoInicial != null) {
      if (await futuro != null) {
        _nuevoArticulo(fotoInicial);
      } else {
        _soltar(fotoInicial);
      }
      return;
    }
    // Para no esperar a la base, la cámara del artículo se abre mientras se
    // busca el punto; si el punto no sirve, se cierra sola y queda el aviso.
    futuro.then((punto) {
      if (punto == null) _cierreCamara?.value = true;
    });
    _fotoArticulo();
  }

  /// Busca el punto del QR (`app_punto_qr`). Devuelve el punto si recibe
  /// depósitos; si no, null y el paso 1 muestra el motivo.
  Future<PuntoQr?> _buscarPunto(CodigoQrPunto qr) async {
    try {
      final punto = await widget.reciclajes.puntoPorQr(qr);
      if (!mounted) return null;
      setState(() {
        _buscandoPunto = false;
        _punto = punto;
        if (!punto.recibeDepositos) {
          _errorQr = punto.motivoNoRecibe;
          _paso = _Paso.qr;
        }
      });
      if (!punto.recibeDepositos) return null;
      _comprobarCercania();
      return punto;
    } on ReciclajeException catch (e) {
      if (mounted) {
        setState(() {
          _buscandoPunto = false;
          _errorQr = e.mensaje;
          _paso = _Paso.qr;
        });
      }
      return null;
    }
  }

  // ---------------------------------------------------------------- Paso 2

  /// La cámara del artículo (paso 2). Con la foto pasa directo a confirmar
  /// (paso 3).
  Future<void> _fotoArticulo() async {
    if (_camaraAbierta || !await _camara.asegurarPermiso(context)) return;
    if (!mounted) return;
    _camaraAbierta = true;
    final cierre = ValueNotifier(false);
    _cierreCamara = cierre;
    if (_actual == null) setState(() => _paso = _Paso.foto);
    FotoNoProcesadaException? fallo;
    File? foto;
    try {
      foto = await _camara.tomarFotoEnApp(
        context,
        titulo: _titulos[_Paso.foto]!,
        paso: _Paso.foto.index + 1,
        total: _Paso.values.length,
        explicacion: _explicaciones[_Paso.foto]!,
        voz: _voz,
        aviso: _avisoCamara,
        textoSalir: _enviados.isEmpty ? null : 'Ver resumen',
        cerrar: cierre,
      );
    } on FotoNoProcesadaException catch (e) {
      fallo = e;
    } catch (e) {
      debugPrint('FlujoReciclaje: cámara ($e)');
      _avisar('No pudimos abrir la cámara.');
    } finally {
      _camaraAbierta = false;
      _cierreCamara = null;
      cierre.dispose();
    }
    if (!mounted) return;
    // Se cerró porque el punto no recibe depósitos: queda el aviso del
    // paso 1.
    if (await _puntoFuturo == null) {
      _soltar(foto);
      return;
    }
    if (!mounted) return;
    if (fallo != null) {
      final decision = await FotoFallidaScreen.mostrar(context, fallo);
      if (!mounted) return;
      if (decision == DecisionFotoFallida.reintentar) return _fotoArticulo();
      Navigator.of(context).pop();
      return;
    }
    if (foto == null) {
      // Cerró la cámara sin foto nueva: si había un artículo por confirmar,
      // sigue con él; si no, sale de las fotos.
      if (_actual == null) _salirDeLasFotos();
      return;
    }
    CamaraService.conservar.add(foto.path);
    _nuevoArticulo(foto);
  }

  /// Sin artículos registrados vuelve a donde estaba la persona (como la
  /// flecha de la cámara del QR); con alguno, al paso 3 con lo registrado.
  void _salirDeLasFotos() {
    if (!mounted) return;
    if (_enviados.isEmpty) {
      Navigator.of(context).pop();
    } else {
      setState(() => _paso = _Paso.confirmar);
    }
  }

  /// La hora de la foto es la de ahora (la base acepta hasta 5 minutos sin
  /// dudar) y el GPS se lee mientras la persona revisa y confirma.
  void _nuevoArticulo(File foto) {
    _soltar(_actual?.foto);
    final articulo = _Articulo(foto, DateTime.now());
    setState(() {
      _actual = articulo;
      _paso = _Paso.confirmar;
    });
    _leerGps(articulo);
  }

  /// GPS de alta precisión: aquí sí se pide el permiso (lo pidió la persona
  /// con su acción). Null si no se pudo leer.
  Future<Position?> _ubicacion() async {
    final ubicar = widget.ubicar;
    if (ubicar != null) return ubicar();
    var estado = await widget.permisos.estado(PermisoApp.ubicacion);
    if (estado != EstadoPermiso.concedido) {
      estado = await widget.permisos.pedir(PermisoApp.ubicacion);
    }
    if (estado != EstadoPermiso.concedido) return null;
    return obtenerUbicacionPrecisa();
  }

  /// Apenas se lee el QR dice sobre la cámara si la persona está cerca del
  /// punto (a [PuntoQr.distanciaMaximaMetros] o menos). Es un aviso: cada
  /// artículo vuelve a medir y la base recalcula la distancia.
  Future<void> _comprobarCercania() async {
    final punto = _punto;
    if (punto == null || _midiendoCercania) return;
    _midiendoCercania = true;
    _avisoCamara.value = null;
    final gps = await _ubicacion();
    _midiendoCercania = false;
    if (!mounted) return;
    final distancia = gps == null
        ? null
        : punto.distanciaMetros(gps.latitude, gps.longitude);
    _avisoCamara.value = distancia == null
        ? null
        : distancia <= PuntoQr.distanciaMaximaMetros
        ? (texto: 'Estás cerca del punto · ${_metros(distancia)}', bien: true)
        : (texto: 'Estás lejos del punto · ${_metros(distancia)}', bien: false);
  }

  /// GPS de alta precisión, obligatorio para registrar el depósito.
  Future<Position?> _leerGps(_Articulo articulo) {
    setState(() {
      articulo.leyendoGps = true;
      articulo.sinGps = false;
    });
    final lectura = _ubicacion().then((gps) {
      if (mounted) {
        setState(() {
          articulo.gps = gps;
          articulo.leyendoGps = false;
        });
      }
      return gps;
    });
    articulo.lecturaGps = lectura;
    return lectura;
  }

  // ---------------------------------------------------------------- Paso 3

  /// Mientras no esté la IA, todo artículo va como plástico, elegido (no por
  /// el modelo): la base lo deja en revisión hasta que el panel lo apruebe.
  /// La foto queda guardada con esa categoría para entrenar el modelo.
  static final _categoriaPorDefecto = ResultadoClasificacion.elegida(
    EtiquetaModelo.deMaterial(TipoMaterial.plastico),
  );

  /// "Confirmar": envía el artículo a la base con su foto, la categoría, el
  /// GPS y la hora de la foto. Si el GPS aún no llega, lo espera.
  Future<void> _confirmar() async {
    final articulo = _actual;
    if (articulo == null || _confirmando) return;
    setState(() => _confirmando = true);
    final gps = articulo.gps ?? await articulo.lecturaGps;
    if (!mounted) return;
    if (gps == null) {
      setState(() {
        _confirmando = false;
        articulo.sinGps = true;
      });
      return;
    }
    articulo.gps = gps;
    articulo.resultado = _categoriaPorDefecto;
    setState(() {
      _confirmando = false;
      _actual = null;
      _enviados.insert(0, articulo);
    });
    _enviar(articulo);
  }

  void _enviar(_Articulo articulo) {
    final punto = _punto!;
    setState(() {
      articulo.error = null;
      articulo.registro = null;
      articulo.envio = widget.reciclajes.registrarDeposito(
        foto: articulo.foto,
        punto: punto,
        gps: articulo.gps!,
        horaCaptura: articulo.horaCaptura,
        resultado: articulo.resultado!,
      );
    });
    articulo.envio!
        .then((registro) {
          if (!mounted) return;
          setState(() => articulo.registro = registro);
          try {
            UsuarioScope.of(context).cargar();
          } catch (_) {
            // Sin UsuarioScope (tests aislados): nada que refrescar.
          }
        })
        .catchError((Object e) {
          if (!mounted) return;
          setState(
            () => articulo.error = e is ReciclajeException
                ? e.mensaje
                : 'No pudimos registrar este artículo.',
          );
        });
  }

  /// Descarta la foto sin confirmar y vuelve a la cámara.
  void _otraFoto() {
    _soltar(_actual?.foto);
    setState(() => _actual = null);
    _fotoArticulo();
  }

  // -------------------------------------------------------------- Vistas

  static const _titulos = {
    _Paso.qr: EscanerQrScreen.titulo,
    _Paso.foto: 'Foto del artículo',
    _Paso.confirmar: 'Confirmar',
  };

  /// Lo que dice el Play de cada paso: qué se espera que haga la persona.
  static const _explicaciones = {
    _Paso.qr: EscanerQrScreen.explicacionPorDefecto,
    _Paso.foto:
        'Frente al contenedor, toma una foto del artículo dentro del marco, '
        'justo antes de depositarlo. Una foto por artículo.',
    _Paso.confirmar:
        'Revisa el punto y la categoría del artículo, deposítalo y toca '
        'Confirmar para registrarlo. Por ahora la categoría es Plástico; '
        'cuando la inteligencia artificial esté instalada, la detectará sola.',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 20, 0),
              child: EncabezadoPaso(
                clave: 'reciclar-paso',
                titulo: _titulos[_paso]!,
                paso: _paso.index + 1,
                total: _Paso.values.length,
                explicacion: _explicaciones[_paso]!,
                voz: _voz,
                onVolver: () => Navigator.of(context).maybePop(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
              child: IndicadorPasos(
                paso: _paso.index,
                total: _Paso.values.length,
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: switch (_paso) {
                  _Paso.qr => _vistaQr(),
                  _Paso.foto => _vistaFoto(),
                  _Paso.confirmar => _vistaConfirmar(),
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _vistaQr() {
    final colores = context.colores;
    return [
      const _Explicacion(
        icono: Icons.qr_code_scanner,
        texto:
            'Ve al punto de reciclaje y escanea el código QR pegado en el '
            'contenedor. Después fotografiarás cada artículo antes de '
            'depositarlo.',
      ),
      const SizedBox(height: 24),
      if (_buscandoPunto)
        const _Estado(ocupado: true, texto: 'Buscando el punto…')
      else ...[
        if (_errorQr != null) ...[
          Container(
            key: const Key('reciclar-error-qr'),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colores.alerta.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline, color: colores.alerta),
                const SizedBox(width: 10),
                Expanded(child: Text(_errorQr!)),
              ],
            ),
          ),
          if (_punto != null && !_punto!.recibeDepositos) ...[
            const SizedBox(height: 8),
            Text(
              'Puedes reportarlo desde la ficha del punto en el mapa.',
              style: TextStyle(color: colores.textoSecundario, fontSize: 13),
            ),
          ],
          const SizedBox(height: 16),
        ],
        ElevatedButton.icon(
          key: const Key('reciclar-escanear-qr'),
          onPressed: _escanearQr,
          icon: const Icon(Icons.qr_code_scanner),
          label: Text(
            _errorQr == null ? 'Escanear QR del punto' : 'Escanear otro QR',
          ),
        ),
      ],
    ];
  }

  /// Detrás de la cámara del artículo (se ve un instante al abrirla o si
  /// falla).
  List<Widget> _vistaFoto() => [
    _Estado(
      ocupado: _camaraAbierta,
      texto: _camaraAbierta
          ? 'Abriendo la cámara…'
          : 'Fotografía un artículo para registrarlo.',
    ),
    if (!_camaraAbierta) ...[
      const SizedBox(height: 16),
      ElevatedButton.icon(
        key: const Key('reciclar-foto-articulo'),
        onPressed: _fotoArticulo,
        icon: const Icon(Icons.photo_camera_outlined),
        label: const Text('Abrir la cámara'),
      ),
    ],
  ];

  /// Paso 3: el punto, el artículo por confirmar (categoría y explicación,
  /// desactivadas hasta que esté la IA) y lo ya registrado.
  List<Widget> _vistaConfirmar() {
    final colores = context.colores;
    final actual = _actual;
    final registros = [
      for (final a in _enviados)
        if (a.registro != null) a.registro!,
    ];
    final puntos = registros.fold(0, (s, r) => s + r.puntos);
    final revision = registros.where((r) => r.enRevision).length;
    final enviando = _enviados.any((a) => a.enviando);
    return [
      _TarjetaPunto(punto: _punto!),
      const SizedBox(height: 16),
      if (actual != null) ...[
        _ArticuloPorConfirmar(
          articulo: actual,
          categoria: _categoriaPorDefecto,
        ),
        const SizedBox(height: 12),
        // Lo que hará la IA: desactivado por ahora.
        const _Desactivado(
          child: _Explicacion(
            icono: Icons.auto_awesome_outlined,
            texto:
                'La inteligencia artificial te dirá qué es el artículo y cómo '
                'reciclarlo. Disponible cuando esté instalada en el teléfono.',
          ),
        ),
        const SizedBox(height: 16),
        if (actual.sinGps) ...[
          const _Estado(
            ocupado: false,
            texto:
                'No pudimos leer tu ubicación. Activa el GPS: es necesario '
                'para validar el depósito.',
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () => _leerGps(actual),
            child: const Text('Reintentar ubicación'),
          ),
          const SizedBox(height: 12),
        ],
        ElevatedButton.icon(
          key: const Key('reciclar-confirmar'),
          onPressed: _confirmando || actual.sinGps ? null : _confirmar,
          icon: _confirmando
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.check),
          label: Text(
            _confirmando && actual.leyendoGps
                ? 'Leyendo tu ubicación…'
                : 'Confirmar',
          ),
        ),
        const SizedBox(height: 8),
        TextButton(
          key: const Key('reciclar-otra-foto'),
          onPressed: _confirmando ? null : _otraFoto,
          child: const Text('Tomar otra foto'),
        ),
      ],
      if (_enviados.isNotEmpty) ...[
        if (actual == null) ...[
          Row(
            children: [
              Icon(
                puntos > 0 ? Icons.check_circle : Icons.recycling,
                color: colores.primario,
                size: 36,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  puntos > 0
                      ? '¡Reciclaje registrado!'
                      : 'Gracias por reciclar',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            [
              '${_enviados.length} '
                  '${_enviados.length == 1 ? 'artículo' : 'artículos'} en '
                  '${_punto!.nombre}.',
              if (puntos > 0) 'Ganaste +$puntos Rebin Points.',
              if (revision > 0)
                '$revision en revisión: si se aprueban, recibirás sus Rebin '
                    'Points.',
            ].join(' '),
            key: const Key('reciclar-resumen'),
            style: TextStyle(color: colores.textoSecundario, fontSize: 15),
          ),
        ] else
          const SizedBox(height: 12),
        const SizedBox(height: 16),
        const Text(
          'Registrados en este punto',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
        const SizedBox(height: 8),
        for (final a in _enviados)
          _FilaArticulo(articulo: a, onReintentar: () => _enviar(a)),
        if (actual == null) ...[
          const SizedBox(height: 20),
          ElevatedButton.icon(
            key: const Key('reciclar-otro'),
            onPressed: _fotoArticulo,
            icon: const Icon(Icons.photo_camera_outlined),
            label: const Text('Reciclar otro artículo'),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            key: const Key('reciclar-terminar'),
            onPressed: enviando ? null : () => Navigator.of(context).pop(),
            child: Text(enviando ? 'Registrando…' : 'Terminar'),
          ),
        ],
      ],
    ];
  }

  /// "38 m" o "1,2 km".
  static String _metros(double metros) => metros < 1000
      ? '${metros.round()} m'
      : '${(metros / 1000).toStringAsFixed(1).replaceAll('.', ',')} km';
}

/// La foto por confirmar con su categoría (Plástico por defecto mientras no
/// esté la IA).
class _ArticuloPorConfirmar extends StatelessWidget {
  final _Articulo articulo;
  final ResultadoClasificacion categoria;

  const _ArticuloPorConfirmar({
    required this.articulo,
    required this.categoria,
  });

  @override
  Widget build(BuildContext context) {
    final colores = context.colores;
    final material = categoria.material!;
    return Container(
      key: const Key('reciclar-articulo'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colores.superficie,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colores.borde),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 96,
            child: FotoResiduo(archivo: articulo.foto, aspecto: 1),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Categoría',
                  style: TextStyle(
                    color: colores.textoSecundario,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(material.icono, color: material.color),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        material.etiqueta,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Por defecto, hasta que esté la IA.',
                  style: TextStyle(
                    color: colores.textoSecundario,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Una sección que todavía no funciona: atenuada, sin responder a toques y
/// con la etiqueta "Desactivado por ahora".
class _Desactivado extends StatelessWidget {
  final Widget child;

  const _Desactivado({required this.child});

  @override
  Widget build(BuildContext context) {
    final colores = context.colores;
    return Semantics(
      enabled: false,
      child: IgnorePointer(
        child: Opacity(
          opacity: 0.5,
          child: Column(
            key: const Key('reciclar-ia-desactivada'),
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              child,
              const SizedBox(height: 4),
              Text(
                'Desactivado por ahora',
                style: TextStyle(
                  color: colores.textoSecundario,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TarjetaPunto extends StatelessWidget {
  final PuntoQr punto;

  const _TarjetaPunto({required this.punto});

  @override
  Widget build(BuildContext context) {
    final colores = context.colores;
    return Container(
      key: const Key('reciclar-punto'),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colores.superficieAlta,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.place, color: colores.primario),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  punto.nombre,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          if (punto.direccion != null) ...[
            const SizedBox(height: 2),
            Text(
              punto.direccion!,
              style: TextStyle(color: colores.textoSecundario, fontSize: 13),
            ),
          ],
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final m in punto.materiales)
                Chip(
                  visualDensity: VisualDensity.compact,
                  avatar: Icon(m.icono, size: 16, color: m.color),
                  label: Text(m.etiqueta, style: const TextStyle(fontSize: 12)),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FilaArticulo extends StatelessWidget {
  final _Articulo articulo;
  final VoidCallback onReintentar;

  const _FilaArticulo({required this.articulo, required this.onReintentar});

  @override
  Widget build(BuildContext context) {
    final colores = context.colores;
    final registro = articulo.registro;
    final resultado = articulo.resultado!;
    final (IconData icono, Color color, String texto) = articulo.error != null
        ? (Icons.error_outline, colores.alerta, articulo.error!)
        : registro == null
        ? (Icons.schedule, colores.textoSecundario, 'Registrando…')
        : registro.aprobado
        ? (
            Icons.check_circle,
            colores.primario,
            '+${registro.puntos} Rebin Points',
          )
        : registro.rechazado
        ? (
            Icons.block,
            colores.alerta,
            'No se aprobó: ${RegistroDeposito.explicar(registro.motivo)}.',
          )
        : registro.enRevision
        ? (
            Icons.hourglass_top_rounded,
            colores.acento,
            'En revisión: ${RegistroDeposito.explicar(registro.motivo)}.',
          )
        : (
            Icons.info_outline,
            colores.textoSecundario,
            'Registrado sin Rebin Points: '
                '${RegistroDeposito.explicar(registro.motivo)}.',
          );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 56,
            child: FotoResiduo(archivo: articulo.foto, aspecto: 1),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  resultado.nombre,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(icono, size: 16, color: color),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        texto,
                        key: const Key('reciclar-estado-articulo'),
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
                if (articulo.error != null)
                  TextButton(
                    onPressed: onReintentar,
                    child: const Text('Reintentar envío'),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Explicacion extends StatelessWidget {
  final IconData icono;
  final String texto;

  const _Explicacion({required this.icono, required this.texto});

  @override
  Widget build(BuildContext context) {
    final colores = context.colores;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icono, color: colores.primario),
        const SizedBox(width: 12),
        Expanded(child: Text(texto)),
      ],
    );
  }
}

/// Línea de estado: spinner o aviso.
class _Estado extends StatelessWidget {
  final bool ocupado;
  final String texto;

  const _Estado({required this.ocupado, required this.texto});

  @override
  Widget build(BuildContext context) {
    final colores = context.colores;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colores.superficieAlta,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          if (ocupado)
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            )
          else
            Icon(Icons.info_outline, color: colores.acento),
          const SizedBox(width: 10),
          Expanded(child: Text(texto)),
        ],
      ),
    );
  }
}
