import 'dart:typed_data';
import 'dart:ui' as ui;

/// dHash de 64 bits de una imagen, en 16 caracteres hexadecimales
/// (`reciclajes.hash_perceptual`). Dos fotos casi iguales (la misma foto
/// reenviada, recomprimida o con otro tamaño) dan el mismo hash o uno muy
/// parecido; la base lo usa para detectar depósitos repetidos.
///
/// Se reduce la foto a 9×8 en escala de grises y cada bit dice si un píxel es
/// más claro que su vecino de la derecha.
Future<String> hashPerceptual(Uint8List bytesImagen) async {
  final codec = await ui.instantiateImageCodec(
    bytesImagen,
    targetWidth: 9,
    targetHeight: 8,
  );
  final imagen = (await codec.getNextFrame()).image;
  final datos = await imagen.toByteData(format: ui.ImageByteFormat.rawRgba);
  imagen.dispose();
  codec.dispose();
  if (datos == null) throw StateError('No se pudo leer la imagen');

  double gris(int x, int y) {
    final i = (y * 9 + x) * 4;
    return 0.299 * datos.getUint8(i) +
        0.587 * datos.getUint8(i + 1) +
        0.114 * datos.getUint8(i + 2);
  }

  final hex = StringBuffer();
  for (var y = 0; y < 8; y++) {
    var fila = 0;
    for (var x = 0; x < 8; x++) {
      fila = (fila << 1) | (gris(x, y) > gris(x + 1, y) ? 1 : 0);
    }
    hex.write(fila.toRadixString(16).padLeft(2, '0'));
  }
  return hex.toString();
}
