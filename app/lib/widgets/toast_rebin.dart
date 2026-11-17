import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/movimiento.dart';

/// Aviso breve en forma de píldora, abajo de la pantalla: "¡Bien! +5 Rebin
/// Points". No bloquea nada y se va solo. Los lectores de pantalla lo anuncian.
class ToastRebin {
  ToastRebin._();

  static OverlayEntry? _actual;
  static Timer? _reloj;

  /// [textoDorado] es la parte que se destaca como recompensa (opcional).
  static void mostrar(
    BuildContext context,
    String texto, {
    String? textoDorado,
    Duration duracion = const Duration(milliseconds: 2600),
  }) {
    final overlay = Overlay.maybeOf(context);
    if (overlay == null) return;
    _quitar();
    final entrada = OverlayEntry(
      builder: (_) => _Toast(texto: texto, textoDorado: textoDorado),
    );
    _actual = entrada;
    overlay.insert(entrada);
    _reloj = Timer(duracion, _quitar);
  }

  static void _quitar() {
    _reloj?.cancel();
    _reloj = null;
    _actual?.remove();
    _actual = null;
  }
}

class _Toast extends StatelessWidget {
  final String texto;
  final String? textoDorado;

  const _Toast({required this.texto, this.textoDorado});

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    final oscuro = Theme.of(context).brightness == Brightness.dark;
    // En claro el aviso es oscuro con dorado claro; en Eco es claro, y el
    // dorado pasa al tono oscuro para mantener el contraste.
    final fondo = c.texto;
    final base = c.fondo;
    final dorado = oscuro ? const Color(0xFF8A6414) : c.recompensa;
    return Positioned(
      left: 20,
      right: 20,
      bottom: MediaQuery.paddingOf(context).bottom + 110,
      child: IgnorePointer(
        child: Semantics(
          liveRegion: true,
          label: textoDorado == null ? texto : '$texto $textoDorado',
          child: ExcludeSemantics(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: Movimiento.dur(context, Movimiento.transicion),
              curve: Movimiento.entrar,
              builder: (_, v, hijo) => Opacity(
                opacity: v,
                child: Transform.translate(
                  offset: Offset(0, 16 * (1 - v)),
                  child: hijo,
                ),
              ),
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(minHeight: 48),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: fondo,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text.rich(
                    TextSpan(
                      style: TextStyle(
                        color: base,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.none,
                      ),
                      children: [
                        TextSpan(text: texto),
                        if (textoDorado != null) ...[
                          const TextSpan(text: ' '),
                          TextSpan(
                            text: textoDorado,
                            style: TextStyle(color: dorado),
                          ),
                        ],
                      ],
                    ),
                    textAlign: TextAlign.center,
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
