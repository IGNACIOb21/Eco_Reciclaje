import 'package:flutter/material.dart';

import '../services/voz_service.dart';
import '../theme/app_theme.dart';

/// Un bloque de texto con su propio Play: dice el título y el texto, cortando
/// el audio anterior. Llaves: [clave] para el bloque y `<clave>-audio` para el
/// Play.
class SeccionConAudio extends StatelessWidget {
  final String clave;
  final IconData icono;
  final String titulo;
  final String texto;
  final VozService voz;
  final Color? color;

  const SeccionConAudio({
    super.key,
    required this.clave,
    required this.icono,
    required this.titulo,
    required this.texto,
    required this.voz,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colores = context.colores;
    final color = this.color ?? colores.primario;
    return Container(
      key: Key(clave),
      padding: const EdgeInsets.fromLTRB(14, 6, 6, 14),
      decoration: BoxDecoration(
        color: colores.superficieAlta,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icono, color: color, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  titulo,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
              IconButton(
                key: Key('$clave-audio'),
                tooltip: 'Escuchar',
                color: color,
                icon: const Icon(Icons.play_arrow_rounded),
                onPressed: () {
                  final pausa = titulo.endsWith('?') ? ' ' : '. ';
                  voz.decir('$titulo$pausa$texto');
                },
              ),
            ],
          ),
          Padding(padding: const EdgeInsets.only(right: 8), child: Text(texto)),
        ],
      ),
    );
  }
}
