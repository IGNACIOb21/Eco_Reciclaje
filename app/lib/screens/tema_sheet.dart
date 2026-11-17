import 'package:flutter/material.dart';

import '../state/tema_controller.dart';
import '../theme/app_theme.dart';
import '../theme/app_themes.dart';
import '../widgets/app_bottom_sheet.dart';

/// Perfil › Tema: elige entre todos los temas de color. Se aplica al tocar
/// una opción (sin botón Guardar) para ver el cambio al tiro.
Future<void> mostrarTema(BuildContext context) {
  return mostrarAppBottomSheet<void>(
    context: context,
    builder: (_) => const TemaSheet(),
  );
}

class TemaSheet extends StatelessWidget {
  const TemaSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = TemaScope.of(context);
    final colores = context.colores;
    return AppBottomSheet(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tema',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
          ),
          const SizedBox(height: 4),
          Text(
            'Se guarda en este teléfono.',
            style: TextStyle(color: colores.textoSecundario),
          ),
          const SizedBox(height: 16),
          for (final tema in TemaApp.values) ...[
            _OpcionTema(
              tema: tema,
              seleccionado: tema == controller.tema,
              onTap: () => controller.cambiar(tema),
            ),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _OpcionTema extends StatelessWidget {
  final TemaApp tema;
  final bool seleccionado;
  final VoidCallback onTap;

  const _OpcionTema({
    required this.tema,
    required this.seleccionado,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colores = context.colores;
    final paleta = tema.paleta;
    return Material(
      color: colores.superficieAlta,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: seleccionado ? colores.primario : Colors.transparent,
              width: 2,
            ),
          ),
          child: Row(
            children: [
              _Muestra(paleta: paleta),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tema.nombre,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      tema.descripcion,
                      style: TextStyle(
                        color: colores.textoSecundario,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                seleccionado ? Icons.check_circle : Icons.circle_outlined,
                color: seleccionado ? colores.primario : colores.borde,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Miniatura del tema: fondo, tarjeta, primario y alerta.
class _Muestra extends StatelessWidget {
  final ColoresApp paleta;

  const _Muestra({required this.paleta});

  @override
  Widget build(BuildContext context) {
    Widget punto(Color color) => Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
    return Container(
      width: 56,
      height: 56,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: paleta.fondo,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: paleta.borde),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: paleta.superficie,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [punto(paleta.primario), punto(paleta.alerta)],
        ),
      ),
    );
  }
}
