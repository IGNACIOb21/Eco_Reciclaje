-- ARCHIVADA (2026-10-07) — NO APLICAR.
-- Nunca se aplicó a la nube (`supabase migration list` la muestra solo en
-- Local). Está escrita contra la tabla `usuario`, que no existe en el esquema
-- remoto real (`usuarios`, ver docs/esquema-remoto.md del repo rebin). La APK
-- ya no la necesita: el nombre real se guarda en user_metadata de Supabase
-- Auth y el alias en `usuarios.alias`.
--
-- Nombre real del usuario, pedido de forma obligatoria al iniciar sesión en
-- la APK junto con el alias (que ya existe: nombre_usuario).
--
-- La columna queda nullable: las cuentas recién creadas por
-- handle_new_auth_user todavía no lo tienen, y la APK muestra el formulario
-- de bienvenida mientras `nombre` sea null. Por eso la obligatoriedad vive en
-- la APK (UX) y acá solo se valida el largo.

alter table public.usuario
  add column if not exists nombre text;

alter table public.usuario
  add constraint usuario_nombre_largo_check
    check (nombre is null or char_length(btrim(nombre)) between 2 and 60);

-- Alias: mismo criterio. NOT VALID para no fallar si alguna fila antigua no
-- cumple; aplica a todo insert/update desde ahora.
alter table public.usuario
  add constraint usuario_nombre_usuario_largo_check
    check (char_length(btrim(nombre_usuario)) between 2 and 30) not valid;

-- El cliente puede escribir su propio nombre (la policy usuario_update_own
-- ya limita la fila a la propia).
grant insert (nombre) on table public.usuario to authenticated;
grant update (nombre) on table public.usuario to authenticated;
