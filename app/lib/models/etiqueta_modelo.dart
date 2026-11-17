import 'material_type.dart';

/// Una clase del modelo de IA (una línea de `assets/modelo/labels.txt`). El
/// modelo solo devuelve un índice; el nombre y la descripción salen de la
/// categoría (`TipoMaterial`), así que toda la app usa los mismos nombres y
/// renombrar una categoría en la base no obliga a reentrenar.
class EtiquetaModelo {
  /// Etiqueta normalizada (minúsculas, sin tildes, `_` en vez de espacios).
  final String etiqueta;

  /// Categoría de la base (`categorias_residuo.codigo`); null si no se recicla.
  final TipoMaterial? material;

  const EtiquetaModelo(this.etiqueta, this.material);

  bool get reciclable => material != null;

  /// Nombre que se muestra y se dice por voz (`TipoMaterial.etiqueta`).
  String get nombre => material?.etiqueta ?? 'No reciclable';

  /// Etiqueta de la clase "no reciclable / no reconocido" (guía de IA, 8.1).
  static const codigoNoReciclable = 'no_reciclable';

  /// Qué hacer con un residuo que no se recicla.
  static const descripcionNoReciclable =
      'Va a la basura común. Si tienes dudas, revisa si tiene un símbolo '
      'de reciclaje.';

  /// La información de [etiqueta] tal como viene en `labels.txt`, o null si
  /// la app no la conoce. Acepta el código de la base (`papel`, `tetra_pak`)
  /// y variantes comunes ("Papel y cartón", "tetrapak", "No reciclable").
  static EtiquetaModelo? de(String etiqueta) =>
      _porEtiqueta[_alias[normalizar(etiqueta)] ?? normalizar(etiqueta)];

  /// La de un material (para cuando la persona elige la categoría a mano).
  static EtiquetaModelo deMaterial(TipoMaterial material) =>
      todas.firstWhere((e) => e.material == material);

  static const noReciclable = EtiquetaModelo(codigoNoReciclable, null);

  /// Las 7 categorías que se reconocen por foto (todas menos Aceite usado,
  /// que se recibe en puntos específicos) y "No reciclable".
  static const todas = [
    EtiquetaModelo('plastico', TipoMaterial.plastico),
    EtiquetaModelo('vidrio', TipoMaterial.vidrio),
    EtiquetaModelo('papel', TipoMaterial.papel),
    EtiquetaModelo('latas', TipoMaterial.latas),
    EtiquetaModelo('metal', TipoMaterial.metal),
    EtiquetaModelo('tetra_pak', TipoMaterial.tetraPak),
    EtiquetaModelo('pilas', TipoMaterial.pilas),
    noReciclable,
  ];

  static final _porEtiqueta = {for (final e in todas) e.etiqueta: e};

  static const _alias = {
    'plastic': 'plastico',
    'plasticos': 'plastico',
    'glass': 'vidrio',
    'papel_y_carton': 'papel',
    'papel_carton': 'papel',
    'carton': 'papel',
    'paper': 'papel',
    'cardboard': 'papel',
    'lata': 'latas',
    'cans': 'latas',
    'can': 'latas',
    'metales': 'metal',
    'tetrapak': 'tetra_pak',
    'tetra': 'tetra_pak',
    'pila': 'pilas',
    'baterias': 'pilas',
    'battery': 'pilas',
    'batteries': 'pilas',
    'no_reciclable_no_reconocido': codigoNoReciclable,
    'no_reconocido': codigoNoReciclable,
    'otro': codigoNoReciclable,
    'trash': codigoNoReciclable,
    'basura': codigoNoReciclable,
  };

  /// Minúsculas, sin tildes y con `_` entre palabras.
  static String normalizar(String texto) {
    const tildes = {'á': 'a', 'é': 'e', 'í': 'i', 'ó': 'o', 'ú': 'u', 'ü': 'u'};
    final base = texto.trim().toLowerCase().split('').map((c) {
      return tildes[c] ?? c;
    }).join();
    return base
        .replaceAll(RegExp(r'[^a-z0-9ñ]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
  }
}
