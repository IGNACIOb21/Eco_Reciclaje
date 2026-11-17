import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Retroalimentación háptica de la app. Solo vibra ante hechos con significado
/// (reclamar una recompensa, subir de nivel), nunca al tocar un botón común.
/// Se apaga desde Perfil › Vibración.
class Haptica {
  Haptica._();

  static const _clave = 'vibracion';

  /// Preferencia de la persona; activa por defecto.
  static bool activa = true;

  /// Lee la preferencia guardada. Se llama una vez al abrir la app.
  static Future<void> cargar() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      activa = prefs.getBool(_clave) ?? true;
    } catch (_) {
      activa = true;
    }
  }

  static Future<void> guardar(bool valor) async {
    activa = valor;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_clave, valor);
    } catch (_) {
      // Si no se guarda, en el próximo arranque vuelve a estar activa.
    }
  }

  static Future<void> ligera() async {
    if (activa) await HapticFeedback.lightImpact();
  }

  static Future<void> media() async {
    if (activa) await HapticFeedback.mediumImpact();
  }

  /// Dos golpes seguidos, para subir de nivel.
  static Future<void> doble() async {
    if (!activa) return;
    await HapticFeedback.mediumImpact();
    await Future<void>.delayed(const Duration(milliseconds: 120));
    await HapticFeedback.heavyImpact();
  }
}
