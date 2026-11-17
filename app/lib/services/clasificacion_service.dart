import 'dart:io';

import 'package:flutter/foundation.dart';

import '../models/etiqueta_modelo.dart';
import '../models/material_type.dart';
import 'descripciones_categorias.dart';
import 'modelo_residuos.dart';

/// Resultado de clasificar la foto de un residuo.
class ResultadoClasificacion {
  final EtiquetaModelo etiqueta;

  /// Confianza calibrada de 0 a 1 (`confianza_ia`). 0 si la categoría la
  /// eligió la persona.
  final double confianza;

  /// Versión del modelo que lo clasificó; null si no hay modelo y la persona
  /// eligió la categoría (la base lo deja en revisión y sin puntos).
  final String? modeloVersion;

  /// false si la confianza quedó bajo el umbral del modelo: la foto no se
  /// reconoce y se pide otra (guía de IA, 8.5).
  final bool reconocido;

  /// Las 3 clases más probables, para mostrar y para depurar.
  final List<Prediccion> alternativas;

  const ResultadoClasificacion({
    required this.etiqueta,
    required this.confianza,
    required this.modeloVersion,
    this.reconocido = true,
    this.alternativas = const [],
  });

  /// La persona eligió la categoría (no hay modelo, o no lo reconoció).
  factory ResultadoClasificacion.elegida(
    EtiquetaModelo etiqueta, {
    ResultadoClasificacion? delModelo,
  }) => ResultadoClasificacion(
    etiqueta: etiqueta,
    confianza: 0,
    modeloVersion: null,
    alternativas: delModelo?.alternativas ?? const [],
  );

  bool get reciclable => etiqueta.reciclable;
  TipoMaterial? get material => etiqueta.material;
  String get nombre => etiqueta.nombre;

  /// Qué es, dónde se deposita y en qué se transforma
  /// (`categorias_residuo.descripcion`, o la copia de la app).
  String get descripcion {
    final material = this.material;
    return material == null
        ? EtiquetaModelo.descripcionNoReciclable
        : DescripcionesCategorias.instancia.descripcion(material);
  }

  /// `categorias_residuo.codigo`; null si no es reciclable.
  String? get codigoCategoria => material?.codigo;

  /// true si no lo clasificó la IA.
  bool get elegidoPorPersona => modeloVersion == null;

  /// Lo que se dice por voz: la categoría y su descripción.
  String get frase => !reconocido
      ? 'No pudimos reconocer el objeto. Toma otra foto.'
      : reciclable
      ? '$nombre. $descripcion'
      : 'Este objeto no es reciclable. $descripcion';
}

/// Clasificación de residuos con el modelo TFLite dentro del teléfono.
///
/// Mientras no exista `assets/modelo/model.tflite`, [disponible] es false y
/// [clasificar] devuelve null: las pantallas le piden a la persona que elija
/// la categoría y la base deja esos registros en revisión, sin puntos. Al
/// copiar el modelo en `assets/modelo/` y recompilar, todo pasa a usar la IA
/// sin cambiar ninguna pantalla.
class ClasificacionService {
  final Future<ModeloResiduos?> Function() _cargar;
  Future<ModeloResiduos?>? _modelo;

  ClasificacionService({Future<ModeloResiduos?> Function()? cargar})
    : _cargar = cargar ?? ModeloResiduos.cargar;

  /// Una sola instancia en la app: el modelo se carga una vez.
  static final instancia = ClasificacionService();

  Future<ModeloResiduos?> get _cargado => _modelo ??= _cargar();

  /// Carga el modelo en segundo plano (para que la primera foto no espere).
  void precargar() => _cargado;

  Future<bool> get disponible async => await _cargado != null;

  /// Clasifica la foto. Null si no hay modelo.
  Future<ResultadoClasificacion?> clasificar(File foto) async {
    final modelo = await _cargado;
    if (modelo == null) return null;
    // Se lee antes de clasificar: quien llama puede borrar la foto apenas la
    // persona sale de la pantalla.
    final bytes = await foto.readAsBytes();
    final cronometro = Stopwatch()..start();
    final predicciones = await modelo.clasificar(bytes);
    debugPrint(
      'Modelo ${modelo.config.version}: ${predicciones.take(3).join(', ')} '
      '(${cronometro.elapsedMilliseconds} ms)',
    );
    final mejor = predicciones.first;
    final etiqueta = EtiquetaModelo.de(mejor.etiqueta);
    if (etiqueta == null) {
      debugPrint(
        'Modelo: la etiqueta "${mejor.etiqueta}" no existe en la app.',
      );
    }
    return ResultadoClasificacion(
      etiqueta: etiqueta ?? EtiquetaModelo.noReciclable,
      confianza: mejor.confianza,
      modeloVersion: modelo.config.version,
      reconocido:
          etiqueta != null && mejor.confianza >= modelo.config.umbralConfianza,
      alternativas: predicciones.take(3).toList(),
    );
  }
}
