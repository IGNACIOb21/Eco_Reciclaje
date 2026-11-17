import 'package:flutter/material.dart';

import '../models/mi_canje.dart';
import '../repositories/beneficios_repository.dart';
import '../theme/app_spacing.dart';
import '../theme/app_theme.dart';
import '../widgets/esqueleto.dart';

/// Los canjes de esta cuenta. Los que están "por retirar" muestran su código,
/// que se presenta ante la entidad.
class MisCanjesScreen extends StatefulWidget {
  final BeneficiosRepository repositorio;

  const MisCanjesScreen({super.key, required this.repositorio});

  @override
  State<MisCanjesScreen> createState() => _MisCanjesScreenState();
}

class _MisCanjesScreenState extends State<MisCanjesScreen> {
  late Future<List<MiCanje>> _canjes = widget.repositorio.misCanjes();

  void _reintentar() {
    setState(() {
      _canjes = widget.repositorio.misCanjes();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colores = context.colores;
    return Scaffold(
      appBar: AppBar(title: const Text('Mis canjes')),
      body: SafeArea(
        child: FutureBuilder<List<MiCanje>>(
          future: _canjes,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const EsqueletoLista();
            }
            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('No se pudieron cargar tus canjes.'),
                    TextButton(
                      onPressed: _reintentar,
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              );
            }
            final canjes = snapshot.data!;
            if (canjes.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Text(
                    'Aún no has canjeado nada. Junta Rebin Points reciclando y elige un beneficio.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: colores.textoSecundario),
                  ),
                ),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: canjes.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final c = canjes[i];
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          c.beneficio,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          '${c.entidad} · ${c.costo} Rebin Points',
                          style: TextStyle(color: colores.textoSecundario),
                        ),
                        const SizedBox(height: 6),
                        Text(c.etiquetaEstado),
                        if (c.pendiente) ...[
                          const SizedBox(height: 8),
                          SelectableText(
                            c.codigo,
                            key: Key('codigo-${c.id}'),
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 4,
                            ),
                          ),
                        ],
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
