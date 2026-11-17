import 'package:flutter/material.dart';

import '../models/punto_reciclaje.dart';
import '../models/tipo_reporte.dart';
import '../repositories/acciones_repository.dart';
import '../services/camara_service.dart';
import '../theme/app_spacing.dart';
import '../theme/app_theme.dart';
import 'realizar_reporte_screen.dart';

/// Paso 1 del reporte: elegir qué pasa en el punto entre las 11 categorías
/// del catálogo, agrupadas en las 3 fases (estado del contenedor, información
/// del punto y otros).
///
/// Al tocar una categoría aparece abajo la casilla "Realizar reporte", fija
/// sin importar el desplazamiento; tocar la misma la desmarca y la casilla se
/// va, tocar otra la deja asociada a la nueva. La casilla abre el paso 2
/// ([RealizarReporteScreen]: foto y comentario). Se cierra devolviendo el
/// [ResultadoAccion] cuando el reporte se envió.
class ReportarEstadoScreen extends StatefulWidget {
  final PuntoReciclaje punto;
  final AccionesRepository repositorio;

  // Solo para tests: una cámara que no abre nada.
  final CamaraService? camara;

  const ReportarEstadoScreen({
    super.key,
    required this.punto,
    required this.repositorio,
    this.camara,
  });

  @override
  State<ReportarEstadoScreen> createState() => _ReportarEstadoScreenState();
}

class _ReportarEstadoScreenState extends State<ReportarEstadoScreen> {
  TipoReporte? _tipo;

  void _tocar(TipoReporte tipo) =>
      setState(() => _tipo = _tipo == tipo ? null : tipo);

  Future<void> _realizar() async {
    final tipo = _tipo;
    if (tipo == null) return;
    final resultado = await Navigator.of(context).push<Object>(
      MaterialPageRoute(
        builder: (_) => RealizarReporteScreen(
          punto: widget.punto,
          tipo: tipo,
          repositorio: widget.repositorio,
          camara: widget.camara,
        ),
      ),
    );
    if (!mounted) return;
    if (resultado is ResultadoAccion) {
      Navigator.of(context).pop(resultado);
    } else if (resultado == RealizarReporteScreen.abandonado) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colores = context.colores;
    final tipo = _tipo;
    return Scaffold(
      appBar: AppBar(title: const Text('Reportar estado')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            Text(
              widget.punto.nombre,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(
              '¿Qué pasa en este punto?',
              style: TextStyle(color: colores.textoSecundario),
            ),
            for (final grupo in GrupoReporte.values) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                grupo.etiqueta,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              for (final t in TipoReporte.values.where((t) => t.grupo == grupo))
                _OpcionReporte(
                  tipo: t,
                  seleccionado: _tipo == t,
                  onTap: () => _tocar(t),
                ),
            ],
          ],
        ),
      ),
      // La casilla vive fuera de la lista: se ve a cualquier altura del
      // desplazamiento y no tapa la última opción.
      bottomNavigationBar: AnimatedSize(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        child: tipo == null
            ? const SizedBox(width: double.infinity)
            : _CasillaRealizar(tipo: tipo, onTap: _realizar),
      ),
    );
  }
}

class _CasillaRealizar extends StatelessWidget {
  final TipoReporte tipo;
  final VoidCallback onTap;

  const _CasillaRealizar({required this.tipo, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colores = context.colores;
    return Material(
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
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              key: const Key('reportar-realizar'),
              onPressed: onTap,
              icon: Icon(tipo.icono),
              label: Text(
                tipo.textoRealizar,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OpcionReporte extends StatelessWidget {
  final TipoReporte tipo;
  final bool seleccionado;
  final VoidCallback? onTap;

  const _OpcionReporte({
    required this.tipo,
    required this.seleccionado,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colores = context.colores;
    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: seleccionado ? colores.primario : colores.borde,
          width: seleccionado ? 2 : 1,
        ),
      ),
      child: ListTile(
        key: Key('reportar-${tipo.codigo}'),
        leading: Icon(tipo.icono, color: colores.primario),
        title: Text(tipo.etiqueta),
        subtitle: Text(tipo.descripcion),
        trailing: seleccionado
            ? Icon(Icons.check_circle, color: colores.primario)
            : null,
        onTap: onTap,
      ),
    );
  }
}
