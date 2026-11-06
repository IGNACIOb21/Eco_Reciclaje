import 'package:geolocator/geolocator.dart';

/// Obtiene la ubicación real del usuario si el permiso y el servicio de GPS
/// están disponibles; devuelve null en cualquier otro caso (denegado,
/// deshabilitado, sin señal) para que quien llama use el centro por defecto.
///
/// No pide el permiso: eso se hace en la bienvenida o desde Ajustes del
/// Perfil (PermisosService), así el usuario que lo rechazó no ve el diálogo
/// cada vez que abre el mapa.
Future<Position?> obtenerUbicacionActual() async {
  try {
    if (!await _hayPermiso()) return null;
    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.medium,
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
