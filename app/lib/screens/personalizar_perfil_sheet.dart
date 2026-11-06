import 'package:flutter/material.dart';

import '../data/comunas_demo.dart';
import '../models/perfil_local.dart';
import '../state/perfil_local_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/app_bottom_sheet.dart';
import '../widgets/avatar_usuario.dart';
import '../widgets/seccion_titulo.dart';

Future<void> mostrarPersonalizarPerfil(BuildContext context) {
  return mostrarAppBottomSheet<void>(
    context: context,
    builder: (_) =>
        PersonalizarPerfilSheet(controller: PerfilLocalScope.of(context)),
  );
}

class PersonalizarPerfilSheet extends StatefulWidget {
  final PerfilLocalController controller;

  const PersonalizarPerfilSheet({super.key, required this.controller});

  @override
  State<PersonalizarPerfilSheet> createState() =>
      _PersonalizarPerfilSheetState();
}

class _PersonalizarPerfilSheetState extends State<PersonalizarPerfilSheet> {
  late final TextEditingController _nombre = TextEditingController(
    text: widget.controller.perfil.nombre,
  );
  late AvatarIcono _icono = widget.controller.perfil.avatarIcono;
  late int _colorIndex = widget.controller.perfil.avatarColorIndex;
  late String _comuna = widget.controller.perfil.comuna;

  @override
  void dispose() {
    _nombre.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    await widget.controller.actualizar(
      widget.controller.perfil.copyWith(
        nombre: _nombre.text,
        avatarIcono: _icono,
        avatarColorIndex: _colorIndex,
        comuna: _comuna,
      ),
    );
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final colores = context.colores;
    final colorActual = coloresAvatar[_colorIndex];

    return AppBottomSheet(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Personalizar perfil',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
          ),
          const SizedBox(height: 16),
          Center(
            child: AvatarUsuario(icono: _icono, color: colorActual, tamano: 84),
          ),
          const SizedBox(height: 20),
          const SeccionTitulo('Nombre visible'),
          const SizedBox(height: 8),
          TextField(
            controller: _nombre,
            maxLength: 24,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              hintText: 'Déjalo vacío para seguir como anónimo',
              counterText: '',
            ),
          ),
          const SizedBox(height: 16),
          const SeccionTitulo('Ícono'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final icono in AvatarIcono.values)
                _OpcionCircular(
                  seleccionado: icono == _icono,
                  color: colorActual,
                  onTap: () => setState(() => _icono = icono),
                  child: Icon(
                    icono.icono,
                    color: icono == _icono
                        ? colorActual
                        : colores.textoSecundario,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          const SeccionTitulo('Color'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            children: [
              for (var i = 0; i < coloresAvatar.length; i++)
                _OpcionCircular(
                  seleccionado: i == _colorIndex,
                  color: coloresAvatar[i],
                  onTap: () => setState(() => _colorIndex = i),
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: coloresAvatar[i],
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          const SeccionTitulo('Tu comuna'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final comuna in comunasDemo)
                ChoiceChip(
                  label: Text(comuna.nombre),
                  selected: _comuna == comuna.nombre,
                  onSelected: (_) => setState(() => _comuna = comuna.nombre),
                ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _guardar,
              child: const Text('Guardar'),
            ),
          ),
        ],
      ),
    );
  }
}

class _OpcionCircular extends StatelessWidget {
  final bool seleccionado;
  final Color color;
  final VoidCallback onTap;
  final Widget child;

  const _OpcionCircular({
    required this.seleccionado,
    required this.color,
    required this.onTap,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final colores = context.colores;
    return InkWell(
      customBorder: const CircleBorder(),
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: seleccionado
              ? color.withValues(alpha: 0.18)
              : colores.superficieAlta,
          border: Border.all(
            color: seleccionado ? color : Colors.transparent,
            width: 2,
          ),
        ),
        child: Center(child: child),
      ),
    );
  }
}
