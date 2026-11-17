import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/movimiento.dart';
import '../theme/tipografia.dart';

/// Anillo de la meta diaria. Al completarse el arco se cierra y pasa a dorado,
/// porque la meta es una recompensa. El color nunca va solo: lleva la etiqueta
/// "0/1" o "1/1" en el centro.
class AnilloMeta extends StatelessWidget {
  /// Entre 0 y 1.
  final double progreso;
  final String etiqueta;
  final double tamano;

  /// Con false el anillo completo queda en verde (lo que se puede tocar) en
  /// vez de dorado; Inicio lo usa así: la meta diaria no entrega puntos.
  final bool dorado;

  const AnilloMeta({
    super.key,
    required this.progreso,
    required this.etiqueta,
    this.tamano = 52,
    this.dorado = true,
  });

  bool get completo => progreso >= 1;

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    return Semantics(
      label: completo ? 'Meta de hoy completa' : 'Meta de hoy pendiente',
      value: etiqueta,
      child: ExcludeSemantics(
        child: SizedBox.square(
          dimension: tamano,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: progreso.clamp(0.0, 1.0)),
            duration: Movimiento.dur(context, Movimiento.celebracion),
            curve: Movimiento.entrar,
            builder: (_, v, _) => CustomPaint(
              painter: _PintorAnillo(
                progreso: v,
                pista: c.primarioSuave,
                arco: completo && dorado ? c.recompensa : c.primario,
                grosor: tamano * 8 / 72,
              ),
              child: Center(
                child: Text(
                  etiqueta,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    fontFeatures: Tipografia.cifras,
                    color: completo
                        ? (dorado ? c.recompensaTexto : c.primarioTexto)
                        : c.textoSecundario,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PintorAnillo extends CustomPainter {
  final double progreso;
  final Color pista;
  final Color arco;
  final double grosor;

  const _PintorAnillo({
    required this.progreso,
    required this.pista,
    required this.arco,
    required this.grosor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromCircle(
      center: size.center(Offset.zero),
      radius: (size.shortestSide - grosor) / 2,
    );
    final trazo = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = grosor
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, 0, 2 * math.pi, false, trazo..color = pista);
    if (progreso > 0) {
      canvas.drawArc(
        rect,
        -math.pi / 2,
        2 * math.pi * progreso,
        false,
        trazo..color = arco,
      );
    }
  }

  @override
  bool shouldRepaint(_PintorAnillo v) =>
      v.progreso != progreso || v.pista != pista || v.arco != arco;
}
