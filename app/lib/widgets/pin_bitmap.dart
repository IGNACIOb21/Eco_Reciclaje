import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../models/material_type.dart';

/// Versión en imagen (PNG) de [MapPin] para Mapbox, que no acepta widgets
/// como marcadores (`PointAnnotationOptions.image`): un material muestra su ícono sobre un círculo de color;
/// varios dividen el círculo en secciones con el ícono de reciclaje al centro.
///
/// Se cachea por combinación de materiales + selección, así que un mapa con
/// decenas de puntos dibuja solo unas pocas imágenes distintas.
class PinBitmaps {
  PinBitmaps._();

  static const double _tamano = 44;
  static const double _escalaSeleccionado = 1.25;

  static final Map<String, Future<Uint8List>> _cache = {};

  static Future<Uint8List> de(
    List<TipoMaterial> materiales, {
    required bool seleccionado,
    required double pixelRatio,
  }) {
    final clave =
        '${materiales.map((m) => m.name).join(',')}|$seleccionado|$pixelRatio';
    return _cache.putIfAbsent(
      clave,
      () => _dibujar(materiales, seleccionado, pixelRatio),
    );
  }

  static Future<Uint8List> _dibujar(
    List<TipoMaterial> materiales,
    bool seleccionado,
    double pixelRatio,
  ) async {
    final lado = _tamano * (seleccionado ? _escalaSeleccionado : 1);
    // Margen para la sombra, que cae hacia abajo.
    const margen = 6.0;
    final ancho = lado + margen * 2;
    final alto = lado + margen * 2;

    final grabadora = ui.PictureRecorder();
    final canvas = Canvas(grabadora)..scale(pixelRatio);
    final centro = Offset(ancho / 2, margen + lado / 2);
    final radio = lado / 2;

    canvas.drawCircle(
      centro.translate(0, 3),
      radio,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
    canvas.drawCircle(centro, radio, Paint()..color = Colors.white);

    final interior = radio - 3;
    final rect = Rect.fromCircle(center: centro, radius: interior);
    final lista = materiales.isEmpty ? [TipoMaterial.vidrio] : materiales;
    final porSeccion = 2 * math.pi / lista.length;
    for (var i = 0; i < lista.length; i++) {
      canvas.drawArc(
        rect,
        -math.pi / 2 + i * porSeccion,
        porSeccion,
        true,
        Paint()..color = lista[i].color,
      );
    }

    final icono = lista.length > 1 ? Icons.recycling : lista.first.icono;
    final escala = seleccionado ? _escalaSeleccionado : 1.0;
    final texto = TextPainter(
      textDirection: TextDirection.ltr,
      text: TextSpan(
        text: String.fromCharCode(icono.codePoint),
        style: TextStyle(
          fontSize: (lista.length > 1 ? 20 : 22) * escala,
          fontFamily: icono.fontFamily,
          package: icono.fontPackage,
          color: Colors.white,
        ),
      ),
    )..layout();
    texto.paint(canvas, centro - Offset(texto.width / 2, texto.height / 2));

    final imagen = await grabadora.endRecording().toImage(
      (ancho * pixelRatio).ceil(),
      (alto * pixelRatio).ceil(),
    );
    final bytes = await imagen.toByteData(format: ui.ImageByteFormat.png);
    return bytes!.buffer.asUint8List();
  }
}
