import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../models/punto_qr.dart';
import '../services/voz_service.dart';
import '../theme/app_theme.dart';
import '../widgets/encabezado_paso.dart';
import '../widgets/marco_escaneo.dart';
import '../widgets/ruta_rapida.dart';

/// Cámara para leer el código QR de un punto de reciclaje. Al detectar un QR
/// con el formato de Rebin ([CodigoQrPunto.leer]) cierra la pantalla y
/// devuelve el texto con `Navigator.pop<String>`. Un QR con otro formato no
/// la cierra: avisa "QR inválido" sobre la cámara y sigue leyendo.
///
/// Arriba lleva el encabezado del paso (título, "Paso X de N", Play con la
/// explicación). La flecha para volver, y el "atrás" del teléfono, devuelven
/// [volver]: quien la abrió sale también del flujo, de vuelta a la pestaña
/// donde estaba la persona.
///
/// Quien la abre debe haber pedido antes el permiso de cámara.
class EscanerQrScreen extends StatefulWidget {
  final int paso;
  final int total;
  final String explicacion;
  final VozService? voz;

  const EscanerQrScreen({
    super.key,
    this.paso = 1,
    this.total = 3,
    this.explicacion = explicacionPorDefecto,
    this.voz,
  });

  static const titulo = 'Escaneo de QR del punto';
  static const qrInvalido = 'QR inválido';
  static const explicacionPorDefecto =
      'Ve al punto de reciclaje y escanea el código QR pegado en el '
      'contenedor.';

  /// Lo que devuelve si la persona toca la flecha para volver: salir del
  /// flujo, no solo de la cámara.
  static const volver = '\u0000volver';

  /// Abre el escáner y espera el contenido del QR, o [volver].
  static Future<String?> abrir(
    BuildContext context, {
    int paso = 1,
    int total = 3,
    String explicacion = explicacionPorDefecto,
    VozService? voz,
  }) => Navigator.of(context).push<String>(
    rutaRapida(
      (_) => EscanerQrScreen(
        paso: paso,
        total: total,
        explicacion: explicacion,
        voz: voz,
      ),
    ),
  );

  @override
  State<EscanerQrScreen> createState() => _EscanerQrScreenState();
}

class _EscanerQrScreenState extends State<EscanerQrScreen> {
  static const double _ladoMarco = 260;

  // 720p basta para leer un QR a la distancia del contenedor: la cámara
  // abre antes y cada cuadro se analiza más rápido que a resolución máxima.
  final _controller = MobileScannerController(
    formats: const [BarcodeFormat.qrCode],
    detectionSpeed: DetectionSpeed.noDuplicates,
    cameraResolution: const Size(1280, 720),
  );

  late final VozService _voz = widget.voz ?? VozService.instancia;

  // La cámara puede reportar el mismo QR varias veces antes de cerrarse.
  bool _leido = false;

  // Se leyó un QR que no es de Rebin: el aviso queda hasta leer otro.
  bool _invalido = false;

  @override
  void dispose() {
    _voz.detener();
    _controller.dispose();
    super.dispose();
  }

  void _volver() {
    if (_leido) return;
    _leido = true;
    Navigator.of(context).pop(EscanerQrScreen.volver);
  }

  void _alDetectar(BarcodeCapture captura) {
    if (_leido) return;
    for (final codigo in captura.barcodes) {
      final valor = codigo.rawValue?.trim();
      if (valor == null || valor.isEmpty) continue;
      if (CodigoQrPunto.leer(valor) == null) {
        if (!_invalido) setState(() => _invalido = true);
        continue;
      }
      _leido = true;
      Navigator.of(context).pop(valor);
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colores = context.colores;
    // El "atrás" del teléfono hace lo mismo que la flecha.
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _volver();
      },
      child: _construir(colores),
    );
  }

  Widget _construir(ColoresApp colores) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: LayoutBuilder(
        builder: (context, restricciones) {
          final ventana = MarcoEscaneo.recuadro(
            restricciones.biggest,
            _ladoMarco,
          );
          return Stack(
            fit: StackFit.expand,
            children: [
              MobileScanner(
                controller: _controller,
                scanWindow: ventana,
                onDetect: _alDetectar,
                errorBuilder: (context, error) => _ErrorCamara(error: error),
              ),
              MarcoEscaneo(lado: _ladoMarco, color: colores.primario),
              Positioned(
                left: 24,
                right: 24,
                top: ventana.bottom + 28,
                child: _invalido
                    ? _AvisoInvalido(color: colores.alerta)
                    : const Text(
                        'Apunta al código QR del punto de reciclaje',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
              // Encabezado sobre una franja oscura para que se lea encima de
              // cualquier imagen de la cámara.
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
                        clave: 'escaner-qr',
                        titulo: EscanerQrScreen.titulo,
                        paso: widget.paso,
                        total: widget.total,
                        explicacion: widget.explicacion,
                        voz: _voz,
                        onVolver: _volver,
                        sobreCamara: true,
                        accion: ValueListenableBuilder(
                          valueListenable: _controller,
                          builder: (context, estado, _) {
                            if (estado.torchState == TorchState.unavailable) {
                              return const SizedBox.shrink();
                            }
                            return IconButton(
                              tooltip: 'Linterna',
                              icon: Icon(
                                estado.torchState == TorchState.on
                                    ? Icons.flash_on
                                    : Icons.flash_off,
                                color: Colors.white,
                              ),
                              onPressed: _controller.toggleTorch,
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// "QR inválido": el código leído no es el de un punto de Rebin.
class _AvisoInvalido extends StatelessWidget {
  final Color color;

  const _AvisoInvalido({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('escaner-qr-invalido'),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.qr_code_2, color: Colors.white),
              SizedBox(width: 8),
              Text(
                EscanerQrScreen.qrInvalido,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          SizedBox(height: 4),
          Text(
            'Este código no es de un punto de Rebin. Escanea el QR pegado en '
            'el contenedor.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _ErrorCamara extends StatelessWidget {
  final MobileScannerException error;

  const _ErrorCamara({required this.error});

  @override
  Widget build(BuildContext context) {
    final sinPermiso =
        error.errorCode == MobileScannerErrorCode.permissionDenied;
    return ColoredBox(
      color: Colors.black,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            sinPermiso
                ? 'Rebin no tiene permiso para usar la cámara. '
                      'Actívalo en Perfil › Ajustes.'
                : 'No pudimos abrir la cámara.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ),
    );
  }
}
