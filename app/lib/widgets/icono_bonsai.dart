import 'package:flutter/material.dart';

/// Ícono de un árbol bonsái en su maceta, dibujado a mano (Material Icons no
/// trae uno). Acompaña al saldo de Rebin Points en el Perfil.
class IconoBonsai extends StatelessWidget {
  final double size;

  /// Color de la copa; por defecto el verde principal del tema.
  final Color? color;

  const IconoBonsai({super.key, this.size = 24, this.color});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _BonsaiPainter(
        copa: color ?? Theme.of(context).colorScheme.primary,
      ),
    );
  }
}

class _BonsaiPainter extends CustomPainter {
  final Color copa;

  _BonsaiPainter({required this.copa});

  static const _madera = Color(0xFF7A4E2D);
  static const _maceta = Color(0xFFB5653A);

  @override
  void paint(Canvas canvas, Size size) {
    // Todo se dibuja en una grilla de 24 × 24 y se escala.
    canvas.scale(size.width / 24, size.height / 24);

    // Maceta: un trapecio con borde superior.
    final maceta = Paint()..color = _maceta;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(4.5, 17.5, 15, 2),
        const Radius.circular(0.8),
      ),
      maceta,
    );
    canvas.drawPath(
      Path()
        ..moveTo(6, 19.5)
        ..lineTo(18, 19.5)
        ..lineTo(16.6, 22.5)
        ..lineTo(7.4, 22.5)
        ..close(),
      maceta,
    );

    // Tronco curvo, más grueso abajo, con una rama hacia la izquierda.
    final tronco = Paint()
      ..color = _madera
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(
      Path()
        ..moveTo(12, 17.6)
        ..cubicTo(11, 15.5, 14.5, 13.5, 13, 11),
      tronco..strokeWidth = 2.2,
    );
    canvas.drawPath(
      Path()
        ..moveTo(13, 11)
        ..cubicTo(12, 9.5, 11, 8.5, 12, 6.5),
      tronco..strokeWidth = 1.6,
    );
    canvas.drawPath(
      Path()
        ..moveTo(12.4, 13.6)
        ..quadraticBezierTo(9.5, 13, 7.5, 11.5),
      tronco..strokeWidth = 1.3,
    );

    // Copa en nubes (el estilo clásico del bonsái), con un tono más claro
    // arriba para dar volumen.
    final hoja = Paint()..color = copa;
    final brillo = Paint()..color = Color.lerp(copa, Colors.white, 0.3)!;
    for (final (centro, rx, ry) in const [
      (Offset(7, 10.6), 3.4, 2.1),
      (Offset(16.4, 10), 3.6, 2.2),
      (Offset(12, 5.4), 4.6, 2.7),
    ]) {
      canvas.drawOval(
        Rect.fromCenter(center: centro, width: rx * 2, height: ry * 2),
        hoja,
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: centro.translate(-rx * 0.2, -ry * 0.35),
          width: rx * 1.1,
          height: ry * 0.8,
        ),
        brillo,
      );
    }
  }

  @override
  bool shouldRepaint(_BonsaiPainter old) => old.copa != copa;
}
