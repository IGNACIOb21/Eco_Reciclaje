# Rebin — Contexto del proyecto (solo APK)

Proyecto de título: app móvil que identifica si un objeto es reciclable a partir de una foto y muestra un mapa comunitario de puntos de reciclaje. Equipo de 2 personas (uno en mapa/backend, otro en cámara/clasificación).

Este repo quedó solo con la parte de la APK (la Web API `/api` y el panel `/admin` se quitaron en la rama `chore/solo-apk`; siguen en el historial de git). **`/app` es una copia antigua de la APK**: la vigente, sus migraciones y su `CLAUDE.md` (stack, pantallas, puntos y niveles) están en el repo `rebin` (`xenzzz/rebin`), que es el que se mantiene al día.

```
/app       copia vieja de la APK Flutter
/backend   SQL antiguo del esquema en singular (`supabase/migrations`, `legacy_esquema_repo`): solo referencia;
           el SQL vigente de la nube está en `rebin/backend/remoto/`
/docs      Definición de BD (desactualizada), RLS del Perfil, importación OSM
/design/mockup   mockups PNG de las pantallas de la APK
```

## Stack

- Flutter + Supabase (SDK directo, bajo RLS) + Mapbox + TFLite on-device.
- **No confirmado:** cualquier otra herramienta (Firebase Cloud Messaging, Riverpod, FVM, etc.). No agregar sin discutirlo.

## Base de datos

- **La nube es la fuente de verdad.** El esquema real es el de `docs/esquema-remoto.md` del repo `rebin` (`usuarios` con `id_usuario` = `auth.uid()`, `alias`; `movimientos_puntos`; `reciclajes`; `reporte_punto`; `logros_usuario`; `roles`).
- La APK lee la base directo (bajo RLS) y escribe solo por funciones `app_*`.
- Lógica compartida (acreditar puntos con `acreditar_puntos`, cercanía con `app_puntos_cercanos`) vive en PostgreSQL.
- Puntos: `ubicacion geography(Point,4326)`, `id_comuna` obligatorio, nunca se eliminan (baja lógica con `estado_operativo = 'cerrado'`). El mapa muestra solo `operativo`, `en_mantencion` y `en_limpieza`.
- El saldo de un usuario se calcula sumando sus movimientos de puntos; en la APK nunca se muestra negativo.
- **Cambios de esquema:** siempre como SQL versionado en `rebin/backend/remoto/` (o `remoto_propuesto/` si lo revisa el dueño, que lo aplica a mano en el SQL Editor). **No correr `supabase db push` desde `backend/`.**
- Las migraciones de `backend/supabase/migrations/` describen un esquema anterior y solo se conservan porque figuran como aplicadas en el proyecto `telgqotqvjzobuucahca` (`supabase migration repair` solo con autorización del dueño). `backend/legacy_esquema_repo/` es el esquema antiguo archivado: no aplicarlo.

## Notas de ambiente

- La APK se desarrolla en Linux Mint — emulador Android liviano (sin Play Store, RAM reducida) y Android físico (MIUI) por USB. `flutter run` no se ejecuta desde Claude Code.
- **Supabase Auth en la nube (configurar en el panel de Supabase, `config.toml` solo aplica al local):** Email OTP Length = 8, expiración 900 s, contraseña mínima 8 con `lower_upper_letters_digits_symbols`, plantilla "Change Email Address" = `backend/supabase/templates/codigo_verificacion.html` (usa `{{ .Token }}`), y SMTP de Resend (`smtp.resend.com`, puerto 465, usuario `resend`, la API key como contraseña).
- **F5 en VS Code** (`.vscode/launch.json`): "cuenta anónima nueva" pasa `--dart-define=NUEVA_CUENTA_ANONIMA=true` (crea una cuenta anónima nueva en cada arranque); "sesión guardada" reutiliza la anterior. Requiere login anónimo habilitado en Supabase Auth.
- Nunca commitear claves de API, credenciales de Supabase ni `google-services.json` — usar `.env`.

## Git

- Remoto: `https://github.com/xenzzz/api-web.git`.
- Nunca commitear en `main`; una rama por cambio; commits atómicos en español; no tocar ramas ajenas; no force-push; nunca merge a `main` sin aprobación (se integra por pull request).
