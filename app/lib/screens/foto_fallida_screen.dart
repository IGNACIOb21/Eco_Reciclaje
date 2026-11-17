import 'package:flutter/material.dart';

import '../services/camara_service.dart';
import '../theme/app_spacing.dart';
import '../theme/app_theme.dart';

/// Qué eligió el usuario tras una foto que no se pudo procesar.
enum DecisionFotoFallida { reintentar, salir }

/// Se abre cuando la compresión de una foto falla ([FotoNoProcesadaException]),
/// en Reportes y en Reciclar. Explica el fallo y deja reintentar la foto o
/// salir del proceso. La original ya se borró en [CamaraService.tomarFoto];
/// las fotos anteriores del proceso se borran al cerrarlo.
class FotoFallidaScreen extends StatelessWidget {
  final FotoNoProcesadaException error;

  const FotoFallidaScreen({
    super.key,
    this.error = const FotoNoProcesadaException(),
  });

  /// Abre la pantalla y devuelve la decisión. Volver atrás cuenta como salir.
  static Future<DecisionFotoFallida> mostrar(
    BuildContext context,
    FotoNoProcesadaException error,
  ) async {
    final decision = await Navigator.of(context).push<DecisionFotoFallida>(
      MaterialPageRoute(builder: (_) => FotoFallidaScreen(error: error)),
    );
    return decision ?? DecisionFotoFallida.salir;
  }

  @override
  Widget build(BuildContext context) {
    final colores = context.colores;
    return Scaffold(
      appBar: AppBar(title: const Text('Foto no procesada')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            children: [
              const Spacer(),
              Icon(
                error.motivo == MotivoFotoFallida.sinEspacio
                    ? Icons.sd_card_alert_outlined
                    : Icons.broken_image_outlined,
                size: 72,
                color: colores.alerta,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                error.mensaje,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'La foto se borró del teléfono y no se envió nada.',
                textAlign: TextAlign.center,
                style: TextStyle(color: colores.textoSecundario),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  key: const Key('foto-fallida-reintentar'),
                  onPressed: () =>
                      Navigator.of(context).pop(DecisionFotoFallida.reintentar),
                  icon: const Icon(Icons.photo_camera_outlined),
                  label: const Text('Reintentar'),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  key: const Key('foto-fallida-salir'),
                  onPressed: () =>
                      Navigator.of(context).pop(DecisionFotoFallida.salir),
                  child: const Text('Salir'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
