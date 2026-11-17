import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/material_type.dart';
import '../models/recolector_particular.dart';
import '../theme/app_spacing.dart';
import '../theme/app_theme.dart';
import '../utils/snackbars.dart';
import 'app_bottom_sheet.dart';
import 'pill.dart';

/// Ficha de un servicio de terceros: descripción, materiales, comunas,
/// horario, contacto (se puede copiar) y los puntos de reciclaje propios.
Future<void> mostrarServicioDetalle(
  BuildContext context,
  RecolectorParticular recolector,
) {
  return mostrarAppBottomSheet<void>(
    context: context,
    builder: (_) =>
        AppBottomSheet(child: ServicioDetalle(recolector: recolector)),
  );
}

class ServicioDetalle extends StatelessWidget {
  final RecolectorParticular recolector;

  const ServicioDetalle({super.key, required this.recolector});

  @override
  Widget build(BuildContext context) {
    final colores = context.colores;
    final secundario = TextStyle(color: colores.textoSecundario, fontSize: 13);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          recolector.nombre,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        const SizedBox(height: AppSpacing.xs),
        if (recolector.retiraADomicilio)
          Pill(
            icono: Icons.local_shipping_outlined,
            texto: 'Retira a domicilio',
            color: colores.primario,
            fontSize: 12,
          ),
        if (recolector.descripcion.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(recolector.descripcion, style: secundario),
        ],
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: [
            for (final material in recolector.materiales)
              Pill(
                icono: material.icono,
                texto: material.etiqueta,
                color: material.color,
                fontSize: 12,
              ),
          ],
        ),
        const _Titulo('Cobertura'),
        Row(
          children: [
            Icon(
              Icons.place_outlined,
              size: 16,
              color: colores.textoSecundario,
            ),
            const SizedBox(width: 6),
            Expanded(child: Text(recolector.comunasTexto, style: secundario)),
          ],
        ),
        if (recolector.horario.isNotEmpty) ...[
          const _Titulo('Horario de atención'),
          for (final tramo in recolector.horario.entries)
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Row(
                children: [
                  SizedBox(
                    width: 90,
                    child: Text(
                      tramo.key,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  Expanded(child: Text(tramo.value, style: secundario)),
                ],
              ),
            ),
        ],
        const _Titulo('Contacto'),
        Row(
          children: [
            Icon(Icons.call_outlined, size: 16, color: colores.textoSecundario),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                recolector.contacto,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            IconButton(
              tooltip: 'Copiar contacto',
              icon: const Icon(Icons.copy, size: 18),
              onPressed: () async {
                await Clipboard.setData(
                  ClipboardData(text: recolector.contacto),
                );
                if (context.mounted) {
                  mostrarSnackbar(context, 'Contacto copiado');
                }
              },
            ),
          ],
        ),
        if (recolector.puntos.isNotEmpty) ...[
          const _Titulo('Sus puntos de reciclaje'),
          for (final punto in recolector.puntos)
            ListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              leading: const Icon(Icons.recycling),
              title: Text(punto.nombre),
              subtitle: punto.direccion.isEmpty ? null : Text(punto.direccion),
            ),
        ],
      ],
    );
  }
}

class _Titulo extends StatelessWidget {
  final String texto;

  const _Titulo(this.texto);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.xs),
      child: Text(
        texto,
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
      ),
    );
  }
}
