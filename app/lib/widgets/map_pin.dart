import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/material_type.dart';

/// Pin de mapa: un solo material muestra su ícono sobre un círculo de color;
/// varios materiales dividen el círculo en secciones de color con un ícono
/// genérico de reciclaje al centro.
class MapPin extends StatelessWidget {
  final List<TipoMaterial> materiales;
  final bool seleccionado;
  final VoidCallback onTap;

  const MapPin({
    super.key,
    required this.materiales,
    required this.onTap,
    this.seleccionado = false,
  });

  static const double _tamano = 44;

  @override
  Widget build(BuildContext context) {
    final esMultiple = materiales.length > 1;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedScale(
        scale: seleccionado ? 1.15 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: Container(
          width: _tamano,
          height: _tamano,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: ClipOval(
            child: esMultiple
                ? CustomPaint(
                    painter: _SeccionesPainter(materiales),
                    child: const Center(
                      child: Icon(
                        Icons.recycling,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  )
                : Container(
                    color: materiales.first.color,
                    child: Icon(
                      materiales.first.icono,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class _SeccionesPainter extends CustomPainter {
  final List<TipoMaterial> materiales;

  _SeccionesPainter(this.materiales);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final anguloPorSeccion = 2 * math.pi / materiales.length;

    for (var i = 0; i < materiales.length; i++) {
      final paint = Paint()..color = materiales[i].color;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2 + i * anguloPorSeccion,
        anguloPorSeccion,
        true,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SeccionesPainter oldDelegate) =>
      oldDelegate.materiales != materiales;
}
