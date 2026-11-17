import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/movimiento.dart';
import '../theme/tipografia.dart';
import 'logo_app.dart';
import 'personas_reciclando.dart';

/// Animación de apertura: sobre el fondo de la app aparece el logo (el tacho
/// del ícono, con sus flechas y la hoja) y la palabra "rebin", mientras abajo
/// varias personas reciclan; luego todo se desvanece y el Inicio se asienta.
///
/// Dura 2,3 s. Si los datos aún no están listos el logo respira (sin
/// spinner), y nunca espera más de [esperaMaxima]. Con "reducir animaciones"
/// se muestra todo ya dibujado y solo se hace el fundido.
class Lanzamiento extends StatefulWidget {
  final Widget child;

  /// Cambia cuando pueden estar listos los datos de entrada.
  final Listenable? datos;

  /// true cuando la app ya puede mostrarse. Si es null, se asume lista.
  final bool Function()? datosListos;

  final Duration esperaMaxima;

  const Lanzamiento({
    super.key,
    required this.child,
    this.datos,
    this.datosListos,
    this.esperaMaxima = const Duration(seconds: 4),
  });

  static const double duracionMs = 2300;
  static const double _salidaMs = 450;

  @override
  State<Lanzamiento> createState() => _LanzamientoState();
}

class _LanzamientoState extends State<Lanzamiento>
    with TickerProviderStateMixin {
  late final AnimationController _anim;
  late final AnimationController _salida;
  late final AnimationController _respira;
  Timer? _limite;
  bool _saliendo = false;
  bool _fin = false;
  bool _reducidoAplicado = false;
  bool _reducido = false;
  bool _sostenido = false;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2300),
    )..addStatusListener((e) {
      if (e == AnimationStatus.completed) _revisar();
    });
    _salida = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    )..addStatusListener((e) {
      if (e == AnimationStatus.completed && mounted) {
        setState(() => _fin = true);
      }
    });
    _respira = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );
    widget.datos?.addListener(_revisar);
    _limite = Timer(widget.esperaMaxima, _empezarSalida);
    _anim.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reducido = Movimiento.reducido(context);
    if (!_reducidoAplicado && _reducido) {
      // Sin movimiento: el logo aparece completo y solo se hace el fundido.
      _reducidoAplicado = true;
      _anim.value = 1;
    }
  }

  @override
  void dispose() {
    _limite?.cancel();
    widget.datos?.removeListener(_revisar);
    _anim.dispose();
    _salida.dispose();
    _respira.dispose();
    super.dispose();
  }

  bool get _listo => widget.datosListos?.call() ?? true;

  void _revisar() {
    if (!mounted || _saliendo) return;
    if (_anim.status != AnimationStatus.completed) return;
    if (_reducido && !_sostenido) {
      // Sin movimiento: el logo queda a la vista un momento antes del fundido.
      _sostenido = true;
      Timer(const Duration(milliseconds: 600), _revisar);
      return;
    }
    if (_listo) {
      _empezarSalida();
    } else if (!_respira.isAnimating) {
      _respira.repeat(reverse: true);
    }
  }

  void _empezarSalida() {
    if (!mounted || _saliendo) return;
    _saliendo = true;
    _limite?.cancel();
    _respira.stop();
    _salida.forward();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _salida,
      builder: (context, hijo) {
        // El Inicio se asienta de 103 % a 100 % mientras el fondo se va.
        final asiento =
            1 + 0.03 * (1 - Movimiento.entrar.transform(_salida.value));
        return Stack(
          fit: StackFit.expand,
          children: [
            Transform.scale(
              scale: _saliendo || _fin ? asiento : 1,
              child: hijo,
            ),
            if (!_fin) _capa(context),
          ],
        );
      },
      child: widget.child,
    );
  }

  Widget _capa(BuildContext context) {
    final c = context.colores;
    final eco = Theme.of(context).brightness == Brightness.dark;
    // La palabra lleva los dos verdes del ícono: "re" oscuro y "bin" vivo.
    final oscuro = eco ? c.texto : LogoAppPainter.tapa;
    final vivo = eco ? c.primario : LogoAppPainter.cuerpo;

    final tSalida = _salida.value * Lanzamiento._salidaMs;
    final opacidad =
        1 - Movimiento.salir.transform((tSalida / 320).clamp(0.0, 1.0));
    final escalaMarca =
        1 - 0.08 * Movimiento.salir.transform((tSalida / 220).clamp(0.0, 1.0));

    return IgnorePointer(
      ignoring: _saliendo,
      child: Opacity(
        opacity: opacidad,
        child: Semantics(
          container: true,
          label: 'Rebin, cargando',
          child: Material(
            color: c.fondo,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {},
              child: AnimatedBuilder(
                animation: Listenable.merge([_anim, _respira]),
                builder: (context, _) {
                  final t = _anim.value * Lanzamiento.duracionMs;
                  final respiro =
                      1 + 0.04 * Curves.easeInOutSine.transform(_respira.value);
                  final pw = Movimiento.entrar.transform(
                    ((t - 780) / 300).clamp(0.0, 1.0),
                  );
                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      RepaintBoundary(
                        child: CustomPaint(
                          key: const Key('lanzamiento-personas'),
                          painter: PersonasReciclandoPainter(tMs: t),
                        ),
                      ),
                      Align(
                        alignment: const Alignment(0, -0.3),
                        child: Transform.scale(
                          scale: escalaMarca,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Transform.scale(
                                scale: respiro,
                                child: SizedBox(
                                  width: 150,
                                  height: 190,
                                  child: CustomPaint(
                                    key: const Key('lanzamiento-logo'),
                                    painter: LogoAppPainter(tMs: t),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 18),
                              Opacity(
                                opacity: pw,
                                child: Transform.translate(
                                  offset: Offset(0, 10 * (1 - pw)),
                                  child: Text.rich(
                                    TextSpan(
                                      children: [
                                        TextSpan(
                                          text: 're',
                                          style: TextStyle(color: oscuro),
                                        ),
                                        TextSpan(
                                          text: 'bin',
                                          style: TextStyle(color: vivo),
                                        ),
                                      ],
                                    ),
                                    style: TextStyle(
                                      fontFamily: Tipografia.titulo,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 48,
                                      height: 1,
                                      letterSpacing: -0.4,
                                      // Halo del color del fondo, por si la
                                      // escena pasa por detrás.
                                      shadows: [
                                        Shadow(color: c.fondo, blurRadius: 16),
                                        Shadow(color: c.fondo, blurRadius: 5),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
