import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Último nivel que la persona ya vio en este teléfono (por cuenta), para
/// celebrar una sola vez cada subida de nivel.
class NivelVistoStore {
  static const _clave = 'ultimo_nivel_visto';

  /// Umbral (`puntos_minimos`) del último nivel visto por [idUsuario]; null si
  /// esa cuenta aún no tiene uno guardado en este teléfono.
  Future<int?> leer(String idUsuario) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_clave);
      if (raw == null) return null;
      final datos = jsonDecode(raw) as Map<String, dynamic>;
      if (datos['id'] != idUsuario) return null;
      return (datos['minimo'] as num).toInt();
    } catch (_) {
      return null;
    }
  }

  Future<void> guardar(String idUsuario, int puntosMinimos) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _clave,
        jsonEncode({'id': idUsuario, 'minimo': puntosMinimos}),
      );
    } catch (_) {
      // Si no se guarda, a lo más se repite una celebración.
    }
  }
}
