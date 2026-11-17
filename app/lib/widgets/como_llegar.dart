import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/punto_reciclaje.dart';
import '../services/navegacion_service.dart';
import '../theme/app_theme.dart';

/// Selector de transporte + botón primario "Cómo llegar", que abre la ruta
/// en Google Maps. El último modo elegido queda como predeterminado en el
/// teléfono (`modo_transporte`); la primera vez es micro/metro.
class ComoLlegar extends StatefulWidget {
  final PuntoReciclaje punto;

  /// Posición del usuario, si se conoce. Sin ella Google Maps usa la suya.
  final double? origenLat;
  final double? origenLng;

  const ComoLlegar({
    super.key,
    required this.punto,
    this.origenLat,
    this.origenLng,
  });

  @override
  State<ComoLlegar> createState() => _ComoLlegarState();
}

class _ComoLlegarState extends State<ComoLlegar> {
  static const _clave = 'modo_transporte';

  ModoTransporte _modo = ModoTransporte.transporte;

  @override
  void initState() {
    super.initState();
    _cargarModo();
  }

  Future<void> _cargarModo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final guardado = prefs.getString(_clave);
      final modo = ModoTransporte.values.where((m) => m.name == guardado);
      if (modo.isNotEmpty && mounted) setState(() => _modo = modo.first);
    } catch (_) {
      // Sin preferencias se queda en micro/metro.
    }
  }

  Future<void> _elegir(ModoTransporte modo) async {
    setState(() => _modo = modo);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_clave, modo.name);
    } catch (_) {}
  }

  Future<void> _abrir() async {
    final abierto = await abrirComoLlegar(
      destinoLat: widget.punto.lat,
      destinoLng: widget.punto.lng,
      modo: _modo,
      origenLat: widget.origenLat,
      origenLng: widget.origenLng,
    );
    if (!abierto && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No pudimos abrir Google Maps en este teléfono.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colores = context.colores;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final modo in ModoTransporte.values)
              ChoiceChip(
                avatar: Icon(
                  modo.icono,
                  size: 16,
                  color: _modo == modo
                      ? colores.primario
                      : colores.textoSecundario,
                ),
                label: Text(modo.etiqueta),
                selected: _modo == modo,
                onSelected: (_) => _elegir(modo),
              ),
          ],
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: _abrir,
          icon: const Icon(Icons.directions),
          label: const Text('Cómo llegar'),
        ),
      ],
    );
  }
}
