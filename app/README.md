# Rebin — App móvil (Flutter)

APK del proyecto Rebin (paquete Dart `recircula`). Mapa comunitario de puntos de reciclaje, perfil con puntos y niveles, comunidad y directorio de recolectores. La cámara/clasificación (TensorFlow Lite on-device) todavía es un placeholder.

Contexto completo del proyecto en [`../CLAUDE.md`](../CLAUDE.md).

## Configuración

```bash
cp .env.example .env
flutter pub get
flutter run
```

`.env`:

```
SUPABASE_URL=https://tu-proyecto.supabase.co
SUPABASE_ANON_KEY=<publishable / anon key>
```

Sin `.env` (o con claves vacías) la app usa repositorios mock y funciona como demo. Para Supabase local (`supabase start`) se usa la IP del PC y la anon key que imprime el comando.

Requiere el login anónimo habilitado en Supabase Auth y las policies RLS de `docs/rls-perfil.md` aplicadas por el dueño del proyecto (sin ellas la base responde 42501). El nombre real se guarda en `user_metadata` y el alias en `usuarios.alias`.

### Correr desde VS Code

`.vscode/launch.json` en la raíz del repo trae dos configuraciones:

- **Rebin APK (cuenta anónima nueva):** pasa `--dart-define=NUEVA_CUENTA_ANONIMA=true`, que descarta la sesión guardada y crea otra cuenta anónima en cada arranque.
- **Rebin APK (sesión guardada):** reutiliza la cuenta anterior.

## Flujo de la app

1. **Arranque:** se abre la sesión anónima de Supabase (`SupabaseService.prepararSesion`) y se carga el perfil local ligado al `auth.uid()` (o al `device_id` sin Supabase).
2. **Bienvenida obligatoria** (`bienvenida_screen.dart`): mientras `usuario.nombre` sea null pide nombre y alias, y luego los permisos de ubicación y notificaciones. Los permisos se pueden rechazar y activar después desde Perfil › Ajustes.
3. **MainShell:** Inicio, Mapa, Comunidad, Servicios y Perfil.
4. **Cuenta con correo (opcional):** desde Perfil se vincula la sesión anónima a un correo con un código de 8 dígitos y una contraseña (`registro_cuenta_screen.dart`). Se conservan los puntos porque es el mismo usuario. "¿Ya tienes cuenta?" abre `iniciar_sesion_screen.dart`.

## Estructura de `lib/`

```
config/        Env (lee .env con flutter_dotenv)
data/          datos de ejemplo (puntos, comunidades, recolectores, comunas)
models/        usuario, perfil, movimiento_punto, punto_reciclaje, nivel, insignia, ...
repositories/  interfaz + versión Mock y Supabase (usuario, cuenta, puntos); recolectores solo Mock
screens/       una por pantalla
services/      supabase_service, ubicacion, permisos, correo (consulta MX), perfil_local_store
state/         UsuarioController y PerfilLocalController (ChangeNotifier + InheritedNotifier)
theme/         AppTheme (claro y Modo Eco) y ColoresApp, espaciados, radios
utils/         fechas, geo, snackbars, validacion_cuenta
widgets/       componentes reutilizables (pines del mapa, tarjetas, avatar, permisos, ...)
```

Las pantallas nunca hablan directo con Supabase: siempre pasan por un repositorio.

## Dependencias principales

`supabase_flutter`, `flutter_dotenv`, `flutter_map` + `latlong2` (OpenStreetMap), `geolocator`, `permission_handler` (fijado en ^12), `shared_preferences`, `uuid`.

## Estado conocido

- Con Supabase configurado el **Mapa no carga puntos**: `PuntosRepositorySupabase` llama a la RPC `puntos_cercanos`, que no existe en el esquema de la nube. Hay que portarla (ver `CLAUDE.md`).
- Comunidad y Servicios usan datos mock.
- La cámara aún no clasifica (`escanear_placeholder_screen.dart`).

## Tests

```bash
flutter test
```

- `test/widget_test.dart`: pantallas sobre repositorios mock (Inicio, Mapa y filtros, Perfil, Modo Eco, Comunidad, vinculación de cuenta e inicio de sesión).
- `test/validacion_cuenta_test.dart`: reglas de correo y contraseña.
