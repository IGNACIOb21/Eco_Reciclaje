import 'package:flutter/material.dart';

import 'tipografia.dart';

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

  /// Verde legible como texto sobre `fondo` (el `primario` no alcanza 4,5:1 en
  /// claro); en Modo Eco es la hoja clara.
  final Color primarioTexto;

  /// Relleno suave del primario (chips, fondos de ícono, barras vacías).
  final Color primarioSuave;

  /// Dorado: solo para recompensas (Rebin Points, "Reclamar", logros).
  final Color recompensa;
  final Color recompensaTexto;
  final Color recompensaSuave;

  /// Terracota para alertas y errores; nunca rojo puro.
  final Color alerta;

  /// Ámbar tostado para avisos (lleno, sin señalización); lejos del dorado.
  final Color advertencia;

  /// Fondo de los chips de advertencia.
  final Color advertenciaSuave;

  /// Fondo de los chips de error (dañado, fuera de uso).
  final Color alertaSuave;

  /// Terracota legible como texto sobre `alertaSuave`.
  final Color alertaTexto;

  /// Azul pizarra para información.
  final Color info;

  /// Fondo de los chips informativos.
  final Color infoSuave;

  /// Texto sobre `infoSuave`.
  final Color infoTexto;

  /// Texto o ícono sobre un relleno `alerta`.
  final Color sobreAlerta;

  /// Texto o ícono sobre un relleno `recompensa`.
  final Color sobreRecompensa;

  /// Fondo de los elementos deshabilitados; el texto encima es `textoSecundario`.
  final Color deshabilitado;

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
    required this.primarioTexto,
    required this.primarioSuave,
    required this.recompensa,
    required this.recompensaTexto,
    required this.recompensaSuave,
    required this.alerta,
    required this.advertencia,
    required this.advertenciaSuave,
    required this.alertaSuave,
    required this.alertaTexto,
    required this.info,
    required this.infoSuave,
    required this.infoTexto,
    required this.sobreAlerta,
    required this.sobreRecompensa,
    required this.deshabilitado,
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
    Color? primarioTexto,
    Color? primarioSuave,
    Color? recompensa,
    Color? recompensaTexto,
    Color? recompensaSuave,
    Color? alerta,
    Color? advertencia,
    Color? advertenciaSuave,
    Color? alertaSuave,
    Color? alertaTexto,
    Color? info,
    Color? infoSuave,
    Color? infoTexto,
    Color? sobreAlerta,
    Color? sobreRecompensa,
    Color? deshabilitado,
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
      primarioTexto: primarioTexto ?? this.primarioTexto,
      primarioSuave: primarioSuave ?? this.primarioSuave,
      recompensa: recompensa ?? this.recompensa,
      recompensaTexto: recompensaTexto ?? this.recompensaTexto,
      recompensaSuave: recompensaSuave ?? this.recompensaSuave,
      alerta: alerta ?? this.alerta,
      advertencia: advertencia ?? this.advertencia,
      advertenciaSuave: advertenciaSuave ?? this.advertenciaSuave,
      alertaSuave: alertaSuave ?? this.alertaSuave,
      alertaTexto: alertaTexto ?? this.alertaTexto,
      info: info ?? this.info,
      infoSuave: infoSuave ?? this.infoSuave,
      infoTexto: infoTexto ?? this.infoTexto,
      sobreAlerta: sobreAlerta ?? this.sobreAlerta,
      sobreRecompensa: sobreRecompensa ?? this.sobreRecompensa,
      deshabilitado: deshabilitado ?? this.deshabilitado,
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
      primarioTexto: Color.lerp(primarioTexto, other.primarioTexto, t)!,
      primarioSuave: Color.lerp(primarioSuave, other.primarioSuave, t)!,
      recompensa: Color.lerp(recompensa, other.recompensa, t)!,
      recompensaTexto: Color.lerp(recompensaTexto, other.recompensaTexto, t)!,
      recompensaSuave: Color.lerp(recompensaSuave, other.recompensaSuave, t)!,
      alerta: Color.lerp(alerta, other.alerta, t)!,
      advertencia: Color.lerp(advertencia, other.advertencia, t)!,
      advertenciaSuave: Color.lerp(
        advertenciaSuave,
        other.advertenciaSuave,
        t,
      )!,
      alertaSuave: Color.lerp(alertaSuave, other.alertaSuave, t)!,
      alertaTexto: Color.lerp(alertaTexto, other.alertaTexto, t)!,
      info: Color.lerp(info, other.info, t)!,
      infoSuave: Color.lerp(infoSuave, other.infoSuave, t)!,
      infoTexto: Color.lerp(infoTexto, other.infoTexto, t)!,
      sobreAlerta: Color.lerp(sobreAlerta, other.sobreAlerta, t)!,
      sobreRecompensa: Color.lerp(sobreRecompensa, other.sobreRecompensa, t)!,
      deshabilitado: Color.lerp(deshabilitado, other.deshabilitado, t)!,
    );
  }
}

extension ColoresDeContexto on BuildContext {
  ColoresApp get colores => Theme.of(this).extension<ColoresApp>()!;
}

class AppTheme {
  AppTheme._();

  // Identidad base. Se usan también como colores de datos (insignias,
  // actividad) en ambos temas. Los colores de materiales y del mapa viven en
  // material_type.dart y mapa_osm.dart y no se tocan aquí.
  static const Color primario = Color(0xFF0C872B);
  static const Color acento = Color(0xFFE2B85C);
  static const Color azul = Color(0xFF2F6DB5);
  static const Color fondoAzulClaro = Color(0xFFDCE6F4);
  static const Color fondoMapa = Color(0xFFECEEF0);

  // Tema claro de Rebin (el que trae la app al instalarla): gris azulado
  // #D4D9DD como color principal de fondos y superficies, y los verdes del
  // ícono (verde Rebin, verde bosque, lima) para acciones, textos y acentos.
  // El dorado queda solo para recompensas.
  static const ColoresApp _claro = ColoresApp(
    primario: Color(0xFF12804B),
    acento: Color(0xFFA8DB3C),
    secundario: Color(0xFF0B4F31),
    fondoSecundario: Color(0xFFC3E3D0),
    fondo: Color(0xFFD4D9DD),
    superficie: Color(0xFFEBEEF0),
    superficieAlta: Color(0xFFC7CED3),
    texto: Color(0xFF0F2419),
    textoSecundario: Color(0xFF3F5448),
    borde: Color(0xFFB4BDC3),
    fondoMapa: Color(0xFFDCE1E4),
    sobrePrimario: Colors.white,
    primarioTexto: Color(0xFF0B4F31),
    primarioSuave: Color(0xFFC3E3D0),
    recompensa: Color(0xFFE2B85C),
    recompensaTexto: Color(0xFF7A560F),
    recompensaSuave: Color(0xFFF6E8C2),
    alerta: Color(0xFFB5573A),
    advertencia: Color(0xFF8F5409),
    advertenciaSuave: Color(0xFFF1E4CC),
    alertaSuave: Color(0xFFF2DDD5),
    alertaTexto: Color(0xFF984630),
    info: Color(0xFF2F6585),
    infoSuave: Color(0xFFDCE7EE),
    infoTexto: Color(0xFF1F4A63),
    sobreAlerta: Color(0xFFFFFFFF),
    sobreRecompensa: Color(0xFF0F2419),
    deshabilitado: Color(0xFFC9D0D4),
  );

  // Modo Eco: derivado de la misma identidad — verde profundo de bosque como
  // fondo (en vez de negro/gris), crema cálido para texto, hoja clara como
  // primario, dorado como acento. Pensado como variante propia.
  static const ColoresApp _eco = ColoresApp(
    primario: Color(0xFF6CC487),
    acento: Color(0xFFE2B85C),
    secundario: Color(0xFF7FA9DB),
    fondoSecundario: Color(0xFF26394F),
    fondo: Color(0xFF13261B),
    superficie: Color(0xFF1C3526),
    superficieAlta: Color(0xFF24412F),
    texto: Color(0xFFECEFE5),
    textoSecundario: Color(0xFFA9B8AC),
    borde: Color(0xFF2F4B39),
    fondoMapa: Color(0xFF2C4034),
    sobrePrimario: Color(0xFF13261B),
    primarioTexto: Color(0xFF8AD6A1),
    primarioSuave: Color(0xFF234A31),
    recompensa: Color(0xFFE2B85C),
    recompensaTexto: Color(0xFFE2B85C),
    recompensaSuave: Color(0xFF3A3418),
    alerta: Color(0xFFE39274),
    advertencia: Color(0xFFE9A86A),
    advertenciaSuave: Color(0xFF3A3220),
    alertaSuave: Color(0xFF3B2A24),
    alertaTexto: Color(0xFFE39274),
    info: Color(0xFF7FB3D1),
    infoSuave: Color(0xFF1F3A45),
    infoTexto: Color(0xFFBFDCEC),
    sobreAlerta: Color(0xFF13261B),
    sobreRecompensa: Color(0xFF13261B),
    deshabilitado: Color(0xFF2A3F31),
  );

  static ThemeData get light =>
      construir(_claro, Brightness.light, sombraTarjetas: true);

  static ThemeData get eco => construir(_eco, Brightness.dark);

  /// Arma el ThemeData de una paleta. Las paletas de color extra están en
  /// app_themes.dart. [sombraTarjetas] da a las tarjetas una sombra suave
  /// (para temas claros con superficies blancas).
  static ThemeData construir(
    ColoresApp c,
    Brightness brillo, {
    bool sombraTarjetas = false,
  }) {
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: c.primario,
          brightness: brillo,
        ).copyWith(
          primary: c.primario,
          onPrimary: c.sobrePrimario,
          secondary: c.acento,
          tertiary: c.alerta,
          error: c.alerta,
          surface: c.superficie,
          onSurface: c.texto,
          outline: c.borde,
        );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      brightness: brillo,
    );
    final textTheme = Tipografia.aplicar(base.textTheme)
        .apply(bodyColor: c.texto, displayColor: c.texto);

    return base.copyWith(
      extensions: [c],
      scaffoldBackgroundColor: c.fondo,
      canvasColor: c.superficie,
      textTheme: textTheme,
      iconTheme: IconThemeData(color: c.texto),
      dividerColor: c.borde,
      // Texto de pestañas con el verde legible (primarioTexto), no con el
      // primario, que no da 4,5:1 sobre el fondo en los temas claros.
      tabBarTheme: TabBarThemeData(
        labelColor: c.primarioTexto,
        unselectedLabelColor: c.textoSecundario,
        indicatorColor: c.primarioTexto,
        dividerColor: c.borde,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: c.texto,
        titleTextStyle: textTheme.titleLarge?.copyWith(fontSize: 22),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: c.primario,
          foregroundColor: c.sobrePrimario,
          minimumSize: const Size(64, 56),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: c.primarioTexto,
          side: BorderSide(color: c.primarioTexto, width: 1.5),
          minimumSize: const Size(64, 52),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(26),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: c.primarioTexto),
      ),
      cardTheme: CardThemeData(
        elevation: sombraTarjetas ? 2 : 0,
        shadowColor: sombraTarjetas
            ? c.texto.withValues(alpha: 0.12)
            : Colors.transparent,
        surfaceTintColor: Colors.transparent,
        // Tarjeta de vidrio: superficie translúcida con un borde claro.
        color: brillo == Brightness.dark
            ? c.superficie
            : c.superficie.withValues(alpha: 0.78),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: brillo == Brightness.dark
              ? BorderSide.none
              : const BorderSide(color: Color(0xCCFFFFFF)),
        ),
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
        // Filtros del Mapa y Servicios: el seleccionado lleva borde primario.
        side: WidgetStateBorderSide.resolveWith(
          (estados) => estados.contains(WidgetState.selected)
              ? BorderSide(color: c.primario, width: 1.5)
              : BorderSide.none,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
      // La pestaña seleccionada se marca con el primario sólido para que se
      // distinga bien en pantallas OLED con brillo bajo.
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: c.superficie,
        indicatorColor: c.primario,
        iconTheme: WidgetStateProperty.resolveWith(
          (estados) => IconThemeData(
            color: estados.contains(WidgetState.selected)
                ? c.sobrePrimario
                : c.textoSecundario,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (estados) => estados.contains(WidgetState.selected)
              ? TextStyle(
                  color: c.texto,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                )
              : TextStyle(color: c.textoSecundario, fontSize: 12),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: c.superficie,
        selectedItemColor: c.primario,
        unselectedItemColor: c.textoSecundario,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: c.superficie,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: c.superficie,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.superficieAlta,
        hintStyle: TextStyle(color: c.textoSecundario),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
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
