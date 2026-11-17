import '../utils/geo.dart';
import 'material_type.dart';

/// Lo que trae el QR pegado en un contenedor (formato en docs/formato-qr.md):
///
///     rebin://punto/<codigo_qr>?s=<qr_secreto>&id=<id_punto>
///         &lat=<latitud>&lng=<longitud>&n=<nombre>
///
/// Solo el código y el secreto validan el punto (`app_punto_qr`). El id, la
/// ubicación y el nombre son informativos: la app compara el id con el de la
/// base y siempre mide la distancia con la ubicación de la base, porque un QR
/// se puede copiar o editar.
class CodigoQrPunto {
  final String codigo;
  final String? secreto;
  final int? idPunto;
  final String? nombre;
  final double? lat;
  final double? lng;

  const CodigoQrPunto(
    this.codigo, {
    this.secreto,
    this.idPunto,
    this.nombre,
    this.lat,
    this.lng,
  });

  static final _codigoValido = RegExp(r'^[A-Za-z0-9_-]{3,100}$');
  static final _idValido = RegExp(r'^[1-9][0-9]{0,17}$');

  /// Null si el contenido no es un QR de Rebin o trae un campo mal formado
  /// (id no numérico, solo latitud o solo longitud, coordenadas fuera de
  /// rango). También acepta el código solo (`RB-…`), para los puntos que no
  /// tienen secreto. Los parámetros desconocidos se ignoran.
  static CodigoQrPunto? leer(String contenido) {
    final texto = contenido.trim();
    final uri = Uri.tryParse(texto);
    if (uri != null && uri.scheme == 'rebin') {
      if (uri.host != 'punto' || uri.pathSegments.length != 1) return null;
      final codigo = uri.pathSegments.single;
      if (!_codigoValido.hasMatch(codigo)) return null;
      final Map<String, String> p;
      try {
        p = uri.queryParameters;
      } catch (_) {
        return null;
      }
      String? opcional(String clave) {
        final valor = p[clave]?.trim();
        return valor == null || valor.isEmpty ? null : valor;
      }

      final id = opcional('id');
      if (id != null && !_idValido.hasMatch(id)) return null;
      final latTexto = opcional('lat');
      final lngTexto = opcional('lng');
      if ((latTexto == null) != (lngTexto == null)) return null;
      final lat = latTexto == null ? null : double.tryParse(latTexto);
      final lng = lngTexto == null ? null : double.tryParse(lngTexto);
      if (latTexto != null &&
          (lat == null || lng == null || lat.abs() > 90 || lng.abs() > 180)) {
        return null;
      }
      final nombre = opcional('n');
      return CodigoQrPunto(
        codigo,
        secreto: opcional('s'),
        idPunto: id == null ? null : int.parse(id),
        nombre: nombre == null || nombre.length <= 100
            ? nombre
            : nombre.substring(0, 100),
        lat: lat,
        lng: lng,
      );
    }
    if (texto.toUpperCase().startsWith('RB-') &&
        _codigoValido.hasMatch(texto)) {
      return CodigoQrPunto(texto);
    }
    return null;
  }
}

/// El punto que corresponde a un QR, según `app_punto_qr`.
class PuntoQr {
  final CodigoQrPunto qr;
  final int idPunto;
  final String nombre;
  final String? direccion;
  final double lat;
  final double lng;
  final String estadoOperativo;
  final String estadoQr;

  /// false si el punto no está operativo o su QR está faltante o dañado: la
  /// base rechazaría los depósitos.
  final bool recibeDepositos;

  /// Categorías que recibe (`punto_categoria`).
  final Set<TipoMaterial> materiales;

  const PuntoQr({
    required this.qr,
    required this.idPunto,
    required this.nombre,
    required this.lat,
    required this.lng,
    required this.materiales,
    this.direccion,
    this.estadoOperativo = 'operativo',
    this.estadoQr = 'activo',
    this.recibeDepositos = true,
  });

  /// Distancia máxima al punto para registrar un depósito: la misma con la
  /// que `app_registrar_deposito` aprueba sin dudar.
  static const distanciaMaximaMetros = 50.0;

  bool acepta(TipoMaterial material) => materiales.contains(material);

  /// Metros en línea recta desde (lat, lng) hasta el punto.
  double distanciaMetros(double lat, double lng) =>
      distanciaKm(lat, lng, this.lat, this.lng) * 1000;

  /// Por qué no recibe depósitos, para mostrarlo.
  String get motivoNoRecibe => estadoQr != 'activo'
      ? 'El QR de este punto está reportado como faltante o dañado.'
      : 'Este punto no está operativo en este momento.';

  factory PuntoQr.fromSupabase(CodigoQrPunto qr, Map<String, dynamic> m) =>
      PuntoQr(
        qr: qr,
        idPunto: (m['id_punto'] as num).toInt(),
        nombre: m['nombre'] as String,
        direccion: m['direccion'] as String?,
        lat: (m['lat'] as num).toDouble(),
        lng: (m['lng'] as num).toDouble(),
        estadoOperativo: m['estado_operativo'] as String,
        estadoQr: m['estado_qr'] as String,
        recibeDepositos: m['recibe_depositos'] as bool,
        materiales: {
          for (final c in (m['categorias'] as List? ?? const []))
            ?MaterialTypeInfo.fromCodigo(c as String),
        },
      );
}
