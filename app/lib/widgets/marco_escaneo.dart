import 'package:flutter/material.dart';

/// Marco de encuadre tipo lector QR: oscurece todo menos un cuadrado central
/// y marca sus cuatro esquinas.
class MarcoEscaneo extends StatelessWidget {
  final double lado;
  final Color color;

  const MarcoEscaneo({super.key, required this.lado, required this.color});

  /// Recuadro del marco dentro de un área de [tamano], para limitar la
  /// detección del escáner a lo que se ve encuadrado.
  static Rect recuadro(Size tamano, double lado) => Rect.fromCenter(
    center: tamano.center(Offset.zero),
    width: lado,
    height: lado,
  );

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        size: Size.infinite,
        painter: _MarcoPainter(lado: lado, color: color),
      ),
    );
  }
}

class _MarcoPainter extends CustomPainter {
  final double lado;
  final Color color;

  _MarcoPainter({required this.lado, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = MarcoEscaneo.recuadro(size, lado);
    const radio = Radius.circular(20);

    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(Offset.zero & size),
        Path()..addRRect(RRect.fromRectAndRadius(rect, radio)),
      ),
      Paint()..color = Colors.black.withValues(alpha: 0.55),
    );

    final trazo = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    const largo = 34.0;
    const r = 20.0;
    for (final (esquina, dx, dy) in [
      (rect.topLeft, 1.0, 1.0),
      (rect.topRight, -1.0, 1.0),
      (rect.bottomLeft, 1.0, -1.0),
      (rect.bottomRight, -1.0, -1.0),
    ]) {
      canvas.drawPath(
        Path()
          ..moveTo(esquina.dx, esquina.dy + dy * largo)
          ..lineTo(esquina.dx, esquina.dy + dy * r)
          ..quadraticBezierTo(
            esquina.dx,
            esquina.dy,
            esquina.dx + dx * r,
            esquina.dy,
          )
          ..lineTo(esquina.dx + dx * largo, esquina.dy),
        trazo,
      );
    }
  }

  @override
  bool shouldRepaint(_MarcoPainter anterior) =>
      anterior.lado != lado || anterior.color != color;
}
