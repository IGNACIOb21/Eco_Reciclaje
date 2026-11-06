import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/movimiento_punto.dart';
import '../models/usuario.dart';
import '../services/supabase_service.dart';
import 'usuario_repository.dart';

/// Modo invitado sobre Supabase: si no hay sesión, inicia una anónima (la
/// sesión la persiste supabase_flutter, así que se recupera el mismo usuario
/// en los siguientes arranques). Luego lee la fila de `usuarios` cuyo
/// `id_usuario` es auth.uid(), suma sus `movimientos_puntos` y cuenta sus
/// reciclajes, reportes y logros.
///
/// La fila de `usuarios` no la crea la APK: la crea el trigger
/// handle_new_auth_user al registrarse (también en sesiones anónimas).
///
/// Requiere policies RLS de select de lo propio en `usuarios`,
/// `movimientos_puntos`, `reciclajes`, `reportes_punto` y `logros_usuario`, y
/// de update de `usuarios.alias` (ver docs/rls-perfil.md). Sin ellas la base
/// responde 42501.
class UsuarioRepositorySupabase implements UsuarioRepository {
  final SupabaseClient _cliente;

  UsuarioRepositorySupabase({SupabaseClient? cliente})
    : _cliente = cliente ?? SupabaseService.cliente;

  static const _maxMovimientos = 10;

  @override
  Future<Usuario> obtenerOCrear() async {
    final authUser =
        _cliente.auth.currentUser ??
        (await _cliente.auth.signInAnonymously()).user!;

    final fila = await _cliente
        .from('usuarios')
        .select('id_usuario, correo_electronico, alias, fecha_creacion')
        .eq('id_usuario', authUser.id)
        .maybeSingle();
    if (fila == null) {
      throw StateError(
        'No hay fila en usuarios para ${authUser.id}: revisar el trigger '
        'handle_new_auth_user y la policy de select de usuarios',
      );
    }

    final (filas, escaneados, reportes, logros) = await (
      _cliente
          .from('movimientos_puntos')
          .select('tipo_referencia, cantidad, fecha')
          .eq('id_usuario', authUser.id)
          .order('fecha', ascending: false),
      _contar('reciclajes', authUser.id),
      _contar('reportes_punto', authUser.id),
      _contar('logros_usuario', authUser.id),
    ).wait;

    final movimientos = filas.map(MovimientoPunto.fromSupabaseRow).toList();
    final puntos = movimientos.fold<int>(0, (total, m) => total + m.cantidad);
    final metadata = authUser.userMetadata;

    // Los canjes restan puntos; el saldo nunca se muestra negativo.
    return Usuario.fromSupabaseRow(
      fila,
      puntosTotales: puntos < 0 ? 0 : puntos,
      nombre: metadata?['nombre'] as String?,
      tieneContrasena: metadata?['tiene_password'] == true,
      objetosEscaneados: escaneados,
      reportesHechos: reportes,
      logrosObtenidos: logros,
      movimientos: movimientos.take(_maxMovimientos).toList(),
    );
  }

  @override
  Future<Usuario> guardarDatos({
    required String nombre,
    required String alias,
  }) async {
    final authUser = _cliente.auth.currentUser;
    if (authUser == null) throw StateError('No hay sesión de Supabase');
    // Primero el alias: si la base lo rechaza, el nombre no se guarda y la
    // bienvenida sigue pidiéndolo. La policy de update limita a la fila propia.
    await _cliente
        .from('usuarios')
        .update({'alias': alias})
        .eq('id_usuario', authUser.id);
    // El nombre real va a user_metadata: `usuarios` no tiene columna para él.
    await _cliente.auth.updateUser(UserAttributes(data: {'nombre': nombre}));
    return obtenerOCrear();
  }

  /// Filas de [tabla] que pertenecen al usuario, sin traerlas.
  Future<int> _contar(String tabla, String idUsuario) async {
    final respuesta = await _cliente
        .from(tabla)
        .select()
        .eq('id_usuario', idUsuario)
        .count(CountOption.exact);
    return respuesta.count;
  }
}
