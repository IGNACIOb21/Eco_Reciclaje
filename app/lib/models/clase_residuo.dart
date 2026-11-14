import 'package:flutter/material.dart';

import 'material_type.dart';

/// Lo que la app sabe de cada clase que devuelve el modelo (las líneas de
/// `assets/modelo/labels.txt`): cómo se llama, su ícono, qué material de la
/// app le corresponde y qué hacer con el objeto.
///
/// [material] es null cuando la app todavía no tiene ese material (ropa,
/// electrónicos y zapatos): el modelo los reconoce, pero no hay filtro de
/// mapa para ellos.
class InfoClase {
  final String codigo;
  final String nombre;
  final IconData icono;
  final Color color;
  final TipoMaterial? material;
  final String consejo;

  const InfoClase({
    required this.codigo,
    required this.nombre,
    required this.icono,
    required this.color,
    required this.material,
    required this.consejo,
  });
}

/// Clase → material de la app. Si el modelo se reentrena con clases nuevas,
/// basta con agregarlas aquí; mientras tanto [infoDeClase] las muestra con su
/// nombre tal cual.
final Map<String, InfoClase> _infoPorClase = {
  'battery': InfoClase(
    codigo: 'battery',
    nombre: 'Pilas / baterías',
    icono: TipoMaterial.pilas.icono,
    color: TipoMaterial.pilas.color,
    material: TipoMaterial.pilas,
    consejo:
        'No las botes a la basura común: llévalas a un punto de recolección de pilas.',
  ),
  'cardboard': InfoClase(
    codigo: 'cardboard',
    nombre: 'Cartón',
    icono: Icons.inventory_2_outlined,
    color: TipoMaterial.papel.color,
    material: TipoMaterial.papel,
    consejo: 'Mantenlo seco y limpio, sin restos de comida ni grasa, y aplástalo.',
  ),
  'clothes': const InfoClase(
    codigo: 'clothes',
    nombre: 'Ropa',
    icono: Icons.checkroom_outlined,
    color: Color(0xFF9C6ADE),
    material: null,
    consejo:
        'Si está en buen estado, dónala. Si no, busca un punto de reciclaje textil.',
  ),
  'electronic': const InfoClase(
    codigo: 'electronic',
    nombre: 'Electrónicos',
    icono: Icons.devices_other_outlined,
    color: Color(0xFF3B82C4),
    material: null,
    consejo:
        'No los botes a la basura común: llévalos a un punto limpio o a una campaña de reciclaje de electrónicos.',
  ),
  'glass': InfoClase(
    codigo: 'glass',
    nombre: 'Vidrio',
    icono: TipoMaterial.vidrio.icono,
    color: TipoMaterial.vidrio.color,
    material: TipoMaterial.vidrio,
    consejo: 'Vacíalo, enjuágalo y llévalo a un contenedor o campana de vidrio.',
  ),
  'metal': InfoClase(
    codigo: 'metal',
    nombre: 'Metal',
    icono: TipoMaterial.metal.icono,
    color: TipoMaterial.metal.color,
    material: TipoMaterial.metal,
    consejo: 'Enjuágalo y llévalo a un punto de reciclaje de metales.',
  ),
  'paper': InfoClase(
    codigo: 'paper',
    nombre: 'Papel',
    icono: TipoMaterial.papel.icono,
    color: TipoMaterial.papel.color,
    material: TipoMaterial.papel,
    consejo: 'Mantenlo seco y limpio, sin restos de comida ni grasa.',
  ),
  'plastic': InfoClase(
    codigo: 'plastic',
    nombre: 'Plástico',
    icono: TipoMaterial.plastico.icono,
    color: TipoMaterial.plastico.color,
    material: TipoMaterial.plastico,
    consejo: 'Vacíalo, enjuágalo y aplástalo antes de llevarlo a un punto de reciclaje.',
  ),
  'shoes': const InfoClase(
    codigo: 'shoes',
    nombre: 'Zapatos',
    icono: Icons.directions_walk,
    color: Color(0xFF8B5E3C),
    material: null,
    consejo:
        'Si están en buen estado, dónalos. Si no, busca un punto de reciclaje de calzado.',
  ),
};

InfoClase infoDeClase(String codigo) {
  return _infoPorClase[codigo] ??
      InfoClase(
        codigo: codigo,
        nombre: codigo,
        icono: Icons.help_outline,
        color: const Color(0xFF8C8F94),
        material: null,
        consejo: 'Revisa en un punto de reciclaje si lo reciben.',
      );
}
