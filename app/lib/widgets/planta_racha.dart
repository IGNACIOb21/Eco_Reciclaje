import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/movimiento.dart';

/// Planta en maceta con una hoja por cada día de racha (se dibujan hasta
/// [maxHojas]). Al entrar las hojas aparecen una tras otra; con "reducir
/// animaciones" ya están dibujadas.
class PlantaRacha extends StatefulWidget {
  final int dias;
  final double tamano;

  static const maxHojas = 14;

  const PlantaRacha({super.key, required this.dias, this.tamano = 140});

  @override
  State<PlantaRacha> createState() => _PlantaRachaState();
}

class _PlantaRachaState extends State<PlantaRacha>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this);

  int get _hojas => math.min(widget.dias, PlantaRacha.maxHojas);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (Movimiento.reducido(context)) {
      _c.value = 1;
    } else if (!_c.isAnimating && _c.value == 0) {
      // Una pausa de cascada por hoja, más lo que tarda la última en abrirse.
      _c.duration = Movimiento.cascada * _hojas + Movimiento.transicion;
      _c.forward();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colores = context.colores;
    return Semantics(
      label: 'Planta con ${widget.dias} hojas',
      child: ExcludeSemantics(
        child: RepaintBoundary(
          child: AnimatedBuilder(
            animation: _c,
            builder: (_, _) => CustomPaint(
              size: Size.square(widget.tamano),
              painter: _PintorPlanta(
                hojas: _hojas,
                progreso: Curves.easeOut.transform(_c.value),
                hoja: colores.primario,
                tallo: colores.primarioTexto,
                maceta: colores.advertencia,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PintorPlanta extends CustomPainter {
  final int hojas;
  final double progreso;
  final Color hoja;
  final Color tallo;
  final Color maceta;

  const _PintorPlanta({
    required this.hojas,
    required this.progreso,
    required this.hoja,
    required this.tallo,
    required this.maceta,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final base = Offset(w / 2, h * 0.78);

    // Maceta.
    final macetaPath = Path()
      ..moveTo(w * 0.30, h * 0.78)
      ..lineTo(w * 0.70, h * 0.78)
      ..lineTo(w * 0.64, h * 0.97)
      ..lineTo(w * 0.36, h * 0.97)
      ..close();
    canvas.drawPath(
      macetaPath,
      Paint()..color = maceta.withValues(alpha: 0.85),
    );
    canvas.drawRect(
      Rect.fromLTWH(w * 0.27, h * 0.74, w * 0.46, h * 0.05),
      Paint()..color = maceta,
    );

    // Tallo: crece con las hojas.
    final alto = h * 0.62;
    final punta = Offset(base.dx, base.dy - alto);
    canvas.drawLine(
      base,
      punta,
      Paint()
        ..color = tallo
        ..strokeWidth = w * 0.025
        ..strokeCap = StrokeCap.round,
    );

    // Hojas alternadas a izquierda y derecha, de abajo hacia arriba.
    final visibles = hojas * progreso;
    for (var i = 0; i < hojas; i++) {
      final t = (visibles - i).clamp(0.0, 1.0);
      if (t == 0) continue;
      final lado = i.isEven ? -1.0 : 1.0;
      final y = base.dy - alto * (0.12 + 0.88 * (i + 1) / (hojas + 1));
      final largo = w * 0.22 * t;
      canvas.save();
      canvas.translate(base.dx, y);
      canvas.rotate(lado * -0.7);
      final path = Path()
        ..moveTo(0, 0)
        ..quadraticBezierTo(lado * largo * 0.5, -largo * 0.45, lado * largo, 0)
        ..quadraticBezierTo(lado * largo * 0.5, largo * 0.35, 0, 0);
      canvas.drawPath(path, Paint()..color = hoja);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_PintorPlanta v) =>
      v.hojas != hojas ||
      v.progreso != progreso ||
      v.hoja != hoja ||
      v.tallo != tallo ||
      v.maceta != maceta;
}
