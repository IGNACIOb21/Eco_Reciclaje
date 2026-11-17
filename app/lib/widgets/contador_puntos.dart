import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/elevacion.dart';
import '../theme/movimiento.dart';
import '../theme/tipografia.dart';

/// Píldora con la estrella dorada y los Rebin Points. Cuando el número sube,
/// "rueda" hasta el valor nuevo y la píldora hace un pequeño pop. Con
/// "reducir animaciones" salta directo al valor final. Se anuncia a los
/// lectores de pantalla cada vez que cambia.
class ContadorPuntos extends StatefulWidget {
  final int puntos;

  const ContadorPuntos({super.key, required this.puntos});

  @override
  State<ContadorPuntos> createState() => _ContadorPuntosState();
}

class _ContadorPuntosState extends State<ContadorPuntos>
    with TickerProviderStateMixin {
  late final AnimationController _rueda = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 400),
  );
  late final AnimationController _pop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 320),
  );
  late int _desde = widget.puntos;
  late int _hasta = widget.puntos;

  int get _mostrado =>
      (_desde + (_hasta - _desde) * Movimiento.entrar.transform(_rueda.value))
          .round();

  @override
  void didUpdateWidget(ContadorPuntos anterior) {
    super.didUpdateWidget(anterior);
    if (anterior.puntos == widget.puntos) return;
    if (Movimiento.reducido(context)) {
      _desde = _hasta = widget.puntos;
      _rueda.value = 1;
      return;
    }
    _desde = _mostrado;
    _hasta = widget.puntos;
    _rueda.forward(from: 0);
    if (widget.puntos > anterior.puntos) _pop.forward(from: 0);
  }

  @override
  void dispose() {
    _rueda.dispose();
    _pop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    return Semantics(
      liveRegion: true,
      label: '${widget.puntos} Rebin Points',
      child: ExcludeSemantics(
        child: AnimatedBuilder(
          animation: Listenable.merge([_rueda, _pop]),
          builder: (_, _) {
            // 1 → 1,12 → 1 con la curva del pop.
            final escala = 1 + 0.12 * (1 - (2 * _pop.value - 1).abs());
            return Transform.scale(
              scale: _pop.isAnimating ? escala : 1,
              child: Container(
                height: 40,
                padding: const EdgeInsets.only(left: 10, right: 14),
                decoration: BoxDecoration(
                  color: c.superficie,
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: context.sombra(2),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.star_rounded, size: 22, color: c.recompensa),
                    const SizedBox(width: 6),
                    Text(
                      '$_mostrado',
                      style: TextStyle(
                        color: c.texto,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        fontFeatures: Tipografia.cifras,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
