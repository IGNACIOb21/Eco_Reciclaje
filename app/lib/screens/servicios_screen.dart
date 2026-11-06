import 'package:flutter/material.dart';

import '../models/material_type.dart';
import '../models/recolector_particular.dart';
import '../repositories/recolectores_repository.dart';
import '../repositories/recolectores_repository_mock.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_theme.dart';
import '../widgets/pill.dart';

/// Pestaña Servicios: directorio de recolectores particulares de materiales
/// reciclables (personas o pequeños negocios que juntan aceite usado, tetra
/// pak, pilas, etc. fuera de los puntos de reciclaje oficiales).
class ServiciosScreen extends StatefulWidget {
  final RecolectoresRepository? repositorio;

  const ServiciosScreen({super.key, this.repositorio});

  @override
  State<ServiciosScreen> createState() => _ServiciosScreenState();
}

class _ServiciosScreenState extends State<ServiciosScreen> {
  late final RecolectoresRepository _repositorio =
      widget.repositorio ?? RecolectoresRepositoryMock();
  late Future<List<RecolectorParticular>> _recolectores = _repositorio
      .obtenerRecolectores();

  Future<void> _recargar() async {
    final future = _repositorio.obtenerRecolectores();
    setState(() => _recolectores = future);
    try {
      await future;
    } catch (_) {
      // El error ya se muestra vía FutureBuilder al reconstruir con el
      // nuevo future; no hace falta relanzarlo acá.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: FutureBuilder<List<RecolectorParticular>>(
          future: _recolectores,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const _ServiciosSkeleton();
            }

            if (snapshot.hasError) {
              // TODO(backend): con RecolectoresRepositorySupabase, distinguir
              // errores de red vs. servidor si hace falta un mensaje más
              // específico que el genérico de acá.
              return _ServiciosError(onReintentar: _recargar);
            }

            final recolectores = snapshot.data ?? const [];
            return RefreshIndicator(
              onRefresh: _recargar,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.sm,
                  AppSpacing.md,
                  AppSpacing.xl,
                ),
                children: [
                  const Text(
                    'Recolectores particulares',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Personas y negocios que retiran materiales que no siempre se reciben en los puntos oficiales.',
                    style: TextStyle(
                      color: context.colores.textoSecundario,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  if (recolectores.isEmpty)
                    // TODO(backend): confirmar si "sin recolectores" también
                    // debe cubrir un bloqueo de RLS una vez exista la tabla
                    // real, o si eso debe verse como error.
                    const _ServiciosVacio()
                  else
                    for (final recolector in recolectores)
                      _RecolectorCard(recolector: recolector),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Placeholder tipo skeleton mientras carga la lista: bloques grises con un
/// pulso de opacidad, hechos con widgets base (sin paquete de shimmer).
class _ServiciosSkeleton extends StatefulWidget {
  const _ServiciosSkeleton();

  @override
  State<_ServiciosSkeleton> createState() => _ServiciosSkeletonState();
}

class _ServiciosSkeletonState extends State<_ServiciosSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colores = context.colores;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final opacidad = 0.4 + _controller.value * 0.4;
        return ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.md,
            AppSpacing.xl,
          ),
          children: [
            _bloque(colores, height: 16, width: 180, opacidad: opacidad),
            const SizedBox(height: AppSpacing.sm),
            for (var i = 0; i < 4; i++) ...[
              _bloque(colores, height: 110, opacidad: opacidad),
              const SizedBox(height: AppSpacing.xs),
            ],
          ],
        );
      },
    );
  }

  Widget _bloque(
    ColoresApp colores, {
    required double height,
    required double opacidad,
    double? width,
  }) {
    return Opacity(
      opacity: opacidad,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: colores.superficieAlta,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
    );
  }
}

/// Mensaje de error con opción de reintentar, en vez de dejar la pantalla en
/// blanco cuando falla la carga.
class _ServiciosError extends StatelessWidget {
  final Future<void> Function() onReintentar;

  const _ServiciosError({required this.onReintentar});

  @override
  Widget build(BuildContext context) {
    final colores = context.colores;
    return LayoutBuilder(
      builder: (context, constraints) {
        return ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.md,
            AppSpacing.xl,
          ),
          children: [
            ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 40,
                      color: colores.textoSecundario,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'No pudimos cargar los recolectores.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: colores.texto,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Revisa tu conexión e intenta de nuevo.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: colores.textoSecundario,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    OutlinedButton(
                      onPressed: onReintentar,
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Mensaje claro cuando el repositorio responde una lista vacía, en vez de
/// no mostrar nada debajo del encabezado.
class _ServiciosVacio extends StatelessWidget {
  const _ServiciosVacio();

  @override
  Widget build(BuildContext context) {
    final colores = context.colores;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
      child: Column(
        children: [
          Icon(Icons.people_outline, size: 40, color: colores.textoSecundario),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Todavía no hay recolectores registrados en tu zona.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colores.textoSecundario,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Desliza hacia abajo para volver a intentarlo.',
            textAlign: TextAlign.center,
            style: TextStyle(color: colores.textoSecundario, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _RecolectorCard extends StatelessWidget {
  final RecolectorParticular recolector;

  const _RecolectorCard({required this.recolector});

  @override
  Widget build(BuildContext context) {
    final colores = context.colores;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        recolector.nombre,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Row(
                        children: [
                          Icon(
                            Icons.place_outlined,
                            size: 14,
                            color: colores.textoSecundario,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            recolector.comuna,
                            style: TextStyle(
                              color: colores.textoSecundario,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (recolector.retiraADomicilio)
                  Pill(
                    icono: Icons.local_shipping_outlined,
                    texto: 'Retira a domicilio',
                    color: colores.primario,
                    fontSize: 11,
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              recolector.descripcion,
              style: TextStyle(color: colores.textoSecundario, fontSize: 13),
            ),
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
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Icon(
                  Icons.call_outlined,
                  size: 14,
                  color: colores.textoSecundario,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    recolector.contacto,
                    style: TextStyle(
                      color: colores.texto,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
