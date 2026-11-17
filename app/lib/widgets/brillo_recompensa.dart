import 'package:flutter/material.dart';

import '../theme/movimiento.dart';

/// Reflejo lento que cruza un botón de recompensa mientras hay algo por
/// reclamar. Va en bucle dentro de un `RepaintBoundary` y se detiene con
/// "reducir animaciones".
class BrilloRecompensa extends StatefulWidget {
  final Widget child;
  final double radio;

  const BrilloRecompensa({super.key, required this.child, this.radio = 30});

  @override
  State<BrilloRecompensa> createState() => _BrilloRecompensaState();
}

class _BrilloRecompensaState extends State<BrilloRecompensa>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: Movimiento.brillo,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (Movimiento.reducido(context)) {
      _c.stop();
    } else if (!_c.isAnimating) {
      _c.repeat();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (Movimiento.reducido(context)) return widget.child;
    return RepaintBoundary(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.radio),
        // passthrough: el botón conserva el ancho que le da su padre (sin
        // esto el Stack lo achicaba al tamaño de su texto).
        child: Stack(
          fit: StackFit.passthrough,
          children: [
            widget.child,
            Positioned.fill(
              child: IgnorePointer(
                child: LayoutBuilder(
                  builder: (_, caja) => AnimatedBuilder(
                    animation: _c,
                    builder: (_, _) {
                      // Cruza de izquierda a derecha en la primera mitad del
                      // ciclo y descansa en la segunda.
                      final t = (_c.value * 2).clamp(0.0, 1.0);
                      final ancho = caja.maxWidth * 0.35;
                      return Transform.translate(
                        offset: Offset(-ancho + (caja.maxWidth + ancho) * t, 0),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: SizedBox(
                            width: ancho,
                            height: double.infinity,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.white.withValues(alpha: 0),
                                    Colors.white.withValues(alpha: 0.35),
                                    Colors.white.withValues(alpha: 0),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
