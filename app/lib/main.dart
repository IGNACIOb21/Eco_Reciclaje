import 'package:flutter/material.dart';

import 'repositories/puntos_repository.dart';
import 'repositories/usuario_repository_mock.dart';
import 'repositories/usuario_repository_supabase.dart';
import 'screens/bienvenida_screen.dart';
import 'screens/main_shell.dart';
import 'services/haptica.dart';
import 'services/supabase_service.dart';
import 'services/ubicacion_service.dart';
import 'state/perfil_local_controller.dart';
import 'state/primer_inicio_controller.dart';
import 'state/tema_controller.dart';
import 'state/usuario_controller.dart';
import 'config/env.dart';
import 'utils/rutas.dart';
import 'widgets/barra_sistema_solida.dart';
import 'widgets/lanzamiento.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseService.inicializar();
  final authUserId = await _prepararSesion();
  // Sin Supabase configurado (sin .env) se usa el usuario de ejemplo para
  // que la app siga funcionando como demo.
  final usuario = UsuarioController(
    SupabaseService.disponible
        ? UsuarioRepositorySupabase()
        : UsuarioRepositoryMock(),
    idSesion: SupabaseService.disponible
        ? () => SupabaseService.cliente.auth.currentUser?.id
        : null,
  );
  // Sin await: la app abre de inmediato y el perfil se completa al llegar.
  usuario.cargar();
  // Lo guardado en el teléfono se lee todo a la vez, junto con la última
  // ubicación conocida (sin encender el GPS) para que el mapa parta cerca.
  final (perfilLocal, primerInicio, tema, _, _) = await (
    PerfilLocalController.cargar(clave: authUserId),
    PrimerInicioController.cargar(),
    TemaController.cargar(),
    Haptica.cargar(),
    precargarUltimaUbicacion(),
  ).wait;
  runApp(
    RecirculaApp(
      perfilLocal: perfilLocal,
      usuario: usuario,
      primerInicio: primerInicio,
      tema: tema,
      mostrarLanzamiento: true,
    ),
  );
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
  final PrimerInicioController primerInicio;
  final TemaController tema;

  // Solo para tests: se propaga hasta MapaScreen para no depender de
  // Supabase inicializado (ver MainShell.puntosRepository).
  final PuntosRepository? puntosRepository;

  /// Animación de apertura (logo y personas reciclando). Solo se activa en
  /// `main`: los tests montan la app sin ella.
  final bool mostrarLanzamiento;

  const RecirculaApp({
    super.key,
    required this.perfilLocal,
    required this.usuario,
    required this.primerInicio,
    required this.tema,
    this.puntosRepository,
    this.mostrarLanzamiento = false,
  });

  @override
  Widget build(BuildContext context) {
    return UsuarioScope(
      controller: usuario,
      child: PerfilLocalScope(
        controller: perfilLocal,
        child: PrimerInicioScope(
          controller: primerInicio,
          child: TemaScope(
            controller: tema,
            child: ListenableBuilder(
              listenable: tema,
              builder: (context, _) {
                return MaterialApp(
                  title: 'Revin',
                  debugShowCheckedModeBanner: false,
                  theme: tema.tema.datos,
                  navigatorObservers: [observadorRutas],
                  builder: (context, child) {
                    final app = BarraSistemaSolida(
                      child: child ?? const SizedBox(),
                    );
                    if (!mostrarLanzamiento) return app;
                    // La animación de apertura va por encima de toda la app.
                    return Lanzamiento(
                      datos: usuario,
                      datosListos: () => usuario.intentado,
                      child: app,
                    );
                  },
                  home: _PuertaEntrada(puntosRepository: puntosRepository),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// La primera vez tras instalar abre la bienvenida (acceso con "Omitir",
/// nombre de usuario y permisos opcionales) sobre la sesión anónima. Desde
/// ahí abre directo en el mapa (Inicio). Iniciar o cerrar sesión cambia la
/// clave del perfil local y el MainShell se reconstruye desde Inicio con la
/// cuenta nueva.
class _PuertaEntrada extends StatelessWidget {
  final PuntosRepository? puntosRepository;

  const _PuertaEntrada({this.puntosRepository});

  @override
  Widget build(BuildContext context) {
    if (!PrimerInicioScope.of(context).completado) {
      return const BienvenidaScreen();
    }
    return MainShell(
      key: ValueKey(PerfilLocalScope.of(context).clave),
      puntosRepository: puntosRepository,
    );
  }
}
