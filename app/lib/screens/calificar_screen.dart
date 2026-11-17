import 'package:flutter/material.dart';

import '../models/punto_reciclaje.dart';
import '../repositories/acciones_repository.dart';
import '../theme/app_spacing.dart';
import '../theme/app_theme.dart';
import '../widgets/mensaje_error.dart';

/// Califica un punto de 1 a 5 estrellas (obligatorio) con etiquetas rápidas y
/// comentario opcionales. Cada vez es una calificación nueva, desde cero (no
/// se edita la anterior): la base permite una por punto cada 24 h, bloquea 24 h
/// a quien junta 10 en una hora y da puntos solo la primera vez en cada punto.
/// Las etiquetas que se contradicen ([opuestas]) son excluyentes: con una
/// marcada, la otra queda bloqueada hasta desmarcarla. Se cierra devolviendo
/// el [ResultadoAccion].
class CalificarScreen extends StatefulWidget {
  final PuntoReciclaje punto;
  final AccionesRepository repositorio;

  const CalificarScreen({
    super.key,
    required this.punto,
    required this.repositorio,
  });

  static const etiquetasRapidas = [
    'Limpio',
    'Fácil de encontrar',
    'Bien señalizado',
    'Seguro',
    'Sucio',
    'Poco seguro',
  ];

  /// Pares que se contradicen: solo se puede marcar una de cada par (la base
  /// exige lo mismo, `etiquetas_invalidas`).
  static const opuestas = {
    'Limpio': 'Sucio',
    'Sucio': 'Limpio',
    'Seguro': 'Poco seguro',
    'Poco seguro': 'Seguro',
  };

  @override
  State<CalificarScreen> createState() => _CalificarScreenState();
}

class _CalificarScreenState extends State<CalificarScreen> {
  final _comentario = TextEditingController();
  final Set<String> _etiquetas = {};
  int _puntuacion = 0;
  bool _enviando = false;
  String? _error;

  /// Bloqueada si su opuesta está marcada.
  bool _bloqueada(String etiqueta) {
    final opuesta = CalificarScreen.opuestas[etiqueta];
    return opuesta != null && _etiquetas.contains(opuesta);
  }

  @override
  void dispose() {
    _comentario.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    if (_puntuacion == 0) {
      setState(() => _error = 'Elige entre 1 y 5 estrellas.');
      return;
    }
    setState(() {
      _enviando = true;
      _error = null;
    });
    try {
      final resultado = await widget.repositorio.calificar(
        idPunto: widget.punto.id,
        puntuacion: _puntuacion,
        etiquetas: _etiquetas.toList(),
        comentario: _comentario.text,
      );
      if (mounted) Navigator.of(context).pop(resultado);
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
    return Scaffold(
      appBar: AppBar(title: const Text('Calificar punto')),
      body: SafeArea(child: _formulario(context)),
    );
  }

  Widget _formulario(BuildContext context) {
    final colores = context.colores;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        Text(
          widget.punto.nombre,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 1; i <= 5; i++)
              IconButton(
                key: Key('calificar-estrella-$i'),
                iconSize: 40,
                color: colores.acento,
                icon: Icon(i <= _puntuacion ? Icons.star : Icons.star_border),
                onPressed: _enviando
                    ? null
                    : () => setState(() => _puntuacion = i),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final etiqueta in CalificarScreen.etiquetasRapidas)
              FilterChip(
                key: Key('calificar-etiqueta-$etiqueta'),
                label: Text(etiqueta),
                selected: _etiquetas.contains(etiqueta),
                onSelected: _enviando || _bloqueada(etiqueta)
                    ? null
                    : (v) => setState(
                        () => v
                            ? _etiquetas.add(etiqueta)
                            : _etiquetas.remove(etiqueta),
                      ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          key: const Key('calificar-comentario'),
          controller: _comentario,
          maxLength: 500,
          maxLines: 3,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(labelText: 'Comentario (opcional)'),
        ),
        if (_error != null) ...[
          const SizedBox(height: AppSpacing.sm),
          MensajeError(texto: _error!),
        ],
        const SizedBox(height: AppSpacing.md),
        ElevatedButton(
          key: const Key('calificar-enviar'),
          onPressed: _enviando ? null : _enviar,
          child: _enviando
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Enviar calificación'),
        ),
      ],
    );
  }
}
