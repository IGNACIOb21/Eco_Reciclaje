import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../services/voz_service.dart';
import '../theme/app_theme.dart';
import '../widgets/encabezado_paso.dart';
import '../widgets/marco_escaneo.dart';

/// Aviso que se muestra sobre la cámara (ej. si la persona está cerca del
/// punto). [bien] lo pinta verde; si no, del color de alerta.
typedef AvisoCamara = ({String texto, bool bien});

/// Cámara dentro de la app para la foto de un artículo, con el mismo formato
/// que la del QR ([EscanerQrScreen]): encabezado del paso arriba (flecha,
/// título, "Paso X de N" y Play), marco al centro (la IA mira el centro de la
/// foto) y el disparador abajo.
///
/// Devuelve la captura original sin procesar, o null si la persona vuelve
/// con la flecha o el "atrás" del teléfono. Quien la abre la procesa
/// ([CamaraService.tomarFotoEnApp]) y debe haber pedido antes el permiso.
class CamaraFotoScreen extends StatefulWidget {
  final String titulo;
  final int paso;
  final int total;
  final String explicacion;
  final VozService? voz;
  final ValueListenable<AvisoCamara?>? aviso;

  /// Si no es null, un botón sobre el disparador con este texto (ej. "Ver
  /// resumen") que cierra la cámara igual que la flecha.
  final String? textoSalir;

  /// Al pasar a true la cámara se cierra sola, sin foto.
  final ValueListenable<bool>? cerrar;

  const CamaraFotoScreen({
    super.key,
    required this.titulo,
    required this.paso,
    required this.total,
    required this.explicacion,
    this.voz,
    this.aviso,
    this.textoSalir,
    this.cerrar,
  });

  static Future<List<CameraDescription>>? _camaras;

  /// La lista de cámaras del teléfono, leída una sola vez: así abrir la
  /// cámara no espera esa consulta. Llamar antes de abrirla la deja lista.
  static Future<List<CameraDescription>> camaras() {
    final pendiente = _camaras ??= availableCameras();
    pendiente.catchError((Object _) {
      _camaras = null;
      return <CameraDescription>[];
    });
    return pendiente;
  }

  @override
  State<CamaraFotoScreen> createState() => _CamaraFotoScreenState();
}

class _CamaraFotoScreenState extends State<CamaraFotoScreen>
    with WidgetsBindingObserver {
  static const double _ladoMarco = 280;

  late final VozService _voz = widget.voz ?? VozService.instancia;

  CameraController? _controller;
  Object? _error;
  bool _tomando = false;
  bool _linterna = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.cerrar?.addListener(_alPedirCierre);
    _iniciar();
  }

  void _alPedirCierre() {
    if (widget.cerrar?.value == true && mounted) Navigator.of(context).pop();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.cerrar?.removeListener(_alPedirCierre);
    _voz.detener();
    _controller?.dispose();
    super.dispose();
  }

  // La cámara se suelta en segundo plano (otra app puede necesitarla) y se
  // vuelve a abrir al regresar.
  @override
  void didChangeAppLifecycleState(AppLifecycleState estado) {
    final controller = _controller;
    if (estado == AppLifecycleState.inactive) {
      _controller = null;
      controller?.dispose();
      if (mounted) setState(() => _linterna = false);
    } else if (estado == AppLifecycleState.resumed && controller == null) {
      _iniciar();
    }
  }

  Future<void> _iniciar() async {
    try {
      final camaras = await CamaraFotoScreen.camaras();
      if (camaras.isEmpty) throw CameraException('sinCamara', null);
      final trasera = camaras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => camaras.first,
      );
      final controller = CameraController(
        trasera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      await controller.initialize();
      // El flash apagado no hace falta esperarlo para mostrar la imagen.
      controller.setFlashMode(FlashMode.off).ignore();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _controller = controller;
        _error = null;
      });
    } catch (e) {
      debugPrint('CamaraFoto: no se pudo abrir ($e)');
      if (mounted) setState(() => _error = e);
    }
  }

  Future<void> _disparar() async {
    final controller = _controller;
    if (controller == null || _tomando || controller.value.isTakingPicture) {
      return;
    }
    setState(() => _tomando = true);
    try {
      final foto = await controller.takePicture();
      if (mounted) Navigator.of(context).pop(File(foto.path));
    } catch (e) {
      debugPrint('CamaraFoto: no se pudo tomar la foto ($e)');
      if (!mounted) return;
      setState(() => _tomando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('No pudimos tomar la foto. Inténtalo de nuevo.'),
        ),
      );
    }
  }

  Future<void> _alternarLinterna() async {
    final controller = _controller;
    if (controller == null) return;
    final encender = !_linterna;
    try {
      await controller.setFlashMode(encender ? FlashMode.torch : FlashMode.off);
      if (mounted) setState(() => _linterna = encender);
    } catch (_) {
      // Sin linterna en este teléfono: no pasa nada.
    }
  }

  void _volver() {
    if (_tomando) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final colores = context.colores;
    final controller = _controller;
    final lista = controller != null && controller.value.isInitialized;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (lista)
            _VistaPrevia(controller: controller)
          else if (_error != null)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'No pudimos abrir la cámara.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white),
                ),
              ),
            )
          else
            const Center(child: CircularProgressIndicator()),
          MarcoEscaneo(lado: _ladoMarco, color: colores.primario),
          LayoutBuilder(
            builder: (context, restricciones) {
              final ventana = MarcoEscaneo.recuadro(
                restricciones.biggest,
                _ladoMarco,
              );
              return Stack(
                children: [
                  Positioned(
                    left: 24,
                    right: 24,
                    top: ventana.bottom + 20,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Encuadra el artículo dentro del marco',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (widget.aviso != null)
                          ValueListenableBuilder(
                            valueListenable: widget.aviso!,
                            builder: (context, aviso, _) => aviso == null
                                ? const SizedBox.shrink()
                                : Padding(
                                    padding: const EdgeInsets.only(top: 10),
                                    child: _Pastilla(
                                      aviso: aviso,
                                      color: aviso.bien
                                          ? colores.primario
                                          : colores.alerta,
                                    ),
                                  ),
                          ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
          // Encabezado sobre una franja oscura, igual que en la cámara del QR.
          Align(
            alignment: Alignment.topCenter,
            child: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xCC000000), Color(0x00000000)],
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(4, 4, 8, 16),
                  child: EncabezadoPaso(
                    clave: 'camara-foto',
                    titulo: widget.titulo,
                    paso: widget.paso,
                    total: widget.total,
                    explicacion: widget.explicacion,
                    voz: _voz,
                    onVolver: _volver,
                    sobreCamara: true,
                    accion: lista
                        ? IconButton(
                            tooltip: 'Linterna',
                            icon: Icon(
                              _linterna ? Icons.flash_on : Icons.flash_off,
                              color: Colors.white,
                            ),
                            onPressed: _alternarLinterna,
                          )
                        : null,
                  ),
                ),
              ),
            ),
          ),
          if (widget.textoSalir != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 132,
              child: Center(
                child: TextButton.icon(
                  key: const Key('camara-foto-salir'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.black54,
                  ),
                  onPressed: _volver,
                  icon: const Icon(Icons.checklist),
                  label: Text(widget.textoSalir!),
                ),
              ),
            ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 36),
              child: _Disparador(
                ocupado: _tomando,
                onTap: lista ? _disparar : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// La imagen de la cámara llenando la pantalla sin deformarse.
class _VistaPrevia extends StatelessWidget {
  final CameraController controller;

  const _VistaPrevia({required this.controller});

  @override
  Widget build(BuildContext context) {
    // previewSize viene apaisado; en vertical se invierte.
    final tamano = controller.value.previewSize;
    if (tamano == null) return CameraPreview(controller);
    return ClipRect(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: tamano.height,
          height: tamano.width,
          child: CameraPreview(controller),
        ),
      ),
    );
  }
}

class _Disparador extends StatelessWidget {
  final bool ocupado;
  final VoidCallback? onTap;

  const _Disparador({required this.ocupado, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Tomar foto',
      child: GestureDetector(
        key: const Key('camara-foto-disparar'),
        onTap: ocupado ? null : onTap,
        child: Container(
          width: 78,
          height: 78,
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 4),
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: onTap == null ? Colors.white38 : Colors.white,
            ),
            child: ocupado
                ? const Padding(
                    padding: EdgeInsets.all(18),
                    child: CircularProgressIndicator(strokeWidth: 3),
                  )
                : null,
          ),
        ),
      ),
    );
  }
}

class _Pastilla extends StatelessWidget {
  final AvisoCamara aviso;
  final Color color;

  const _Pastilla({required this.aviso, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('camara-foto-aviso'),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            aviso.bien ? Icons.where_to_vote : Icons.wrong_location_outlined,
            color: Colors.white,
            size: 18,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              aviso.texto,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
