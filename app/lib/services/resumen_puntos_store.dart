import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/resumen_puntos.dart';

/// Última copia de los puntos y niveles leídos de Supabase, para que el
/// Perfil muestre el progreso sin conexión. Guarda una sola copia: la de la
/// última cuenta que cargó (el ResumenPuntos lleva su id).
class ResumenPuntosStore {
  static const _clave = 'resumen_puntos';

  Future<ResumenPuntos?> cargar() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_clave);
      if (raw == null) return null;
      return ResumenPuntos.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      // Copia corrupta o de un formato viejo: se ignora.
      return null;
    }
  }

  Future<void> guardar(ResumenPuntos resumen) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_clave, jsonEncode(resumen.toJson()));
  }
}
