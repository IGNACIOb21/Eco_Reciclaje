import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../utils/fechas.dart';
import 'actividad_puntos.dart';
import 'insignia.dart';
import 'nivel.dart';
import 'usuario.dart';

/// Set fijo de insignias del Perfil; se marcan obtenidas en orden según
/// cuántos `logro_usuario` tenga la cuenta.
const _insigniasBase = [
  (Icons.recycling, AppTheme.primario),
  (Icons.location_on, AppTheme.azul),
  (Icons.star, AppTheme.acento),
  (Icons.flag, AppTheme.acento),
];

class PerfilUsuario {
  final String nombre;
  final String miembroDesde;
  final int puntosTotales;
  final int objetosEscaneados;
  final int reportesHechos;
  final List<Insignia> insignias;
  final List<ActividadPuntos> actividad;

  const PerfilUsuario({
    required this.nombre,
    required this.miembroDesde,
    required this.puntosTotales,
    required this.objetosEscaneados,
    required this.reportesHechos,
    required this.insignias,
    required this.actividad,
  });

  /// Perfil armado 100% con los datos de la cuenta en Supabase.
  factory PerfilUsuario.desdeUsuario(Usuario usuario) {
    return PerfilUsuario(
      nombre: usuario.alias,
      miembroDesde: mesYAnio(usuario.fechaRegistro),
      puntosTotales: usuario.puntosTotales,
      objetosEscaneados: usuario.objetosEscaneados,
      reportesHechos: usuario.reportesHechos,
      insignias: [
        for (final (i, (icono, color)) in _insigniasBase.indexed)
          Insignia(
            icono: icono,
            color: i < usuario.logrosObtenidos ? color : Colors.grey,
            obtenida: i < usuario.logrosObtenidos,
          ),
      ],
      actividad: [
        for (final m in usuario.movimientos) ActividadPuntos.desdeMovimiento(m),
      ],
    );
  }

  Nivel get nivelActual => NivelInfo.paraPuntos(puntosTotales);

  int? get puntosParaSiguienteNivel => nivelActual.siguiente?.umbral;

  /// Avance dentro del nivel actual (ej. Pro va de 130 a 200: con 158 pts
  /// la barra marca 40 %, no 158/200).
  double get progresoNivel {
    final tope = puntosParaSiguienteNivel;
    if (tope == null) return 1.0;
    final base = nivelActual.umbral;
    return ((puntosTotales - base) / (tope - base)).clamp(0.0, 1.0);
  }
}
