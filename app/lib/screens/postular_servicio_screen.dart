import 'package:flutter/material.dart';

import '../data/comunas_region_metropolitana.dart';
import '../models/material_type.dart';
import '../models/postulacion_servicio.dart';
import '../repositories/recolectores_repository.dart';
import '../theme/app_spacing.dart';
import '../utils/horario_texto.dart';
import '../widgets/app_bottom_sheet.dart';
import '../widgets/mensaje_error.dart';

/// Formulario para postular un servicio de recolección. Al enviarlo queda en
/// revisión: el panel lo aprueba (y pasa a verse en la lista) o lo rechaza con
/// un motivo. Se cierra devolviendo true cuando la postulación se envió.
class PostularServicioScreen extends StatefulWidget {
  final RecolectoresRepository repositorio;

  const PostularServicioScreen({super.key, required this.repositorio});

  @override
  State<PostularServicioScreen> createState() => _PostularServicioScreenState();
}

class _PostularServicioScreenState extends State<PostularServicioScreen> {
  final _nombre = TextEditingController();
  final _contacto = TextEditingController();
  final _descripcion = TextEditingController();
  final _horario = TextEditingController();
  final Set<TipoMaterial> _materiales = {};
  final Set<String> _comunas = {};
  bool _retiraADomicilio = false;
  bool _enviando = false;
  String? _error;

  static const _maxComunas = 10;

  @override
  void dispose() {
    _nombre.dispose();
    _contacto.dispose();
    _descripcion.dispose();
    _horario.dispose();
    super.dispose();
  }

  /// Primer problema del formulario, o null si se puede enviar.
  String? _validar() {
    if (_nombre.text.trim().length < 3) {
      return 'El nombre debe tener al menos 3 caracteres.';
    }
    if (_contacto.text.trim().length < 3) {
      return 'Indica un contacto (teléfono, correo o red social).';
    }
    if (_materiales.isEmpty) return 'Elige al menos un material que recoges.';
    if (_comunas.isEmpty) return 'Elige al menos una comuna de cobertura.';
    try {
      horarioDesdeTexto(_horario.text);
    } on FormatException catch (e) {
      return '${e.message} Revisa "${e.source}".';
    }
    return null;
  }

  Future<void> _elegirComunas() async {
    final elegidas = await mostrarAppBottomSheet<Set<String>>(
      context: context,
      builder: (_) => _SelectorComunas(inicial: _comunas, maximo: _maxComunas),
    );
    if (elegidas != null) {
      setState(() {
        _comunas
          ..clear()
          ..addAll(elegidas);
      });
    }
  }

  Future<void> _enviar() async {
    final problema = _validar();
    if (problema != null) {
      setState(() => _error = problema);
      return;
    }
    setState(() {
      _enviando = true;
      _error = null;
    });
    try {
      await widget.repositorio.postular(
        PostulacionServicio(
          nombre: _nombre.text.trim(),
          contacto: _contacto.text.trim(),
          comunas: _comunas.toList()..sort(),
          materiales: _materiales.toList(),
          descripcion: _descripcion.text.trim(),
          retiraADomicilio: _retiraADomicilio,
          horario: horarioDesdeTexto(_horario.text),
        ),
      );
      if (mounted) Navigator.of(context).pop(true);
    } on PostulacionException catch (e) {
      if (mounted) setState(() => _error = e.mensaje);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = const PostulacionException(
            MotivoErrorPostulacion.desconocido,
          ).mensaje,
        );
      }
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Postular mi servicio')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            const Text(
              'Si recolectas materiales reciclables (aceite, pilas, tetra pak…), cuéntanos cómo contactarte. Revisamos cada postulación antes de publicarla.',
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              key: const Key('postular-nombre'),
              controller: _nombre,
              maxLength: 100,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Nombre del servicio',
              ),
            ),
            TextField(
              key: const Key('postular-contacto'),
              controller: _contacto,
              maxLength: 150,
              decoration: const InputDecoration(
                labelText: 'Contacto',
                helperText: 'Teléfono, correo o red social',
              ),
            ),
            TextField(
              key: const Key('postular-descripcion'),
              controller: _descripcion,
              maxLength: 500,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Descripción (opcional)',
              ),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Retiro a domicilio'),
              value: _retiraADomicilio,
              onChanged: (v) => setState(() => _retiraADomicilio = v),
            ),
            const SizedBox(height: AppSpacing.xs),
            const Text(
              'Materiales que recoges',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: AppSpacing.xs,
              children: [
                for (final material in TipoMaterial.values)
                  FilterChip(
                    avatar: Icon(
                      material.icono,
                      size: 16,
                      color: material.color,
                    ),
                    label: Text(material.etiqueta),
                    selected: _materiales.contains(material),
                    onSelected: (v) => setState(
                      () => v
                          ? _materiales.add(material)
                          : _materiales.remove(material),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            const Text(
              'Comunas de cobertura',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSpacing.xs),
            if (_comunas.isNotEmpty)
              Wrap(
                spacing: AppSpacing.xs,
                children: [
                  for (final c in (_comunas.toList()..sort()))
                    Chip(label: Text(c)),
                ],
              ),
            OutlinedButton.icon(
              key: const Key('postular-comunas'),
              onPressed: _elegirComunas,
              icon: const Icon(Icons.place_outlined),
              label: Text(
                _comunas.isEmpty ? 'Elegir comunas' : 'Cambiar comunas',
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              key: const Key('postular-horario'),
              controller: _horario,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Horario de atención (opcional)',
                helperText: 'Una línea por tramo, ej. "lun-vie: 9:00-18:00"',
                alignLabelWithHint: true,
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.sm),
              MensajeError(texto: _error!),
            ],
            const SizedBox(height: AppSpacing.md),
            FilledButton(
              key: const Key('postular-enviar'),
              onPressed: _enviando ? null : _enviar,
              child: _enviando
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Enviar postulación'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Lista de las comunas del catálogo con casillas. Devuelve el conjunto
/// elegido al pulsar "Listo".
class _SelectorComunas extends StatefulWidget {
  final Set<String> inicial;
  final int maximo;

  const _SelectorComunas({required this.inicial, required this.maximo});

  @override
  State<_SelectorComunas> createState() => _SelectorComunasState();
}

class _SelectorComunasState extends State<_SelectorComunas> {
  late final Set<String> _elegidas = {...widget.inicial};

  @override
  Widget build(BuildContext context) {
    final alto = MediaQuery.of(context).size.height * 0.7;
    return SafeArea(
      child: SizedBox(
        height: alto,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Text(
                'Comunas de cobertura (${_elegidas.length}/${widget.maximo})',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ),
            Expanded(
              child: ListView(
                children: [
                  for (final comuna in comunasRegionMetropolitana)
                    CheckboxListTile(
                      dense: true,
                      title: Text(comuna),
                      value: _elegidas.contains(comuna),
                      onChanged: (v) => setState(() {
                        if (v == true) {
                          if (_elegidas.length < widget.maximo) {
                            _elegidas.add(comuna);
                          }
                        } else {
                          _elegidas.remove(comuna);
                        }
                      }),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(_elegidas),
                  child: const Text('Listo'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
