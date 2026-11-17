import 'package:flutter/material.dart';

import '../models/postulacion_servicio.dart';
import '../repositories/recolectores_repository.dart';
import '../theme/app_spacing.dart';
import '../theme/app_theme.dart';
import '../widgets/pill.dart';
import '../widgets/esqueleto.dart';

/// Postulaciones de servicios que envió esta cuenta, con su estado y, si se
/// rechazaron, el motivo que dejó quien las revisó.
class MisPostulacionesScreen extends StatefulWidget {
  final RecolectoresRepository repositorio;

  const MisPostulacionesScreen({super.key, required this.repositorio});

  @override
  State<MisPostulacionesScreen> createState() => _MisPostulacionesScreenState();
}

class _MisPostulacionesScreenState extends State<MisPostulacionesScreen> {
  late Future<List<MiPostulacion>> _postulaciones = widget.repositorio
      .misPostulaciones();

  Future<void> _recargar() async {
    final future = widget.repositorio.misPostulaciones();
    setState(() => _postulaciones = future);
    try {
      await future;
    } catch (_) {
      // El error se muestra vía FutureBuilder al reconstruir.
    }
  }

  @override
  Widget build(BuildContext context) {
    final colores = context.colores;
    return Scaffold(
      appBar: AppBar(title: const Text('Mis postulaciones')),
      body: FutureBuilder<List<MiPostulacion>>(
        future: _postulaciones,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const EsqueletoLista();
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('No pudimos cargar tus postulaciones.'),
                  const SizedBox(height: AppSpacing.sm),
                  OutlinedButton(
                    onPressed: _recargar,
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }
          final lista = snapshot.data ?? const [];
          if (lista.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Text(
                  'Todavía no has postulado ningún servicio.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: colores.textoSecundario),
                ),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: _recargar,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                for (final p in lista) _TarjetaPostulacion(postulacion: p),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _TarjetaPostulacion extends StatelessWidget {
  final MiPostulacion postulacion;

  const _TarjetaPostulacion({required this.postulacion});

  @override
  Widget build(BuildContext context) {
    final colores = context.colores;
    final (color, icono) = switch (postulacion.estado) {
      EstadoPostulacion.activo => (
        colores.primario,
        Icons.check_circle_outline,
      ),
      EstadoPostulacion.rechazado => (
        Theme.of(context).colorScheme.error,
        Icons.cancel_outlined,
      ),
      EstadoPostulacion.inactivo => (
        colores.textoSecundario,
        Icons.pause_circle_outline,
      ),
      EstadoPostulacion.pendiente => (
        colores.textoSecundario,
        Icons.hourglass_empty,
      ),
    };
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    postulacion.nombre,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ),
                Pill(
                  icono: icono,
                  texto: postulacion.estado.etiqueta,
                  color: color,
                  fontSize: 12,
                ),
              ],
            ),
            if (postulacion.motivoRechazo != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Motivo: ${postulacion.motivoRechazo}',
                style: TextStyle(color: colores.textoSecundario, fontSize: 13),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
