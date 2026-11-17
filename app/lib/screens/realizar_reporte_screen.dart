import 'dart:io';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../models/punto_reciclaje.dart';
import '../models/tipo_reporte.dart';
import '../repositories/acciones_repository.dart';
import '../services/camara_service.dart';
import '../services/ubicacion_service.dart';
import '../theme/app_spacing.dart';
import '../theme/app_theme.dart';
import '../utils/geo.dart';
import '../widgets/mensaje_error.dart';
import 'foto_fallida_screen.dart';

/// Paso 2 del reporte: foto del punto (obligatoria) y comentario (opcional;
/// obligatorio en "Otro" y, con 20 caracteres o más, en los motivos de
/// "Información del punto"). En "Ubicación incorrecta" se puede marcar
/// "Usar mi ubicación actual" para proponer la ubicación real del punto (a
/// 500 m o menos del pin). "Enviar reporte" queda apagado, en un tono
/// atenuado, hasta que hay foto; al tomarla pasa al color pleno.
///
/// La foto se sube al bucket `reportes` (ver AccionesRepositorySupabase) y
/// la copia del teléfono se borra al salir. Si la foto no se puede procesar se
/// abre [FotoFallidaScreen]: "Reintentar" vuelve a abrir la cámara y "Salir"
/// cierra todo el reporte devolviendo [abandonado].
class RealizarReporteScreen extends StatefulWidget {
  /// Lo que devuelve la pantalla cuando el usuario sale del reporte tras una
  /// foto fallida: [ReportarEstadoScreen] también se cierra.
  static const abandonado = #reporteAbandonado;

  final PuntoReciclaje punto;
  final TipoReporte tipo;
  final AccionesRepository repositorio;

  /// Foto ya tomada (la que se recupera si Android cerró la app con la
  /// cámara abierta, ver [desdePendiente]).
  final File? fotoInicial;

  // Solo para tests: una cámara que no abre nada.
  final CamaraService? camara;

  // Solo para tests: la posición GPS (por defecto, obtenerUbicacionPrecisa).
  final Future<Position?> Function()? ubicar;

  /// Distancia máxima entre la ubicación propuesta y el pin actual; más
  /// lejos se usa "Sugerir un punto". La base exige lo mismo.
  static const distanciaMaximaMetros = 500;

  static const avisoUbicacion =
      'Debes ubicarte cerca del punto de reciclaje para que se tome la alerta '
      'y rectificar, si es necesario, la ubicación del punto.';

  const RealizarReporteScreen({
    super.key,
    required this.punto,
    required this.tipo,
    required this.repositorio,
    this.fotoInicial,
    this.camara,
    this.ubicar,
  });

  /// Lo que se guarda al abrir la cámara para volver a esta pantalla si
  /// Android cierra la app mientras tanto ([CamaraService.tomarFoto]).
  static Map<String, Object?> pendientePara(
    PuntoReciclaje punto,
    TipoReporte tipo,
  ) => {
    'flujo': 'reporte',
    'tipo': tipo.codigo,
    'punto': {
      'id': punto.id,
      'nombre': punto.nombre,
      'comuna': punto.comuna,
      'direccion': punto.direccion,
      'lat': punto.lat,
      'lng': punto.lng,
      'fuente': punto.fuente.name,
    },
  };

  /// La pantalla armada desde [pendiente] con la foto recuperada, o null si
  /// lo guardado no es de un reporte o no se entiende.
  static RealizarReporteScreen? desdePendiente(
    Map<String, Object?> pendiente,
    File foto,
    AccionesRepository repositorio,
  ) {
    try {
      if (pendiente['flujo'] != 'reporte') return null;
      final tipo = TipoReporte.desdeCodigo(pendiente['tipo'] as String);
      if (tipo == null) return null;
      final punto = PuntoReciclaje.fromSupabaseRow({
        ...(pendiente['punto'] as Map).cast<String, dynamic>(),
        'estado_actual': 'disponible',
        'materiales': const <String>[],
        'calificacion_promedio': 0,
        'num_calificaciones': 0,
      });
      return RealizarReporteScreen(
        punto: punto,
        tipo: tipo,
        repositorio: repositorio,
        fotoInicial: foto,
      );
    } catch (e) {
      debugPrint('RealizarReporte: pendiente no válido ($e)');
      return null;
    }
  }

  @override
  State<RealizarReporteScreen> createState() => _RealizarReporteScreenState();
}

class _RealizarReporteScreenState extends State<RealizarReporteScreen> {
  final _comentario = TextEditingController();
  late final CamaraService _camara = widget.camara ?? CamaraService();
  late File? _foto = widget.fotoInicial;
  bool _camaraAbierta = false;
  bool _procesando = false;
  bool _enviando = false;
  String? _error;

  // "Usar mi ubicación actual" (solo en Ubicación incorrecta).
  bool _usarUbicacion = false;
  bool _ubicando = false;
  Position? _ubicacion;
  String? _errorUbicacion;

  @override
  void dispose() {
    _comentario.dispose();
    CamaraService.borrar(_foto);
    super.dispose();
  }

  Future<void> _tomarFoto() async {
    if (_camaraAbierta || !await _camara.asegurarPermiso(context)) return;
    _camaraAbierta = true;
    setState(() => _procesando = true);
    FotoNoProcesadaException? fallo;
    try {
      final nueva = await _camara.tomarFoto(
        pendiente: RealizarReporteScreen.pendientePara(
          widget.punto,
          widget.tipo,
        ),
      );
      if (nueva == null || !mounted) return;
      final anterior = _foto;
      setState(() {
        _foto = nueva;
        _error = null;
      });
      if (anterior != null && anterior.path != nueva.path) {
        CamaraService.borrar(anterior);
      }
    } on FotoNoProcesadaException catch (e) {
      fallo = e;
    } catch (e) {
      debugPrint('RealizarReporte: cámara ($e)');
      if (mounted) setState(() => _error = 'No pudimos abrir la cámara.');
    } finally {
      _camaraAbierta = false;
      if (mounted) setState(() => _procesando = false);
    }
    if (fallo != null && mounted) await _fotoFallida(fallo);
  }

  /// La compresión falló: se muestra el fallo y se reintenta o se sale del
  /// reporte (al cerrarse, dispose borra la foto anterior si la había).
  Future<void> _fotoFallida(FotoNoProcesadaException error) async {
    final decision = await FotoFallidaScreen.mostrar(context, error);
    if (!mounted) return;
    if (decision == DecisionFotoFallida.reintentar) {
      await _tomarFoto();
    } else {
      Navigator.of(context).pop(RealizarReporteScreen.abandonado);
    }
  }

  /// Marca o desmarca "Usar mi ubicación actual". Al marcarla lee el GPS:
  /// sin posición, o a más de [RealizarReporteScreen.distanciaMaximaMetros]
  /// del pin, se desmarca y dice por qué.
  Future<void> _cambiarUbicacion(bool usar) async {
    setState(() {
      _usarUbicacion = usar;
      _ubicacion = null;
      _errorUbicacion = null;
      _ubicando = usar;
    });
    if (!usar) return;
    final posicion = await (widget.ubicar ?? obtenerUbicacionPrecisa)();
    if (!mounted || !_usarUbicacion) return;
    setState(() {
      _ubicando = false;
      if (posicion == null) {
        _usarUbicacion = false;
        _errorUbicacion =
            'No pudimos obtener tu ubicación. Revisa que el GPS esté '
            'encendido y el permiso de ubicación activo (Perfil › Ajustes).';
        return;
      }
      final metros = _metrosAlPin(posicion);
      if (metros > RealizarReporteScreen.distanciaMaximaMetros) {
        _usarUbicacion = false;
        _errorUbicacion =
            'Estás a ${metros.round()} m del punto. Acércate a menos de '
            '${RealizarReporteScreen.distanciaMaximaMetros} m para enviar tu '
            'ubicación.';
        return;
      }
      _ubicacion = posicion;
    });
  }

  double _metrosAlPin(Position p) =>
      distanciaKm(widget.punto.lat, widget.punto.lng, p.latitude, p.longitude) *
      1000;

  Future<void> _enviar() async {
    final minimo = widget.tipo.minimoComentario;
    if (_comentario.text.trim().length < minimo) {
      setState(
        () => _error = minimo >= 20
            ? 'Escribe al menos $minimo caracteres para describir el problema.'
            : 'Cuéntanos qué pasa en el comentario.',
      );
      return;
    }
    setState(() {
      _enviando = true;
      _error = null;
    });
    try {
      final resultado = await widget.repositorio.reportarEstado(
        idPunto: widget.punto.id,
        tipo: widget.tipo,
        comentario: _comentario.text,
        foto: _foto,
        ubicacion: _usarUbicacion ? _ubicacion : null,
      );
      if (mounted) Navigator.of(context).pop(resultado);
    } on AccionException catch (e) {
      if (mounted) setState(() => _error = e.mensaje);
    } catch (_) {
      if (mounted) {
        setState(
          () =>
              _error = const AccionException(MotivoErrorAccion.desconocido)
                  .mensaje,
        );
      }
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colores = context.colores;
    final listo = _foto != null && !_enviando && !_procesando && !_ubicando;
    return Scaffold(
      appBar: AppBar(title: Text(widget.tipo.tituloReporte)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            Text(
              widget.punto.nombre,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(widget.tipo.icono, color: colores.primario, size: 20),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    widget.tipo.etiqueta,
                    style: TextStyle(color: colores.textoSecundario),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            const Text(
              '1. Toma una foto del punto',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            _CasillaFoto(
              foto: _foto,
              procesando: _procesando,
              onTap: _enviando || _procesando ? null : _tomarFoto,
            ),
            const SizedBox(height: AppSpacing.md),
            const Text(
              '2. Deja un comentario',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            TextField(
              key: const Key('reportar-comentario'),
              controller: _comentario,
              enabled: !_enviando,
              maxLength: 500,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: widget.tipo.requiereComentario
                    ? 'Comentario (obligatorio)'
                    : 'Comentario (opcional)',
                hintText: widget.tipo.ayudaComentario,
                helperText: widget.tipo.minimoComentario >= 20
                    ? 'Mínimo ${widget.tipo.minimoComentario} caracteres'
                    : null,
              ),
            ),
            if (widget.tipo.permiteUbicacion) ...[
              const SizedBox(height: AppSpacing.md),
              const Text(
                '3. Ubicación real del punto (opcional)',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              _UbicacionPropuesta(
                usar: _usarUbicacion,
                ubicando: _ubicando,
                metrosAlPin: _ubicacion == null
                    ? null
                    : _metrosAlPin(_ubicacion!),
                precision: _ubicacion?.accuracy,
                error: _errorUbicacion,
                onCambiar: _enviando ? null : _cambiarUbicacion,
              ),
            ],
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Si hay un riesgo para las personas (por ejemplo, un contenedor en llamas), llama a los servicios de emergencia: Rebin no los reemplaza.',
              style: TextStyle(color: colores.textoSecundario, fontSize: 12),
            ),
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.sm),
              MensajeError(texto: _error!),
            ],
          ],
        ),
      ),
      bottomNavigationBar: Material(
        color: colores.superficie,
        elevation: 8,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              AppSpacing.sm,
            ),
            child: ElevatedButton(
              key: const Key('reportar-enviar'),
              onPressed: listo ? _enviar : null,
              // Sin foto el botón queda en un tono atenuado del primario; con
              // foto toma el color pleno, más claro, para indicar que ya se
              // puede enviar.
              style: ElevatedButton.styleFrom(
                disabledBackgroundColor: colores.primario.withValues(
                  alpha: 0.25,
                ),
                disabledForegroundColor: colores.texto.withValues(alpha: 0.5),
              ),
              child: _enviando
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      _foto == null
                          ? 'Toma la foto para enviar'
                          : 'Enviar reporte',
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

/// "Usar mi ubicación actual" y, marcada, el aviso de que hay que estar
/// cerca del punto y el estado del GPS.
class _UbicacionPropuesta extends StatelessWidget {
  final bool usar;
  final bool ubicando;
  final double? metrosAlPin;
  final double? precision;
  final String? error;
  final ValueChanged<bool>? onCambiar;

  const _UbicacionPropuesta({
    required this.usar,
    required this.ubicando,
    required this.metrosAlPin,
    required this.precision,
    required this.error,
    required this.onCambiar,
  });

  @override
  Widget build(BuildContext context) {
    final colores = context.colores;
    final metros = metrosAlPin;
    final cambiar = onCambiar;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CheckboxListTile(
          key: const Key('reportar-ubicacion'),
          value: usar,
          onChanged: cambiar == null ? null : (v) => cambiar(v ?? false),
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          secondary: Icon(Icons.my_location, color: colores.primario),
          title: const Text('Usar mi ubicación actual'),
        ),
        if (usar)
          Container(
            key: const Key('reportar-ubicacion-aviso'),
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: colores.superficieAlta,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colores.primario),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, color: colores.primario, size: 20),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(RealizarReporteScreen.avisoUbicacion),
                    ),
                  ],
                ),
                if (ubicando || metros != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    ubicando
                        ? 'Obteniendo tu ubicación…'
                        : 'Ubicación lista: a ${metros!.round()} m del pin, '
                              'precisión de ${precision?.round() ?? '?'} m.',
                    style: TextStyle(
                      color: colores.textoSecundario,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
        if (error != null) MensajeError(texto: error!),
      ],
    );
  }
}

class _CasillaFoto extends StatelessWidget {
  final File? foto;
  final bool procesando;
  final VoidCallback? onTap;

  const _CasillaFoto({
    required this.foto,
    required this.procesando,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colores = context.colores;
    final archivo = foto;
    return Material(
      color: colores.superficieAlta,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: archivo == null ? colores.borde : colores.primario,
          width: archivo == null ? 1 : 2,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: const Key('reportar-foto'),
        onTap: onTap,
        child: SizedBox(
          height: 180,
          width: double.infinity,
          child: procesando
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 12),
                    Text(
                      'Preparando la foto…',
                      style: TextStyle(color: colores.textoSecundario),
                    ),
                  ],
                )
              : archivo == null
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.photo_camera_outlined,
                      size: 40,
                      color: colores.primario,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Tomar foto',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Obligatoria',
                      style: TextStyle(
                        color: colores.textoSecundario,
                        fontSize: 12,
                      ),
                    ),
                  ],
                )
              : Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.file(
                      archivo,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) =>
                          ColoredBox(color: colores.superficieAlta),
                    ),
                    Positioned(
                      right: 8,
                      bottom: 8,
                      child: Chip(
                        avatar: const Icon(Icons.refresh, size: 18),
                        label: const Text('Volver a tomar'),
                        backgroundColor: colores.superficie,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
