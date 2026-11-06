import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../models/perfil_local.dart';

/// Persistencia local del perfil, namespaced por el device_id del modo
/// invitado (UUID generado una vez en este dispositivo).
class PerfilLocalStore {
  static const _claveDeviceId = 'device_id';

  Future<String> obtenerDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    final existente = prefs.getString(_claveDeviceId);
    if (existente != null) return existente;
    final nuevo = const Uuid().v4();
    await prefs.setString(_claveDeviceId, nuevo);
    return nuevo;
  }

  Future<PerfilLocal> cargar(String deviceId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_clavePerfil(deviceId));
    if (raw == null) return const PerfilLocal();
    return PerfilLocal.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> guardar(String deviceId, PerfilLocal perfil) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_clavePerfil(deviceId), jsonEncode(perfil.toJson()));
  }

  String _clavePerfil(String deviceId) => 'perfil_local_$deviceId';
}
