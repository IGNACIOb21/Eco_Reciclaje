import '../models/usuario.dart';

/// Fuente de datos del usuario actual (nombre, alias, puntos, fecha de
/// registro). La personalización visual (avatar, comuna) sigue siendo local,
/// ver PerfilLocalStore.
abstract class UsuarioRepository {
  /// Devuelve el usuario de esta sesión, creándolo si es la primera vez.
  Future<Usuario> obtenerOCrear();

  /// Guarda el alias y, si viene, el nombre real del usuario de esta sesión
  /// y devuelve el usuario actualizado.
  Future<Usuario> guardarDatos({required String alias, String? nombre});
}
