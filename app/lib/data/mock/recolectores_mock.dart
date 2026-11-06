import '../../models/material_type.dart';
import '../../models/recolector_particular.dart';

/// Datos de ejemplo de recolectores particulares — temporal, hasta que esta
/// entidad se defina y migre en Supabase (ver TODO en
/// recolectores_repository.dart). Personas, negocios y contactos no son
/// reales.
final List<RecolectorParticular> recolectoresMock = [
  const RecolectorParticular(
    id: '1',
    nombre: 'Aceite Circular Ñuñoa',
    materiales: [TipoMaterial.aceite],
    comuna: 'Ñuñoa',
    descripcion:
        'Retira aceite de cocina usado en botellas cerradas, mínimo 1 litro.',
    contacto: '+56 9 8123 4567',
    retiraADomicilio: true,
  ),
  const RecolectorParticular(
    id: '2',
    nombre: 'Karla V. — Tetra Pak Providencia',
    materiales: [TipoMaterial.tetraPak],
    comuna: 'Providencia',
    descripcion:
        'Junta tetra pak limpio y aplastado, coordina el retiro por WhatsApp.',
    contacto: '@karla.reciclatetra (Instagram)',
    retiraADomicilio: true,
  ),
  const RecolectorParticular(
    id: '3',
    nombre: 'EcoPilas Macul',
    materiales: [TipoMaterial.pilas],
    comuna: 'Macul',
    descripcion: 'Acopio de pilas y baterías chicas, dejar en el punto fijo los fines de semana.',
    contacto: '+56 9 5555 1234',
    retiraADomicilio: false,
  ),
  const RecolectorParticular(
    id: '4',
    nombre: 'Recicladora El Roble',
    materiales: [TipoMaterial.aceite, TipoMaterial.latas],
    comuna: 'La Reina',
    descripcion: 'Compra aceite usado y latas de aluminio por kilo.',
    contacto: 'recicladoraelroble@gmail.com',
    retiraADomicilio: false,
  ),
  const RecolectorParticular(
    id: '5',
    nombre: 'Vidrio Vecinal Las Condes',
    materiales: [TipoMaterial.vidrio],
    comuna: 'Las Condes',
    descripcion: 'Retira botellas y frascos de vidrio, avisar con un día de anticipación.',
    contacto: '+56 9 4321 8765',
    retiraADomicilio: true,
  ),
  const RecolectorParticular(
    id: '6',
    nombre: 'Papelero Peñalolén',
    materiales: [TipoMaterial.papel, TipoMaterial.tetraPak],
    comuna: 'Peñalolén',
    descripcion:
        'Recibe cartón, papel y tetra pak en su local, horario de tarde.',
    contacto: '+56 9 1122 3344',
    retiraADomicilio: false,
  ),
];
