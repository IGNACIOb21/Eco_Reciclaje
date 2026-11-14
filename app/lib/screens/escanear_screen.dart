import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/resultado_clasificacion.dart';
import '../services/clasificador_service.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_theme.dart';
import '../widgets/mensaje_error.dart';
import '../widgets/pill.dart';

/// Pestaña Escanear: saca o elige una foto y el modelo TFLite (on-device)
/// dice qué material es. Por ahora todo es local: no guarda nada en
/// Supabase ni suma puntos.
///
/// El modelo se carga recién al primer escaneo (no al abrir la app): esta
/// pantalla vive dentro de un IndexedStack y se construye siempre, así el
/// arranque no paga el costo y los tests no necesitan la librería nativa.
class EscanearScreen extends StatefulWidget {
  /// Lleva a la pestaña del mapa.
  final VoidCallback onIrAMapa;

  const EscanearScreen({super.key, required this.onIrAMapa});

  @override
  State<EscanearScreen> createState() => _EscanearScreenState();
}

class _EscanearScreenState extends State<EscanearScreen> {
  final _picker = ImagePicker();
  Clasificador? _clasificador;

  File? _foto;
  ResultadoClasificacion? _resultado;
  String? _error;
  bool _trabajando = false;

  @override
  void dispose() {
    _clasificador?.cerrar();
    super.dispose();
  }

  Future<XFile?> _elegirFoto(ImageSource origen) async {
    try {
      // La foto se reduce al elegirla: una de 12 MP tarda mucho en
      // decodificarse y el modelo solo usa 224x224.
      return await _picker.pickImage(
        source: origen,
        maxWidth: 1280,
        maxHeight: 1280,
        imageQuality: 90,
      );
    } catch (e) {
      debugPrint('EscanearScreen: no se pudo elegir la foto ($e)');
      if (mounted) {
        setState(() {
          _error = origen == ImageSource.camera
              ? 'No se pudo abrir la cámara.'
              : 'No se pudo abrir la galería.';
        });
      }
      return null;
    }
  }

  Future<void> _escanear(ImageSource origen) async {
    if (_trabajando) return;
    final elegido = await _elegirFoto(origen);
    if (elegido == null || !mounted) return;

    setState(() {
      _foto = File(elegido.path);
      _resultado = null;
      _error = null;
      _trabajando = true;
    });
    try {
      final bytes = await elegido.readAsBytes();
      final clasificador = _clasificador ??= await Clasificador.cargar();
      final resultado = await clasificador.clasificar(bytes);
      if (!mounted) return;
      setState(() => _resultado = resultado);
    } catch (e) {
      debugPrint('EscanearScreen: falló la clasificación ($e)');
      if (mounted) {
        setState(() => _error = 'No pude analizar la foto. Intenta con otra.');
      }
    } finally {
      if (mounted) setState(() => _trabajando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colores = context.colores;
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            const Text(
              'Escanear objeto',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              'Saca una foto o elige una de tu galería y te digo qué material es.',
              style: TextStyle(color: colores.textoSecundario),
            ),
            const SizedBox(height: AppSpacing.lg),
            _Visor(foto: _foto, trabajando: _trabajando),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _trabajando
                        ? null
                        : () => _escanear(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Cámara'),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _trabajando
                        ? null
                        : () => _escanear(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text('Galería'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            if (_error != null) MensajeError(texto: _error!),
            if (_resultado != null)
              _TarjetaResultado(
                resultado: _resultado!,
                onIrAMapa: widget.onIrAMapa,
              ),
          ],
        ),
      ),
    );
  }
}

class _Visor extends StatelessWidget {
  final File? foto;
  final bool trabajando;

  const _Visor({required this.foto, required this.trabajando});

  @override
  Widget build(BuildContext context) {
    final colores = context.colores;
    return AspectRatio(
      aspectRatio: 1,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          color: colores.fondoMapa,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (foto == null)
                Center(
                  child: Icon(
                    Icons.camera_alt_outlined,
                    size: 56,
                    color: colores.primario,
                  ),
                )
              else
                Image.file(foto!, fit: BoxFit.cover),
              if (trabajando)
                Container(
                  color: Colors.black38,
                  child: const Center(child: CircularProgressIndicator()),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TarjetaResultado extends StatelessWidget {
  final ResultadoClasificacion resultado;
  final VoidCallback onIrAMapa;

  const _TarjetaResultado({required this.resultado, required this.onIrAMapa});

  @override
  Widget build(BuildContext context) {
    final colores = context.colores;
    final mejor = resultado.mejor;
    final info = mejor.info;
    final confianza = resultado.confianza;

    final titulo = switch (confianza) {
      Confianza.segura => info.nombre,
      Confianza.dudosa => 'Creo que es ${info.nombre}',
      Confianza.baja => 'No estoy seguro',
    };
    final aviso = switch (confianza) {
      Confianza.segura => null,
      Confianza.dudosa =>
        'No estoy del todo seguro. Mira las otras opciones más abajo.',
      Confianza.baja =>
        'Prueba con más luz, de más cerca y con el objeto solo en la foto.',
    };

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colores.superficie,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: colores.borde),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: info.color.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                child: Icon(info.icono, color: info.color),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  titulo,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Pill(
                texto: '${(mejor.probabilidad * 100).toStringAsFixed(0)}%',
                color: switch (confianza) {
                  Confianza.segura => colores.primario,
                  Confianza.dudosa => colores.acento,
                  Confianza.baja => Theme.of(context).colorScheme.error,
                },
                fontWeight: FontWeight.w700,
              ),
            ],
          ),
          if (aviso != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(aviso, style: TextStyle(color: colores.textoSecundario)),
          ],
          if (confianza != Confianza.baja) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(info.consejo),
          ],
          const SizedBox(height: AppSpacing.md),
          const Text(
            'Otras posibilidades',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          ),
          const SizedBox(height: AppSpacing.xs),
          for (final p in resultado.top) _FilaPrediccion(prediccion: p),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Análisis en el teléfono: ${resultado.milisegundosInferencia} ms',
            style: TextStyle(color: colores.textoSecundario, fontSize: 12),
          ),
          if (confianza != Confianza.baja && info.material != null) ...[
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onIrAMapa,
                icon: const Icon(Icons.map_outlined),
                label: const Text('Ver puntos de reciclaje'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _FilaPrediccion extends StatelessWidget {
  final Prediccion prediccion;

  const _FilaPrediccion({required this.prediccion});

  @override
  Widget build(BuildContext context) {
    final colores = context.colores;
    final info = prediccion.info;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(info.nombre, overflow: TextOverflow.ellipsis),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.pill),
              child: LinearProgressIndicator(
                value: prediccion.probabilidad,
                minHeight: 8,
                color: info.color,
                backgroundColor: colores.superficieAlta,
              ),
            ),
          ),
          SizedBox(
            width: 52,
            child: Text(
              '${(prediccion.probabilidad * 100).toStringAsFixed(1)}%',
              textAlign: TextAlign.end,
              style: TextStyle(color: colores.textoSecundario, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
