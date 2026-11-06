import 'package:flutter/material.dart';

import 'repositories/puntos_repository.dart';
import 'repositories/usuario_repository_mock.dart';
import 'repositories/usuario_repository_supabase.dart';
import 'screens/bienvenida_screen.dart';
import 'screens/main_shell.dart';
import 'services/supabase_service.dart';
import 'state/perfil_local_controller.dart';
import 'state/usuario_controller.dart';
import 'config/env.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseService.inicializar();
  final authUserId = await _prepararSesion();
  final perfilLocal = await PerfilLocalController.cargar(clave: authUserId);
  // Sin Supabase configurado (sin .env) se usa el usuario de ejemplo para
  // que la app siga funcionando como demo.
  final usuario = UsuarioController(
    SupabaseService.disponible
        ? UsuarioRepositorySupabase()
        : UsuarioRepositoryMock(),
  );
  // Sin await: la app abre de inmediato y el perfil se completa al llegar.
  usuario.cargar();
  runApp(RecirculaApp(perfilLocal: perfilLocal, usuario: usuario));
}

/// Abre la sesión anónima de Supabase antes de montar la app, para que el
/// perfil local y los datos del usuario queden ligados a esa cuenta. Al
/// correr con F5 (`NUEVA_CUENTA_ANONIMA=true`) se crea una cuenta nueva.
/// Sin Supabase o sin conexión devuelve null: el UsuarioController reintenta
/// el login después y el perfil local cae al device_id.
Future<String?> _prepararSesion() async {
  if (!SupabaseService.disponible) return null;
  try {
    final user = await SupabaseService.prepararSesion(
      cuentaNueva: Env.nuevaCuentaAnonima,
    ).timeout(const Duration(seconds: 8));
    return user.id;
  } catch (e) {
    debugPrint('main: no se pudo abrir la sesión anónima ($e)');
    return null;
  }
}

class RecirculaApp extends StatelessWidget {
  final PerfilLocalController perfilLocal;
  final UsuarioController usuario;

  // Solo para tests: se propaga hasta MapaScreen para no depender de
  // Supabase inicializado (ver MainShell.puntosRepository).
  final PuntosRepository? puntosRepository;

  const RecirculaApp({
    super.key,
    required this.perfilLocal,
    required this.usuario,
    this.puntosRepository,
  });

  @override
  Widget build(BuildContext context) {
    return UsuarioScope(
      controller: usuario,
      child: PerfilLocalScope(
        controller: perfilLocal,
        child: ListenableBuilder(
          listenable: perfilLocal,
          builder: (context, _) {
            return MaterialApp(
              title: 'Recircula',
              debugShowCheckedModeBanner: false,
              theme: perfilLocal.perfil.modoEco ? AppTheme.eco : AppTheme.light,
              home: _PuertaEntrada(puntosRepository: puntosRepository),
            );
          },
        ),
      ),
    );
  }
}

/// Decide la primera pantalla según el usuario de la sesión: espera a que
/// cargue, muestra la bienvenida obligatoria si le faltan nombre y alias, y
/// si no entra a la app. Si la carga falla (sin conexión) entra igual: el
/// Perfil ofrece reintentar y la bienvenida aparece al reconectar.
class _PuertaEntrada extends StatelessWidget {
  final PuntosRepository? puntosRepository;

  const _PuertaEntrada({this.puntosRepository});

  @override
  Widget build(BuildContext context) {
    final usuarioCtrl = UsuarioScope.of(context);
    final usuario = usuarioCtrl.usuario;
    if (!usuarioCtrl.intentado) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (usuario != null && usuario.faltanDatos) {
      return const BienvenidaScreen();
    }
    return MainShell(puntosRepository: puntosRepository);
  }
}
