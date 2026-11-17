import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recircula/theme/app_theme.dart';

double _lum(Color c) {
  double canal(double v) =>
      v <= 0.03928 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * canal(c.r) + 0.7152 * canal(c.g) + 0.0722 * canal(c.b);
}

double _contraste(Color a, Color b) {
  final la = _lum(a), lb = _lum(b);
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

void main() {
  // Cada par es (texto, fondo, mínimo). 4,5 para texto normal; 3 para lo que
  // se lee grande o es un borde (WCAG AA).
  for (final (nombre, tema) in [
    ('claro', AppTheme.light),
    ('Eco', AppTheme.eco),
  ]) {
    test('los pares de color del modo $nombre cumplen el contraste', () {
      final c = tema.extension<ColoresApp>()!;
      final pares = <String, (Color, Color, double)>{
        'texto/fondo': (c.texto, c.fondo, 4.5),
        'texto/superficie': (c.texto, c.superficie, 4.5),
        'textoSecundario/fondo': (c.textoSecundario, c.fondo, 4.5),
        'textoSecundario/superficie': (c.textoSecundario, c.superficie, 4.5),
        'primarioTexto/fondo': (c.primarioTexto, c.fondo, 4.5),
        'primarioTexto/primarioSuave': (c.primarioTexto, c.primarioSuave, 4.5),
        'sobrePrimario/primario': (c.sobrePrimario, c.primario, 4.5),
        'recompensaTexto/fondo': (c.recompensaTexto, c.fondo, 4.5),
        'sobreRecompensa/recompensa': (c.sobreRecompensa, c.recompensa, 4.5),
        'sobreAlerta/alerta': (c.sobreAlerta, c.alerta, 4.5),
        'alertaTexto/alertaSuave': (c.alertaTexto, c.alertaSuave, 4.5),
        'advertencia/advertenciaSuave': (
          c.advertencia,
          c.advertenciaSuave,
          4.5,
        ),
        'infoTexto/infoSuave': (c.infoTexto, c.infoSuave, 4.5),
        'textoSecundario/deshabilitado': (
          c.textoSecundario,
          c.deshabilitado,
          4.5,
        ),
        'primario/fondo (relleno)': (c.primario, c.fondo, 3),
      };
      final fallos = <String>[];
      pares.forEach((nombre, p) {
        final r = _contraste(p.$1, p.$2);
        if (r < p.$3) {
          fallos.add('$nombre: ${r.toStringAsFixed(2)}:1 (mínimo ${p.$3})');
        }
      });
      expect(fallos, isEmpty);
    });
  }
}
