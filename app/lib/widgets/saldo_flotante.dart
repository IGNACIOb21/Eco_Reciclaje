import 'package:flutter/material.dart';

import '../state/usuario_controller.dart';
import 'contador_puntos.dart';

/// Saldo de Rebin Points junto al buscador del mapa (Inicio), como en el
/// rediseño: la píldora del contador, que rueda y hace pop al cambiar. No se
/// muestra hasta que el usuario carga.
class SaldoFlotante extends StatelessWidget {
  final VoidCallback? onTap;

  const SaldoFlotante({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    final saldo = UsuarioScope.of(context).usuario?.puntosTotales;
    if (saldo == null) return const SizedBox.shrink();
    return GestureDetector(
      key: const Key('inicio-saldo'),
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48),
        child: Center(child: ContadorPuntos(puntos: saldo < 0 ? 0 : saldo)),
      ),
    );
  }
}
