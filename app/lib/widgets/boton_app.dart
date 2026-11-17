import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/movimiento.dart';
import 'presionable.dart';

enum VarianteBoton {
  /// Acción principal: relleno verde.
  primario,

  /// Acción secundaria: borde verde, sin relleno.
  secundario,

  /// Solo para recompensas ("Reclamar"): dorado con borde oscuro, para que se
  /// lea como botón aunque el dorado contraste poco con el fondo.
  recompensa,

  /// Acción de bajo peso ("Ahora no", "Volver"): solo texto verde.
  terciario,

  /// Acción destructiva ("Eliminar reporte"): terracota, nunca rojo puro.
  peligro,
}

enum EstadoBoton {
  reposo,

  /// La acción está en curso: una barra avanza por dentro del botón.
  cargando,

  /// La acción terminó: aparece un check con rebote.
  exito,
}

/// Botón base de la app con todos sus estados (reposo, presionado, cargando,
/// éxito y deshabilitado). Usa los tokens de [ColoresApp].
class BotonApp extends StatelessWidget {
  final String texto;
  final VoidCallback? onPressed;
  final VarianteBoton variante;
  final EstadoBoton estado;
  final IconData? icono;

  /// Texto mientras carga y al terminar; si es null se deja [texto].
  final String? textoCargando;
  final String? textoExito;

  const BotonApp({
    super.key,
    required this.texto,
    required this.onPressed,
    this.variante = VarianteBoton.primario,
    this.estado = EstadoBoton.reposo,
    this.icono,
    this.textoCargando,
    this.textoExito,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    final exito = estado == EstadoBoton.exito;
    final cargando = estado == EstadoBoton.cargando;
    final habilitado = onPressed != null && estado == EstadoBoton.reposo;

    final (fondo, texto0, borde) = switch (variante) {
      _ when exito => (c.primarioSuave, c.primarioTexto, Colors.transparent),
      VarianteBoton.primario => (
        c.primario,
        c.sobrePrimario,
        Colors.transparent,
      ),
      VarianteBoton.secundario => (
        Colors.transparent,
        c.primarioTexto,
        c.primarioTexto,
      ),
      VarianteBoton.recompensa => (
        c.recompensa,
        c.sobreRecompensa,
        c.recompensaTexto,
      ),
      VarianteBoton.terciario => (
        Colors.transparent,
        c.primarioTexto,
        Colors.transparent,
      ),
      VarianteBoton.peligro => (c.alerta, c.sobreAlerta, Colors.transparent),
    };
    // Deshabilitado (sin acción y en reposo): neutro, sin borde de color.
    final apagado = onPressed == null && estado == EstadoBoton.reposo;
    final colorFondo = apagado
        ? (variante == VarianteBoton.terciario
              ? Colors.transparent
              : c.deshabilitado)
        : fondo;
    final colorTexto = apagado ? c.textoSecundario : texto0;
    final colorBorde = apagado ? Colors.transparent : borde;

    final etiqueta = cargando
        ? (textoCargando ?? texto)
        : exito
        ? (textoExito ?? texto)
        : texto;

    return Presionable(
      onTap: habilitado ? onPressed : null,
      child: AnimatedContainer(
        duration: Movimiento.dur(context, Movimiento.micro),
        height: 56,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: colorFondo,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: colorBorde,
            width: variante == VarianteBoton.recompensa ? 1 : 1.5,
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (cargando)
              Positioned.fill(
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: Movimiento.dur(
                    context,
                    const Duration(milliseconds: 900),
                  ),
                  curve: Movimiento.entrar,
                  builder: (_, v, _) => Align(
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: v,
                      child: ColoredBox(
                        color: Colors.white.withValues(alpha: 0.35),
                        child: const SizedBox.expand(),
                      ),
                    ),
                  ),
                ),
              ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (exito)
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.4, end: 1),
                    duration: Movimiento.dur(
                      context,
                      const Duration(milliseconds: 320),
                    ),
                    curve: Movimiento.rebote,
                    builder: (_, v, child) =>
                        Transform.scale(scale: v, child: child),
                    child: Icon(Icons.check, size: 20, color: colorTexto),
                  )
                else if (icono != null)
                  Icon(icono, size: 20, color: colorTexto),
                if (exito || icono != null) const SizedBox(width: 8),
                Text(
                  etiqueta,
                  style: TextStyle(
                    color: colorTexto,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
