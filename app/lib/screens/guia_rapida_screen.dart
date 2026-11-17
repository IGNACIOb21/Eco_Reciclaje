import 'package:flutter/material.dart';

import '../models/material_type.dart';
import '../services/descripciones_categorias.dart';
import '../services/voz_service.dart';
import '../theme/app_theme.dart';
import '../widgets/seccion_con_audio.dart';

/// Guía rápida (desde Inicio): qué es cada categoría, en qué se transforma y
/// qué no se recicla, cada texto con su Play. Los textos salen de
/// `categorias_residuo` vía [DescripcionesCategorias] (o de `TipoMaterial` sin
/// conexión).
class GuiaRapidaScreen extends StatefulWidget {
  final VozService? voz;

  const GuiaRapidaScreen({super.key, this.voz});

  @override
  State<GuiaRapidaScreen> createState() => _GuiaRapidaScreenState();
}

class _GuiaRapidaScreenState extends State<GuiaRapidaScreen> {
  late final VozService _voz = widget.voz ?? VozService.instancia;

  @override
  void initState() {
    super.initState();
    DescripcionesCategorias.instancia.cargar();
  }

  @override
  void dispose() {
    _voz.detener();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colores = context.colores;
    return Scaffold(
      appBar: AppBar(title: const Text('Guía rápida')),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: DescripcionesCategorias.instancia,
          builder: (context, _) => ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              Text(
                'Cómo separar bien: toca una categoría para ver qué abarca, en '
                'qué se transforma y qué no se recicla.',
                style: TextStyle(color: colores.textoSecundario),
              ),
              const SizedBox(height: 16),
              for (final material in TipoMaterial.values) ...[
                _CategoriaGuia(material: material, voz: _voz),
                const SizedBox(height: 10),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoriaGuia extends StatelessWidget {
  final TipoMaterial material;
  final VozService voz;

  const _CategoriaGuia({required this.material, required this.voz});

  @override
  Widget build(BuildContext context) {
    final colores = context.colores;
    final textos = DescripcionesCategorias.instancia;
    final clave = 'guia-${material.codigo}';
    return Material(
      color: material.color.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        // Sin las líneas que ExpansionTile dibuja al abrirse.
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          key: Key(clave),
          leading: Icon(material.icono, color: material.color, size: 30),
          title: Text(
            material.etiqueta,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
          iconColor: colores.texto,
          collapsedIconColor: colores.textoSecundario,
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          // Al cerrar una categoría se corta su audio.
          onExpansionChanged: (abierta) {
            if (!abierta) voz.detener();
          },
          children: [
            SeccionConAudio(
              clave: '$clave-descripcion',
              icono: Icons.info_outline_rounded,
              titulo: material.etiqueta,
              texto: textos.descripcion(material),
              voz: voz,
              color: material.color,
            ),
            const SizedBox(height: 10),
            SeccionConAudio(
              clave: '$clave-productos',
              icono: Icons.autorenew_rounded,
              titulo: '¿En qué se transforma?',
              texto: textos.productos(material),
              voz: voz,
              color: material.color,
            ),
            const SizedBox(height: 10),
            SeccionConAudio(
              clave: '$clave-partes',
              icono: Icons.do_not_disturb_on_outlined,
              titulo: 'Qué no se recicla',
              texto: textos.partesNoReciclables(material),
              voz: voz,
              color: material.color,
            ),
          ],
        ),
      ),
    );
  }
}
