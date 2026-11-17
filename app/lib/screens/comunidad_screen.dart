import 'package:flutter/material.dart';

import '../repositories/comunidad_por_defecto.dart';
import '../repositories/comunidad_repository.dart';
import '../repositories/retos_por_defecto.dart';
import '../repositories/retos_repository.dart';
import '../state/perfil_local_controller.dart';
import '../theme/app_theme.dart';
import 'comunidad_pestanas.dart';
import 'grupos_comunidad.dart';
import 'personalizar_perfil_sheet.dart';

/// Comunidad (pág. 12 del rediseño): la comuna arriba y cuatro pestañas. Hoy,
/// Actividad y Ranking salen de la base (`ComunidadRepository`) y Grupos son
/// las comunidades reales de Supabase (`ComunidadesRepository`, ver
/// grupos_comunidad.dart).
class ComunidadScreen extends StatelessWidget {
  /// Solo para tests: por defecto [comunidadPorDefecto].
  final ComunidadRepository? repositorio;

  /// Solo para tests: por defecto [retosPorDefecto].
  final RetosRepository? retos;

  const ComunidadScreen({super.key, this.repositorio, this.retos});

  @override
  Widget build(BuildContext context) {
    final local = PerfilLocalScope.of(context).perfil;
    final colores = context.colores;
    final repo = repositorio ?? comunidadPorDefecto();
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        body: SafeArea(
        bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Comunidad',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ),
                    // La comuna sale del perfil local; se cambia ahí.
                    TextButton.icon(
                      key: const Key('comunidad-comuna'),
                      onPressed: () => mostrarPersonalizarPerfil(context),
                      icon: Icon(
                        Icons.place_outlined,
                        size: 18,
                        color: colores.textoSecundario,
                      ),
                      label: Text(local.comuna),
                    ),
                  ],
                ),
              ),
              const TabBar(
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                tabs: [
                  Tab(text: 'Hoy'),
                  Tab(text: 'Actividad'),
                  Tab(text: 'Ranking'),
                  Tab(text: 'Grupos'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    HoyComunidad(
                      repositorio: repo,
                      retos: retos ?? retosPorDefecto(),
                      comuna: local.comuna,
                    ),
                    ActividadComunidad(repositorio: repo, comuna: local.comuna),
                    RankingComunidad(repositorio: repo),
                    const GruposComunidad(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
