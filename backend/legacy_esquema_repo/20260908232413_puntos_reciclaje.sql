-- Esquema base para el mapa comunitario: catálogo de materiales, puntos de
-- reciclaje (con columna geography para PostGIS) y su relación muchos-a-muchos
-- con materiales. calificacion_promedio/num_calificaciones y estado_actual
-- quedan denormalizados en puntos_reciclaje por ahora — se normalizan a las
-- tablas calificaciones/reportes_estado cuando se construyan esas features
-- (ver docs/definicion-base-de-datos.md).

create extension if not exists postgis;

create table materiales (
  codigo text primary key,
  nombre text not null,
  orden smallint not null default 0
);

alter table materiales enable row level security;

create policy "lectura publica de materiales"
  on materiales for select
  using (true);

insert into materiales (codigo, nombre, orden) values
  ('vidrio', 'Vidrio', 1),
  ('papel', 'Papel y cartón', 2),
  ('plastico', 'Plástico', 3),
  ('metal', 'Metal', 4),
  ('pilas', 'Pilas', 5),
  ('latas', 'Latas', 6),
  ('tetra_pak', 'Tetra Pak', 7);

create table puntos_reciclaje (
  id uuid primary key default gen_random_uuid(),
  nombre text not null,
  direccion text,
  comuna text not null,
  lat double precision not null check (lat between -90 and 90),
  lng double precision not null check (lng between -180 and 180),
  geog geography(point, 4326) generated always as (
    st_setsrid(st_makepoint(lng, lat), 4326)::geography
  ) stored,
  fuente text not null default 'comunidad' check (fuente in ('oficial', 'comunidad')),
  estado_actual text not null default 'disponible' check (estado_actual in (
    'disponible', 'lleno', 'danado', 'sin_senalizacion', 'mal_mantenimiento', 'fuera_de_uso'
  )),
  calificacion_promedio numeric(2, 1) not null default 0 check (calificacion_promedio between 0 and 5),
  num_calificaciones integer not null default 0 check (num_calificaciones >= 0),
  creado_por uuid references auth.users (id),
  creado_en timestamptz not null default now()
);

create index puntos_reciclaje_geog_idx on puntos_reciclaje using gist (geog);
create index puntos_reciclaje_comuna_idx on puntos_reciclaje (comuna);

alter table puntos_reciclaje enable row level security;

create policy "lectura publica de puntos"
  on puntos_reciclaje for select
  using (true);

create policy "usuarios autenticados agregan puntos"
  on puntos_reciclaje for insert
  with check (auth.uid() is not null);

create table puntos_reciclaje_materiales (
  punto_id uuid not null references puntos_reciclaje (id) on delete cascade,
  material_codigo text not null references materiales (codigo) on delete restrict,
  primary key (punto_id, material_codigo)
);

create index puntos_reciclaje_materiales_material_idx on puntos_reciclaje_materiales (material_codigo);

alter table puntos_reciclaje_materiales enable row level security;

create policy "lectura publica de puntos_materiales"
  on puntos_reciclaje_materiales for select
  using (true);

create policy "usuarios autenticados asocian materiales"
  on puntos_reciclaje_materiales for insert
  with check (auth.uid() is not null);

-- Calcula puntos de reciclaje cercanos a una coordenada dentro de un radio.
-- No está restringida por comuna: comuna_filtro es un parámetro opcional de
-- filtrado (usado por la UI), no una limitación estructural de la función.
-- Los parámetros usan el prefijo p_ para no colisionar con las columnas
-- homónimas de puntos_reciclaje (lat/lng) dentro de la consulta.
create or replace function puntos_cercanos(
  p_lat double precision,
  p_lng double precision,
  radio_km double precision default 5,
  comuna_filtro text default null,
  materiales_filtro text[] default null,
  solo_disponibles boolean default false,
  calificacion_minima numeric default 0
)
returns table (
  id uuid,
  nombre text,
  direccion text,
  comuna text,
  lat double precision,
  lng double precision,
  fuente text,
  estado_actual text,
  calificacion_promedio numeric,
  num_calificaciones integer,
  materiales text[],
  distancia_km double precision
)
language sql
stable
as $$
  select
    p.id, p.nombre, p.direccion, p.comuna, p.lat, p.lng, p.fuente,
    p.estado_actual, p.calificacion_promedio, p.num_calificaciones,
    coalesce(array_agg(pm.material_codigo) filter (where pm.material_codigo is not null), '{}'),
    st_distance(p.geog, st_setsrid(st_makepoint(p_lng, p_lat), 4326)::geography) / 1000.0 as distancia_km
  from puntos_reciclaje p
  left join puntos_reciclaje_materiales pm on pm.punto_id = p.id
  where st_dwithin(p.geog, st_setsrid(st_makepoint(p_lng, p_lat), 4326)::geography, radio_km * 1000)
    and (comuna_filtro is null or p.comuna = comuna_filtro)
    and (not solo_disponibles or p.estado_actual = 'disponible')
    and p.calificacion_promedio >= calificacion_minima
    and (
      materiales_filtro is null
      or exists (
        select 1 from puntos_reciclaje_materiales pm2
        where pm2.punto_id = p.id and pm2.material_codigo = any (materiales_filtro)
      )
    )
  group by p.id
  order by distancia_km asc;
$$;

grant execute on function puntos_cercanos to anon, authenticated;
