import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Config de entorno leída desde el asset `.env` con flutter_dotenv (ver
/// `.env.example` para la plantilla). Requiere `dotenv.load()` previo en
/// main; si el archivo no cargó o le faltan claves, [estaConfigurado] es false
/// y la app sigue funcionando sin Supabase.
class Env {
  static String get supabaseUrl => _leer('SUPABASE_URL');
  static String get supabaseAnonKey => _leer('SUPABASE_ANON_KEY');

  /// `--dart-define=NUEVA_CUENTA_ANONIMA=true` (lo pasa el launch.json de
  /// VS Code al correr con F5): descarta la sesión guardada y crea una cuenta
  /// anónima nueva en Supabase en cada arranque.
  static const bool nuevaCuentaAnonima = bool.fromEnvironment(
    'NUEVA_CUENTA_ANONIMA',
  );

  static bool get estaConfigurado =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  static String _leer(String clave) =>
      dotenv.isInitialized ? (dotenv.maybeGet(clave) ?? '').trim() : '';
}
