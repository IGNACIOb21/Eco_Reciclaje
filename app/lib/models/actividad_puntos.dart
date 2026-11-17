import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'movimiento_punto.dart';

/// Entrada del historial de actividad del perfil: una acción del sistema de
/// puntos (escanear, reportar, calificar) junto con lo que acreditó.
class ActividadPuntos {
  final IconData icono;
  final Color color;
  final String texto;
  final int puntos;

  const ActividadPuntos({
    required this.icono,
    required this.color,
    required this.texto,
    required this.puntos,
  });

  factory ActividadPuntos.desdeMovimiento(MovimientoPunto movimiento) {
    final (icono, color, texto) = switch (movimiento.tipo) {
      'deposito' => (
        Icons.recycling,
        AppTheme.primario,
        'Reciclaste un objeto',
      ),
      'escaneo' => (
        Icons.document_scanner_outlined,
        AppTheme.primario,
        'Escaneaste un objeto',
      ),
      'reporte' => (
        Icons.flag_outlined,
        AppTheme.azul,
        'Reportaste el estado de un punto',
      ),
      'valoracion' => (
        Icons.star_outline,
        AppTheme.acento,
        'Calificaste un punto',
      ),
      'sugerencia' => (
        Icons.add_location_alt_outlined,
        AppTheme.azul,
        'Sugeriste un punto nuevo',
      ),
      'racha' => (
        Icons.local_fire_department_outlined,
        AppTheme.acento,
        'Mantuviste tu racha diaria',
      ),
      'canje' => (Icons.redeem, AppTheme.acento, 'Canjeaste un beneficio'),
      _ => (Icons.star, AppTheme.acento, 'Ajuste de Rebin Points'),
    };
    // Un canje positivo es la devolución de un canje cancelado, y una acción
    // con puntos negativos es una reversión (p. ej. un reporte que resultó
    // infundado): no deben leerse como si la persona hubiera hecho la acción.
    final devolucion = movimiento.tipo == 'canje' && movimiento.cantidad > 0;
    final reversion = movimiento.tipo != 'canje' && movimiento.cantidad < 0;
    return ActividadPuntos(
      icono: icono,
      color: color,
      texto: devolucion
          ? 'Te devolvimos los Rebin Points de un canje'
          : reversion
          ? 'Se revirtieron Rebin Points de una acción'
          : texto,
      puntos: movimiento.cantidad,
    );
  }
}
