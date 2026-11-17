import 'dart:math' as math;

import 'package:flutter/material.dart';

/// El logo de la app (el mismo del ícono del teléfono): un tacho verde con
/// las flechas de reciclaje, tapa oscura y una hoja encima. Se dibuja en
/// vectores para que se vea nítido a cualquier tamaño.
///
/// [tMs] anima la entrada: sube el tacho (0–600 ms), giran las flechas
/// (250–850 ms) y brota la hoja (650–1000 ms). Con `tMs >= 1000` queda
/// completo.
class LogoAppPainter extends CustomPainter {
  final double tMs;

  LogoAppPainter({this.tMs = 1000});

  static const tapa = Color(0xFF0F5B2E);
  static const cuerpo = Color(0xFF138046);
  static const hoja = Color(0xFFA6DC3E);
  static const flechas = Colors.white;

  static double _tramo(double t, double desde, double dura) =>
      ((t - desde) / dura).clamp(0.0, 1.0);

  @override
  void paint(Canvas canvas, Size size) {
    // Coordenadas del diseño original del ícono (1024 × 1024), recortadas a
    // la zona del tacho: x 290..734, y 230..790.
    const ox = 290.0, oy = 230.0, ancho = 444.0, alto = 560.0;
    final escala = math.min(size.width / ancho, size.height / alto);
    canvas.translate(
      (size.width - ancho * escala) / 2,
      (size.height - alto * escala) / 2,
    );
    canvas.scale(escala);
    canvas.translate(-ox, -oy);

    final pTacho = Curves.easeOutBack.transform(_tramo(tMs, 0, 600));
    final pFlechas = Curves.easeOutCubic.transform(_tramo(tMs, 250, 600));
    final pHoja = Curves.elasticOut.transform(_tramo(tMs, 650, 350));
    if (pTacho <= 0) return;

    // El tacho sube desde abajo y crece un poco.
    canvas.save();
    const base = Offset(512, 771);
    canvas.translate(base.dx, base.dy + 40 * (1 - pTacho));
    canvas.scale(0.85 + 0.15 * pTacho);
    canvas.translate(-base.dx, -base.dy);
    final opacidad = _tramo(tMs, 0, 200);
    Paint pintura(Color c) =>
        Paint()..color = c.withValues(alpha: c.a * opacidad);

    // Cuerpo: trapecio con las esquinas de abajo redondeadas.
    canvas.drawPath(
      Path()
        ..moveTo(353, 459)
        ..lineTo(671, 459)
        ..lineTo(646, 735)
        ..quadraticBezierTo(643, 771, 607, 771)
        ..lineTo(417, 771)
        ..quadraticBezierTo(381, 771, 378, 735)
        ..close(),
      pintura(cuerpo),
    );

    // Tapa.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTRB(310, 380, 714, 438),
        const Radius.circular(29),
      ),
      pintura(tapa),
    );

    // Hoja sobre la tapa, brota desde su base.
    if (pHoja > 0) {
      canvas.save();
      const raiz = Offset(514, 376);
      canvas.translate(raiz.dx, raiz.dy);
      canvas.scale(pHoja);
      canvas.translate(-raiz.dx, -raiz.dy);
      canvas.drawPath(
        Path()
          ..moveTo(514, 376)
          ..cubicTo(500, 300, 540, 252, 628, 251)
          ..cubicTo(630, 330, 590, 384, 514, 376)
          ..close(),
        pintura(hoja),
      );
      canvas.restore();
    }

    // Flechas de reciclaje: dos arcos con punta, girando al entrar.
    if (pFlechas > 0) {
      const centro = Offset(512, 592);
      const radio = 84.0;
      canvas.save();
      canvas.translate(centro.dx, centro.dy);
      canvas.rotate(-math.pi * (1 - pFlechas));
      final trazo = Paint()
        ..color = flechas.withValues(alpha: opacidad * pFlechas)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 28
        ..strokeCap = StrokeCap.round;
      final punta = Paint()
        ..color = flechas.withValues(alpha: opacidad * pFlechas);
      for (final inicio in [200.0, 20.0]) {
        const barrido = 125.0;
        final a0 = inicio * math.pi / 180;
        final a1 = (inicio + barrido) * math.pi / 180;
        canvas.drawArc(
          Rect.fromCircle(center: Offset.zero, radius: radio),
          a0,
          a1 - a0,
          false,
          trazo,
        );
        // Punta en el extremo, mirando en el sentido del giro.
        final fin = Offset(math.cos(a1), math.sin(a1)) * radio;
        final tangente = Offset(-math.sin(a1), math.cos(a1));
        final normal = Offset(math.cos(a1), math.sin(a1));
        canvas.drawPath(
          Path()
            ..moveTo(fin.dx + tangente.dx * 44, fin.dy + tangente.dy * 44)
            ..lineTo(fin.dx + normal.dx * 34, fin.dy + normal.dy * 34)
            ..lineTo(fin.dx - normal.dx * 34, fin.dy - normal.dy * 34)
            ..close(),
          punta,
        );
      }
      canvas.restore();
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(LogoAppPainter old) => old.tMs != tMs;
}
