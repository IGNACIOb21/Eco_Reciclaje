import 'package:flutter/material.dart';

import 'app_theme.dart';

/// Paletas de color extra (además del claro y el Modo Eco de AppTheme),
/// pensadas para mejorar el contraste en pantallas OLED como la del S24.
class AppThemes {
  AppThemes._();

  /// 1. Bosque Cyber: negro mate para OLED, verde neón como primario y
  /// amarillo cítrico para alertas y "no reciclable".
  static const ColoresApp bosqueCyber = ColoresApp(
    primario: Color(0xFF00FF87),
    acento: Color(0xFFB7FF00),
    secundario: Color(0xFF00FF87),
    fondoSecundario: Color(0xFF1F3324),
    fondo: Color(0xFF0C0F0A),
    superficie: Color(0xFF18241B),
    superficieAlta: Color(0xFF223326),
    texto: Color(0xFFF1F5F9),
    textoSecundario: Color(0xFFA7B8AB),
    borde: Color(0xFF2E4433),
    fondoMapa: Color(0xFF142018),
    sobrePrimario: Color(0xFF0C0F0A),
    alerta: Color(0xFFB7FF00),
    primarioTexto: Color(0xFF00FF87),
    primarioSuave: Color(0xFF1F3324),
    recompensa: Color(0xFFE2B85C),
    recompensaTexto: Color(0xFFE2B85C),
    recompensaSuave: Color(0xFF3A3418),
    alertaSuave: Color(0xFF3B2A24),
    alertaTexto: Color(0xFFE39274),
    advertencia: Color(0xFFE9A86A),
    advertenciaSuave: Color(0xFF3A3220),
    info: Color(0xFF7FB3D1),
    infoSuave: Color(0xFF1F3A45),
    infoTexto: Color(0xFFBFDCEC),
    sobreAlerta: Color(0xFF0C0F0A),
    sobreRecompensa: Color(0xFF0C0F0A),
    deshabilitado: Color(0xFF223326),
  );

  /// 2. Tierra & Terracota: verde orgánico suave, salvia para la barra
  /// inferior y los filtros, terracota para detalles.
  static const ColoresApp terracota = ColoresApp(
    primario: Color(0xFF87A987),
    acento: Color(0xFFC67D5A),
    secundario: Color(0xFF9A5536),
    fondoSecundario: Color(0xFFF1DED3),
    fondo: Color(0xFFC2D6B9),
    superficie: Color(0xFFE2E8DD),
    superficieAlta: Color(0xFFD2DFCB),
    texto: Color(0xFF1C2826),
    textoSecundario: Color(0xFF4A5A55),
    borde: Color(0xFFADC2A4),
    fondoMapa: Color(0xFFD6E3CF),
    sobrePrimario: Color(0xFF1C2826),
    alerta: Color(0xFFA9492B),
    primarioTexto: Color(0xFF2F5D3A),
    primarioSuave: Color(0xFFD2DFCB),
    recompensa: Color(0xFFE2B85C),
    recompensaTexto: Color(0xFF7A560F),
    recompensaSuave: Color(0xFFF6E8C2),
    alertaSuave: Color(0xFFF2DDD5),
    alertaTexto: Color(0xFF8A3A22),
    advertencia: Color(0xFF8F5409),
    advertenciaSuave: Color(0xFFF1E4CC),
    info: Color(0xFF2F6585),
    infoSuave: Color(0xFFDCE7EE),
    infoTexto: Color(0xFF1F4A63),
    sobreAlerta: Color(0xFFFFFFFF),
    sobreRecompensa: Color(0xFF1C2826),
    deshabilitado: Color(0xFFD2DFCB),
  );

  /// 3. Azul Nórdico: gris azulado claro, tarjetas blancas con sombra suave,
  /// azul marino para títulos y acciones, gris acero para íconos.
  static const ColoresApp nordico = ColoresApp(
    primario: Color(0xFF1B3A4B),
    acento: Color(0xFF90A4AE),
    secundario: Color(0xFF1B3A4B),
    fondoSecundario: Color(0xFFDCE6EC),
    fondo: Color(0xFFECEFF1),
    superficie: Colors.white,
    superficieAlta: Color(0xFFE3E8EB),
    texto: Color(0xFF0D1F2D),
    textoSecundario: Color(0xFF546E7A),
    borde: Color(0xFFCFD8DC),
    fondoMapa: Color(0xFFE3E9ED),
    sobrePrimario: Colors.white,
    alerta: Color(0xFFC0392B),
    primarioTexto: Color(0xFF1B3A4B),
    primarioSuave: Color(0xFFDCE6EC),
    recompensa: Color(0xFFE2B85C),
    recompensaTexto: Color(0xFF7A560F),
    recompensaSuave: Color(0xFFF6E8C2),
    alertaSuave: Color(0xFFF5DCD8),
    alertaTexto: Color(0xFF9B2D21),
    advertencia: Color(0xFF8F5409),
    advertenciaSuave: Color(0xFFF1E4CC),
    info: Color(0xFF2F6585),
    infoSuave: Color(0xFFDCE6EC),
    infoTexto: Color(0xFF1B3A4B),
    sobreAlerta: Color(0xFFFFFFFF),
    sobreRecompensa: Color(0xFF0D1F2D),
    deshabilitado: Color(0xFFE3E8EB),
  );

  static ThemeData get cyberForestTheme =>
      AppTheme.construir(bosqueCyber, Brightness.dark);

  static ThemeData get terracottaTheme =>
      AppTheme.construir(terracota, Brightness.light);

  static ThemeData get nordicBlueTheme =>
      AppTheme.construir(nordico, Brightness.light, sombraTarjetas: true);
}

/// Temas que se eligen en Perfil › Tema. El nombre del enum es lo que se
/// guarda en el teléfono, así que no renombrar los valores.
enum TemaApp {
  claro('Modo claro', 'Gris azulado con verdes de Rebin', null),
  bosqueCyber(
    'Bosque Cyber',
    'Negro mate con verde neón, ideal para OLED',
    AppThemes.bosqueCyber,
  ),
  eco('Modo Eco', 'Verde bosque profundo con dorado', null),
  terracota(
    'Tierra & Terracota',
    'Verde salvia orgánico con terracota',
    AppThemes.terracota,
  ),
  nordico(
    'Azul Nórdico',
    'Gris azulado limpio con azul marino',
    AppThemes.nordico,
  );

  final String nombre;
  final String descripcion;
  final ColoresApp? _paleta;

  const TemaApp(this.nombre, this.descripcion, this._paleta);

  /// Tema al instalar la app: el claro, en plomo casi blanco.
  static const porDefecto = TemaApp.claro;

  ThemeData get datos => switch (this) {
    TemaApp.bosqueCyber => AppThemes.cyberForestTheme,
    TemaApp.eco => AppTheme.eco,
    TemaApp.claro => AppTheme.light,
    TemaApp.terracota => AppThemes.terracottaTheme,
    TemaApp.nordico => AppThemes.nordicBlueTheme,
  };

  /// Paleta del tema, para mostrar su muestra de colores.
  ColoresApp get paleta => _paleta ?? datos.extension<ColoresApp>()!;

  static TemaApp? desdeNombre(String? nombre) {
    for (final tema in values) {
      if (tema.name == nombre) return tema;
    }
    return null;
  }
}
