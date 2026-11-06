-- ============================================================================
-- NO TOMAR COMO REFERENCIA DEL ESQUEMA ACTUAL (nota agregada 2026-10-07)
--
-- YA APLICADA con `supabase db push` al proyecto telgqotqvjzobuucahca
-- (`supabase migration list` la muestra en Local y Remote). Se queda en
-- migrations/ para no desalinear el historial remoto; sacarla requiere
-- `supabase migration repair --status reverted 20261003120000`, solo con
-- autorización del dueño del proyecto.
--
-- Está escrita contra el esquema anterior (usuario con auth_user_id,
-- usuario_rol.usuario_id bigint, rol). El esquema real usa usuarios
-- (id_usuario = auth.uid()), usuario_rol.id_usuario y roles: las policies
-- equivalentes para ese esquema van como SQL nuevo en rebin/backend/remoto/
-- (ver docs/rls-perfil.md).
-- ============================================================================

-- Cierra el acceso a usuario, usuario_rol y rol.
--
-- Antes: policies "allow_all" para anon y authenticated, así que cualquier
-- cliente (incluso sin sesión) podía leer todos los usuarios, editar filas
-- ajenas y asignarse el rol de administrador insertando en usuario_rol.
--
-- Después:
--   usuario      cada uno ve, crea y edita solo su propia fila; solo puede
--                cambiar nombre_usuario y url_imagen_perfil.
--   usuario_rol  cada uno ve solo sus roles; nadie los escribe desde el
--                cliente. Se asignan desde la Web API (service_role) o SQL.
--   rol          catálogo de solo lectura para usuarios con sesión.
--
-- Lo que sigue funcionando:
--   - handle_new_auth_user (SECURITY DEFINER, dueño postgres) sigue creando
--     la fila de usuario y el rol 'usuario' al registrarse.
--   - La APK (sesión anónima = rol authenticated) lee su fila y, de respaldo,
--     la inserta si el trigger no lo hizo (usuario_repository_supabase.dart).
--   - current_usuario_id() no cambia.

-- usuario ------------------------------------------------------------------

drop policy if exists "Permitir acceso a usuarios autenticados y anónimos" on public.usuario;
drop policy if exists "usuario_select_own" on public.usuario;
drop policy if exists "usuario_update_own" on public.usuario;

create policy "usuario_select_own" on public.usuario
  for select
  to authenticated
  using (auth_user_id = auth.uid());

create policy "usuario_insert_own" on public.usuario
  for insert
  to authenticated
  with check (auth_user_id = auth.uid());

create policy "usuario_update_own" on public.usuario
  for update
  to authenticated
  using (auth_user_id = auth.uid())
  with check (auth_user_id = auth.uid());

-- Sin policy de delete: los usuarios no se borran desde el cliente.

-- Las policies filtran filas; los grants limitan columnas. Así un usuario no
-- puede reactivarse (activo), cambiar su correo ni su fecha de registro.
revoke all on table public.usuario from anon, authenticated;
grant select on table public.usuario to authenticated;
grant insert (auth_user_id, nombre_usuario, url_imagen_perfil) on table public.usuario to authenticated;
grant update (nombre_usuario, url_imagen_perfil) on table public.usuario to authenticated;

-- usuario_rol --------------------------------------------------------------

drop policy if exists "usuario_rol_allow_all" on public.usuario_rol;

create policy "usuario_rol_select_own" on public.usuario_rol
  for select
  to authenticated
  using (usuario_id = public.current_usuario_id());

revoke all on table public.usuario_rol from anon, authenticated;
grant select on table public.usuario_rol to authenticated;

-- rol ----------------------------------------------------------------------

-- También estaba abierto: borrar un rol eliminaba en cascada sus usuario_rol.
drop policy if exists "rol_allow_all" on public.rol;

create policy "rol_select" on public.rol
  for select
  to authenticated
  using (true);

revoke all on table public.rol from anon, authenticated;
grant select on table public.rol to authenticated;
