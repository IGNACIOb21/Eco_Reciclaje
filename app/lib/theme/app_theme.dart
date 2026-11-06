import 'package:flutter/material.dart';

/// Tokens de color de la app. Cada pantalla los lee vía `context.colores`
/// para que el Modo Eco sea una variante de diseño propia y no una inversión.
class ColoresApp extends ThemeExtension<ColoresApp> {
  final Color primario;
  final Color acento;
  final Color secundario;
  final Color fondoSecundario;
  final Color fondo;
  final Color superficie;
  final Color superficieAlta;
  final Color texto;
  final Color textoSecundario;
  final Color borde;
  final Color fondoMapa;
  final Color sobrePrimario;

  const ColoresApp({
    required this.primario,
    required this.acento,
    required this.secundario,
    required this.fondoSecundario,
    required this.fondo,
    required this.superficie,
    required this.superficieAlta,
    required this.texto,
    required this.textoSecundario,
    required this.borde,
    required this.fondoMapa,
    required this.sobrePrimario,
  });

  @override
  ColoresApp copyWith({
    Color? primario,
    Color? acento,
    Color? secundario,
    Color? fondoSecundario,
    Color? fondo,
    Color? superficie,
    Color? superficieAlta,
    Color? texto,
    Color? textoSecundario,
    Color? borde,
    Color? fondoMapa,
    Color? sobrePrimario,
  }) {
    return ColoresApp(
      primario: primario ?? this.primario,
      acento: acento ?? this.acento,
      secundario: secundario ?? this.secundario,
      fondoSecundario: fondoSecundario ?? this.fondoSecundario,
      fondo: fondo ?? this.fondo,
      superficie: superficie ?? this.superficie,
      superficieAlta: superficieAlta ?? this.superficieAlta,
      texto: texto ?? this.texto,
      textoSecundario: textoSecundario ?? this.textoSecundario,
      borde: borde ?? this.borde,
      fondoMapa: fondoMapa ?? this.fondoMapa,
      sobrePrimario: sobrePrimario ?? this.sobrePrimario,
    );
  }

  @override
  ColoresApp lerp(ThemeExtension<ColoresApp>? other, double t) {
    if (other is! ColoresApp) return this;
    return ColoresApp(
      primario: Color.lerp(primario, other.primario, t)!,
      acento: Color.lerp(acento, other.acento, t)!,
      secundario: Color.lerp(secundario, other.secundario, t)!,
      fondoSecundario: Color.lerp(fondoSecundario, other.fondoSecundario, t)!,
      fondo: Color.lerp(fondo, other.fondo, t)!,
      superficie: Color.lerp(superficie, other.superficie, t)!,
      superficieAlta: Color.lerp(superficieAlta, other.superficieAlta, t)!,
      texto: Color.lerp(texto, other.texto, t)!,
      textoSecundario: Color.lerp(textoSecundario, other.textoSecundario, t)!,
      borde: Color.lerp(borde, other.borde, t)!,
      fondoMapa: Color.lerp(fondoMapa, other.fondoMapa, t)!,
      sobrePrimario: Color.lerp(sobrePrimario, other.sobrePrimario, t)!,
    );
  }
}

extension ColoresDeContexto on BuildContext {
  ColoresApp get colores => Theme.of(this).extension<ColoresApp>()!;
}

class AppTheme {
  AppTheme._();

  // Identidad base (cálida/colorida). Se usan también como colores de datos
  // (materiales, insignias, actividad) en ambos temas.
  static const Color primario = Color(0xFF2E9E5B);
  static const Color acento = Color(0xFFF2B705);
  static const Color azul = Color(0xFF3B82C4);
  static const Color fondoAzulClaro = Color(0xFFDCEAFB);
  static const Color fondoMapa = Color(0xFFF3EFE3);

  static const ColoresApp _claro = ColoresApp(
    primario: primario,
    acento: acento,
    secundario: azul,
    fondoSecundario: fondoAzulClaro,
    fondo: Color(0xFFFAF9F5),
    superficie: Colors.white,
    superficieAlta: Color(0xFFF0EEE6),
    texto: Color(0xFF1B1B1B),
    textoSecundario: Color(0xFF6E6A60),
    borde: Color(0xFFE0DDD3),
    fondoMapa: fondoMapa,
    sobrePrimario: Colors.white,
  );

  // Modo Eco: derivado de la misma identidad — verde profundo de bosque como
  // fondo (en vez de negro/gris), crema cálido para texto, hoja clara como
  // primario, dorado/ocre como acentos. Pensado como variante propia.
  static const ColoresApp _eco = ColoresApp(
    primario: Color(0xFF8FD19E),
    acento: Color(0xFFE3B94F),
    secundario: Color(0xFFD99A5B),
    fondoSecundario: Color(0xFF3A3527),
    fondo: Color(0xFF1B2A22),
    superficie: Color(0xFF253A2F),
    superficieAlta: Color(0xFF32493B),
    texto: Color(0xFFF3EAD4),
    textoSecundario: Color(0xFFB9B097),
    borde: Color(0xFF46604F),
    fondoMapa: Color(0xFF2C4034),
    sobrePrimario: Color(0xFF12261B),
  );

  static ThemeData get light => _construir(_claro, Brightness.light);

  static ThemeData get eco => _construir(_eco, Brightness.dark);

  static ThemeData _construir(ColoresApp c, Brightness brillo) {
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: c.primario,
          brightness: brillo,
        ).copyWith(
          primary: c.primario,
          onPrimary: c.sobrePrimario,
          secondary: c.acento,
          surface: c.superficie,
          onSurface: c.texto,
          outline: c.borde,
        );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      brightness: brillo,
    );
    final textTheme = base.textTheme.apply(
      bodyColor: c.texto,
      displayColor: c.texto,
    );

    return base.copyWith(
      extensions: [c],
      scaffoldBackgroundColor: c.fondo,
      canvasColor: c.superficie,
      textTheme: textTheme,
      iconTheme: IconThemeData(color: c.texto),
      dividerColor: c.borde,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: c.texto,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: c.primario,
          foregroundColor: c.sobrePrimario,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: c.primario,
          side: BorderSide(color: c.primario, width: 1.5),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: c.primario),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: c.superficie,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: c.superficieAlta,
        selectedColor: c.primario.withValues(
          alpha: brillo == Brightness.dark ? 0.3 : 0.15,
        ),
        labelStyle: TextStyle(fontWeight: FontWeight.w500, color: c.texto),
        secondaryLabelStyle: TextStyle(
          fontWeight: FontWeight.w500,
          color: c.texto,
        ),
        checkmarkColor: c.texto,
        iconTheme: IconThemeData(color: c.texto),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: c.superficie,
        indicatorColor: c.primario.withValues(
          alpha: brillo == Brightness.dark ? 0.3 : 0.15,
        ),
        iconTheme: WidgetStatePropertyAll(IconThemeData(color: c.texto)),
        labelTextStyle: WidgetStatePropertyAll(
          TextStyle(color: c.texto, fontSize: 12),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: c.superficie,
        surfaceTintColor: Colors.transparent,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: c.superficie,
        surfaceTintColor: Colors.transparent,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.superficieAlta,
        hintStyle: TextStyle(color: c.textoSecundario),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: c.primario,
        thumbColor: c.primario,
        inactiveTrackColor: c.superficieAlta,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (estados) =>
              estados.contains(WidgetState.selected) ? c.sobrePrimario : null,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (estados) =>
              estados.contains(WidgetState.selected) ? c.primario : null,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: brillo == Brightness.dark
            ? c.superficieAlta
            : const Color(0xFF2B2B2B),
        contentTextStyle: TextStyle(
          color: brillo == Brightness.dark ? c.texto : Colors.white,
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: c.primario),
    );
  }
}
