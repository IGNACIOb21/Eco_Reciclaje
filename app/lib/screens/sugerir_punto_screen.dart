import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../data/comunas_region_metropolitana.dart';
import '../models/material_type.dart';
import '../repositories/acciones_repository.dart';
import '../theme/app_spacing.dart';
import '../theme/app_theme.dart';
import '../widgets/mensaje_error.dart';

/// Sugiere un punto de reciclaje que no está en la app. La ubicación sale del
/// GPS (si hay permiso) o del centro del mapa; se puede alternar entre ambas.
/// Queda en revisión: la entidad de la comuna (o la plataforma) la aprueba o
/// la rechaza. Se cierra devolviendo true cuando se envió.
class SugerirPuntoScreen extends StatefulWidget {
  final AccionesRepository repositorio;

  /// Posición GPS; null si no hay permiso o aún no hay fijo.
  final LatLng? gps;

  /// Centro visible del mapa al abrir la pantalla.
  final LatLng centroMapa;

  const SugerirPuntoScreen({
    super.key,
    required this.repositorio,
    required this.centroMapa,
    this.gps,
  });

  @override
  State<SugerirPuntoScreen> createState() => _SugerirPuntoScreenState();
}

class _SugerirPuntoScreenState extends State<SugerirPuntoScreen> {
  final _nombre = TextEditingController();
  final _direccion = TextEditingController();
  final Set<TipoMaterial> _materiales = {};
  late bool _usarGps = widget.gps != null;
  String? _comuna;
  bool _enviando = false;
  String? _error;

  LatLng get _ubicacion =>
      _usarGps && widget.gps != null ? widget.gps! : widget.centroMapa;

  @override
  void dispose() {
    _nombre.dispose();
    _direccion.dispose();
    super.dispose();
  }

  String? _validar() {
    if (_nombre.text.trim().length < 3) {
      return 'Ponle un nombre al punto (al menos 3 caracteres).';
    }
    if (_comuna == null) return 'Elige la comuna del punto.';
    if (_materiales.isEmpty) {
      return 'Elige al menos un material que reciba el punto.';
    }
    return null;
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
      await widget.repositorio.sugerirPunto(
        nombre: _nombre.text,
        lat: _ubicacion.latitude,
        lng: _ubicacion.longitude,
        comuna: _comuna!,
        materiales: _materiales.toList(),
        direccion: _direccion.text,
      );
      if (mounted) Navigator.of(context).pop(true);
    } on AccionException catch (e) {
      if (mounted) setState(() => _error = e.mensaje);
    } catch (_) {
      if (mounted) {
        setState(
          () =>
              _error = const AccionException(MotivoErrorAccion.desconocido)
                  .mensaje,
        );
      }
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colores = context.colores;
    final u = _ubicacion;
    return Scaffold(
      appBar: AppBar(title: const Text('Sugerir un punto')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            const Text(
              '¿Conoces un punto de reciclaje que no aparece? Cuéntanos dónde está. Lo revisamos antes de publicarlo y, si se aprueba, ganas Rebin Points.',
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              key: const Key('sugerir-nombre'),
              controller: _nombre,
              maxLength: 100,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Nombre del punto'),
            ),
            TextField(
              key: const Key('sugerir-direccion'),
              controller: _direccion,
              maxLength: 200,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Dirección o referencia (opcional)',
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            DropdownButtonFormField<String>(
              key: const Key('sugerir-comuna'),
              initialValue: _comuna,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Comuna'),
              items: [
                for (final c in comunasRegionMetropolitana)
                  DropdownMenuItem(value: c, child: Text(c)),
              ],
              onChanged: _enviando ? null : (v) => setState(() => _comuna = v),
            ),
            const SizedBox(height: AppSpacing.md),
            const Text(
              'Materiales que recibe',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
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
                    onSelected: _enviando
                        ? null
                        : (v) => setState(
                            () => v
                                ? _materiales.add(material)
                                : _materiales.remove(material),
                          ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            const Text(
              'Ubicación',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            SegmentedButton<bool>(
              key: const Key('sugerir-origen'),
              segments: [
                ButtonSegment(
                  value: true,
                  enabled: widget.gps != null,
                  icon: const Icon(Icons.my_location),
                  label: const Text('Donde estoy'),
                ),
                const ButtonSegment(
                  value: false,
                  icon: Icon(Icons.center_focus_strong_outlined),
                  label: Text('Centro del mapa'),
                ),
              ],
              selected: {_usarGps && widget.gps != null},
              onSelectionChanged: _enviando
                  ? null
                  : (s) => setState(() => _usarGps = s.first),
            ),
            const SizedBox(height: 6),
            Text(
              key: const Key('sugerir-coordenadas'),
              '${u.latitude.toStringAsFixed(5)}, ${u.longitude.toStringAsFixed(5)}'
              '${widget.gps == null ? '  ·  sin GPS: se usa el centro del mapa' : ''}',
              style: TextStyle(color: colores.textoSecundario, fontSize: 12),
            ),
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.sm),
              MensajeError(texto: _error!),
            ],
            const SizedBox(height: AppSpacing.md),
            ElevatedButton(
              key: const Key('sugerir-enviar'),
              onPressed: _enviando ? null : _enviar,
              child: _enviando
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Enviar sugerencia'),
            ),
          ],
        ),
      ),
    );
  }
}
