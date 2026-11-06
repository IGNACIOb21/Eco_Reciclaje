# Rebin

App móvil que identifica si un objeto es reciclable a partir de una foto y muestra un mapa comunitario de puntos de reciclaje. Proyecto de título.

> `/app` es una copia antigua de la APK (2026-10-07). La versión vigente está en el repo `rebin` (`xenzzz/rebin`).

Contexto detallado: ver [`CLAUDE.md`](CLAUDE.md).

## Estructura

```
/app       App móvil Flutter (Android/iOS) — ver app/README.md
/backend   Supabase: migraciones antiguas, plantillas de Auth, script de importación OSM
/docs      Documentación de base de datos, RLS e importación OSM
/design    Mockups de las pantallas de la APK
```

## Requisitos

- Flutter (SDK compatible con Dart 3)
- Un proyecto Supabase con el SQL de `backend/remoto/` del repo `rebin` aplicado

## App móvil (`/app`)

```bash
cd app
cp .env.example .env     # completar SUPABASE_URL y SUPABASE_ANON_KEY
flutter pub get
flutter run
```

Sin `.env` la app funciona igual como demo con repositorios mock. Con Supabase configurado abre una sesión anónima y pide nombre y alias en la bienvenida.

En VS Code, F5 ofrece dos configuraciones (`.vscode/launch.json`): **cuenta anónima nueva** (crea una cuenta nueva en cada arranque) y **sesión guardada**.

Tests: `flutter test`.

## Base de datos (`/backend`)

- El esquema real de la nube es el de `docs/esquema-remoto.md` del repo `rebin`. Los cambios para la nube se escriben como SQL en `rebin/backend/remoto/` y los aplica el dueño del proyecto.
- `backend/supabase/migrations/` describe un esquema **anterior** y solo se conserva porque ya figura en el historial remoto. **No correr `supabase db push` desde `backend/`.**
- `backend/supabase/templates/codigo_verificacion.html`: correo con el código de 8 dígitos para vincular la cuenta. En la nube hay que configurarlo a mano en Auth, junto con el largo del OTP, la política de contraseñas y el SMTP (detalle en `CLAUDE.md`).
- `backend/legacy_esquema_repo/` es el esquema antiguo archivado: no aplicarlo.

## Notas

- Nunca commitear `.env`, claves de Supabase ni `google-services.json`.
