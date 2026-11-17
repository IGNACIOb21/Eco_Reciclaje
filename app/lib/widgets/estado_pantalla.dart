import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'boton_app.dart';

/// Estado vacío o de error que dice qué hacer: un ícono en un círculo verde
/// suave, un título, una explicación y hasta dos acciones (la principal como
/// botón y la secundaria como enlace).
class EstadoPantalla extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String? texto;
  final String? accion;
  final VoidCallback? onAccion;
  final String? accionSecundaria;
  final VoidCallback? onAccionSecundaria;

  const EstadoPantalla({
    super.key,
    required this.icono,
    required this.titulo,
    this.texto,
    this.accion,
    this.onAccion,
    this.accionSecundaria,
    this.onAccionSecundaria,
  });

  @override
  Widget build(BuildContext context) {
    final colores = context.colores;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: colores.primarioSuave,
              shape: BoxShape.circle,
            ),
            child: Icon(icono, size: 30, color: colores.primarioTexto),
          ),
          const SizedBox(height: 14),
          Text(
            titulo,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          if (texto != null) ...[
            const SizedBox(height: 6),
            Text(
              texto!,
              textAlign: TextAlign.center,
              style: TextStyle(color: colores.textoSecundario),
            ),
          ],
          if (accion != null) ...[
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: BotonApp(texto: accion!, onPressed: onAccion),
            ),
          ],
          if (accionSecundaria != null) ...[
            const SizedBox(height: 4),
            TextButton(
              onPressed: onAccionSecundaria,
              child: Text(accionSecundaria!),
            ),
          ],
        ],
      ),
    );
  }
}
