# Eco Reciclaje — Contexto del proyecto (solo APK)

Proyecto de título: app móvil que identifica de qué material es un objeto a partir de una foto y muestra un mapa de puntos de reciclaje. Equipo de 2 personas (uno en mapa/backend, otro en cámara/clasificación).

`/app` parte del diseño de Rebin (`rebin-main`, commit `28a427d`) con el escáner y el modelo TFLite de Joaquín, conectada a la base **Proyecto_Eco_reciclaje** (`shkdlkbhpkbrfxemctdj`). Rebin (`xenzzz/rebin`) es otro proyecto con otra base (`telgqotqvjzobuucahca`): no mezclar.

```
/app                    APK Flutter
/backend/eco_reciclaje  SQL aplicado en Proyecto_Eco_reciclaje (00..09), pruebas y config.toml de Auth
/backend                (resto) SQL antiguo de Rebin: solo referencia
/docs                   Definición de BD de Rebin (desactualizada)
/design/mockup          mockups PNG de las pantallas
```

## Stack

- Flutter + Supabase (SDK directo, bajo RLS) + Mapbox + TFLite on-device.
- **No confirmado:** cualquier otra herramienta (Firebase Cloud Messaging, Riverpod, FVM, etc.). No agregar sin discutirlo.

## App

- Barra: Inicio (mapa con `ResumenInicio` y saldo) · Comunidad (Hoy, Actividad, Ranking, Grupos) · Escanear (botón central → `EscanearScreen`) · Servicios · Perfil.
- Abre directo en el mapa con sesión anónima: no hay bienvenida ni inicio de sesión al arrancar. El permiso de ubicación se pide una vez sobre el mapa. El registro con correo (código de 8 dígitos + contraseña) está en Perfil.
- Tema por defecto: `TemaApp.claro` (plomo casi blanco, `fondo` `#F1F2F4`).
- Escáner: `lib/escaneo/` (clases del modelo → `categoria_residuo.codigo` en `info_clase.dart`).
- Ocultos porque la base no los soporta: sugerir/confirmar puntos, misiones, sorpresa diaria, congeladores, flujo de depósito con QR (`flujo_reciclaje_screen.dart` sigue en el código pero no se abre).

## Base de datos

- **La nube es la fuente de verdad.** Esquema en singular: `usuario` (PK entera `usuario_id`, `auth_id` = `auth.uid()`, `nombre_usuario` es el alias), `punto_reciclaje` (lat/lng numéricos, sin PostGIS), `reciclaje`, `movimiento_punto`, `comunidad`, `miembro_comunidad`, `foro`, `publicacion_foro`, `logro`, `logro_usuario`, `canjeo_beneficio`, `canjeo`, `reporte_punto`, `calificacion_punto`, `servicio_tercero`.
- La APK lee lo público y lo propio (RLS) y escribe solo por funciones `app_*` (`security definer`).
- El saldo es la suma de `movimiento_punto`; en la APK nunca se muestra negativo.
- **Cambios de esquema:** siempre como SQL idempotente nuevo en `backend/eco_reciclaje/` (numerado), con su prueba en `pruebas/` terminada en `ROLLBACK`. Se aplica con `supabase db query --linked --project-ref shkdlkbhpkbrfxemctdj -f <ruta absoluta>`.
- **No correr `supabase db push` desde `backend/`** (esas migraciones son del esquema de Rebin).

## Notas de ambiente

- Auth se configura con `supabase config push --project-ref shkdlkbhpkbrfxemctdj` desde `backend/eco_reciclaje/` (anónimo activo, OTP 8 dígitos / 900 s, contraseña fuerte). El correo con el código sale por SMTP de Resend (remitente `no-reply@rebin.lat`); la API key va en `backend/eco_reciclaje/.env` (`SMTP_PASS`, `SMTP_ADMIN_EMAIL`) y hay que cargarla antes del push. `config push` aplica sin preguntar: para comparar usar `supabase config diff`.
- **F5 en VS Code** (`.vscode/launch.json`): "cuenta anónima nueva" pasa `--dart-define=NUEVA_CUENTA_ANONIMA=true`; "sesión guardada" reutiliza la anterior.
- Nunca commitear claves de API, la secret key de Supabase ni `google-services.json` — usar `.env`. La app usa solo la publishable key.

## Git

- Remoto: `https://github.com/IGNACIOb21/Eco_Reciclaje.git`. Rama base de este trabajo: `joaquin`; el rediseño está en `rediseno-rebin`.
- Nunca commitear en `main`; una rama por cambio; commits atómicos en español; no tocar ramas ajenas; no force-push; nunca merge a `main` sin aprobación (se integra por pull request).
