import 'package:flutter/material.dart';

import '../services/voz_service.dart';
import '../theme/app_theme.dart';

/// Encabezado de un paso de "Reciclar en un punto" (y de la cámara del QR):
/// la flecha para volver al lado del título, "Paso X de N" debajo y, bajo
/// ellos, un Play que explica en voz alta qué se espera en ese paso.
///
/// [sobreCamara] lo pinta en blanco para ir encima de la imagen de la cámara.
/// Llaves: `<clave>-volver` y `<clave>-audio`.
class EncabezadoPaso extends StatelessWidget {
  final String clave;
  final String titulo;
  final int paso;
  final int total;
  final String explicacion;
  final VozService voz;
  final VoidCallback onVolver;
  final bool sobreCamara;

  /// Botón opcional a la derecha del título (ej. la linterna).
  final Widget? accion;

  const EncabezadoPaso({
    super.key,
    required this.clave,
    required this.titulo,
    required this.paso,
    required this.total,
    required this.explicacion,
    required this.voz,
    required this.onVolver,
    this.sobreCamara = false,
    this.accion,
  });

  @override
  Widget build(BuildContext context) {
    final colores = context.colores;
    final texto = sobreCamara ? Colors.white : colores.texto;
    final secundario = sobreCamara ? Colors.white70 : colores.textoSecundario;
    final destacado = sobreCamara ? Colors.white : colores.primarioTexto;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(
              key: Key('$clave-volver'),
              tooltip: 'Volver',
              icon: Icon(Icons.arrow_back, color: texto),
              onPressed: onVolver,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: Theme.of(context).textTheme.titleLarge
                        ?.copyWith(color: texto, fontSize: 20),
                  ),
                  Text(
                    'Paso $paso de $total',
                    style: TextStyle(color: secundario, fontSize: 13),
                  ),
                ],
              ),
            ),
            ?accion,
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(left: 52, top: 4),
          child: TextButton.icon(
            key: Key('$clave-audio'),
            style: TextButton.styleFrom(
              foregroundColor: destacado,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              minimumSize: const Size(0, 40),
            ),
            onPressed: () => voz.decir(explicacion),
            icon: const Icon(Icons.play_circle_outline),
            label: const Text('¿Qué hago aquí?'),
          ),
        ),
      ],
    );
  }
}
