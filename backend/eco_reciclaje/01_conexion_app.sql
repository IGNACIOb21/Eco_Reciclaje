-- Proyecto_Eco_reciclaje (shkdlkbhpkbrfxemctdj)
-- Paso 1: conecta el esquema con Supabase Auth y abre a la app solo lo que
-- debe leer. Las escrituras de la app van solo por funciones app_* (paso 2).
-- Idempotente: se puede volver a correr.

begin;

-- ---------------------------------------------------------------------------
-- Columnas nuevas
-- ---------------------------------------------------------------------------

-- Cada fila de usuario queda ligada a su cuenta de Supabase Auth (también las
-- anónimas). usuario_id sigue siendo la PK entera que usan las demás tablas.
alter table usuario
  add column if not exists auth_id uuid unique references auth.users (id) on delete cascade;

-- Código estable que usa la app (TipoMaterial.codigo y clases del modelo).
alter table categoria_residuo
  add column if not exists codigo varchar(30) unique;

-- Comuna para filtrar el mapa y agrupar comunidades; osm_id para no duplicar
-- puntos importados desde OpenStreetMap.
alter table punto_reciclaje
  add column if not exists comuna varchar(60),
  add column if not exists osm_id varchar(40) unique;

-- El tipo detallado del reporte que elige la app (11 opciones) se guarda en
-- subtipo; tipo_reporte guarda su grupo dentro del enum existente. ruta_foto
-- es la ruta del archivo en el bucket privado `reportes`.
alter table reporte_punto
  add column if not exists subtipo varchar(40),
  add column if not exists ruta_foto text;

alter table calificacion_punto
  add column if not exists etiquetas text[];

alter table comunidad
  add column if not exists comuna varchar(60);

-- Código que muestra el usuario al retirar un beneficio.
alter table canjeo
  add column if not exists codigo_canje varchar(12) unique,
  add column if not exists fecha_validacion timestamptz;

-- ---------------------------------------------------------------------------
-- Servicios de terceros (pestaña Servicios): recolectores particulares que
-- postulan desde la app y un administrador aprueba.
-- ---------------------------------------------------------------------------

create table if not exists servicio_tercero (
  servicio_tercero_id integer generated always as identity primary key,
  usuario_id integer references usuario (usuario_id) on delete set null,
  nombre varchar(100) not null,
  contacto varchar(150) not null,
  descripcion text,
  comunas text[] not null,
  materiales text[] not null,
  retira_a_domicilio boolean not null default false,
  horario jsonb,
  estado varchar(20) not null default 'pendiente'
    check (estado in ('pendiente', 'activo', 'rechazado', 'inactivo')),
  motivo_rechazo text,
  fecha_registro timestamptz not null default now()
);

alter table servicio_tercero enable row level security;

-- ---------------------------------------------------------------------------
-- Auth → usuario
-- ---------------------------------------------------------------------------

-- usuario_id de la sesión actual (null si no hay sesión o fila).
create or replace function public.app_usuario_id()
returns integer
language sql
stable
security definer
set search_path = public
as $$
  select usuario_id from usuario where auth_id = auth.uid()
$$;

-- Crea la fila de usuario al registrarse en Auth, incluidas las sesiones
-- anónimas con que abre la app.
create or replace function public.handle_new_auth_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_id integer;
begin
  insert into usuario (auth_id, nombre_usuario, correo_electronico)
  values (
    new.id,
    'Reciclador-' || upper(substr(replace(new.id::text, '-', ''), 1, 5)),
    nullif(new.email, '')
  )
  on conflict (auth_id) do nothing
  returning usuario_id into v_id;

  if v_id is not null then
    insert into usuario_rol (usuario_id, rol_id)
    select v_id, rol_id from rol where nombre = 'ciudadano'
    on conflict do nothing;

    insert into configuracion_usuario (usuario_id)
    values (v_id)
    on conflict do nothing;
  end if;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_auth_user();

-- Al vincular un correo a la cuenta (registro desde Perfil), se copia a
-- usuario.correo_electronico.
create or replace function public.handle_auth_user_email_change()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  update usuario
     set correo_electronico = nullif(new.email, '')
   where auth_id = new.id;
  return new;
end;
$$;

drop trigger if exists on_auth_user_email_change on auth.users;
create trigger on_auth_user_email_change
  after update of email on auth.users
  for each row
  when (old.email is distinct from new.email)
  execute function public.handle_auth_user_email_change();

revoke execute on function public.handle_new_auth_user() from public, anon, authenticated;
revoke execute on function public.handle_auth_user_email_change() from public, anon, authenticated;

-- ---------------------------------------------------------------------------
-- RLS: lectura
-- ---------------------------------------------------------------------------

-- Catálogos y contenido público: cualquiera con la app puede leerlos.
do $$
declare
  t text;
begin
  foreach t in array array[
    'categoria_residuo', 'punto_reciclaje', 'punto_categoria',
    'entidad_administradora', 'regla_puntuacion', 'canjeo_beneficio',
    'evento_reciclaje', 'logro', 'elemento_personalizado', 'rol',
    'comunidad', 'foro', 'meta_comunidad', 'beneficio_comunidad'
  ] loop
    execute format('drop policy if exists app_lectura_publica on %I', t);
    execute format(
      'create policy app_lectura_publica on %I for select to anon, authenticated using (true)',
      t
    );
  end loop;
end $$;

-- Lo propio: cada usuario lee solo sus filas.
do $$
declare
  t text;
begin
  foreach t in array array[
    'movimiento_punto', 'reciclaje', 'reporte_punto', 'logro_usuario',
    'canjeo', 'notificacion', 'configuracion_usuario', 'elemento_usuario',
    'evento_usuario', 'distribucion_punto', 'calificacion_punto',
    'miembro_comunidad', 'usuario_rol'
  ] loop
    execute format('drop policy if exists app_lectura_propia on %I', t);
    execute format(
      'create policy app_lectura_propia on %I for select to authenticated using (usuario_id = (select public.app_usuario_id()))',
      t
    );
  end loop;
end $$;

drop policy if exists app_lectura_propia on usuario;
create policy app_lectura_propia on usuario
  for select to authenticated
  using (auth_id = (select auth.uid()));

-- Las publicaciones y comentarios de comunidades se leen por funciones (que
-- agregan el alias del autor sin exponer la tabla usuario).

commit;
