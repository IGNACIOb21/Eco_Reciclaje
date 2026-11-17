import 'package:flutter/material.dart';

import '../models/etiqueta_modelo.dart';
import '../models/material_type.dart';
import '../services/clasificacion_service.dart';
import '../services/descripciones_categorias.dart';
import '../services/voz_service.dart';
import '../theme/app_theme.dart';

/// Resultado de clasificar un residuo: la respuesta ("¡Es reciclable!") va
/// primero y grande; el contenedor y la descripción quedan debajo. Audio:
///   * El altavoz del encabezado solo corta lo que esté sonando.
///   * La tarjeta del contenedor (o su Play, del color de la categoría) dice la
///     descripción, igual que "Escuchar de nuevo".
/// Cada Play corta el audio anterior antes de empezar.
class ResultadoClasificacionVista extends StatelessWidget {
  final ResultadoClasificacion resultado;
  final VozService voz;

  const ResultadoClasificacionVista({
    super.key,
    required this.resultado,
    required this.voz,
  });

  @override
  Widget build(BuildContext context) {
    final colores = context.colores;
    // Del tema, para que el "sí" y el "no" contrasten con cada fondo.
    final color = resultado.reciclable ? colores.primario : colores.alerta;
    final material = resultado.material;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(
              resultado.reciclable ? Icons.check_circle : Icons.cancel,
              color: color,
              size: 36,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                resultado.reciclable ? '¡Es reciclable!' : 'No es reciclable',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ),
            _BotonDetener(voz: voz),
          ],
        ),
        const SizedBox(height: 12),
        if (material != null)
          Material(
            color: material.color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(16),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              key: const Key('resultado-tarjeta'),
              onTap: () => voz.decir(resultado.frase),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 6, 14),
                child: Row(
                  children: [
                    Icon(material.icono, color: material.color, size: 32),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Va en el contenedor de',
                            style: TextStyle(color: colores.textoSecundario),
                          ),
                          Text(
                            resultado.nombre,
                            key: const Key('resultado-categoria'),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      key: const Key('resultado-play'),
                      tooltip: 'Escuchar la descripción',
                      iconSize: 36,
                      color: material.color,
                      icon: const Icon(Icons.play_circle_fill_rounded),
                      onPressed: () => voz.decir(resultado.frase),
                    ),
                  ],
                ),
              ),
            ),
          ),
        const SizedBox(height: 12),
        // Se redibuja si llega la descripción de la base después de la foto.
        ListenableBuilder(
          listenable: DescripcionesCategorias.instancia,
          builder: (context, _) => Text(
            resultado.descripcion,
            key: const Key('resultado-descripcion'),
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          key: const Key('resultado-repetir'),
          onPressed: () => voz.decir(resultado.frase),
          icon: const Icon(Icons.replay_rounded),
          label: const Text('Escuchar de nuevo'),
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerLeft,
          child: Chip(
            key: const Key('resultado-origen'),
            visualDensity: VisualDensity.compact,
            avatar: Icon(
              resultado.elegidoPorPersona
                  ? Icons.touch_app_outlined
                  : Icons.auto_awesome,
              size: 16,
            ),
            label: Text(
              resultado.elegidoPorPersona
                  ? 'Categoría elegida por ti: se revisa antes de dar Rebin Points'
                  : 'IA · ${(resultado.confianza * 100).round()} % de '
                        'confianza',
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ),
      ],
    );
  }
}

/// Altavoz del encabezado: solo corta el audio que esté sonando. Sin audio
/// queda inactivo.
class _BotonDetener extends StatelessWidget {
  final VozService voz;

  const _BotonDetener({required this.voz});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: voz,
      builder: (context, _) => IconButton(
        key: const Key('resultado-voz'),
        tooltip: voz.hablando ? 'Detener el audio' : null,
        icon: Icon(
          voz.hablando ? Icons.volume_up_rounded : Icons.volume_off_rounded,
        ),
        onPressed: voz.hablando ? voz.detener : null,
      ),
    );
  }
}

/// Las categorías que se reconocen por foto, para elegir a mano cuando no
/// hay modelo o no reconoció el objeto.
class SelectorCategoria extends StatelessWidget {
  final ValueChanged<EtiquetaModelo> onElegir;

  const SelectorCategoria({super.key, required this.onElegir});

  @override
  Widget build(BuildContext context) {
    final colores = context.colores;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final e in EtiquetaModelo.todas)
          ActionChip(
            key: Key('categoria-${e.etiqueta}'),
            avatar: Icon(
              e.material?.icono ?? Icons.delete_outline,
              size: 18,
              color: e.material?.color ?? colores.alerta,
            ),
            label: Text(e.nombre),
            onPressed: () => onElegir(e),
          ),
      ],
    );
  }
}
