import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/movimiento.dart';
import '../theme/tipografia.dart';

/// La píldora dorada "+5" que viaja en arco desde donde se ganó hasta el
/// contador. El origen y el destino se indican con `GlobalKey`, así que
/// funciona sobre cualquier pantalla. Al llegar avisa con [alLlegar] (ahí van
/// la háptica y el pop del contador).
class PuntosQueVuelan {
  PuntosQueVuelan._();

  static const Duration duracion = Duration(milliseconds: 650);

  static void lanzar(
    BuildContext context, {
    required GlobalKey desde,
    required GlobalKey hasta,
    required String texto,
    VoidCallback? alLlegar,
  }) {
    final origen = _centro(desde);
    final destino = _centro(hasta);
    final overlay = Overlay.maybeOf(context);
    if (origen == null ||
        destino == null ||
        overlay == null ||
        Movimiento.reducido(context)) {
      alLlegar?.call();
      return;
    }
    late final OverlayEntry entrada;
    entrada = OverlayEntry(
      builder: (_) => _Vuelo(
        origen: origen,
        destino: destino,
        texto: texto,
        alTerminar: () {
          entrada.remove();
          alLlegar?.call();
        },
      ),
    );
    overlay.insert(entrada);
  }

  static Offset? _centro(GlobalKey llave) {
    final caja = llave.currentContext?.findRenderObject();
    if (caja is! RenderBox || !caja.attached || !caja.hasSize) return null;
    return caja.localToGlobal(caja.size.center(Offset.zero));
  }
}

class _Vuelo extends StatefulWidget {
  final Offset origen;
  final Offset destino;
  final String texto;
  final VoidCallback alTerminar;

  const _Vuelo({
    required this.origen,
    required this.destino,
    required this.texto,
    required this.alTerminar,
  });

  @override
  State<_Vuelo> createState() => _VueloState();
}

class _VueloState extends State<_Vuelo> with SingleTickerProviderStateMixin {
  // x frena suave y y acelera tarde: la combinación dibuja el arco.
  static const Curve _curvaY = Cubic(0.5, 0.0, 0.9, 0.6);

  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: PuntosQueVuelan.duracion,
  );

  @override
  void initState() {
    super.initState();
    _c.addStatusListener((estado) {
      if (estado == AnimationStatus.completed) widget.alTerminar();
    });
    _c.forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colores = context.colores;
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, _) {
          final t = _c.value;
          final x = Offset.lerp(
            widget.origen,
            widget.destino,
            Movimiento.entrar.transform(t),
          )!.dx;
          final y = Offset.lerp(
            widget.origen,
            widget.destino,
            _curvaY.transform(t),
          )!.dy;
          final escala = 1 - 0.45 * t;
          final opacidad = t < 0.7
              ? 1.0
              : (1 - (t - 0.7) / 0.3).clamp(0.0, 1.0);
          return Stack(
            children: [
              Positioned(
                left: x,
                top: y,
                child: FractionalTranslation(
                  translation: const Offset(-0.5, -0.5),
                  child: Opacity(
                    opacity: opacidad,
                    child: Transform.scale(
                      scale: escala,
                      child: Container(
                        height: 40,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: colores.recompensa,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: colores.recompensaTexto),
                        ),
                        child: Text(
                          widget.texto,
                          style: TextStyle(
                            color: colores.sobreRecompensa,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            fontFeatures: Tipografia.cifras,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
