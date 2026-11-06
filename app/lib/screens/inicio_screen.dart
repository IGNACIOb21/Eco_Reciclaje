import 'package:flutter/material.dart';

import '../data/comunas_demo.dart';
import '../data/mock_puntos.dart';
import '../models/actividad_puntos.dart';
import '../models/movimiento_punto.dart';
import '../state/perfil_local_controller.dart';
import '../state/usuario_controller.dart';
import '../theme/app_theme.dart';
import '../utils/geo.dart';
import '../utils/snackbars.dart';
import '../widgets/actividad_puntos_tile.dart';
import '../widgets/avatar_usuario.dart';
import '../widgets/pill.dart';

class InicioScreen extends StatelessWidget {
  final VoidCallback onIrAMapa;
  final VoidCallback onIrAEscanear;

  const InicioScreen({
    super.key,
    required this.onIrAMapa,
    required this.onIrAEscanear,
  });

  @override
  Widget build(BuildContext context) {
    final local = PerfilLocalScope.of(context).perfil;
    final colores = context.colores;
    final usuario = UsuarioScope.of(context).usuario;
    final puntosCercanos = mockPuntos
        .where(
          (p) =>
              distanciaKm(centroDefectoLat, centroDefectoLng, p.lat, p.lng) < 1,
        )
        .length;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            Row(
              children: [
                AvatarUsuario(
                  icono: local.avatarIcono,
                  color: local.avatarColor,
                  tamano: 40,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        local.esAnonimo
                            ? '¡Hola!'
                            : 'Hola, ${local.nombreVisible}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        local.comuna,
                        style: TextStyle(
                          color: colores.textoSecundario,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Pill(
                  icono: Icons.star,
                  texto: '${usuario?.puntosTotales ?? "–"}',
                  color: colores.secundario,
                  fondo: colores.fondoSecundario,
                  fontWeight: FontWeight.w700,
                  gap: 4,
                ),
              ],
            ),
            const SizedBox(height: 20),
            _MapaPreviewCard(puntosCercanos: puntosCercanos, onTap: onIrAMapa),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _AccionCard(
                    icono: Icons.camera_alt,
                    titulo: 'Escanear objeto',
                    subtitulo: '¿Es reciclable?',
                    color: colores.primario,
                    fondo: colores.primario.withValues(alpha: 0.14),
                    onTap: onIrAEscanear,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _AccionCard(
                    icono: Icons.menu_book_outlined,
                    titulo: 'Guía rápida',
                    subtitulo: 'Cómo separar bien',
                    color: colores.texto,
                    fondo: colores.superficie,
                    borde: colores.borde,
                    onTap: () =>
                        mostrarProximamente(context, 'Guía de reciclaje'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'Actividad reciente',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
            const SizedBox(height: 8),
            if (usuario != null && usuario.movimientos.isEmpty)
              Text(
                'Aún no tienes actividad. ¡Escanea tu primer objeto!',
                style: TextStyle(color: colores.textoSecundario),
              ),
            for (final movimiento
                in usuario?.movimientos.take(3) ?? const <MovimientoPunto>[])
              ActividadPuntosTile(
                actividad: ActividadPuntos.desdeMovimiento(movimiento),
              ),
          ],
        ),
      ),
    );
  }
}

class _MapaPreviewCard extends StatelessWidget {
  final int puntosCercanos;
  final VoidCallback onTap;

  const _MapaPreviewCard({required this.puntosCercanos, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colores = context.colores;
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colores.fondoSecundario,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 84,
              decoration: BoxDecoration(
                color: colores.superficie.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Stack(
                children: [
                  Positioned(
                    left: 24,
                    top: 20,
                    child: _PuntoMini(color: colores.primario),
                  ),
                  Positioned(
                    right: 40,
                    top: 16,
                    child: _PuntoMini(color: colores.primario),
                  ),
                  Positioned(
                    left: 90,
                    bottom: 18,
                    child: _PuntoMini(color: colores.secundario),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Mapa de reciclaje',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                ),
                Icon(Icons.arrow_forward, color: colores.secundario),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              '$puntosCercanos puntos cerca de ti',
              style: TextStyle(color: colores.textoSecundario, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

class _PuntoMini extends StatelessWidget {
  final Color color;

  const _PuntoMini({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _AccionCard extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String subtitulo;
  final Color color;
  final Color fondo;
  final Color? borde;
  final VoidCallback onTap;

  const _AccionCard({
    required this.icono,
    required this.titulo,
    required this.subtitulo,
    required this.color,
    required this.fondo,
    required this.onTap,
    this.borde,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: fondo,
          borderRadius: BorderRadius.circular(18),
          border: borde != null ? Border.all(color: borde!) : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icono, color: color),
            const SizedBox(height: 10),
            Text(
              titulo,
              style: TextStyle(fontWeight: FontWeight.w700, color: color),
            ),
            const SizedBox(height: 2),
            Text(
              subtitulo,
              style: TextStyle(
                fontSize: 12,
                color: color.withValues(alpha: 0.75),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
