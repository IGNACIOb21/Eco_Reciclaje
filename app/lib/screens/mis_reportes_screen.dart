import 'package:flutter/material.dart';

import '../models/mi_reporte.dart';
import '../models/tipo_reporte.dart';
import '../repositories/acciones_repository.dart';
import '../state/mis_reportes_controller.dart';
import '../theme/app_spacing.dart';
import '../theme/app_theme.dart';
import '../utils/fechas.dart';
import '../widgets/esqueleto.dart';

/// "Mis reportes": una tarjeta por cada tipo de reporte de la app, con
/// cuántos hizo la persona y cómo va el último. Tocar una tarjeta abre el
/// historial de ese tipo ([ReportesDeTipoScreen]); si no tiene reportes de
/// ese tipo, en vez de abrirlo una ventana al centro dice "Sin reportes en
/// (tipo)" con "Cerrar". La lógica está en [MisReportesController].
class MisReportesScreen extends StatefulWidget {
  final AccionesRepository repositorio;

  const MisReportesScreen({super.key, required this.repositorio});

  @override
  State<MisReportesScreen> createState() => _MisReportesScreenState();
}

class _MisReportesScreenState extends State<MisReportesScreen> {
  late final _controller = MisReportesController(widget.repositorio)..cargar();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _abrir(TipoReporte tipo) {
    final reportes = _controller.reportesDe(tipo);
    if (reportes.isEmpty) {
      _avisarSinReportes(tipo);
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ReportesDeTipoScreen(tipo: tipo, reportes: reportes),
      ),
    );
  }

  void _avisarSinReportes(TipoReporte tipo) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        key: const Key('mis-reportes-sin-reportes'),
        icon: Icon(tipo.icono, color: context.colores.primarioTexto),
        content: Text(
          MisReportesController.sinReportesEn(tipo),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colores = context.colores;
    return Scaffold(
      appBar: AppBar(title: const Text('Mis reportes')),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: _controller,
          builder: (context, _) {
            if (_controller.cargando) {
              return const EsqueletoLista();
            }
            if (_controller.error != null) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('No se pudieron cargar tus reportes.'),
                    TextButton(
                      onPressed: _controller.cargar,
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              );
            }
            return ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                for (final tipo in TipoReporte.values) ...[
                  _tarjetaTipo(tipo, colores),
                  const SizedBox(height: 8),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _tarjetaTipo(TipoReporte tipo, ColoresApp colores) {
    final tiene = _controller.reportesDe(tipo).isNotEmpty;
    return Card(
      key: Key('mis-reportes-${tipo.codigo}'),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        leading: Icon(
          tipo.icono,
          color: tiene ? colores.primario : colores.textoSecundario,
        ),
        title: Text(tipo.etiqueta),
        subtitle: Text(_controller.resumenDe(tipo)),
        trailing: tiene ? const Icon(Icons.chevron_right) : null,
        onTap: () => _abrir(tipo),
      ),
    );
  }
}

/// Historial de los reportes de un tipo: el punto, la fecha, cómo va y el
/// comentario de cada uno, del más nuevo al más viejo.
class ReportesDeTipoScreen extends StatelessWidget {
  final TipoReporte tipo;
  final List<MiReporte> reportes;

  const ReportesDeTipoScreen({
    super.key,
    required this.tipo,
    required this.reportes,
  });

  @override
  Widget build(BuildContext context) {
    final colores = context.colores;
    return Scaffold(
      appBar: AppBar(title: Text(tipo.etiqueta)),
      body: SafeArea(
        child: ListView.separated(
          padding: const EdgeInsets.all(AppSpacing.md),
          itemCount: reportes.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (_, i) {
            final r = reportes[i];
            final comentario = r.comentario?.trim() ?? '';
            return Card(
              child: ListTile(
                leading: Icon(tipo.icono, color: colores.primario),
                title: Text(r.punto),
                subtitle: Text(
                  [
                    '${r.avance} · ${haceTiempo(r.fecha)}',
                    if (comentario.isNotEmpty) '"$comentario"',
                  ].join('\n'),
                ),
                isThreeLine: comentario.isNotEmpty,
              ),
            );
          },
        ),
      ),
    );
  }
}
