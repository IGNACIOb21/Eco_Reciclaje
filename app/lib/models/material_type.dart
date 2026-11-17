import 'package:flutter/material.dart';

enum TipoMaterial {
  vidrio,
  papel,
  plastico,
  metal,
  pilas,
  latas,
  tetraPak,
  aceite,
}

/// Frase de las categorías que se reciclan enteras (sección "Qué no se
/// recicla").
const seReciclaCompleto =
    'Este material se recicla por completo, siempre que esté limpio, seco y '
    'libre de contenido.';

extension MaterialTypeInfo on TipoMaterial {
  /// Código tal como está en `categorias_residuo.codigo` del esquema remoto (ver
  /// backend/remoto/20261010100000_app_puntos_cercanos.sql). Un reciclable es una
  /// categoría: el aceite usado es una más, como vidrio o papel.
  String get codigo => switch (this) {
    TipoMaterial.vidrio => 'vidrio',
    TipoMaterial.papel => 'papel',
    TipoMaterial.plastico => 'plastico',
    TipoMaterial.metal => 'metal',
    TipoMaterial.pilas => 'pilas',
    TipoMaterial.latas => 'latas',
    TipoMaterial.tetraPak => 'tetra_pak',
    TipoMaterial.aceite => 'aceite',
  };

  static TipoMaterial? fromCodigo(String codigo) => switch (codigo) {
    'vidrio' => TipoMaterial.vidrio,
    'papel' => TipoMaterial.papel,
    'plastico' => TipoMaterial.plastico,
    'metal' => TipoMaterial.metal,
    'pilas' => TipoMaterial.pilas,
    'latas' => TipoMaterial.latas,
    'tetra_pak' => TipoMaterial.tetraPak,
    'aceite' => TipoMaterial.aceite,
    _ => null,
  };

  String get etiqueta => switch (this) {
    TipoMaterial.vidrio => 'Vidrio',
    TipoMaterial.papel => 'Papel y cartón',
    TipoMaterial.plastico => 'Plástico',
    TipoMaterial.metal => 'Metal',
    TipoMaterial.pilas => 'Pilas',
    TipoMaterial.latas => 'Latas',
    TipoMaterial.tetraPak => 'Tetra Pak',
    TipoMaterial.aceite => 'Aceite usado',
  };

  /// Qué abarca, dónde se deposita y en qué se transforma, para mostrar y
  /// decir por voz. Es la copia local de `categorias_residuo.descripcion`
  /// (backend/remoto_propuesto/20261018100000_descripciones_categorias.sql):
  /// la app usa la de la base cuando la tiene (`DescripcionesCategorias`).
  String get descripcion => switch (this) {
    TipoMaterial.latas =>
      'Envases de aluminio como latas de bebidas y conservas. Deben '
          'depositarse limpios y aplastados en el contenedor de Latas. Al '
          'reciclarse, se transforman en nuevas latas o piezas de aluminio.',
    TipoMaterial.pilas =>
      'Pilas domésticas como AA, AAA y de botón. Deben depositarse en '
          'contenedores especiales para residuos peligrosos. Se reciclan para '
          'recuperar metales pesados como zinc y níquel.',
    TipoMaterial.tetraPak =>
      'Envases multilaminados de leches, jugos y alimentos. Deben '
          'depositarse limpios, secos y aplastados en el contenedor de Tetra '
          'Pak. Se reciclan para fabricar cartón y placas de construcción.',
    TipoMaterial.vidrio =>
      'Botellas y frascos de vidrio. Deben depositarse sin tapas ni corchos '
          'en el contenedor de Vidrio. Se reciclan infinitamente para fabricar '
          'nuevas botellas y envases de vidrio.',
    TipoMaterial.metal =>
      'Objetos metálicos como tapas, tarros y chatarra pequeña. Deben '
          'depositarse limpios en el contenedor de Metal. Se reciclan para '
          'elaborar estructuras metálicas y herramientas.',
    TipoMaterial.plastico =>
      'Botellas de bebida, envases rígidos y bolsas plásticas. Deben '
          'depositarse limpios y aplastados en el contenedor de Plástico. Se '
          'reciclan en fibras textiles y nuevos envases.',
    TipoMaterial.papel =>
      'Hojas, revistas, cajas de cartón y diarios. Deben depositarse secos y '
          'aplanados en el contenedor de Papel y cartón. Se reciclan en papel '
          'higiénico y cajas de cartón reciclado.',
    TipoMaterial.aceite =>
      'Aceite de cocina usado y frío. Debe entregarse embotellado en puntos '
          'de acopio de Aceite usado. Se recicla principalmente para producir '
          'biocombustible y jabón.',
  };

  /// En qué productos se suele transformar al reciclarse (sección "¿En qué se
  /// transforma?"). Copia local de `categorias_residuo.destino_reutilizacion`.
  String get productosResultantes => switch (this) {
    TipoMaterial.plastico =>
      'Los plásticos reciclados suelen ser procesados para fabricar nuevas '
          'botellas de bebida, fibras textiles para ropa, maceteros, tuberías '
          'y envases rígidos.',
    TipoMaterial.vidrio =>
      'El vidrio reciclado se funde para fabricar nuevas botellas, frascos y '
          'envases de vidrio, una y otra vez y sin perder calidad.',
    TipoMaterial.papel =>
      'El papel y el cartón reciclados se convierten en papel higiénico, '
          'servilletas, cajas de cartón, cartulinas y bandejas para huevos.',
    TipoMaterial.latas =>
      'Las latas de aluminio recicladas se funden para fabricar nuevas latas, '
          'piezas de automóviles, marcos de ventanas y utensilios de cocina.',
    TipoMaterial.metal =>
      'Los metales reciclados se funden para fabricar estructuras, '
          'herramientas, piezas de maquinaria, clavos y nuevos envases.',
    TipoMaterial.tetraPak =>
      'Los envases de Tetra Pak se separan en cartón, plástico y aluminio. El '
          'cartón se usa para fabricar papel y cajas, y la mezcla de plástico y '
          'aluminio, para placas de construcción y muebles.',
    TipoMaterial.pilas =>
      'De las pilas recicladas se recuperan metales como zinc, níquel y '
          'manganeso, que se reutilizan en nuevas baterías y en la industria '
          'metalúrgica.',
    TipoMaterial.aceite =>
      'El aceite usado se transforma principalmente en biodiésel, y también '
          'en jabones, velas y lubricantes industriales.',
  };

  /// Qué partes del artículo no se suelen reciclar (sección "Qué no se recicla"). Si se recicla entero, lo dice con
  /// [seReciclaCompleto]. Copia local de
  /// `categorias_residuo.partes_no_reciclables`.
  String get partesNoReciclables => switch (this) {
    TipoMaterial.plastico =>
      'Las bombillas, los cubiertos desechables, los envoltorios metalizados '
          'de snacks, el plumavit y las tapas compuestas de varios materiales '
          'no se reciclan. Tampoco los líquidos residuales ni los plásticos '
          'con restos de comida o grasa.',
    TipoMaterial.vidrio =>
      '$seReciclaCompleto Las tapas y los corchos no se reciclan con el '
          'vidrio. Los espejos, las ventanas, las ampolletas, la loza y la '
          'cerámica tampoco van en este contenedor.',
    TipoMaterial.papel =>
      'No se reciclan el papel sucio con comida o grasa, como las cajas de '
          'pizza manchadas o las servilletas usadas, el papel plastificado o '
          'metalizado, los tickets de papel térmico, ni los sellos, las cintas '
          'adhesivas, los corchetes y los espirales pegados al papel.',
    TipoMaterial.latas =>
      '$seReciclaCompleto Los aerosoles con contenido y las latas con '
          'restos de pintura o químicos no se reciclan aquí.',
    TipoMaterial.metal =>
      'Las partes de plástico, goma o madera, como mangos o sellos, no se '
          'reciclan con el metal. Tampoco los restos de comida ni los envases '
          'con pintura o químicos.',
    TipoMaterial.tetraPak =>
      'Las bombillas y sus envoltorios plásticos no se reciclan con el '
          'envase, ni los líquidos residuales que queden dentro.',
    TipoMaterial.pilas =>
      'La pila se recicla entera como residuo peligroso, sin desarmarla. Las '
          'baterías de auto no van en este contenedor.',
    TipoMaterial.aceite =>
      'El agua, los restos de comida y el aceite de motor mezclados con el '
          'aceite de cocina impiden reciclarlo.',
  };

  IconData get icono => switch (this) {
    TipoMaterial.vidrio => Icons.wine_bar_outlined,
    TipoMaterial.papel => Icons.description_outlined,
    TipoMaterial.plastico => Icons.local_drink_outlined,
    TipoMaterial.metal => Icons.hardware_outlined,
    TipoMaterial.pilas => Icons.battery_full,
    TipoMaterial.latas => Icons.local_bar_outlined,
    TipoMaterial.tetraPak => Icons.inventory_2_outlined,
    TipoMaterial.aceite => Icons.oil_barrel_outlined,
  };

  Color get color => switch (this) {
    TipoMaterial.vidrio => const Color(0xFF2E9E5B),
    TipoMaterial.papel => const Color(0xFF2E7DD1),
    TipoMaterial.plastico => const Color(0xFFF2B705),
    TipoMaterial.metal => const Color(0xFF8C8F94),
    TipoMaterial.pilas => const Color(0xFFE0483F),
    TipoMaterial.latas => const Color(0xFFE07B39),
    TipoMaterial.tetraPak => const Color(0xFF7C4DBE),
    TipoMaterial.aceite => const Color(0xFF8B5E3C),
  };
}
