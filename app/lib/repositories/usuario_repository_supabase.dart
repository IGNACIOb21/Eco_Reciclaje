import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/movimiento_punto.dart';
import '../models/nivel.dart';
import '../models/usuario.dart';
import '../services/supabase_service.dart';
import 'usuario_repository.dart';

/// Modo invitado sobre Supabase (Proyecto_Eco_reciclaje): si no hay sesión,
/// inicia una anónima (supabase_flutter la persiste, así que se recupera el
/// mismo usuario en los siguientes arranques). Luego pide todo el perfil con
/// la RPC `app_mi_perfil` (saldo, acumulado, racha, conteos y últimos
/// movimientos), ver backend/eco_reciclaje/02_funciones_app.sql.
///
/// La fila de `usuario` no la crea la APK: la crea el trigger
/// handle_new_auth_user al abrir la sesión (también en sesiones anónimas).
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

    final (perfil, niveles) = await (
      _cliente.rpc('app_mi_perfil', params: {'p_movimientos': _maxMovimientos}),
      _niveles(),
    ).wait;
    final fila = Map<String, dynamic>.from(perfil as Map);
    final metadata = authUser.userMetadata;

    return Usuario.fromSupabaseRow(
      {
        'id_usuario': fila['id_usuario'],
        'correo_electronico': fila['correo_electronico'],
        'alias': fila['alias'],
        'fecha_creacion': fila['fecha_creacion'],
      },
      puntosTotales: (fila['saldo'] as num).toInt(),
      puntosAcumulados: (fila['acumulado'] as num).toInt(),
      niveles: niveles,
      racha: (fila['racha'] as num?)?.toInt() ?? 0,
      nombre: metadata?['nombre'] as String?,
      tieneContrasena: metadata?['tiene_password'] == true,
      objetosEscaneados: (fila['escaneados'] as num?)?.toInt() ?? 0,
      reportesHechos: (fila['reportes'] as num?)?.toInt() ?? 0,
      logrosObtenidos: (fila['logros'] as num?)?.toInt() ?? 0,
      movimientos: [
        for (final m in (fila['movimientos'] as List?) ?? const [])
          MovimientoPunto.fromSupabaseRow(Map<String, dynamic>.from(m as Map)),
      ],
    );
  }

  @override
  Future<Usuario> guardarDatos({required String alias, String? nombre}) async {
    if (_cliente.auth.currentUser == null) {
      throw StateError('No hay sesión de Supabase');
    }
    await _cliente.rpc('app_guardar_alias', params: {'p_alias': alias});
    // El nombre real (opcional) va a user_metadata: `usuario` no tiene
    // columna para él.
    if (nombre != null) {
      await _cliente.auth.updateUser(UserAttributes(data: {'nombre': nombre}));
    }
    return obtenerOCrear();
  }

  /// Los niveles casi nunca cambian: se leen una vez por sesión de la app.
  static List<Nivel>? _nivelesLeidos;

  /// Umbrales de `app_niveles`. Null si no se pudo: el UsuarioController usa
  /// la última copia guardada.
  Future<List<Nivel>?> _niveles() async {
    final leidos = _nivelesLeidos;
    if (leidos != null) return leidos;
    try {
      final filas = await _cliente.rpc('app_niveles') as List;
      if (filas.isNotEmpty) {
        return _nivelesLeidos = [
          for (final f in filas) Nivel.fromJson(f as Map<String, dynamic>),
        ];
      }
    } catch (e) {
      debugPrint('UsuarioRepository: app_niveles no disponible ($e)');
    }
    return null;
  }
}
