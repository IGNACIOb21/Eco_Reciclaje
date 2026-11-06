import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

/// Permisos que la APK pide en la bienvenida y que se pueden activar después
/// desde Ajustes del Perfil.
enum PermisoApp { ubicacion, notificaciones }

/// Estado simplificado para la UI: concedido, se puede pedir con el diálogo
/// del sistema, o hay que ir a los ajustes del teléfono (Android deja de
/// mostrar el diálogo tras dos rechazos).
enum EstadoPermiso { concedido, pendiente, bloqueado }

/// Envoltorio de permission_handler. No lanza: en plataformas sin el plugin
/// (tests, escritorio) responde como si el permiso estuviera pendiente.
class PermisosService {
  const PermisosService();

  Permission _permiso(PermisoApp p) => switch (p) {
    PermisoApp.ubicacion => Permission.locationWhenInUse,
    PermisoApp.notificaciones => Permission.notification,
  };

  Future<EstadoPermiso> estado(PermisoApp p) async {
    try {
      return _traducir(await _permiso(p).status);
    } catch (e) {
      debugPrint('PermisosService: no se pudo leer $p ($e)');
      return EstadoPermiso.pendiente;
    }
  }

  /// Muestra el diálogo del sistema; si ya está bloqueado abre los ajustes de
  /// la app. Devuelve el estado resultante.
  Future<EstadoPermiso> pedir(PermisoApp p) async {
    try {
      final actual = await estado(p);
      if (actual == EstadoPermiso.bloqueado) {
        await openAppSettings();
        return actual;
      }
      return _traducir(await _permiso(p).request());
    } catch (e) {
      debugPrint('PermisosService: no se pudo pedir $p ($e)');
      return EstadoPermiso.pendiente;
    }
  }

  EstadoPermiso _traducir(PermissionStatus s) {
    if (s.isGranted || s.isLimited || s.isProvisional) {
      return EstadoPermiso.concedido;
    }
    if (s.isPermanentlyDenied || s.isRestricted) return EstadoPermiso.bloqueado;
    return EstadoPermiso.pendiente;
  }
}
