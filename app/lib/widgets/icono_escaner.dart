import 'package:flutter/material.dart';

/// Ícono de escáner de QR (cuatro esquinas y una línea al centro), dibujado en
/// código para que coincida con el del diseño.
class IconoEscaner extends StatelessWidget {
  final double tamano;
  final Color color;

  const IconoEscaner({super.key, this.tamano = 30, required this.color});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(tamano),
      painter: _IconoEscanerPainter(color),
    );
  }
}

class _IconoEscanerPainter extends CustomPainter {
  final Color color;

  const _IconoEscanerPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final k = size.width / 24;
    canvas.scale(k, k);
    final trazo = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = color;
    const r = Radius.circular(1);
    final camino = Path()
      ..moveTo(4, 8)
      ..lineTo(4, 5)
      ..arcToPoint(const Offset(5, 4), radius: r)
      ..lineTo(8, 4)
      ..moveTo(16, 4)
      ..lineTo(19, 4)
      ..arcToPoint(const Offset(20, 5), radius: r)
      ..lineTo(20, 8)
      ..moveTo(20, 16)
      ..lineTo(20, 19)
      ..arcToPoint(const Offset(19, 20), radius: r)
      ..lineTo(16, 20)
      ..moveTo(8, 20)
      ..lineTo(5, 20)
      ..arcToPoint(const Offset(4, 19), radius: r)
      ..lineTo(4, 16)
      ..moveTo(8, 12)
      ..lineTo(16, 12);
    canvas.drawPath(camino, trazo);
  }

  @override
  bool shouldRepaint(_IconoEscanerPainter viejo) => viejo.color != color;
}
