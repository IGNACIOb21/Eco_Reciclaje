import 'package:flutter/material.dart';

enum EstadoPunto {
  disponible,
  lleno,
  danado,
  sinSenalizacion,
  malMantenimiento,
  fueraDeUso,
}

extension EstadoPuntoInfo on EstadoPunto {
  /// Código tal como está en `puntos_reciclaje.estado_actual` (ver
  /// backend/supabase/migrations/20260908232413_puntos_reciclaje.sql).
  String get codigo => switch (this) {
    EstadoPunto.disponible => 'disponible',
    EstadoPunto.lleno => 'lleno',
    EstadoPunto.danado => 'danado',
    EstadoPunto.sinSenalizacion => 'sin_senalizacion',
    EstadoPunto.malMantenimiento => 'mal_mantenimiento',
    EstadoPunto.fueraDeUso => 'fuera_de_uso',
  };

  static EstadoPunto fromCodigo(String codigo) => switch (codigo) {
    'lleno' => EstadoPunto.lleno,
    'danado' => EstadoPunto.danado,
    'sin_senalizacion' => EstadoPunto.sinSenalizacion,
    'mal_mantenimiento' => EstadoPunto.malMantenimiento,
    'fuera_de_uso' => EstadoPunto.fueraDeUso,
    _ => EstadoPunto.disponible,
  };

  String get etiqueta => switch (this) {
    EstadoPunto.disponible => 'Disponible',
    EstadoPunto.lleno => 'Lleno',
    EstadoPunto.danado => 'Dañado',
    EstadoPunto.sinSenalizacion => 'Sin señalización',
    EstadoPunto.malMantenimiento => 'Mal mantenimiento',
    EstadoPunto.fueraDeUso => 'Fuera de uso',
  };

  IconData get icono => switch (this) {
    EstadoPunto.disponible => Icons.check_circle,
    EstadoPunto.lleno => Icons.inventory,
    EstadoPunto.danado => Icons.report_problem,
    EstadoPunto.sinSenalizacion => Icons.help,
    EstadoPunto.malMantenimiento => Icons.build,
    EstadoPunto.fueraDeUso => Icons.block,
  };

  Color get color => switch (this) {
    EstadoPunto.disponible => const Color(0xFF2E9E5B),
    EstadoPunto.lleno => const Color(0xFFF2B705),
    EstadoPunto.danado => const Color(0xFFE0483F),
    EstadoPunto.sinSenalizacion => const Color(0xFF8C8F94),
    EstadoPunto.malMantenimiento => const Color(0xFFE07B39),
    EstadoPunto.fueraDeUso => const Color(0xFF6B6E73),
  };
}
