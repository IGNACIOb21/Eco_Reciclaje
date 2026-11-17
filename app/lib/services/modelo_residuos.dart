import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

/// Modelo de IA que clasifica la foto de un residuo, dentro del teléfono.
///
/// Lo entrega el equipo de Machine Learning en `assets/modelo/` (contrato en
/// `assets/modelo/LEEME.md`):
///   * `model.tflite`: entrada [1, alto, ancho, 3] RGB; salida [1, N].
///   * `labels.txt`: una etiqueta por línea, en el orden de la salida.
///   * `modelo.json`: versión, rango de la entrada, umbral, etc. (opcional).
///
/// Si `model.tflite` no está, [ModeloResiduos.cargar] devuelve null y la app
/// sigue funcionando sin IA (la persona elige la categoría).
class ModeloResiduos {
  static const rutaModelo = 'assets/modelo/model.tflite';
  static const rutaEtiquetas = 'assets/modelo/labels.txt';
  static const rutaConfig = 'assets/modelo/modelo.json';

  final ConfigModelo config;
  final List<String> etiquetas;
  final MotorInferencia motor;

  ModeloResiduos({
    required this.config,
    required this.etiquetas,
    required this.motor,
  }) {
    final clases = motor.salida.elementos;
    if (clases != etiquetas.length) {
      throw FormatException(
        'labels.txt tiene ${etiquetas.length} etiquetas y el modelo devuelve '
        '$clases clases.',
      );
    }
  }

  /// Carga el modelo de los assets. Null si no hay `model.tflite` (aún no
  /// llega); cualquier otro problema (labels.txt distinto, json mal escrito)
  /// también deja la app sin IA y queda en el log.
  static Future<ModeloResiduos?> cargar({
    AssetBundle? bundle,
    Future<MotorInferencia> Function(Uint8List modelo)? crearMotor,
  }) async {
    final assets = bundle ?? rootBundle;
    final ByteData datosModelo;
    try {
      datosModelo = await assets.load(rutaModelo);
    } catch (_) {
      debugPrint('Modelo: no hay $rutaModelo, la app sigue sin IA.');
      return null;
    }
    try {
      final etiquetas = const LineSplitter()
          .convert(await assets.loadString(rutaEtiquetas))
          .map((l) => l.trim())
          .where((l) => l.isNotEmpty)
          .toList();
      ConfigModelo config;
      try {
        config = ConfigModelo.fromJson(
          jsonDecode(await assets.loadString(rutaConfig))
              as Map<String, dynamic>,
        );
      } on FlutterError {
        config = const ConfigModelo();
      }
      final bytes = datosModelo.buffer.asUint8List(
        datosModelo.offsetInBytes,
        datosModelo.lengthInBytes,
      );
      final motor = await (crearMotor ?? MotorTflite.crear)(bytes);
      try {
        return ModeloResiduos(
          config: config,
          etiquetas: etiquetas,
          motor: motor,
        );
      } catch (_) {
        await motor.cerrar();
        rethrow;
      }
    } catch (e) {
      debugPrint('Modelo: no se pudo cargar ($e), la app sigue sin IA.');
      return null;
    }
  }

  /// Clasifica una foto (JPEG ya comprimido por CamaraService) y devuelve las
  /// probabilidades por etiqueta, de mayor a menor.
  Future<List<Prediccion>> clasificar(Uint8List jpeg) async {
    final entrada = motor.entrada;
    final rgb = await decodificarRgb(
      jpeg,
      alto: entrada.alto,
      ancho: entrada.ancho,
    );
    final tensor = tensorDeEntrada(
      rgb,
      entrada,
      minimo: config.rangoEntrada.$1,
      maximo: config.rangoEntrada.$2,
    );
    final cruda = valoresDeSalida(await motor.ejecutar(tensor), motor.salida);
    final probabilidades = aProbabilidades(
      cruda,
      sonLogits: config.salidaEnLogits,
      temperatura: config.temperatura,
    );
    final predicciones = [
      for (var i = 0; i < etiquetas.length; i++)
        Prediccion(etiquetas[i], probabilidades[i]),
    ]..sort((a, b) => b.confianza.compareTo(a.confianza));
    return predicciones;
  }

  Future<void> cerrar() => motor.cerrar();
}

class Prediccion {
  final String etiqueta;
  final double confianza;

  const Prediccion(this.etiqueta, this.confianza);

  @override
  String toString() => '$etiqueta ${(confianza * 100).toStringAsFixed(1)}%';
}

/// `assets/modelo/modelo.json`. Todo es opcional; los valores por defecto
/// son los de la guía de IA.
class ConfigModelo {
  /// Versión del modelo (se guarda con cada escaneo y depósito).
  final String version;
  final String? fecha;

  /// Rango en que el modelo espera cada canal de color. (0, 255) si el
  /// reescalado va dentro del modelo (lo que pide la guía, 8.6); (0, 1) o
  /// (-1, 1) si hay que hacerlo antes.
  final (double, double) rangoEntrada;

  /// true si la salida son logits (sin softmax).
  final bool salidaEnLogits;

  /// Temperature scaling de la calibración (8.5); 1 = sin cambio.
  final double temperatura;

  /// Confianza mínima para aceptar la clase; bajo ella la foto queda "no
  /// reconocida" y se pide otra.
  final double umbralConfianza;

  const ConfigModelo({
    this.version = 'sin-version',
    this.fecha,
    this.rangoEntrada = (0, 255),
    this.salidaEnLogits = false,
    this.temperatura = 1,
    this.umbralConfianza = 0.7,
  });

  factory ConfigModelo.fromJson(Map<String, dynamic> json) {
    final rango = json['rango_entrada'] as List?;
    return ConfigModelo(
      version: (json['version'] as String?)?.trim().isNotEmpty == true
          ? (json['version'] as String).trim()
          : 'sin-version',
      fecha: json['fecha'] as String?,
      rangoEntrada: rango == null || rango.length != 2
          ? (0, 255)
          : ((rango[0] as num).toDouble(), (rango[1] as num).toDouble()),
      salidaEnLogits: json['salida'] == 'logits',
      temperatura: (json['temperatura'] as num?)?.toDouble() ?? 1,
      umbralConfianza: (json['umbral_confianza'] as num?)?.toDouble() ?? 0.7,
    );
  }
}

enum TipoTensor { float32, uint8, int8 }

/// Forma, tipo y cuantización de un tensor.
class DescripcionTensor {
  final List<int> forma;
  final TipoTensor tipo;
  final double escala;
  final int puntoCero;

  const DescripcionTensor({
    required this.forma,
    required this.tipo,
    this.escala = 0,
    this.puntoCero = 0,
  });

  int get elementos => forma.fold(1, (a, b) => a * b);
  int get bytesPorElemento => tipo == TipoTensor.float32 ? 4 : 1;
  int get bytes => elementos * bytesPorElemento;

  /// Entrada [1, alto, ancho, 3].
  int get alto => forma[1];
  int get ancho => forma[2];
}

/// Quien ejecuta el modelo. En la app es [MotorTflite]; en los tests, uno
/// falso.
abstract class MotorInferencia {
  DescripcionTensor get entrada;
  DescripcionTensor get salida;

  /// Bytes del tensor de entrada → bytes del tensor de salida.
  Future<Uint8List> ejecutar(Uint8List entrada);

  Future<void> cerrar();
}

/// TensorFlow Lite (LiteRT) con `tflite_flutter`. La inferencia corre en otro
/// isolate para no congelar la pantalla.
class MotorTflite implements MotorInferencia {
  final Interpreter _interprete;
  final IsolateInterpreter _isolate;
  @override
  final DescripcionTensor entrada;
  @override
  final DescripcionTensor salida;

  // IsolateInterpreter ignora una llamada mientras otra está en curso: se
  // encadenan.
  Future<void> _cola = Future.value();

  MotorTflite._(this._interprete, this._isolate, this.entrada, this.salida);

  static Future<MotorInferencia> crear(Uint8List modelo) async {
    final opciones = InterpreterOptions()..threads = 4;
    final interprete = Interpreter.fromBuffer(modelo, options: opciones);
    final entrada = _describir(interprete.getInputTensor(0));
    final salida = _describir(interprete.getOutputTensor(0));
    if (entrada.forma.length != 4 || entrada.forma[3] != 3) {
      interprete.close();
      throw FormatException(
        'La entrada del modelo debe ser [1, alto, ancho, 3] y es '
        '${entrada.forma}.',
      );
    }
    final isolate = await IsolateInterpreter.create(
      address: interprete.address,
    );
    return MotorTflite._(interprete, isolate, entrada, salida);
  }

  static DescripcionTensor _describir(Tensor t) {
    final tipo = switch (t.type) {
      TensorType.float32 => TipoTensor.float32,
      TensorType.uint8 => TipoTensor.uint8,
      TensorType.int8 => TipoTensor.int8,
      _ => throw FormatException('Tipo de tensor no soportado: ${t.type}'),
    };
    return DescripcionTensor(
      forma: t.shape,
      tipo: tipo,
      escala: t.params.scale,
      puntoCero: t.params.zeroPoint,
    );
  }

  @override
  Future<Uint8List> ejecutar(Uint8List datos) {
    final resultado = _cola.then((_) async {
      final salidaBytes = Uint8List(salida.bytes);
      await _isolate.run(datos, salidaBytes.buffer);
      return salidaBytes;
    });
    _cola = resultado.then((_) {}, onError: (_) {});
    return resultado;
  }

  @override
  Future<void> cerrar() async {
    await _isolate.close();
    _interprete.close();
  }
}

// --------------------------------------------------------- Preparar la foto

/// Decodifica el JPEG reducido para que su lado corto cubra [ancho]×[alto] y
/// recorta el centro (sin deformar la foto). Devuelve RGB, 3 bytes por píxel.
Future<Uint8List> decodificarRgb(
  Uint8List jpeg, {
  required int alto,
  required int ancho,
}) async {
  final buffer = await ui.ImmutableBuffer.fromUint8List(jpeg);
  final descriptor = await ui.ImageDescriptor.encoded(buffer);
  final escala = math.max(ancho / descriptor.width, alto / descriptor.height);
  final codec = await descriptor.instantiateCodec(
    targetWidth: math.max(ancho, (descriptor.width * escala).round()),
    targetHeight: math.max(alto, (descriptor.height * escala).round()),
  );
  final imagen = (await codec.getNextFrame()).image;
  final datos = await imagen.toByteData(format: ui.ImageByteFormat.rawRgba);
  final (w, h) = (imagen.width, imagen.height);
  imagen.dispose();
  codec.dispose();
  descriptor.dispose();
  buffer.dispose();
  if (datos == null) throw StateError('No se pudo leer la imagen');
  return recortarCentroRgb(
    datos.buffer.asUint8List(),
    ancho: w,
    alto: h,
    anchoRecorte: ancho,
    altoRecorte: alto,
  );
}

/// Recorta el centro de una imagen RGBA y lo devuelve en RGB.
Uint8List recortarCentroRgb(
  Uint8List rgba, {
  required int ancho,
  required int alto,
  required int anchoRecorte,
  required int altoRecorte,
}) {
  final x0 = (ancho - anchoRecorte) ~/ 2;
  final y0 = (alto - altoRecorte) ~/ 2;
  final rgb = Uint8List(anchoRecorte * altoRecorte * 3);
  var j = 0;
  for (var y = 0; y < altoRecorte; y++) {
    var i = ((y0 + y) * ancho + x0) * 4;
    for (var x = 0; x < anchoRecorte; x++, i += 4) {
      rgb[j++] = rgba[i];
      rgb[j++] = rgba[i + 1];
      rgb[j++] = rgba[i + 2];
    }
  }
  return rgb;
}

/// Bytes del tensor de entrada a partir de los píxeles RGB (0-255).
/// float32: cada canal llevado a [minimo, maximo]. uint8: el píxel tal cual.
/// int8: el valor en [minimo, maximo] cuantizado con la escala del tensor.
Uint8List tensorDeEntrada(
  Uint8List rgb,
  DescripcionTensor entrada, {
  double minimo = 0,
  double maximo = 255,
}) {
  double valor(int pixel) => minimo + pixel / 255 * (maximo - minimo);
  switch (entrada.tipo) {
    case TipoTensor.uint8:
      return Uint8List.fromList(rgb);
    case TipoTensor.float32:
      final f = Float32List(rgb.length);
      for (var i = 0; i < rgb.length; i++) {
        f[i] = valor(rgb[i]);
      }
      return f.buffer.asUint8List();
    case TipoTensor.int8:
      final q = Int8List(rgb.length);
      final escala = entrada.escala == 0 ? 1.0 : entrada.escala;
      for (var i = 0; i < rgb.length; i++) {
        q[i] = (valor(rgb[i]) / escala + entrada.puntoCero).round().clamp(
          -128,
          127,
        );
      }
      return q.buffer.asUint8List();
  }
}

/// Valores de la salida como doubles (descuantizados si hace falta).
List<double> valoresDeSalida(Uint8List bytes, DescripcionTensor salida) {
  final datos = ByteData.sublistView(bytes);
  double descuantizar(int q) => salida.escala == 0
      ? q.toDouble()
      : (q - salida.puntoCero) * salida.escala;
  return List.generate(salida.elementos, (i) {
    return switch (salida.tipo) {
      TipoTensor.float32 => datos.getFloat32(i * 4, Endian.host),
      TipoTensor.uint8 => descuantizar(datos.getUint8(i)),
      TipoTensor.int8 => descuantizar(datos.getInt8(i)),
    };
  });
}

/// Probabilidades que suman 1. Con logits (o con temperatura distinta de 1)
/// aplica softmax(valor / temperatura); si ya son probabilidades solo las
/// normaliza.
List<double> aProbabilidades(
  List<double> valores, {
  bool sonLogits = false,
  double temperatura = 1,
}) {
  if (valores.isEmpty) return const [];
  final t = temperatura <= 0 ? 1.0 : temperatura;
  if (!sonLogits && t == 1) {
    final positivos = valores.map((v) => math.max(v, 0.0)).toList();
    final suma = positivos.fold(0.0, (a, b) => a + b);
    if (suma <= 0) return List.filled(valores.length, 1 / valores.length);
    return positivos.map((v) => v / suma).toList();
  }
  final logits = sonLogits
      ? valores
      : valores.map((p) => math.log(math.max(p, 1e-9))).toList();
  final maximo = logits.reduce(math.max);
  final exps = logits.map((l) => math.exp((l - maximo) / t)).toList();
  final suma = exps.fold(0.0, (a, b) => a + b);
  return exps.map((e) => e / suma).toList();
}
