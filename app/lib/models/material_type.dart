import 'package:flutter/material.dart';

enum TipoMaterial {
  vidrio,
  papel,
  plastico,
  metal,
  pilas,
  latas,
  tetraPak,
  aceite,
}

extension MaterialTypeInfo on TipoMaterial {
  /// Código tal como está en la tabla `materiales` de Supabase (ver
  /// backend/supabase/migrations/20260908232413_puntos_reciclaje.sql).
  /// `aceite` no tiene código porque todavía no existe en esa tabla.
  String? get codigo => switch (this) {
    TipoMaterial.vidrio => 'vidrio',
    TipoMaterial.papel => 'papel',
    TipoMaterial.plastico => 'plastico',
    TipoMaterial.metal => 'metal',
    TipoMaterial.pilas => 'pilas',
    TipoMaterial.latas => 'latas',
    TipoMaterial.tetraPak => 'tetra_pak',
    TipoMaterial.aceite => null,
  };

  static TipoMaterial? fromCodigo(String codigo) => switch (codigo) {
    'vidrio' => TipoMaterial.vidrio,
    'papel' => TipoMaterial.papel,
    'plastico' => TipoMaterial.plastico,
    'metal' => TipoMaterial.metal,
    'pilas' => TipoMaterial.pilas,
    'latas' => TipoMaterial.latas,
    'tetra_pak' => TipoMaterial.tetraPak,
    _ => null,
  };

  String get etiqueta => switch (this) {
    TipoMaterial.vidrio => 'Vidrio',
    TipoMaterial.papel => 'Papel y cartón',
    TipoMaterial.plastico => 'Plástico',
    TipoMaterial.metal => 'Metal',
    TipoMaterial.pilas => 'Pilas',
    TipoMaterial.latas => 'Latas',
    TipoMaterial.tetraPak => 'Tetra Pak',
    TipoMaterial.aceite => 'Aceite usado',
  };

  IconData get icono => switch (this) {
    TipoMaterial.vidrio => Icons.wine_bar_outlined,
    TipoMaterial.papel => Icons.description_outlined,
    TipoMaterial.plastico => Icons.local_drink_outlined,
    TipoMaterial.metal => Icons.hardware_outlined,
    TipoMaterial.pilas => Icons.battery_full,
    TipoMaterial.latas => Icons.local_bar_outlined,
    TipoMaterial.tetraPak => Icons.inventory_2_outlined,
    TipoMaterial.aceite => Icons.oil_barrel_outlined,
  };

  Color get color => switch (this) {
    TipoMaterial.vidrio => const Color(0xFF2E9E5B),
    TipoMaterial.papel => const Color(0xFF2E7DD1),
    TipoMaterial.plastico => const Color(0xFFF2B705),
    TipoMaterial.metal => const Color(0xFF8C8F94),
    TipoMaterial.pilas => const Color(0xFFE0483F),
    TipoMaterial.latas => const Color(0xFFE07B39),
    TipoMaterial.tetraPak => const Color(0xFF7C4DBE),
    TipoMaterial.aceite => const Color(0xFF8B5E3C),
  };
}
