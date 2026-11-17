import 'dart:io';

import 'package:flutter/material.dart';

import '../services/clasificacion_service.dart';
import '../services/voz_service.dart';
import '../theme/app_theme.dart';
import 'resultado_clasificacion.dart';

/// Foto de un residuo → "Analizando objeto..." → resultado de la IA (dicho
/// por voz). Avisa con [onResultado] cuando hay una categoría final:
///   * Sin modelo, la persona elige la categoría (la base lo deja en
///     revisión, sin puntos).
///   * Si la IA no lo reconoce (bajo el umbral), pide otra foto o que la
///     persona elija.
///   * Si la IA se equivocó, "¿No es esto?" deja corregirla.
class PanelClasificacion extends StatefulWidget {
  final File foto;
  final ClasificacionService clasificador;
  final VozService voz;
  final ValueChanged<ResultadoClasificacion?> onResultado;
  final VoidCallback onOtraFoto;

  const PanelClasificacion({
    super.key,
    required this.foto,
    required this.clasificador,
    required this.voz,
    required this.onResultado,
    required this.onOtraFoto,
  });

  @override
  State<PanelClasificacion> createState() => _PanelClasificacionState();
}

class _PanelClasificacionState extends State<PanelClasificacion> {
  bool _analizando = true;
  bool _fallo = false;
  bool _eligiendo = false;
  ResultadoClasificacion? _delModelo;
  ResultadoClasificacion? _final;

  @override
  void initState() {
    super.initState();
    _analizar();
  }

  @override
  void didUpdateWidget(PanelClasificacion anterior) {
    super.didUpdateWidget(anterior);
    if (anterior.foto.path != widget.foto.path) _analizar();
  }

  Future<void> _analizar() async {
    final foto = widget.foto;
    setState(() {
      _analizando = true;
      _fallo = false;
      _eligiendo = false;
      _delModelo = null;
      _final = null;
    });
    ResultadoClasificacion? r;
    try {
      r = await widget.clasificador.clasificar(foto);
    } catch (e) {
      debugPrint('Clasificación: $e');
      if (mounted && foto == widget.foto) {
        setState(() {
          _analizando = false;
          _fallo = true;
        });
      }
      return;
    }
    if (!mounted || foto != widget.foto) return;
    setState(() {
      _analizando = false;
      _delModelo = r;
      _eligiendo = r == null;
    });
    if (r == null) return;
    widget.voz.decir(r.frase);
    if (r.reconocido) _fijar(r);
  }

  void _fijar(ResultadoClasificacion? r) {
    setState(() {
      _final = r;
      if (r != null) _eligiendo = false;
    });
    widget.onResultado(r);
  }

  void _elegir() {
    _fijar(null);
    setState(() => _eligiendo = true);
  }

  @override
  Widget build(BuildContext context) {
    final colores = context.colores;
    final delModelo = _delModelo;
    final resultado = _final;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FotoResiduo(
          archivo: widget.foto,
          cubierta: _analizando ? const _Analizando() : null,
        ),
        const SizedBox(height: 20),
        if (_analizando)
          Text(
            'Esto toma solo unos segundos.',
            textAlign: TextAlign.center,
            style: TextStyle(color: colores.textoSecundario),
          )
        else if (_fallo) ...[
          const Text(
            'No pudimos analizar la foto.',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: widget.onOtraFoto,
            child: const Text('Tomar otra foto'),
          ),
        ] else if (resultado != null) ...[
          ResultadoClasificacionVista(resultado: resultado, voz: widget.voz),
          if (!resultado.elegidoPorPersona)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                key: const Key('clasificacion-corregir'),
                onPressed: _elegir,
                child: const Text('¿No es esto? Elegir la categoría'),
              ),
            ),
        ] else if (_eligiendo) ...[
          Text(
            delModelo == null
                ? 'La identificación automática todavía no está disponible. '
                      '¿Qué es?'
                : '¿Qué es?',
            key: const Key('clasificacion-elegir'),
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
          const SizedBox(height: 4),
          Text(
            'Si la eliges tú, el registro se revisa antes de dar Rebin Points.',
            style: TextStyle(color: colores.textoSecundario, fontSize: 13),
          ),
          const SizedBox(height: 12),
          SelectorCategoria(
            onElegir: (e) {
              final r = ResultadoClasificacion.elegida(e, delModelo: delModelo);
              widget.voz.decir(r.frase);
              _fijar(r);
            },
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: widget.onOtraFoto,
            child: const Text('Tomar otra foto'),
          ),
        ] else if (delModelo != null && !delModelo.reconocido) ...[
          Row(
            children: [
              Icon(Icons.help_outline, color: colores.alerta, size: 32),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'No pudimos reconocer el objeto',
                  key: Key('clasificacion-no-reconocido'),
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Fotografía un solo objeto, de cerca y con buena luz.',
            style: TextStyle(color: colores.textoSecundario),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: widget.onOtraFoto,
            icon: const Icon(Icons.photo_camera_outlined),
            label: const Text('Tomar otra foto'),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: _elegir,
            child: const Text('Elegir yo la categoría'),
          ),
        ],
      ],
    );
  }
}

/// Foto con esquinas redondeadas y, opcionalmente, algo encima o un texto.
/// Ancho en píxeles físicos de [caja] (null si no tiene límite).
int? _anchoEnPixeles(BuildContext context, BoxConstraints caja) =>
    caja.hasBoundedWidth
        ? (caja.maxWidth * MediaQuery.devicePixelRatioOf(context)).ceil()
        : null;

class FotoResiduo extends StatelessWidget {
  final File archivo;
  final Widget? cubierta;
  final String? etiqueta;
  final double aspecto;

  const FotoResiduo({
    super.key,
    required this.archivo,
    this.cubierta,
    this.etiqueta,
    this.aspecto = 3 / 4,
  });

  @override
  Widget build(BuildContext context) {
    final colores = context.colores;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: AspectRatio(
            aspectRatio: aspecto,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Se decodifica al ancho en que se muestra: la miniatura
                // de 56 px no carga la foto completa en memoria.
                LayoutBuilder(
                  builder: (context, caja) => Image.file(
                    archivo,
                    fit: BoxFit.cover,
                    cacheWidth: _anchoEnPixeles(context, caja),
                    errorBuilder: (_, _, _) =>
                        ColoredBox(color: colores.superficieAlta),
                  ),
                ),
                ?cubierta,
              ],
            ),
          ),
        ),
        if (etiqueta != null) ...[
          const SizedBox(height: 6),
          Text(
            etiqueta!,
            textAlign: TextAlign.center,
            style: TextStyle(color: colores.textoSecundario, fontSize: 12),
          ),
        ],
      ],
    );
  }
}

class _Analizando extends StatelessWidget {
  const _Analizando();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black.withValues(alpha: 0.45),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 16),
            Text(
              'Analizando objeto...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
