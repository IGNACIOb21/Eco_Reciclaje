import 'package:shared_preferences/shared_preferences.dart';

/// Preferencia "Recordatorio amable" de la racha. Hoy solo se guarda: las
/// notificaciones reales llegan cuando se apruebe FCM.
class RecordatorioRachaStore {
  static const _clave = 'recordatorio_racha';

  /// Activado por defecto.
  static Future<bool> leer() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_clave) ?? true;
    } catch (_) {
      return true;
    }
  }

  static Future<void> guardar(bool activo) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_clave, activo);
    } catch (_) {
      // Si no se guarda, vuelve a su valor por defecto: no es grave.
    }
  }
}
