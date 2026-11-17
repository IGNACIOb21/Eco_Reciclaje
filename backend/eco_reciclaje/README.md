# Base de datos: Proyecto_Eco_reciclaje

Proyecto Supabase `shkdlkbhpkbrfxemctdj` (us-east-1). Su esquema de 31 tablas en singular (`usuario`, `punto_reciclaje`, `reciclaje`, `comunidad`…) ya existía. Estos archivos lo conectan con la APK sin cambiar sus tablas originales: solo agregan columnas, funciones, permisos y datos base.

## Orden de aplicación

Todos son idempotentes (se pueden volver a correr). Ya están aplicados en la nube.

| Archivo | Qué hace |
|---|---|
| `00_tipos.sql` | Valores nuevos de `tipo_movimiento_enum` (reporte, calificación, devolución de canje). Va solo porque un valor nuevo de enum no se puede usar en la misma transacción. |
| `01_conexion_app.sql` | `usuario.auth_id` ligado a Supabase Auth, trigger que crea la fila de `usuario` al abrir sesión (también anónima), columnas de apoyo, tabla `servicio_tercero` y políticas RLS de lectura. |
| `02_funciones_app.sql` | Funciones `app_*` que llama la APK: perfil y puntos, mapa (`app_puntos_cercanos`), escaneo (`app_registrar_reciclaje`, máx. 5 artículos por registro y 30 por día), reportes, calificaciones, beneficios y canjes, comunidades y servicios. |
| `03_storage.sql` | Buckets `reportes` (privado), `avatares`, `comunidades`, `elementos` y `descargas` (públicos) con sus políticas. |
| `04_seed.sql` | Roles, 11 categorías con su código, reglas de puntuación, entidades y 46 puntos de reciclaje de OpenStreetMap. |
| `05_inicio.sql` | `app_resumen_hoy`: meta del día (3 objetos) y racha, para la cabecera del mapa. |
| `06_logros.sql` | Insignias sobre `logro` y `logro_usuario` (columnas `codigo`, `metrica`, `puntos_recompensa`). |
| `07_comunidad_comuna.sql` | Pestañas Hoy, Actividad y Ranking de Comunidad (`usuario.comuna`, `usuario.oculto_ranking`). |
| `08_seed_beneficios_servicios.sql` | Datos de ejemplo: 6 beneficios y 6 servicios de recolectores (ficticios). |
| `09_seguridad.sql` | Quita `_racha` a `authenticated`, bloquea el beneficio al canjear y al usuario al calificar, y revoca la escritura directa en tablas. |

Para aplicarlos con la CLI (sesión iniciada con `supabase login`), usando rutas absolutas:

```
supabase db query --linked --project-ref shkdlkbhpkbrfxemctdj -f <ruta absoluta>\01_conexion_app.sql
```

`pruebas/` tiene pruebas de humo que crean un usuario de prueba y terminan con `ROLLBACK` (no dejan datos).

## Reglas

- La APK solo **lee** catálogos y lo propio (RLS) y **escribe** por funciones `app_*` (`security definer`, validan `auth.uid()`).
- La APK usa la **publishable key**. La secret key (service role) nunca va en la app ni en el repositorio.
- Las cuentas anónimas no pueden canjear beneficios: primero se registra un correo desde Perfil.

## Auth (configurado con `supabase config push` desde esta carpeta)

`supabase/config.toml` deja activado: inicio de sesión anónimo, código de 8 dígitos que vence en 15 min, contraseña de 8+ caracteres con mayúscula, minúscula, número y símbolo.

**Registro con correo (SMTP propio):** en el plan gratuito Supabase no deja cambiar la plantilla sin un SMTP propio; sin ella, el correo de "cambiar email" trae un enlace en vez del código de 8 dígitos que pide la app. `supabase/config.toml` ya trae la plantilla (`supabase/templates/codigo_verificacion.html`) y el SMTP de Resend (misma cuenta que Rebin); los secretos se leen de variables de entorno. Pasos:

1. En Resend → *Domains*, tener un dominio con estado *Verified* (sin dominio, Resend solo entrega al correo dueño de la cuenta).
2. En Resend → *API Keys* crear una key propia de este proyecto con permiso *Sending access*.
3. Copiar `.env.example` como `.env` en esta carpeta y completarlo (`.env` no se versiona).
4. Desde esta carpeta, en PowerShell, cargar el `.env` y subir la configuración:

   ```powershell
   Get-Content .env | Where-Object { $_ -match '^\s*[^#].*=' } | ForEach-Object { $k, $v = $_ -split '=', 2; Set-Item "env:$($k.Trim())" $v.Trim() }
   supabase config push --project-ref shkdlkbhpkbrfxemctdj
   ```

5. Comprobar en *Authentication → Emails* que el SMTP quedó activo y probar el registro desde Perfil en la APK.

## Lo que no existe en este esquema (oculto en la app)

Sugerir puntos nuevos, misiones semanales, sorpresa diaria, congeladores de racha y el flujo de depósito con QR en el punto.
