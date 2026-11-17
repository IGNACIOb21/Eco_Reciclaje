import 'package:geolocator/geolocator.dart';

/// Obtiene la ubicación real del usuario si el permiso y el servicio de GPS
/// están disponibles; devuelve null en cualquier otro caso (denegado,
/// deshabilitado, sin señal) para que quien llama use el centro por defecto.
///
/// No pide el permiso: eso se hace en la bienvenida o desde Ajustes del
/// Perfil (PermisosService), así el usuario que lo rechazó no ve el diálogo
/// cada vez que abre el mapa.
///
/// Espera hasta [limite] (bajo techo el GPS puede no responder nunca); si no
/// llega, usa la última posición que conoce el teléfono.
Future<Position?> obtenerUbicacionActual({
  Duration limite = const Duration(seconds: 15),
}) async {
  try {
    if (!await _hayPermiso()) return null;
    return await Geolocator.getCurrentPosition(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.medium,
        timeLimit: limite,
      ),
    );
  } catch (_) {
    try {
      return await Geolocator.getLastKnownPosition();
    } catch (_) {
      return null;
    }
  }
}

/// Por qué no hay posición, para avisar lo correcto.
enum EstadoUbicacion { lista, gpsApagado, sinPermiso }

/// Lee el estado real del teléfono (servicio de ubicación y permiso de la
/// app), sin pedir nada. Sin el plugin (tests) responde [sinPermiso].
Future<EstadoUbicacion> estadoUbicacion() async {
  try {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return EstadoUbicacion.gpsApagado;
    }
    final permiso = await Geolocator.checkPermission();
    return permiso == LocationPermission.always ||
            permiso == LocationPermission.whileInUse
        ? EstadoUbicacion.lista
        : EstadoUbicacion.sinPermiso;
  } catch (_) {
    return EstadoUbicacion.sinPermiso;
  }
}

/// Última posición conocida, para empezar cerca de la persona sin esperar al
/// GPS (Inicio cuenta los puntos cercanos, el Mapa pide los primeros puntos).
/// La llena [precargarUltimaUbicacion] al abrir la app y la actualiza el
/// seguimiento del Mapa. Null sin permiso o si el teléfono no guarda ninguna.
Position? ultimaUbicacionConocida;

/// Lee la última posición que el teléfono ya conoce, sin encender el GPS
/// (responde en milisegundos). Nunca tarda más de [limite].
Future<void> precargarUltimaUbicacion({
  Duration limite = const Duration(milliseconds: 500),
}) async {
  try {
    if (!await _hayPermiso().timeout(limite)) return;
    ultimaUbicacionConocida ??= await Geolocator.getLastKnownPosition().timeout(
      limite,
    );
  } catch (_) {
    // Sin permiso, sin GPS o sin respuesta: se usa el centro por defecto.
  }
}

/// Posición de alta precisión para registrar un depósito (`precision_gps`,
/// `ubicacion_simulada`). Null sin permiso, sin GPS o si no responde a
/// tiempo. Tampoco pide el permiso.
Future<Position?> obtenerUbicacionPrecisa() async {
  try {
    if (!await _hayPermiso()) return null;
    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.best,
        timeLimit: Duration(seconds: 20),
      ),
    );
  } catch (_) {
    return null;
  }
}

/// Posición en tiempo real (cada [metros] de desplazamiento). Stream vacío
/// si no hay permiso o GPS, o si el plugin no está disponible.
Stream<Position> seguirUbicacion({int metros = 10}) async* {
  try {
    if (!await _hayPermiso()) return;
  } catch (_) {
    return;
  }
  yield* Geolocator.getPositionStream(
    locationSettings: LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: metros,
    ),
  );
}

Future<bool> _hayPermiso() async {
  if (!await Geolocator.isLocationServiceEnabled()) return false;
  final permiso = await Geolocator.checkPermission();
  return permiso == LocationPermission.always ||
      permiso == LocationPermission.whileInUse;
}
