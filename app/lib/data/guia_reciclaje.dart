import '../models/material_type.dart';

/// Qué sí y qué no se recicla de un material, y cómo dejarlo.
class GuiaMaterial {
  final TipoMaterial material;
  final String intro;
  final List<String> si;
  final List<String> no;

  /// Sigue a "Antes de dejarlo:".
  final String preparacion;

  const GuiaMaterial({
    required this.material,
    required this.intro,
    required this.si,
    required this.no,
    required this.preparacion,
  });
}

/// Un tipo de plástico según el número del triángulo.
class ResinaPlastico {
  final int numero;
  final String sigla;
  final String ejemplos;
  final bool seRecicla;

  const ResinaPlastico(this.numero, this.sigla, this.ejemplos, this.seRecicla);
}

/// Textos del lienzo corregido del rediseño (`Guia.dc.html`): el PEBD (bolsas
/// y film) NO se recicla. Aceite usado no estaba en el lienzo; su texto es
/// propio y falta revisarlo con el equipo.
const guiaReciclaje = [
  GuiaMaterial(
    material: TipoMaterial.plastico,
    intro:
        'No todo el plástico es igual. El número dentro del triángulo dice si '
        'se puede reciclar.',
    si: [
      'Botellas de bebida y agua (1)',
      'Envases de shampoo, cloro y detergente (2)',
      'Tapas y potes de yogur (5)',
    ],
    no: [
      'Plumavit y bandejas de carne (6)',
      'Bolsas y envoltorios flexibles, aunque estén limpios',
      'Envases con restos de comida',
    ],
    preparacion: 'enjuaga, escurre y aplasta. Las tapas pueden ir puestas.',
  ),
  GuiaMaterial(
    material: TipoMaterial.vidrio,
    intro: 'El vidrio se recicla infinitas veces sin perder calidad.',
    si: [
      'Botellas de vino, cerveza y jugo',
      'Frascos de mermelada y conservas',
    ],
    no: [
      'Vasos, copas y loza',
      'Espejos y vidrio de ventana',
      'Ampolletas y tubos fluorescentes',
    ],
    preparacion: 'vacía y saca las tapas metálicas (van en latas).',
  ),
  GuiaMaterial(
    material: TipoMaterial.papel,
    intro: 'Papel y cartón limpios y secos.',
    si: ['Diarios, revistas, cuadernos', 'Cajas de cartón desarmadas'],
    no: [
      'Servilletas y papel higiénico usados',
      'Cajas de pizza con grasa',
      'Papel plastificado o metalizado',
    ],
    preparacion: 'desarma las cajas y mantenlo seco.',
  ),
  GuiaMaterial(
    material: TipoMaterial.metal,
    intro: 'Tarros y piezas metálicas pequeñas.',
    si: ['Tarros de conserva', 'Tapas metálicas de frascos'],
    no: ['Aerosoles con contenido', 'Cables y electrónicos (ver Servicios)'],
    preparacion: 'enjuaga los tarros y dobla la tapa hacia adentro.',
  ),
  GuiaMaterial(
    material: TipoMaterial.latas,
    intro: 'Latas de aluminio de bebida y cerveza.',
    si: ['Latas de bebida, cerveza y jugo'],
    no: ['Papel aluminio con comida', 'Latas de pintura'],
    preparacion: 'vacía y aplasta para que ocupen menos.',
  ),
  GuiaMaterial(
    material: TipoMaterial.pilas,
    intro: 'Nunca a la basura común: contaminan el suelo y el agua.',
    si: ['Pilas AA, AAA, botón', 'Baterías de celular (en puntos especiales)'],
    no: ['Baterías de auto (devuélvelas en la tienda)'],
    preparacion: 'cubre los polos con cinta si están hinchadas.',
  ),
  GuiaMaterial(
    material: TipoMaterial.tetraPak,
    intro:
        'Es su propia categoría: cartón, plástico y aluminio en capas. Va en '
        'su contenedor, no con el papel.',
    si: ['Cajas de leche, jugo y vino', 'Cajas de crema y salsas'],
    no: ['Vasos de papel de café (son otro material)'],
    preparacion: 'enjuaga, abre las esquinas y aplasta.',
  ),
  GuiaMaterial(
    material: TipoMaterial.aceite,
    intro:
        'El aceite de cocina usado nunca va por el desagüe: contamina el agua.',
    si: ['Aceite de cocina usado, ya frío', 'Aceite de freír colado'],
    no: [
      'Aceite de motor (va a un servicio especial)',
      'Grasa mezclada con restos de comida',
    ],
    preparacion:
        'déjalo enfriar, cuélalo y guárdalo en una botella plástica cerrada.',
  ),
];

const resinasPlastico = [
  ResinaPlastico(1, 'PET', 'Botellas de bebida', true),
  ResinaPlastico(2, 'PEAD', 'Shampoo, cloro', true),
  ResinaPlastico(3, 'PVC', 'Tuberías, blísteres', false),
  ResinaPlastico(4, 'PEBD', 'Bolsas, film y envoltorios', false),
  ResinaPlastico(5, 'PP', 'Tapas, potes de yogur', true),
  ResinaPlastico(6, 'PS', 'Plumavit, vasos', false),
  ResinaPlastico(7, 'Otros', 'Mezclas, policarbonato', false),
];

/// Vale para todos los materiales.
const avisoQuemado =
    'Un objeto quemado o derretido no se recicla, aunque sea del material '
    'correcto.';
