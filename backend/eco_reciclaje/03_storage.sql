-- Proyecto_Eco_reciclaje (shkdlkbhpkbrfxemctdj)
-- Paso 3: buckets de Storage y sus permisos. Cada usuario sube solo dentro
-- de su carpeta `<auth.uid()>/...`.
-- Idempotente.

begin;

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values
  -- Fotos obligatorias de "Reportar un problema" en un punto. Privado: las ve
  -- solo quien las subió (y el panel con la service role).
  ('reportes', 'reportes', false, 1048576, array['image/jpeg', 'image/png', 'image/webp']),
  -- Foto de perfil (usuario.url_imagen_perfil). Pública para mostrarla.
  ('avatares', 'avatares', true, 1048576, array['image/jpeg', 'image/png', 'image/webp']),
  -- Ícono de cada comunidad (comunidad.url_icono). Público.
  ('comunidades', 'comunidades', true, 1048576, array['image/jpeg', 'image/png', 'image/webp']),
  -- Íconos y marcos desbloqueables (elemento_personalizado.url_recurso).
  -- Público; solo lo carga el administrador desde el panel.
  ('elementos', 'elementos', true, 524288, array['image/png', 'image/svg+xml', 'image/webp']),
  -- Instaladores de la app (APK) para compartir el enlace de descarga. Público;
  -- solo lo carga el administrador desde el panel.
  ('descargas', 'descargas', true, 52428800, array['application/vnd.android.package-archive', 'application/octet-stream'])
on conflict (id) do update
  set public = excluded.public,
      file_size_limit = excluded.file_size_limit,
      allowed_mime_types = excluded.allowed_mime_types;

-- Políticas en storage.objects --------------------------------------------

drop policy if exists "reportes: subir en carpeta propia" on storage.objects;
create policy "reportes: subir en carpeta propia" on storage.objects
  for insert to authenticated
  with check (
    bucket_id = 'reportes'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );

drop policy if exists "reportes: ver las propias" on storage.objects;
create policy "reportes: ver las propias" on storage.objects
  for select to authenticated
  using (
    bucket_id = 'reportes'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );

drop policy if exists "avatares: subir en carpeta propia" on storage.objects;
create policy "avatares: subir en carpeta propia" on storage.objects
  for insert to authenticated
  with check (
    bucket_id = 'avatares'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );

drop policy if exists "avatares: reemplazar el propio" on storage.objects;
create policy "avatares: reemplazar el propio" on storage.objects
  for update to authenticated
  using (
    bucket_id = 'avatares'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );

drop policy if exists "avatares: borrar el propio" on storage.objects;
create policy "avatares: borrar el propio" on storage.objects
  for delete to authenticated
  using (
    bucket_id = 'avatares'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );

-- El ícono de una comunidad lo sube su administrador, en la carpeta
-- `<comunidad_id>/`.
drop policy if exists "comunidades: subir si administra" on storage.objects;
create policy "comunidades: subir si administra" on storage.objects
  for insert to authenticated
  with check (
    bucket_id = 'comunidades'
    and exists (
      select 1 from public.miembro_comunidad m
       where m.usuario_id = (select public.app_usuario_id())
         and m.rol_miembro = 'administrador'
         and m.comunidad_id::text = (storage.foldername(name))[1]
    )
  );

commit;
