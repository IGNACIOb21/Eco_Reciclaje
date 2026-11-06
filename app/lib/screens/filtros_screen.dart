import 'package:flutter/material.dart';

import '../data/comunas_demo.dart';
import '../models/filtros_mapa.dart';
import '../models/material_type.dart';
import '../theme/app_theme.dart';
import '../widgets/app_bottom_sheet.dart';
import '../widgets/seccion_titulo.dart';

/// Muestra la hoja de filtros y devuelve los filtros aplicados, o null si se
/// cerró sin aplicar (ej. deslizando hacia abajo).
Future<FiltrosMapa?> mostrarFiltrosMapa(
  BuildContext context,
  FiltrosMapa actuales,
) {
  return mostrarAppBottomSheet<FiltrosMapa>(
    context: context,
    builder: (_) => FiltrosScreen(filtrosIniciales: actuales),
  );
}

class FiltrosScreen extends StatefulWidget {
  final FiltrosMapa filtrosIniciales;

  const FiltrosScreen({super.key, required this.filtrosIniciales});

  @override
  State<FiltrosScreen> createState() => _FiltrosScreenState();
}

class _FiltrosScreenState extends State<FiltrosScreen> {
  late String? _comuna = widget.filtrosIniciales.comuna;
  final Set<TipoMaterial> _materiales = {};
  late double _distanciaMaxima = widget.filtrosIniciales.distanciaMaximaKm;
  late bool _soloDisponibles = widget.filtrosIniciales.soloDisponibles;
  late int _calificacionMinima = widget.filtrosIniciales.calificacionMinima;
  late OrdenPuntos _ordenarPor = widget.filtrosIniciales.ordenarPor;

  @override
  void initState() {
    super.initState();
    _materiales.addAll(widget.filtrosIniciales.materiales);
  }

  @override
  Widget build(BuildContext context) {
    return AppBottomSheet(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Filtros',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
          ),
          const SizedBox(height: 20),
          const SeccionTitulo('Comuna'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                label: const Text('Todas'),
                selected: _comuna == null,
                onSelected: (_) => setState(() => _comuna = null),
              ),
              for (final comuna in comunasDemo)
                ChoiceChip(
                  label: Text(comuna.nombre),
                  selected: _comuna == comuna.nombre,
                  onSelected: (_) => setState(() => _comuna = comuna.nombre),
                ),
            ],
          ),
          const SizedBox(height: 20),
          SeccionTitulo('Materiales'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final material in TipoMaterial.values)
                FilterChip(
                  avatar: Icon(material.icono, size: 16, color: material.color),
                  label: Text(material.etiqueta),
                  selected: _materiales.contains(material),
                  onSelected: (seleccionado) => setState(() {
                    if (seleccionado) {
                      _materiales.add(material);
                    } else {
                      _materiales.remove(material);
                    }
                  }),
                ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SeccionTitulo('Distancia máxima'),
              Text(
                '${_distanciaMaxima.toStringAsFixed(_distanciaMaxima < 1 ? 1 : 0)} km',
                style: TextStyle(
                  color: context.colores.textoSecundario,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          Slider(
            value: _distanciaMaxima,
            min: 0.5,
            max: 10,
            divisions: 19,
            onChanged: (valor) => setState(() => _distanciaMaxima = valor),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SeccionTitulo('Solo mostrar disponibles'),
              Switch(
                value: _soloDisponibles,
                onChanged: (valor) => setState(() => _soloDisponibles = valor),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SeccionTitulo('Calificación mínima'),
          const SizedBox(height: 6),
          Row(
            children: List.generate(5, (i) {
              final n = i + 1;
              return IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                icon: Icon(
                  n <= _calificacionMinima ? Icons.star : Icons.star_border,
                  color: context.colores.acento,
                ),
                onPressed: () => setState(() {
                  _calificacionMinima = _calificacionMinima == n ? 0 : n;
                }),
              );
            }),
          ),
          const SizedBox(height: 12),
          SeccionTitulo('Ordenar por'),
          const SizedBox(height: 8),
          DropdownButtonFormField<OrdenPuntos>(
            initialValue: _ordenarPor,
            decoration: InputDecoration(
              fillColor: context.colores.fondoSecundario,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            items: [
              for (final orden in OrdenPuntos.values)
                DropdownMenuItem(value: orden, child: Text(orden.etiqueta)),
            ],
            onChanged: (valor) =>
                setState(() => _ordenarPor = valor ?? _ordenarPor),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () =>
                      Navigator.of(context).pop(const FiltrosMapa()),
                  child: const Text('Limpiar'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.colores.fondoSecundario,
                    foregroundColor: context.colores.secundario,
                  ),
                  onPressed: () => Navigator.of(context).pop(
                    FiltrosMapa(
                      comuna: _comuna,
                      materiales: _materiales,
                      distanciaMaximaKm: _distanciaMaxima,
                      soloDisponibles: _soloDisponibles,
                      calificacionMinima: _calificacionMinima,
                      ordenarPor: _ordenarPor,
                    ),
                  ),
                  child: const Text('Aplicar filtros'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
