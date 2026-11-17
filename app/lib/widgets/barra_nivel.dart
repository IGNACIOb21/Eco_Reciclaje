import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/movimiento.dart';

/// Barra de avance hacia el siguiente nivel. Cuando el progreso sube, se
/// llena en 650 ms, destella en la punta y suelta 6 partículas (dibujadas en
/// un solo `CustomPainter`, nunca un widget por partícula). Con "reducir
/// animaciones" salta al valor final sin destello.
class BarraNivel extends StatefulWidget {
  /// Entre 0 y 1.
  final double progreso;
  final double alto;

  const BarraNivel({super.key, required this.progreso, this.alto = 12});

  @override
  State<BarraNivel> createState() => _BarraNivelState();
}

class _BarraNivelState extends State<BarraNivel> with TickerProviderStateMixin {
  late final AnimationController _llenado = AnimationController(
    vsync: this,
    duration: Movimiento.celebracion,
  );
  late final AnimationController _destello = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
  );
  late double _desde = widget.progreso.clamp(0, 1);
  late double _hasta = _desde;

  double get _actual =>
      _desde + (_hasta - _desde) * Movimiento.entrar.transform(_llenado.value);

  @override
  void didUpdateWidget(BarraNivel anterior) {
    super.didUpdateWidget(anterior);
    final nuevo = widget.progreso.clamp(0.0, 1.0);
    if (nuevo == _hasta) return;
    if (Movimiento.reducido(context)) {
      _desde = _hasta = nuevo;
      _llenado.value = 1;
      return;
    }
    _desde = _actual;
    _hasta = nuevo;
    _llenado.forward(from: 0);
    if (nuevo > _desde) _destello.forward(from: 0);
  }

  @override
  void dispose() {
    _llenado.dispose();
    _destello.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    return Semantics(
      label: 'Avance de nivel',
      value: '${(widget.progreso.clamp(0.0, 1.0) * 100).round()} %',
      child: ExcludeSemantics(
        child: SizedBox(
          height: widget.alto,
          child: AnimatedBuilder(
            animation: Listenable.merge([_llenado, _destello]),
            builder: (_, _) => CustomPaint(
              painter: _PintorBarra(
                progreso: _actual,
                destello: _destello.isAnimating ? _destello.value : 0,
                fondo: c.primarioSuave,
                relleno: c.primario,
                particula: c.recompensa,
              ),
              size: Size.infinite,
            ),
          ),
        ),
      ),
    );
  }
}

class _PintorBarra extends CustomPainter {
  final double progreso;
  final double destello;
  final Color fondo;
  final Color relleno;
  final Color particula;

  const _PintorBarra({
    required this.progreso,
    required this.destello,
    required this.fondo,
    required this.relleno,
    required this.particula,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final radio = Radius.circular(size.height / 2);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, radio),
      Paint()..color = fondo,
    );
    final ancho = size.width * progreso;
    if (ancho <= 0) return;
    final barra = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, math.max(ancho, size.height), size.height),
      radio,
    );
    canvas.drawRRect(barra, Paint()..color = relleno);
    if (destello > 0) {
      // Destello blanco que se apaga en el primer cuarto.
      final alfa = destello < 0.25
          ? destello / 0.25 * 0.85
          : 0.85 * (1 - (destello - 0.25) / 0.75);
      canvas.drawRRect(
        barra,
        Paint()..color = Colors.white.withValues(alpha: alfa.clamp(0.0, 1.0)),
      );
      // 6 partículas que salen de la punta.
      const dir = [
        Offset(-14, -16),
        Offset(0, -22),
        Offset(14, -15),
        Offset(20, -2),
        Offset(-20, -4),
        Offset(8, 14),
      ];
      final p = Curves.easeOutCubic.transform(destello);
      final punta = Offset(math.max(ancho, size.height / 2), size.height / 2);
      for (var i = 0; i < dir.length; i++) {
        canvas.drawCircle(
          punta + dir[i] * p,
          2.5 * (1 - 0.7 * p),
          Paint()
            ..color = (i.isOdd ? relleno : particula).withValues(
              alpha: (1 - p).clamp(0.0, 1.0),
            ),
        );
      }
    }
  }

  @override
  bool shouldRepaint(_PintorBarra v) =>
      v.progreso != progreso || v.destello != destello || v.fondo != fondo;
}
