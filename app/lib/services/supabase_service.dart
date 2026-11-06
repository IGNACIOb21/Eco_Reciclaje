import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/env.dart';

/// Punto único de arranque y acceso al cliente de Supabase. Las pantallas no
/// lo usan directo: el acceso a datos va siempre por clases repositorio
/// (ej. PuntosRepositorySupabase), que reciben [cliente] de acá.
class SupabaseService {
  SupabaseService._();

  static bool _inicializado = false;

  /// true si Supabase quedó inicializado con credenciales válidas.
  static bool get disponible => _inicializado;

  /// Carga `.env` e inicializa Supabase. No lanza: si falta el archivo o las
  /// claves, la app arranca igual (los repositorios mock siguen sirviendo).
  static Future<void> inicializar() async {
    if (_inicializado) return;
    try {
      await dotenv.load(fileName: '.env');
    } catch (e) {
      debugPrint('SupabaseService: no se pudo cargar .env ($e)');
      return;
    }
    if (!Env.estaConfigurado) {
      debugPrint('SupabaseService: faltan SUPABASE_URL / SUPABASE_ANON_KEY');
      return;
    }
    await Supabase.initialize(
      url: Env.supabaseUrl,
      publishableKey: Env.supabaseAnonKey,
    );
    _inicializado = true;
  }

  /// Deja una sesión de Supabase Auth abierta y devuelve su usuario. Si no
  /// hay sesión guardada inicia una anónima (el trigger `handle_new_auth_user`
  /// crea su fila en `usuario`). Con [cuentaNueva] cierra antes la sesión
  /// guardada, así cada arranque queda con una cuenta anónima recién creada.
  static Future<User> prepararSesion({bool cuentaNueva = false}) async {
    final auth = cliente.auth;
    if (cuentaNueva && auth.currentUser != null) {
      await auth.signOut(scope: SignOutScope.local);
    }
    final user = auth.currentUser ?? (await auth.signInAnonymously()).user!;
    debugPrint('SupabaseService: sesión anónima ${user.id}');
    return user;
  }

  /// Cliente compartido. Lanza si se usa sin haber inicializado.
  static SupabaseClient get cliente {
    if (!_inicializado) {
      throw StateError('Supabase no está inicializado (revisa app/.env)');
    }
    return Supabase.instance.client;
  }
}
