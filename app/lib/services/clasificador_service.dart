import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

import '../models/resultado_clasificacion.dart';

/// Lado de la foto que espera el modelo (IMG_SIZE de config.py).
const int tamanoImagenModelo = 224;

const String _rutaModelo = 'assets/modelo/model.tflite';
const String _rutaEtiquetas = 'assets/modelo/labels.txt';

/// Prepara la foto igual que `preparar_foto` de predecir.py: RGB, 224x224
/// (estirada, sin recortar) y float32 con valores 0..255. NO se normaliza:
/// MobileNetV3 ya lo hace dentro del modelo.
///
/// Es una función de nivel superior para poder correrla con `compute` (en
/// otro isolate) y no congelar la pantalla con fotos grandes.
Float32List prepararImagen(Uint8List bytes) {
  final decodificada = img.decodeImage(bytes);
  if (decodificada == null) {
    throw const FormatException('No se pudo leer la imagen.');
  }
  // Las fotos de celular traen la rotación en EXIF: se aplica para que el
  // modelo no reciba la foto de lado.
  final orientada = img.bakeOrientation(decodificada);
  final redimensionada = img.copyResize(
    orientada,
    width: tamanoImagenModelo,
    height: tamanoImagenModelo,
    interpolation: img.Interpolation.linear,
  );
  final rgb = redimensionada.convert(numChannels: 3);

  final datos = Float32List(tamanoImagenModelo * tamanoImagenModelo * 3);
  var i = 0;
  for (final px in rgb) {
    datos[i++] = px.r.toDouble();
    datos[i++] = px.g.toDouble();
    datos[i++] = px.b.toDouble();
  }
  return datos;
}

/// Carga el modelo TFLite y clasifica fotos. Todo ocurre en el teléfono: no
/// usa internet ni Supabase.
class Clasificador {
  final Interpreter _interprete;

  /// Clases en el orden en que las devuelve el modelo (labels.txt).
  final List<String> clases;

  Clasificador._(this._interprete, this.clases);

  static Future<Clasificador> cargar() async {
    final interprete = await Interpreter.fromAsset(_rutaModelo);
    try {
      final texto = await rootBundle.loadString(_rutaEtiquetas);
      final clases = texto
          .split('\n')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      // El modelo y labels.txt deben salir del mismo entrenamiento.
      final salidas = interprete.getOutputTensor(0).shape.last;
      if (salidas != clases.length) {
        throw StateError(
          'El modelo devuelve $salidas clases pero labels.txt tiene '
          '${clases.length}. Copia model.tflite y labels.txt juntos.',
        );
      }
      return Clasificador._(interprete, clases);
    } catch (_) {
      interprete.close();
      rethrow;
    }
  }

  Future<ResultadoClasificacion> clasificar(
    Uint8List bytesFoto, {
    int top = 3,
  }) async {
    final entrada = await compute(prepararImagen, bytesFoto);

    final salida = [List<double>.filled(clases.length, 0.0)];
    final reloj = Stopwatch()..start();
    _interprete.run(
      entrada.reshape([1, tamanoImagenModelo, tamanoImagenModelo, 3]),
      salida,
    );
    reloj.stop();

    final probs = salida[0];
    final indices = List<int>.generate(probs.length, (i) => i)
      ..sort((a, b) => probs[b].compareTo(probs[a]));
    final mejores = indices
        .take(top)
        .map((i) => Prediccion(clases[i], probs[i]))
        .toList();
    return ResultadoClasificacion(mejores, reloj.elapsedMilliseconds);
  }

  void cerrar() => _interprete.close();
}
