import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../models/material_type.dart';
import '../models/sugerencia_cercana.dart';
import '../repositories/acciones_repository.dart';
import '../theme/app_spacing.dart';
import '../theme/app_theme.dart';
import '../utils/snackbars.dart';

/// Puntos sugeridos por otras personas cerca de [ubicacion] que aún no se han
/// revisado. Confirmar que existen no da puntos: solo sube su prioridad en la
/// cola de revisión (y exige estar a 300 m o menos del lugar).
class ConfirmarSugerenciasScreen extends StatefulWidget {
  final AccionesRepository repositorio;
  final LatLng ubicacion;

  const ConfirmarSugerenciasScreen({
    super.key,
    required this.repositorio,
    required this.ubicacion,
  });

  @override
  State<ConfirmarSugerenciasScreen> createState() =>
      _ConfirmarSugerenciasScreenState();
}

class _ConfirmarSugerenciasScreenState
    extends State<ConfirmarSugerenciasScreen> {
  late Future<List<SugerenciaCercana>> _sugerencias = _consultar();
  final Map<int, SugerenciaCercana> _confirmadas = {};
  final Set<int> _enviando = {};

  Future<List<SugerenciaCercana>> _consultar() =>
      widget.repositorio.sugerenciasCercanas(
        lat: widget.ubicacion.latitude,
        lng: widget.ubicacion.longitude,
      );

  Future<void> _confirmar(SugerenciaCercana s) async {
    setState(() => _enviando.add(s.id));
    try {
      final total = await widget.repositorio.confirmarSugerencia(
        idSugerencia: s.id,
        lat: widget.ubicacion.latitude,
        lng: widget.ubicacion.longitude,
      );
      if (!mounted) return;
      setState(() => _confirmadas[s.id] = s.confirmada(total));
      mostrarSnackbar(context, 'Gracias por confirmarlo.');
    } on AccionException catch (e) {
      if (mounted) mostrarSnackbar(context, e.mensaje);
    } catch (_) {
      if (mounted) {
        mostrarSnackbar(
          context,
          const AccionException(MotivoErrorAccion.desconocido).mensaje,
        );
      }
    } finally {
      if (mounted) setState(() => _enviando.remove(s.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colores = context.colores;
    return Scaffold(
      appBar: AppBar(title: const Text('Puntos por confirmar')),
      body: SafeArea(
        child: FutureBuilder<List<SugerenciaCercana>>(
          future: _sugerencias,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('No se pudieron cargar las sugerencias.'),
                    TextButton(
                      onPressed: () => setState(() {
                        _sugerencias = _consultar();
                      }),
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              );
            }
            final lista = snapshot.data!;
            if (lista.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Text(
                    'No hay puntos nuevos por confirmar cerca de ti.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: colores.textoSecundario),
                  ),
                ),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: lista.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final s = _confirmadas[lista[i].id] ?? lista[i];
                final puede = !s.esMia && !s.yaConfirmada;
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.nombre,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        Text(
                          '${s.comuna} · ${s.confirmaciones} '
                          '${s.confirmaciones == 1 ? 'confirmación' : 'confirmaciones'}',
                          style: TextStyle(color: colores.textoSecundario),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          children: [
                            for (final m in s.materiales)
                              Icon(m.icono, size: 18, color: m.color),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Align(
                          alignment: Alignment.centerRight,
                          child: OutlinedButton(
                            key: Key('confirmar-${s.id}'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md,
                              ),
                            ),
                            onPressed: puede && !_enviando.contains(s.id)
                                ? () => _confirmar(s)
                                : null,
                            child: Text(
                              s.esMia
                                  ? 'Tu sugerencia'
                                  : s.yaConfirmada
                                  ? 'Confirmado'
                                  : 'Sí existe',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
