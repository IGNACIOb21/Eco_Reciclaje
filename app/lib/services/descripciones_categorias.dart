import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/material_type.dart';
import 'supabase_service.dart';

/// Los textos de cada categoría que muestran y dicen por voz el resultado de
/// la cámara y la Guía rápida, tal como están en `categorias_residuo`:
///   * [descripcion] (`descripcion`): qué abarca, dónde se deposita y en qué
///     se transforma.
///   * [productos] (`destino_reutilizacion`): en qué productos se convierte.
///   * [partesNoReciclables] (`partes_no_reciclables`): qué partes del
///     artículo no se suelen reciclar.
///
/// Se leen con `app_categorias` y se guarda una copia en el teléfono
/// (`descripciones_categorias`). Sin conexión, sin Supabase, antes de que
/// exista la función o con un texto vacío en la base, se usa el que trae la
/// app (`TipoMaterial` en material_type.dart).
class DescripcionesCategorias extends ChangeNotifier {
  final Future<List<dynamic>?> Function() _leer;
  final Map<TipoMaterial, Map<String, String>> _textos = {};
  Future<void>? _carga;

  DescripcionesCategorias({Future<List<dynamic>?> Function()? leer})
    : _leer = leer ?? _leerSupabase;

  /// Una sola instancia en la app: se lee una vez por sesión.
  static final instancia = DescripcionesCategorias();

  static const _clave = 'descripciones_categorias';
  static const _columnas = [
    'descripcion',
    'destino_reutilizacion',
    'partes_no_reciclables',
  ];

  String descripcion(TipoMaterial material) =>
      _textos[material]?['descripcion'] ?? material.descripcion;

  String productos(TipoMaterial material) =>
      _textos[material]?['destino_reutilizacion'] ??
      material.productosResultantes;

  String partesNoReciclables(TipoMaterial material) =>
      _textos[material]?['partes_no_reciclables'] ??
      material.partesNoReciclables;

  /// Carga la copia del teléfono y después la de la base. No lanza; si la
  /// base falla, el próximo llamado vuelve a intentarlo.
  Future<void> cargar() => _carga ??= _cargar();

  Future<void> _cargar() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final copia = prefs.getString(_clave);
      if (copia != null) _aplicar(jsonDecode(copia) as List<dynamic>);
    } catch (_) {
      // Copia corrupta: se ignora.
    }
    try {
      final filas = await _leer();
      if (filas == null) return;
      if (_aplicar(filas)) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_clave, jsonEncode(filas));
      }
    } catch (e) {
      debugPrint('DescripcionesCategorias: $e');
      _carga = null;
    }
  }

  /// true si alguna fila trajo algún texto válido.
  bool _aplicar(List<dynamic> filas) {
    var alguno = false;
    for (final fila in filas) {
      if (fila is! Map) continue;
      final material = MaterialTypeInfo.fromCodigo('${fila['codigo']}');
      if (material == null) continue;
      for (final columna in _columnas) {
        final texto = (fila[columna] as String?)?.trim() ?? '';
        if (texto.isEmpty) continue;
        (_textos[material] ??= {})[columna] = texto;
        alguno = true;
      }
    }
    if (alguno) notifyListeners();
    return alguno;
  }

  static Future<List<dynamic>?> _leerSupabase() async {
    if (!SupabaseService.disponible) return null;
    final filas = await SupabaseService.cliente.rpc('app_categorias');
    return filas is List ? filas : null;
  }
}
