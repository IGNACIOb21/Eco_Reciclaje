/// Centro aproximado de cada comuna de la demo, usado para sembrar los puntos
/// mock y como opciones del filtro de comuna. No es una restricción del
/// backend — la función RPC `puntos_cercanos` funciona con cualquier comuna.
class ComunaDemo {
  final String nombre;
  final double lat;
  final double lng;
  final String calleReferencia;

  const ComunaDemo({
    required this.nombre,
    required this.lat,
    required this.lng,
    required this.calleReferencia,
  });
}

const comunasDemo = [
  ComunaDemo(
    nombre: 'Santiago',
    lat: -33.4489,
    lng: -70.6693,
    calleReferencia: "Av. Libertador Bernardo O'Higgins",
  ),
  ComunaDemo(
    nombre: 'Providencia',
    lat: -33.4265,
    lng: -70.6188,
    calleReferencia: 'Av. Providencia',
  ),
  ComunaDemo(
    nombre: 'Ñuñoa',
    lat: -33.4558,
    lng: -70.5989,
    calleReferencia: 'Av. Irarrázaval',
  ),
  ComunaDemo(
    nombre: 'La Reina',
    lat: -33.4436,
    lng: -70.5389,
    calleReferencia: 'Av. Larraín',
  ),
  ComunaDemo(
    nombre: 'Las Condes',
    lat: -33.4089,
    lng: -70.5693,
    calleReferencia: 'Av. Apoquindo',
  ),
  ComunaDemo(
    nombre: 'Peñalolén',
    lat: -33.4890,
    lng: -70.5477,
    calleReferencia: 'Av. Grecia',
  ),
  ComunaDemo(
    nombre: 'Macul',
    lat: -33.4869,
    lng: -70.5978,
    calleReferencia: 'Av. Macul',
  ),
];

/// Centro por defecto del mapa cuando no hay GPS disponible: Plaza Ñuñoa.
const centroDefectoLat = -33.4558;
const centroDefectoLng = -70.5989;
