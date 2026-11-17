import 'package:flutter/material.dart';

import '../models/material_type.dart';
import '../models/recolector_particular.dart';
import '../repositories/recolectores_repository.dart';
import '../repositories/recolectores_repository_mock.dart';
import '../repositories/recolectores_repository_supabase.dart';
import '../services/supabase_service.dart';
import '../theme/app_spacing.dart';
import '../theme/app_theme.dart';
import '../widgets/pill.dart';
import '../widgets/servicio_detalle_sheet.dart';
import '../widgets/esqueleto.dart';
import '../utils/snackbars.dart';
import 'mis_postulaciones_screen.dart';
import 'postular_servicio_screen.dart';

/// Pestaña Servicios: directorio de recolectores particulares de materiales
/// reciclables (personas o pequeños negocios que juntan aceite usado, tetra
/// pak, pilas, etc. fuera de los puntos de reciclaje oficiales). Se puede
/// filtrar por material, abrir la ficha de cada uno y postular un servicio
/// propio (queda en revisión hasta que el panel lo apruebe).
class ServiciosScreen extends StatefulWidget {
  final RecolectoresRepository? repositorio;

  const ServiciosScreen({super.key, this.repositorio});

  @override
  State<ServiciosScreen> createState() => _ServiciosScreenState();
}

class _ServiciosScreenState extends State<ServiciosScreen> {
  late final RecolectoresRepository _repositorio =
      widget.repositorio ??
      (SupabaseService.disponible
          ? RecolectoresRepositorySupabase()
          : RecolectoresRepositoryMock());
  final Set<TipoMaterial> _materiales = {};
  late Future<List<RecolectorParticular>> _recolectores = _consultar();

  Future<List<RecolectorParticular>> _consultar() =>
      _repositorio.obtenerRecolectores(materiales: _materiales.toList());

  void _alternarMaterial(TipoMaterial material) {
    setState(() {
      if (!_materiales.remove(material)) _materiales.add(material);
      _recolectores = _consultar();
    });
  }

  Future<void> _postular() async {
    final enviada = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => PostularServicioScreen(repositorio: _repositorio),
      ),
    );
    if (enviada == true && mounted) {
      mostrarSnackbar(
        context,
        'Recibimos tu postulación. Puedes ver su estado en "Mis postulaciones".',
      );
    }
  }

  void _verMisPostulaciones() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MisPostulacionesScreen(repositorio: _repositorio),
      ),
    );
  }

  Future<void> _recargar() async {
    final future = _consultar();
    setState(() {
      _recolectores = future;
    });
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
        bottom: false,
        child: FutureBuilder<List<RecolectorParticular>>(
          future: _recolectores,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const EsqueletoLista();
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
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.sm,
                  AppSpacing.md,
                  AppSpacing.xl + MediaQuery.paddingOf(context).bottom,
                ),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Recolectores particulares',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      IconButton(
                        tooltip: 'Mis postulaciones',
                        onPressed: _verMisPostulaciones,
                        icon: const Icon(Icons.assignment_outlined),
                      ),
                    ],
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
                  _FiltroMateriales(
                    seleccionados: _materiales,
                    onAlternar: _alternarMaterial,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  OutlinedButton.icon(
                    onPressed: _postular,
                    icon: const Icon(Icons.add_circle_outline),
                    label: const Text('Postular mi servicio'),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  if (recolectores.isEmpty)
                    // TODO(backend): confirmar si "sin recolectores" también
                    // debe cubrir un bloqueo de RLS una vez exista la tabla
                    // real, o si eso debe verse como error.
                    const _ServiciosVacio()
                  else
                    for (final recolector in recolectores)
                      _RecolectorCard(
                        recolector: recolector,
                        onTap: () =>
                            mostrarServicioDetalle(context, recolector),
                      ),
                ],
              ),
            );
          },
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
          padding: EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.md,
            AppSpacing.xl + MediaQuery.paddingOf(context).bottom,
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
            'No encontramos recolectores con esos filtros.',
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

/// Chips para filtrar por material (se pueden combinar).
class _FiltroMateriales extends StatelessWidget {
  final Set<TipoMaterial> seleccionados;
  final ValueChanged<TipoMaterial> onAlternar;

  const _FiltroMateriales({
    required this.seleccionados,
    required this.onAlternar,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final material in TipoMaterial.values)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.xs),
              child: FilterChip(
                avatar: Icon(material.icono, size: 16, color: material.color),
                label: Text(material.etiqueta),
                selected: seleccionados.contains(material),
                onSelected: (_) => onAlternar(material),
              ),
            ),
        ],
      ),
    );
  }
}

class _RecolectorCard extends StatelessWidget {
  final RecolectorParticular recolector;
  final VoidCallback onTap;

  const _RecolectorCard({required this.recolector, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colores = context.colores;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.xs),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
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
                            Flexible(
                              child: Text(
                                recolector.comunasTexto,
                                style: TextStyle(
                                  color: colores.textoSecundario,
                                  fontSize: 12,
                                ),
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
      ),
    );
  }
}
