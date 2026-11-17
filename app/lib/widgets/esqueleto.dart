import 'package:flutter/material.dart';

import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_theme.dart';
import '../theme/movimiento.dart';

/// Esqueleto de carga: bloques del color `superficieAlta` que laten despacio
/// mientras llegan los datos, en vez de una rueda girando. El latido va dentro
/// de un `RepaintBoundary` y se detiene con "reducir animaciones".
class Esqueleto extends StatefulWidget {
  final Widget child;

  const Esqueleto({super.key, required this.child});

  @override
  State<Esqueleto> createState() => _EsqueletoState();
}

class _EsqueletoState extends State<Esqueleto>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
    lowerBound: 0.4,
    upperBound: 0.8,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (Movimiento.reducido(context)) {
      _c.value = 0.6;
    } else if (!_c.isAnimating) {
      _c.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Cargando',
    liveRegion: true,
    child: ExcludeSemantics(
      child: RepaintBoundary(
        child: FadeTransition(opacity: _c, child: widget.child),
      ),
    ),
  );
}

/// Un bloque gris del esqueleto.
class BloqueEsqueleto extends StatelessWidget {
  final double alto;
  final double? ancho;
  final double radio;

  const BloqueEsqueleto({
    super.key,
    required this.alto,
    this.ancho,
    this.radio = AppRadius.md,
  });

  @override
  Widget build(BuildContext context) => Container(
    width: ancho,
    height: alto,
    decoration: BoxDecoration(
      color: context.colores.superficieAlta,
      borderRadius: BorderRadius.circular(radio),
    ),
  );
}

/// Esqueleto de una lista: un título corto y [filas] tarjetas de [altoFila].
/// Con [desplazable] en false se arma como columna (para ponerlo dentro de
/// otra lista).
class EsqueletoLista extends StatelessWidget {
  final int filas;
  final double altoFila;
  final bool conTitulo;
  final bool desplazable;
  final EdgeInsetsGeometry padding;

  const EsqueletoLista({
    super.key,
    this.filas = 4,
    this.altoFila = 110,
    this.conTitulo = true,
    this.desplazable = true,
    this.padding = const EdgeInsets.fromLTRB(
      AppSpacing.md,
      AppSpacing.sm,
      AppSpacing.md,
      AppSpacing.xl,
    ),
  });

  @override
  Widget build(BuildContext context) {
    final hijos = [
      if (conTitulo) ...[
        const BloqueEsqueleto(alto: 16, ancho: 180),
        const SizedBox(height: AppSpacing.sm),
      ],
      for (var i = 0; i < filas; i++) ...[
        BloqueEsqueleto(alto: altoFila),
        const SizedBox(height: AppSpacing.xs),
      ],
    ];
    return Esqueleto(
      child: desplazable
          ? ListView(padding: padding, children: hijos)
          : Padding(
              padding: padding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: hijos,
              ),
            ),
    );
  }
}
