-- Puntos de reciclaje importados desde OpenStreetMap (Overpass).
-- Generado por backend/scripts/importar_osm_geojson.js a partir de
-- backend/data/osm/rm_reciclaje_AAAA-MM-DD.geojson
-- No editar a mano: si cambian los datos de origen, correr el script de nuevo.
-- Fuente: © colaboradores de OpenStreetMap, datos bajo licencia ODbL.
-- Generado: 2026-09-24T13:13:19.011Z
--
-- Idempotente: cada punto se omite si ya existe otro a menos de 30m
-- (st_dwithin sobre geog) o si su osm_id ya fue importado antes.

begin;

insert into puntos_reciclaje (nombre, direccion, comuna, lat, lng, fuente, osm_id, tipo_punto, creado_por)
select 'Punto Limpio Parque de los Reyes Avenida Presidente Balmaceda', 'Avenida Presidente Balmaceda', 'Santiago', -33.428326, -70.668573, 'osm', 'way/544370772', 'punto_limpio', null
where not exists (
  select 1 from puntos_reciclaje p
  where st_dwithin(p.geog, st_setsrid(st_makepoint(-70.668573, -33.428326), 4326)::geography, 30)
)
on conflict (osm_id) do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'papel' from puntos_reciclaje where osm_id = 'way/544370772'
on conflict do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'plastico' from puntos_reciclaje where osm_id = 'way/544370772'
on conflict do nothing;

insert into puntos_reciclaje (nombre, direccion, comuna, lat, lng, fuente, osm_id, tipo_punto, creado_por)
select 'Punto de reciclaje', null, null, -33.310124, -70.322686, 'osm', 'node/611957126', null, null
where not exists (
  select 1 from puntos_reciclaje p
  where st_dwithin(p.geog, st_setsrid(st_makepoint(-70.322686, -33.310124), 4326)::geography, 30)
)
on conflict (osm_id) do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'vidrio' from puntos_reciclaje where osm_id = 'node/611957126'
on conflict do nothing;

insert into puntos_reciclaje (nombre, direccion, comuna, lat, lng, fuente, osm_id, tipo_punto, creado_por)
select 'Romerelli Tucapel', 'Tucapel 1695', 'La Pintana', -33.588426, -70.656612, 'osm', 'way/646368338', 'punto_limpio', null
where not exists (
  select 1 from puntos_reciclaje p
  where st_dwithin(p.geog, st_setsrid(st_makepoint(-70.656612, -33.588426), 4326)::geography, 30)
)
on conflict (osm_id) do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'latas' from puntos_reciclaje where osm_id = 'way/646368338'
on conflict do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'metal' from puntos_reciclaje where osm_id = 'way/646368338'
on conflict do nothing;

insert into puntos_reciclaje (nombre, direccion, comuna, lat, lng, fuente, osm_id, tipo_punto, creado_por)
select 'Contenedor de reciclaje', null, null, -33.275133, -70.703917, 'osm', 'way/732427993', 'contenedor', null
where not exists (
  select 1 from puntos_reciclaje p
  where st_dwithin(p.geog, st_setsrid(st_makepoint(-70.703917, -33.275133), 4326)::geography, 30)
)
on conflict (osm_id) do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'papel' from puntos_reciclaje where osm_id = 'way/732427993'
on conflict do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'plastico' from puntos_reciclaje where osm_id = 'way/732427993'
on conflict do nothing;

insert into puntos_reciclaje (nombre, direccion, comuna, lat, lng, fuente, osm_id, tipo_punto, creado_por)
select 'Centro Laboral Oreste Plath Avenida Lo Errázuriz', 'Avenida Lo Errázuriz 2701', 'Cerrillos', -33.483378, -70.724195, 'osm', 'way/764468589', 'punto_limpio', null
where not exists (
  select 1 from puntos_reciclaje p
  where st_dwithin(p.geog, st_setsrid(st_makepoint(-70.724195, -33.483378), 4326)::geography, 30)
)
on conflict (osm_id) do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'vidrio' from puntos_reciclaje where osm_id = 'way/764468589'
on conflict do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'papel' from puntos_reciclaje where osm_id = 'way/764468589'
on conflict do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'plastico' from puntos_reciclaje where osm_id = 'way/764468589'
on conflict do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'latas' from puntos_reciclaje where osm_id = 'way/764468589'
on conflict do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'metal' from puntos_reciclaje where osm_id = 'way/764468589'
on conflict do nothing;

insert into puntos_reciclaje (nombre, direccion, comuna, lat, lng, fuente, osm_id, tipo_punto, creado_por)
select 'Punto Limpio Colegio Colonial de Pirque Avenida Concha y Toro s/n', 'Avenida Concha y Toro s/n', 'Pirque', -33.630457, -70.572266, 'osm', 'way/915903043', 'punto_limpio', null
where not exists (
  select 1 from puntos_reciclaje p
  where st_dwithin(p.geog, st_setsrid(st_makepoint(-70.572266, -33.630457), 4326)::geography, 30)
)
on conflict (osm_id) do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'vidrio' from puntos_reciclaje where osm_id = 'way/915903043'
on conflict do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'papel' from puntos_reciclaje where osm_id = 'way/915903043'
on conflict do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'plastico' from puntos_reciclaje where osm_id = 'way/915903043'
on conflict do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'latas' from puntos_reciclaje where osm_id = 'way/915903043'
on conflict do nothing;

insert into puntos_reciclaje (nombre, direccion, comuna, lat, lng, fuente, osm_id, tipo_punto, creado_por)
select 'Reciclaje Plaza Santa Ana', null, null, -33.438229, -70.658893, 'osm', 'node/927292092', null, null
where not exists (
  select 1 from puntos_reciclaje p
  where st_dwithin(p.geog, st_setsrid(st_makepoint(-70.658893, -33.438229), 4326)::geography, 30)
)
on conflict (osm_id) do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'vidrio' from puntos_reciclaje where osm_id = 'node/927292092'
on conflict do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'papel' from puntos_reciclaje where osm_id = 'node/927292092'
on conflict do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'latas' from puntos_reciclaje where osm_id = 'node/927292092'
on conflict do nothing;

insert into puntos_reciclaje (nombre, direccion, comuna, lat, lng, fuente, osm_id, tipo_punto, creado_por)
select 'Punto de reciclaje', null, null, -33.454284, -70.600343, 'osm', 'node/977464975', null, null
where not exists (
  select 1 from puntos_reciclaje p
  where st_dwithin(p.geog, st_setsrid(st_makepoint(-70.600343, -33.454284), 4326)::geography, 30)
)
on conflict (osm_id) do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'vidrio' from puntos_reciclaje where osm_id = 'node/977464975'
on conflict do nothing;

insert into puntos_reciclaje (nombre, direccion, comuna, lat, lng, fuente, osm_id, tipo_punto, creado_por)
select 'Punto Limpio Santiago Recicla Costaneras Férreas', 'Costaneras Férreas 0495', 'Quilicura', -33.35479, -70.714138, 'osm', 'way/992262400', 'punto_limpio', null
where not exists (
  select 1 from puntos_reciclaje p
  where st_dwithin(p.geog, st_setsrid(st_makepoint(-70.714138, -33.35479), 4326)::geography, 30)
)
on conflict (osm_id) do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'vidrio' from puntos_reciclaje where osm_id = 'way/992262400'
on conflict do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'tetra_pak' from puntos_reciclaje where osm_id = 'way/992262400'
on conflict do nothing;

insert into puntos_reciclaje (nombre, direccion, comuna, lat, lng, fuente, osm_id, tipo_punto, creado_por)
select 'Punto Limpio de Reciclaje - El Mañío', null, null, -33.370688, -70.741999, 'osm', 'way/1193836390', 'punto_limpio', null
where not exists (
  select 1 from puntos_reciclaje p
  where st_dwithin(p.geog, st_setsrid(st_makepoint(-70.741999, -33.370688), 4326)::geography, 30)
)
on conflict (osm_id) do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'papel' from puntos_reciclaje where osm_id = 'way/1193836390'
on conflict do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'plastico' from puntos_reciclaje where osm_id = 'way/1193836390'
on conflict do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'latas' from puntos_reciclaje where osm_id = 'way/1193836390'
on conflict do nothing;

insert into puntos_reciclaje (nombre, direccion, comuna, lat, lng, fuente, osm_id, tipo_punto, creado_por)
select 'Punto de reciclaje', null, null, -33.354536, -70.754707, 'osm', 'way/1277605850', null, null
where not exists (
  select 1 from puntos_reciclaje p
  where st_dwithin(p.geog, st_setsrid(st_makepoint(-70.754707, -33.354536), 4326)::geography, 30)
)
on conflict (osm_id) do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'papel' from puntos_reciclaje where osm_id = 'way/1277605850'
on conflict do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'plastico' from puntos_reciclaje where osm_id = 'way/1277605850'
on conflict do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'latas' from puntos_reciclaje where osm_id = 'way/1277605850'
on conflict do nothing;

insert into puntos_reciclaje (nombre, direccion, comuna, lat, lng, fuente, osm_id, tipo_punto, creado_por)
select 'Punto Limpio Juan Antonio Ríos Avenida Presidente Eduardo Frei Montalva', 'Avenida Presidente Eduardo Frei Montalva', 'Independencia', -33.423143, -70.672878, 'osm', 'way/1330785467', 'punto_limpio', null
where not exists (
  select 1 from puntos_reciclaje p
  where st_dwithin(p.geog, st_setsrid(st_makepoint(-70.672878, -33.423143), 4326)::geography, 30)
)
on conflict (osm_id) do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'vidrio' from puntos_reciclaje where osm_id = 'way/1330785467'
on conflict do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'papel' from puntos_reciclaje where osm_id = 'way/1330785467'
on conflict do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'plastico' from puntos_reciclaje where osm_id = 'way/1330785467'
on conflict do nothing;

insert into puntos_reciclaje (nombre, direccion, comuna, lat, lng, fuente, osm_id, tipo_punto, creado_por)
select 'Contenedor de reciclaje', null, null, -33.420861, -70.614635, 'osm', 'node/1909931037', 'contenedor', null
where not exists (
  select 1 from puntos_reciclaje p
  where st_dwithin(p.geog, st_setsrid(st_makepoint(-70.614635, -33.420861), 4326)::geography, 30)
)
on conflict (osm_id) do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'vidrio' from puntos_reciclaje where osm_id = 'node/1909931037'
on conflict do nothing;

insert into puntos_reciclaje (nombre, direccion, comuna, lat, lng, fuente, osm_id, tipo_punto, creado_por)
select 'Cooperativa de reciclaje La Reina Jorge Alessandri', 'Jorge Alessandri 680', 'Santiago', -33.457542, -70.545817, 'osm', 'node/2287552493', 'punto_limpio', null
where not exists (
  select 1 from puntos_reciclaje p
  where st_dwithin(p.geog, st_setsrid(st_makepoint(-70.545817, -33.457542), 4326)::geography, 30)
)
on conflict (osm_id) do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'papel' from puntos_reciclaje where osm_id = 'node/2287552493'
on conflict do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'latas' from puntos_reciclaje where osm_id = 'node/2287552493'
on conflict do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'metal' from puntos_reciclaje where osm_id = 'node/2287552493'
on conflict do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'pilas' from puntos_reciclaje where osm_id = 'node/2287552493'
on conflict do nothing;

insert into puntos_reciclaje (nombre, direccion, comuna, lat, lng, fuente, osm_id, tipo_punto, creado_por)
select 'Punto de reciclaje', null, null, -33.442316, -70.578688, 'osm', 'node/2801428141', null, null
where not exists (
  select 1 from puntos_reciclaje p
  where st_dwithin(p.geog, st_setsrid(st_makepoint(-70.578688, -33.442316), 4326)::geography, 30)
)
on conflict (osm_id) do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'vidrio' from puntos_reciclaje where osm_id = 'node/2801428141'
on conflict do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'papel' from puntos_reciclaje where osm_id = 'node/2801428141'
on conflict do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'latas' from puntos_reciclaje where osm_id = 'node/2801428141'
on conflict do nothing;

insert into puntos_reciclaje (nombre, direccion, comuna, lat, lng, fuente, osm_id, tipo_punto, creado_por)
select 'Contenedor de reciclaje', null, null, -33.376911, -70.570229, 'osm', 'node/3102557500', 'contenedor', null
where not exists (
  select 1 from puntos_reciclaje p
  where st_dwithin(p.geog, st_setsrid(st_makepoint(-70.570229, -33.376911), 4326)::geography, 30)
)
on conflict (osm_id) do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'vidrio' from puntos_reciclaje where osm_id = 'node/3102557500'
on conflict do nothing;

insert into puntos_reciclaje (nombre, direccion, comuna, lat, lng, fuente, osm_id, tipo_punto, creado_por)
select 'Esquina El Solar Avenida Consistorial', 'Avenida Consistorial', 'Peñalolén', -33.487197, -70.549171, 'osm', 'node/3200714438', null, null
where not exists (
  select 1 from puntos_reciclaje p
  where st_dwithin(p.geog, st_setsrid(st_makepoint(-70.549171, -33.487197), 4326)::geography, 30)
)
on conflict (osm_id) do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'vidrio' from puntos_reciclaje where osm_id = 'node/3200714438'
on conflict do nothing;

insert into puntos_reciclaje (nombre, direccion, comuna, lat, lng, fuente, osm_id, tipo_punto, creado_por)
select 'Recinto Municipal Grecia', 'Grecia', 'Peñalolén', -33.476995, -70.5417, 'osm', 'node/3200714439', null, null
where not exists (
  select 1 from puntos_reciclaje p
  where st_dwithin(p.geog, st_setsrid(st_makepoint(-70.5417, -33.476995), 4326)::geography, 30)
)
on conflict (osm_id) do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'vidrio' from puntos_reciclaje where osm_id = 'node/3200714439'
on conflict do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'papel' from puntos_reciclaje where osm_id = 'node/3200714439'
on conflict do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'plastico' from puntos_reciclaje where osm_id = 'node/3200714439'
on conflict do nothing;

insert into puntos_reciclaje (nombre, direccion, comuna, lat, lng, fuente, osm_id, tipo_punto, creado_por)
select 'Punto de reciclaje Avenida Lincoln', 'Avenida Lincoln 1410', 'Lo Espejo', -33.514999, -70.673557, 'osm', 'node/3200714440', null, null
where not exists (
  select 1 from puntos_reciclaje p
  where st_dwithin(p.geog, st_setsrid(st_makepoint(-70.673557, -33.514999), 4326)::geography, 30)
)
on conflict (osm_id) do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'vidrio' from puntos_reciclaje where osm_id = 'node/3200714440'
on conflict do nothing;

insert into puntos_reciclaje (nombre, direccion, comuna, lat, lng, fuente, osm_id, tipo_punto, creado_por)
select 'Punto de reciclaje Avenida Adolfo Lopez Mateo', 'Avenida Adolfo Lopez Mateo 1595', 'Lo Espejo', -33.522578, -70.679217, 'osm', 'node/3200714441', null, null
where not exists (
  select 1 from puntos_reciclaje p
  where st_dwithin(p.geog, st_setsrid(st_makepoint(-70.679217, -33.522578), 4326)::geography, 30)
)
on conflict (osm_id) do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'vidrio' from puntos_reciclaje where osm_id = 'node/3200714441'
on conflict do nothing;

insert into puntos_reciclaje (nombre, direccion, comuna, lat, lng, fuente, osm_id, tipo_punto, creado_por)
select 'Punto de reciclaje Avenida Lo Ovalle', 'Avenida Lo Ovalle 2356', 'Lo Espejo', -33.508494, -70.677383, 'osm', 'node/3200714442', null, null
where not exists (
  select 1 from puntos_reciclaje p
  where st_dwithin(p.geog, st_setsrid(st_makepoint(-70.677383, -33.508494), 4326)::geography, 30)
)
on conflict (osm_id) do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'vidrio' from puntos_reciclaje where osm_id = 'node/3200714442'
on conflict do nothing;

insert into puntos_reciclaje (nombre, direccion, comuna, lat, lng, fuente, osm_id, tipo_punto, creado_por)
select 'Centro Integral de Reducción de Residuos Sólidos Punta Arenas', 'Punta Arenas 6711', 'La Granja', -33.518451, -70.611548, 'osm', 'node/3200714443', 'punto_limpio', null
where not exists (
  select 1 from puntos_reciclaje p
  where st_dwithin(p.geog, st_setsrid(st_makepoint(-70.611548, -33.518451), 4326)::geography, 30)
)
on conflict (osm_id) do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'vidrio' from puntos_reciclaje where osm_id = 'node/3200714443'
on conflict do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'papel' from puntos_reciclaje where osm_id = 'node/3200714443'
on conflict do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'plastico' from puntos_reciclaje where osm_id = 'node/3200714443'
on conflict do nothing;

insert into puntos_reciclaje (nombre, direccion, comuna, lat, lng, fuente, osm_id, tipo_punto, creado_por)
select 'Punto de reciclaje Avenida Valparaíso', 'Avenida Valparaíso 7171', 'Lo Espejo', -33.516589, -70.678453, 'osm', 'node/3200714444', null, null
where not exists (
  select 1 from puntos_reciclaje p
  where st_dwithin(p.geog, st_setsrid(st_makepoint(-70.678453, -33.516589), 4326)::geography, 30)
)
on conflict (osm_id) do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'vidrio' from puntos_reciclaje where osm_id = 'node/3200714444'
on conflict do nothing;

insert into puntos_reciclaje (nombre, direccion, comuna, lat, lng, fuente, osm_id, tipo_punto, creado_por)
select 'Punto de reciclaje Avenida Central', 'Avenida Central 8321', 'Lo Espejo', -33.522808, -70.698378, 'osm', 'node/3200714445', null, null
where not exists (
  select 1 from puntos_reciclaje p
  where st_dwithin(p.geog, st_setsrid(st_makepoint(-70.698378, -33.522808), 4326)::geography, 30)
)
on conflict (osm_id) do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'plastico' from puntos_reciclaje where osm_id = 'node/3200714445'
on conflict do nothing;

insert into puntos_reciclaje (nombre, direccion, comuna, lat, lng, fuente, osm_id, tipo_punto, creado_por)
select 'Plaza Cuauhtémoc', null, null, -33.395975, -70.56762, 'osm', 'node/3200714446', 'contenedor', null
where not exists (
  select 1 from puntos_reciclaje p
  where st_dwithin(p.geog, st_setsrid(st_makepoint(-70.56762, -33.395975), 4326)::geography, 30)
)
on conflict (osm_id) do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'vidrio' from puntos_reciclaje where osm_id = 'node/3200714446'
on conflict do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'papel' from puntos_reciclaje where osm_id = 'node/3200714446'
on conflict do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'plastico' from puntos_reciclaje where osm_id = 'node/3200714446'
on conflict do nothing;

insert into puntos_reciclaje (nombre, direccion, comuna, lat, lng, fuente, osm_id, tipo_punto, creado_por)
select 'Punto Limpio Club de Campo Entel', null, 'Peñalolén', -33.499687, -70.574316, 'osm', 'node/3200714447', null, null
where not exists (
  select 1 from puntos_reciclaje p
  where st_dwithin(p.geog, st_setsrid(st_makepoint(-70.574316, -33.499687), 4326)::geography, 30)
)
on conflict (osm_id) do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'vidrio' from puntos_reciclaje where osm_id = 'node/3200714447'
on conflict do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'papel' from puntos_reciclaje where osm_id = 'node/3200714447'
on conflict do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'plastico' from puntos_reciclaje where osm_id = 'node/3200714447'
on conflict do nothing;

insert into puntos_reciclaje (nombre, direccion, comuna, lat, lng, fuente, osm_id, tipo_punto, creado_por)
select 'Punto Limpio Colegio Pedro de Valdivia', null, 'Peñalolén', -33.491866, -70.576312, 'osm', 'node/3200714448', null, null
where not exists (
  select 1 from puntos_reciclaje p
  where st_dwithin(p.geog, st_setsrid(st_makepoint(-70.576312, -33.491866), 4326)::geography, 30)
)
on conflict (osm_id) do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'vidrio' from puntos_reciclaje where osm_id = 'node/3200714448'
on conflict do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'papel' from puntos_reciclaje where osm_id = 'node/3200714448'
on conflict do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'plastico' from puntos_reciclaje where osm_id = 'node/3200714448'
on conflict do nothing;

insert into puntos_reciclaje (nombre, direccion, comuna, lat, lng, fuente, osm_id, tipo_punto, creado_por)
select 'Punto Limpio Colina Centro', null, null, -33.207983, -70.675617, 'osm', 'node/3200714449', null, null
where not exists (
  select 1 from puntos_reciclaje p
  where st_dwithin(p.geog, st_setsrid(st_makepoint(-70.675617, -33.207983), 4326)::geography, 30)
)
on conflict (osm_id) do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'vidrio' from puntos_reciclaje where osm_id = 'node/3200714449'
on conflict do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'papel' from puntos_reciclaje where osm_id = 'node/3200714449'
on conflict do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'plastico' from puntos_reciclaje where osm_id = 'node/3200714449'
on conflict do nothing;

insert into puntos_reciclaje (nombre, direccion, comuna, lat, lng, fuente, osm_id, tipo_punto, creado_por)
select 'Punto Limpio Piedra Roja Avenida Paseo Colina Sur', 'Avenida Paseo Colina Sur 14500', 'Colina', -33.276871, -70.62662, 'osm', 'node/3200714450', 'contenedor', null
where not exists (
  select 1 from puntos_reciclaje p
  where st_dwithin(p.geog, st_setsrid(st_makepoint(-70.62662, -33.276871), 4326)::geography, 30)
)
on conflict (osm_id) do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'vidrio' from puntos_reciclaje where osm_id = 'node/3200714450'
on conflict do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'papel' from puntos_reciclaje where osm_id = 'node/3200714450'
on conflict do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'plastico' from puntos_reciclaje where osm_id = 'node/3200714450'
on conflict do nothing;

insert into puntos_reciclaje (nombre, direccion, comuna, lat, lng, fuente, osm_id, tipo_punto, creado_por)
select 'Punto Limpio Walmart Quilin', null, 'Peñalolén', -33.486146, -70.579027, 'osm', 'node/3200714451', null, null
where not exists (
  select 1 from puntos_reciclaje p
  where st_dwithin(p.geog, st_setsrid(st_makepoint(-70.579027, -33.486146), 4326)::geography, 30)
)
on conflict (osm_id) do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'vidrio' from puntos_reciclaje where osm_id = 'node/3200714451'
on conflict do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'papel' from puntos_reciclaje where osm_id = 'node/3200714451'
on conflict do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'plastico' from puntos_reciclaje where osm_id = 'node/3200714451'
on conflict do nothing;

insert into puntos_reciclaje (nombre, direccion, comuna, lat, lng, fuente, osm_id, tipo_punto, creado_por)
select 'Punto de reciclaje', null, 'Peñalolén', -33.498181, -70.560755, 'osm', 'node/3200714456', null, null
where not exists (
  select 1 from puntos_reciclaje p
  where st_dwithin(p.geog, st_setsrid(st_makepoint(-70.560755, -33.498181), 4326)::geography, 30)
)
on conflict (osm_id) do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'vidrio' from puntos_reciclaje where osm_id = 'node/3200714456'
on conflict do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'papel' from puntos_reciclaje where osm_id = 'node/3200714456'
on conflict do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'plastico' from puntos_reciclaje where osm_id = 'node/3200714456'
on conflict do nothing;

insert into puntos_reciclaje (nombre, direccion, comuna, lat, lng, fuente, osm_id, tipo_punto, creado_por)
select 'Contenedor de reciclaje Los Presidentes', 'Los Presidentes', 'Peñalolén', -33.486771, -70.557037, 'osm', 'node/3200714457', 'contenedor', null
where not exists (
  select 1 from puntos_reciclaje p
  where st_dwithin(p.geog, st_setsrid(st_makepoint(-70.557037, -33.486771), 4326)::geography, 30)
)
on conflict (osm_id) do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'vidrio' from puntos_reciclaje where osm_id = 'node/3200714457'
on conflict do nothing;

insert into puntos_reciclaje (nombre, direccion, comuna, lat, lng, fuente, osm_id, tipo_punto, creado_por)
select 'Punto de reciclaje Avenida Santa María', 'Avenida Santa María', 'Vitacura', -33.377749, -70.572155, 'osm', 'node/3200714458', null, null
where not exists (
  select 1 from puntos_reciclaje p
  where st_dwithin(p.geog, st_setsrid(st_makepoint(-70.572155, -33.377749), 4326)::geography, 30)
)
on conflict (osm_id) do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'vidrio' from puntos_reciclaje where osm_id = 'node/3200714458'
on conflict do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'papel' from puntos_reciclaje where osm_id = 'node/3200714458'
on conflict do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'plastico' from puntos_reciclaje where osm_id = 'node/3200714458'
on conflict do nothing;

insert into puntos_reciclaje (nombre, direccion, comuna, lat, lng, fuente, osm_id, tipo_punto, creado_por)
select 'Contenedor de reciclaje Costanera Sur San Josemaría Escrivá de Balaguer', 'Costanera Sur San Josemaría Escrivá de Balaguer', 'Vitacura', -33.379406, -70.572168, 'osm', 'node/3200714459', 'contenedor', null
where not exists (
  select 1 from puntos_reciclaje p
  where st_dwithin(p.geog, st_setsrid(st_makepoint(-70.572168, -33.379406), 4326)::geography, 30)
)
on conflict (osm_id) do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'vidrio' from puntos_reciclaje where osm_id = 'node/3200714459'
on conflict do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'papel' from puntos_reciclaje where osm_id = 'node/3200714459'
on conflict do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'plastico' from puntos_reciclaje where osm_id = 'node/3200714459'
on conflict do nothing;

insert into puntos_reciclaje (nombre, direccion, comuna, lat, lng, fuente, osm_id, tipo_punto, creado_por)
select 'Punto de reciclaje', null, null, -33.386882, -70.600808, 'osm', 'node/3200714460', null, null
where not exists (
  select 1 from puntos_reciclaje p
  where st_dwithin(p.geog, st_setsrid(st_makepoint(-70.600808, -33.386882), 4326)::geography, 30)
)
on conflict (osm_id) do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'vidrio' from puntos_reciclaje where osm_id = 'node/3200714460'
on conflict do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'papel' from puntos_reciclaje where osm_id = 'node/3200714460'
on conflict do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'plastico' from puntos_reciclaje where osm_id = 'node/3200714460'
on conflict do nothing;

insert into puntos_reciclaje (nombre, direccion, comuna, lat, lng, fuente, osm_id, tipo_punto, creado_por)
select 'Punto de reciclaje Talinay', 'Talinay', 'Peñalolén', -33.459023, -70.531819, 'osm', 'node/3200715961', null, null
where not exists (
  select 1 from puntos_reciclaje p
  where st_dwithin(p.geog, st_setsrid(st_makepoint(-70.531819, -33.459023), 4326)::geography, 30)
)
on conflict (osm_id) do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'vidrio' from puntos_reciclaje where osm_id = 'node/3200715961'
on conflict do nothing;

insert into puntos_reciclaje (nombre, direccion, comuna, lat, lng, fuente, osm_id, tipo_punto, creado_por)
select 'Punto de reciclaje Orientales', 'Orientales', 'Peñalolén', -33.466962, -70.558662, 'osm', 'node/3200715962', null, null
where not exists (
  select 1 from puntos_reciclaje p
  where st_dwithin(p.geog, st_setsrid(st_makepoint(-70.558662, -33.466962), 4326)::geography, 30)
)
on conflict (osm_id) do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'vidrio' from puntos_reciclaje where osm_id = 'node/3200715962'
on conflict do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'papel' from puntos_reciclaje where osm_id = 'node/3200715962'
on conflict do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'plastico' from puntos_reciclaje where osm_id = 'node/3200715962'
on conflict do nothing;

insert into puntos_reciclaje (nombre, direccion, comuna, lat, lng, fuente, osm_id, tipo_punto, creado_por)
select 'Punto de reciclaje Orientales', 'Orientales', 'Peñalolén', -33.469182, -70.553083, 'osm', 'node/3200715963', null, null
where not exists (
  select 1 from puntos_reciclaje p
  where st_dwithin(p.geog, st_setsrid(st_makepoint(-70.553083, -33.469182), 4326)::geography, 30)
)
on conflict (osm_id) do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'vidrio' from puntos_reciclaje where osm_id = 'node/3200715963'
on conflict do nothing;

insert into puntos_reciclaje (nombre, direccion, comuna, lat, lng, fuente, osm_id, tipo_punto, creado_por)
select 'Punto de reciclaje Grecia', 'Grecia', 'Peñalolén', -33.469683, -70.575142, 'osm', 'node/3200715964', null, null
where not exists (
  select 1 from puntos_reciclaje p
  where st_dwithin(p.geog, st_setsrid(st_makepoint(-70.575142, -33.469683), 4326)::geography, 30)
)
on conflict (osm_id) do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'vidrio' from puntos_reciclaje where osm_id = 'node/3200715964'
on conflict do nothing;

insert into puntos_reciclaje (nombre, direccion, comuna, lat, lng, fuente, osm_id, tipo_punto, creado_por)
select 'Punto de reciclaje Grecia', 'Grecia', 'Peñalolén', -33.47022, -70.57158, 'osm', 'node/3200715965', null, null
where not exists (
  select 1 from puntos_reciclaje p
  where st_dwithin(p.geog, st_setsrid(st_makepoint(-70.57158, -33.47022), 4326)::geography, 30)
)
on conflict (osm_id) do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'vidrio' from puntos_reciclaje where osm_id = 'node/3200715965'
on conflict do nothing;

insert into puntos_reciclaje (nombre, direccion, comuna, lat, lng, fuente, osm_id, tipo_punto, creado_por)
select 'Punto de reciclaje Avenida Grecia', 'Avenida Grecia', 'Peñalolén', -33.47599, -70.54393, 'osm', 'node/3200715966', null, null
where not exists (
  select 1 from puntos_reciclaje p
  where st_dwithin(p.geog, st_setsrid(st_makepoint(-70.54393, -33.47599), 4326)::geography, 30)
)
on conflict (osm_id) do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'vidrio' from puntos_reciclaje where osm_id = 'node/3200715966'
on conflict do nothing;

insert into puntos_reciclaje (nombre, direccion, comuna, lat, lng, fuente, osm_id, tipo_punto, creado_por)
select 'Punto de reciclaje El Duraznal', 'El Duraznal', 'Peñalolén', -33.47793, -70.565864, 'osm', 'node/3200715967', null, null
where not exists (
  select 1 from puntos_reciclaje p
  where st_dwithin(p.geog, st_setsrid(st_makepoint(-70.565864, -33.47793), 4326)::geography, 30)
)
on conflict (osm_id) do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'vidrio' from puntos_reciclaje where osm_id = 'node/3200715967'
on conflict do nothing;

insert into puntos_reciclaje (nombre, direccion, comuna, lat, lng, fuente, osm_id, tipo_punto, creado_por)
select 'Punto de reciclaje Tobalaba', 'Tobalaba', 'Peñalolén', -33.48173, -70.558113, 'osm', 'node/3200715968', null, null
where not exists (
  select 1 from puntos_reciclaje p
  where st_dwithin(p.geog, st_setsrid(st_makepoint(-70.558113, -33.48173), 4326)::geography, 30)
)
on conflict (osm_id) do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'vidrio' from puntos_reciclaje where osm_id = 'node/3200715968'
on conflict do nothing;

insert into puntos_reciclaje (nombre, direccion, comuna, lat, lng, fuente, osm_id, tipo_punto, creado_por)
select 'Contenedor de reciclaje Antupiren', 'Antupiren', 'Peñalolén', -33.483321, -70.534546, 'osm', 'node/3200715970', 'contenedor', null
where not exists (
  select 1 from puntos_reciclaje p
  where st_dwithin(p.geog, st_setsrid(st_makepoint(-70.534546, -33.483321), 4326)::geography, 30)
)
on conflict (osm_id) do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'vidrio' from puntos_reciclaje where osm_id = 'node/3200715970'
on conflict do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'papel' from puntos_reciclaje where osm_id = 'node/3200715970'
on conflict do nothing;

insert into puntos_reciclaje (nombre, direccion, comuna, lat, lng, fuente, osm_id, tipo_punto, creado_por)
select 'Punto de reciclaje Avenida Tobalaba', 'Avenida Tobalaba 13949', 'Peñalolén', -33.503556, -70.561241, 'osm', 'node/3200715971', null, null
where not exists (
  select 1 from puntos_reciclaje p
  where st_dwithin(p.geog, st_setsrid(st_makepoint(-70.561241, -33.503556), 4326)::geography, 30)
)
on conflict (osm_id) do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'vidrio' from puntos_reciclaje where osm_id = 'node/3200715971'
on conflict do nothing;

insert into puntos_reciclaje (nombre, direccion, comuna, lat, lng, fuente, osm_id, tipo_punto, creado_por)
select 'Punto de reciclaje Avenida San Luis de Macul', 'Avenida San Luis de Macul', 'Peñalolén', -33.506188, -70.578568, 'osm', 'node/3200715973', null, null
where not exists (
  select 1 from puntos_reciclaje p
  where st_dwithin(p.geog, st_setsrid(st_makepoint(-70.578568, -33.506188), 4326)::geography, 30)
)
on conflict (osm_id) do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'vidrio' from puntos_reciclaje where osm_id = 'node/3200715973'
on conflict do nothing;

insert into puntos_reciclaje (nombre, direccion, comuna, lat, lng, fuente, osm_id, tipo_punto, creado_por)
select 'Punto de reciclaje Avenida San Luis de Macul', 'Avenida San Luis de Macul', 'Peñalolén', -33.506175, -70.578673, 'osm', 'node/3200715974', null, null
where not exists (
  select 1 from puntos_reciclaje p
  where st_dwithin(p.geog, st_setsrid(st_makepoint(-70.578673, -33.506175), 4326)::geography, 30)
)
on conflict (osm_id) do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'vidrio' from puntos_reciclaje where osm_id = 'node/3200715974'
on conflict do nothing;

insert into puntos_reciclaje (nombre, direccion, comuna, lat, lng, fuente, osm_id, tipo_punto, creado_por)
select 'Punto de reciclaje Avenida José Joaquin Prieto', 'Avenida José Joaquin Prieto', 'Lo Espejo', -33.509985, -70.671338, 'osm', 'node/3200715976', null, null
where not exists (
  select 1 from puntos_reciclaje p
  where st_dwithin(p.geog, st_setsrid(st_makepoint(-70.671338, -33.509985), 4326)::geography, 30)
)
on conflict (osm_id) do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'vidrio' from puntos_reciclaje where osm_id = 'node/3200715976'
on conflict do nothing;

insert into puntos_reciclaje (nombre, direccion, comuna, lat, lng, fuente, osm_id, tipo_punto, creado_por)
select 'Punto de Reciclaje Avenida La Marina', 'Avenida La Marina 2500', 'Pedro Aguirre Cerda', -33.492552, -70.67047, 'osm', 'node/3676456357', null, null
where not exists (
  select 1 from puntos_reciclaje p
  where st_dwithin(p.geog, st_setsrid(st_makepoint(-70.67047, -33.492552), 4326)::geography, 30)
)
on conflict (osm_id) do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'vidrio' from puntos_reciclaje where osm_id = 'node/3676456357'
on conflict do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'papel' from puntos_reciclaje where osm_id = 'node/3676456357'
on conflict do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'plastico' from puntos_reciclaje where osm_id = 'node/3676456357'
on conflict do nothing;

insert into puntos_reciclaje (nombre, direccion, comuna, lat, lng, fuente, osm_id, tipo_punto, creado_por)
select 'Punto de Reciclaje centroamérica', 'centroamérica', null, -33.493914, -70.684069, 'osm', 'node/3676456359', null, null
where not exists (
  select 1 from puntos_reciclaje p
  where st_dwithin(p.geog, st_setsrid(st_makepoint(-70.684069, -33.493914), 4326)::geography, 30)
)
on conflict (osm_id) do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'vidrio' from puntos_reciclaje where osm_id = 'node/3676456359'
on conflict do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'papel' from puntos_reciclaje where osm_id = 'node/3676456359'
on conflict do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'latas' from puntos_reciclaje where osm_id = 'node/3676456359'
on conflict do nothing;

insert into puntos_reciclaje (nombre, direccion, comuna, lat, lng, fuente, osm_id, tipo_punto, creado_por)
select 'Punto de Reciclaje', null, null, -33.485528, -70.672124, 'osm', 'node/4981116088', null, null
where not exists (
  select 1 from puntos_reciclaje p
  where st_dwithin(p.geog, st_setsrid(st_makepoint(-70.672124, -33.485528), 4326)::geography, 30)
)
on conflict (osm_id) do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'vidrio' from puntos_reciclaje where osm_id = 'node/4981116088'
on conflict do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'papel' from puntos_reciclaje where osm_id = 'node/4981116088'
on conflict do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'plastico' from puntos_reciclaje where osm_id = 'node/4981116088'
on conflict do nothing;

insert into puntos_reciclaje (nombre, direccion, comuna, lat, lng, fuente, osm_id, tipo_punto, creado_por)
select 'Punto Limpio', null, null, -33.466197, -70.54638, 'osm', 'node/5132060023', null, null
where not exists (
  select 1 from puntos_reciclaje p
  where st_dwithin(p.geog, st_setsrid(st_makepoint(-70.54638, -33.466197), 4326)::geography, 30)
)
on conflict (osm_id) do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'vidrio' from puntos_reciclaje where osm_id = 'node/5132060023'
on conflict do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'papel' from puntos_reciclaje where osm_id = 'node/5132060023'
on conflict do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'plastico' from puntos_reciclaje where osm_id = 'node/5132060023'
on conflict do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'latas' from puntos_reciclaje where osm_id = 'node/5132060023'
on conflict do nothing;

insert into puntos_reciclaje (nombre, direccion, comuna, lat, lng, fuente, osm_id, tipo_punto, creado_por)
select 'Punto Limpio Loreto Loreto', 'Loreto', 'Recoleta', -33.433915, -70.642377, 'osm', 'node/5446265032', 'contenedor', null
where not exists (
  select 1 from puntos_reciclaje p
  where st_dwithin(p.geog, st_setsrid(st_makepoint(-70.642377, -33.433915), 4326)::geography, 30)
)
on conflict (osm_id) do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'vidrio' from puntos_reciclaje where osm_id = 'node/5446265032'
on conflict do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'papel' from puntos_reciclaje where osm_id = 'node/5446265032'
on conflict do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'plastico' from puntos_reciclaje where osm_id = 'node/5446265032'
on conflict do nothing;

insert into puntos_reciclaje (nombre, direccion, comuna, lat, lng, fuente, osm_id, tipo_punto, creado_por)
select 'Reciclaje vidrios', null, null, -33.516108, -71.118645, 'osm', 'node/5499521980', 'contenedor', null
where not exists (
  select 1 from puntos_reciclaje p
  where st_dwithin(p.geog, st_setsrid(st_makepoint(-71.118645, -33.516108), 4326)::geography, 30)
)
on conflict (osm_id) do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'vidrio' from puntos_reciclaje where osm_id = 'node/5499521980'
on conflict do nothing;

insert into puntos_reciclaje (nombre, direccion, comuna, lat, lng, fuente, osm_id, tipo_punto, creado_por)
select 'Punto Limpio UNAB', null, null, -33.453763, -70.667023, 'osm', 'node/5523236716', 'contenedor', null
where not exists (
  select 1 from puntos_reciclaje p
  where st_dwithin(p.geog, st_setsrid(st_makepoint(-70.667023, -33.453763), 4326)::geography, 30)
)
on conflict (osm_id) do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'vidrio' from puntos_reciclaje where osm_id = 'node/5523236716'
on conflict do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'papel' from puntos_reciclaje where osm_id = 'node/5523236716'
on conflict do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'plastico' from puntos_reciclaje where osm_id = 'node/5523236716'
on conflict do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'latas' from puntos_reciclaje where osm_id = 'node/5523236716'
on conflict do nothing;

insert into puntos_reciclaje (nombre, direccion, comuna, lat, lng, fuente, osm_id, tipo_punto, creado_por)
select 'Contenedor de reciclaje', null, null, -33.72859, -70.317404, 'osm', 'node/5528165703', 'contenedor', null
where not exists (
  select 1 from puntos_reciclaje p
  where st_dwithin(p.geog, st_setsrid(st_makepoint(-70.317404, -33.72859), 4326)::geography, 30)
)
on conflict (osm_id) do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'vidrio' from puntos_reciclaje where osm_id = 'node/5528165703'
on conflict do nothing;

insert into puntos_reciclaje (nombre, direccion, comuna, lat, lng, fuente, osm_id, tipo_punto, creado_por)
select 'Contenedor de reciclaje', null, null, -33.481198, -70.579983, 'osm', 'node/5544242466', 'contenedor', null
where not exists (
  select 1 from puntos_reciclaje p
  where st_dwithin(p.geog, st_setsrid(st_makepoint(-70.579983, -33.481198), 4326)::geography, 30)
)
on conflict (osm_id) do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'vidrio' from puntos_reciclaje where osm_id = 'node/5544242466'
on conflict do nothing;

insert into puntos_reciclaje (nombre, direccion, comuna, lat, lng, fuente, osm_id, tipo_punto, creado_por)
select 'Contenedor de reciclaje', null, null, -33.448225, -70.617002, 'osm', 'node/5802428493', 'contenedor', null
where not exists (
  select 1 from puntos_reciclaje p
  where st_dwithin(p.geog, st_setsrid(st_makepoint(-70.617002, -33.448225), 4326)::geography, 30)
)
on conflict (osm_id) do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'vidrio' from puntos_reciclaje where osm_id = 'node/5802428493'
on conflict do nothing;

insert into puntos_reciclaje (nombre, direccion, comuna, lat, lng, fuente, osm_id, tipo_punto, creado_por)
select 'Punto de Reciclaje Avenida La Marina', 'Avenida La Marina 2500', null, -33.496434, -70.667532, 'osm', 'node/5880053275', null, null
where not exists (
  select 1 from puntos_reciclaje p
  where st_dwithin(p.geog, st_setsrid(st_makepoint(-70.667532, -33.496434), 4326)::geography, 30)
)
on conflict (osm_id) do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'vidrio' from puntos_reciclaje where osm_id = 'node/5880053275'
on conflict do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'papel' from puntos_reciclaje where osm_id = 'node/5880053275'
on conflict do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'plastico' from puntos_reciclaje where osm_id = 'node/5880053275'
on conflict do nothing;

insert into puntos_reciclaje (nombre, direccion, comuna, lat, lng, fuente, osm_id, tipo_punto, creado_por)
select 'Punto de Reciclaje Tongoy', 'Tongoy 2500', 'Pedro Aguirre Cerda', -33.498804, -70.679357, 'osm', 'node/5880053276', null, null
where not exists (
  select 1 from puntos_reciclaje p
  where st_dwithin(p.geog, st_setsrid(st_makepoint(-70.679357, -33.498804), 4326)::geography, 30)
)
on conflict (osm_id) do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'vidrio' from puntos_reciclaje where osm_id = 'node/5880053276'
on conflict do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'papel' from puntos_reciclaje where osm_id = 'node/5880053276'
on conflict do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'plastico' from puntos_reciclaje where osm_id = 'node/5880053276'
on conflict do nothing;

insert into puntos_reciclaje (nombre, direccion, comuna, lat, lng, fuente, osm_id, tipo_punto, creado_por)
select 'Punto Verde CESFAM Augusto d''Halmar', 'Augusto d''Halmar 555', 'El Bosque', -33.561098, -70.674362, 'osm', 'node/5975047785', 'punto_limpio', null
where not exists (
  select 1 from puntos_reciclaje p
  where st_dwithin(p.geog, st_setsrid(st_makepoint(-70.674362, -33.561098), 4326)::geography, 30)
)
on conflict (osm_id) do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'vidrio' from puntos_reciclaje where osm_id = 'node/5975047785'
on conflict do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'papel' from puntos_reciclaje where osm_id = 'node/5975047785'
on conflict do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'plastico' from puntos_reciclaje where osm_id = 'node/5975047785'
on conflict do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'latas' from puntos_reciclaje where osm_id = 'node/5975047785'
on conflict do nothing;

insert into puntos_reciclaje (nombre, direccion, comuna, lat, lng, fuente, osm_id, tipo_punto, creado_por)
select 'Romerelli Arzobispo Subercaseaux', 'Arzobispo Subercaseaux 4169', 'Estación Central', -33.466243, -70.690886, 'osm', 'node/6067180555', 'punto_limpio', null
where not exists (
  select 1 from puntos_reciclaje p
  where st_dwithin(p.geog, st_setsrid(st_makepoint(-70.690886, -33.466243), 4326)::geography, 30)
)
on conflict (osm_id) do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'latas' from puntos_reciclaje where osm_id = 'node/6067180555'
on conflict do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'metal' from puntos_reciclaje where osm_id = 'node/6067180555'
on conflict do nothing;

insert into puntos_reciclaje (nombre, direccion, comuna, lat, lng, fuente, osm_id, tipo_punto, creado_por)
select 'Romerelli Los Yacimientos', 'Los Yacimientos 640', 'Maipú', -33.527198, -70.740539, 'osm', 'node/6279081237', 'punto_limpio', null
where not exists (
  select 1 from puntos_reciclaje p
  where st_dwithin(p.geog, st_setsrid(st_makepoint(-70.740539, -33.527198), 4326)::geography, 30)
)
on conflict (osm_id) do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'latas' from puntos_reciclaje where osm_id = 'node/6279081237'
on conflict do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'metal' from puntos_reciclaje where osm_id = 'node/6279081237'
on conflict do nothing;

insert into puntos_reciclaje (nombre, direccion, comuna, lat, lng, fuente, osm_id, tipo_punto, creado_por)
select 'Contenedor de reciclaje', null, null, -33.545133, -70.768952, 'osm', 'node/6311524264', 'contenedor', null
where not exists (
  select 1 from puntos_reciclaje p
  where st_dwithin(p.geog, st_setsrid(st_makepoint(-70.768952, -33.545133), 4326)::geography, 30)
)
on conflict (osm_id) do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'vidrio' from puntos_reciclaje where osm_id = 'node/6311524264'
on conflict do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'plastico' from puntos_reciclaje where osm_id = 'node/6311524264'
on conflict do nothing;

insert into puntos_reciclaje (nombre, direccion, comuna, lat, lng, fuente, osm_id, tipo_punto, creado_por)
select 'Contenedor de reciclaje', null, null, -33.541975, -70.766666, 'osm', 'node/6311524268', 'contenedor', null
where not exists (
  select 1 from puntos_reciclaje p
  where st_dwithin(p.geog, st_setsrid(st_makepoint(-70.766666, -33.541975), 4326)::geography, 30)
)
on conflict (osm_id) do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'vidrio' from puntos_reciclaje where osm_id = 'node/6311524268'
on conflict do nothing;

insert into puntos_reciclaje (nombre, direccion, comuna, lat, lng, fuente, osm_id, tipo_punto, creado_por)
select 'Contenedor de reciclaje', null, null, -33.445995, -70.635103, 'osm', 'node/6446790110', 'contenedor', null
where not exists (
  select 1 from puntos_reciclaje p
  where st_dwithin(p.geog, st_setsrid(st_makepoint(-70.635103, -33.445995), 4326)::geography, 30)
)
on conflict (osm_id) do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'vidrio' from puntos_reciclaje where osm_id = 'node/6446790110'
on conflict do nothing;

insert into puntos_reciclaje (nombre, direccion, comuna, lat, lng, fuente, osm_id, tipo_punto, creado_por)
select 'Contenedor de reciclaje', null, null, -33.489851, -70.767636, 'osm', 'node/8132494049', 'contenedor', null
where not exists (
  select 1 from puntos_reciclaje p
  where st_dwithin(p.geog, st_setsrid(st_makepoint(-70.767636, -33.489851), 4326)::geography, 30)
)
on conflict (osm_id) do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'vidrio' from puntos_reciclaje where osm_id = 'node/8132494049'
on conflict do nothing;

insert into puntos_reciclaje (nombre, direccion, comuna, lat, lng, fuente, osm_id, tipo_punto, creado_por)
select 'Contenedor de reciclaje', null, null, -33.500217, -70.508331, 'osm', 'node/8156504564', 'contenedor', null
where not exists (
  select 1 from puntos_reciclaje p
  where st_dwithin(p.geog, st_setsrid(st_makepoint(-70.508331, -33.500217), 4326)::geography, 30)
)
on conflict (osm_id) do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'vidrio' from puntos_reciclaje where osm_id = 'node/8156504564'
on conflict do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'plastico' from puntos_reciclaje where osm_id = 'node/8156504564'
on conflict do nothing;

insert into puntos_reciclaje (nombre, direccion, comuna, lat, lng, fuente, osm_id, tipo_punto, creado_por)
select 'Contenedor de reciclaje', null, null, -33.485253, -70.76878, 'osm', 'node/8423238282', 'contenedor', null
where not exists (
  select 1 from puntos_reciclaje p
  where st_dwithin(p.geog, st_setsrid(st_makepoint(-70.76878, -33.485253), 4326)::geography, 30)
)
on conflict (osm_id) do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'vidrio' from puntos_reciclaje where osm_id = 'node/8423238282'
on conflict do nothing;

insert into puntos_reciclaje (nombre, direccion, comuna, lat, lng, fuente, osm_id, tipo_punto, creado_por)
select 'Punto Limpio TriCiclos Manuel Antonio Matta', 'Manuel Antonio Matta 581', null, -33.36754, -70.727216, 'osm', 'node/8957868716', 'punto_limpio', null
where not exists (
  select 1 from puntos_reciclaje p
  where st_dwithin(p.geog, st_setsrid(st_makepoint(-70.727216, -33.36754), 4326)::geography, 30)
)
on conflict (osm_id) do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'vidrio' from puntos_reciclaje where osm_id = 'node/8957868716'
on conflict do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'papel' from puntos_reciclaje where osm_id = 'node/8957868716'
on conflict do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'plastico' from puntos_reciclaje where osm_id = 'node/8957868716'
on conflict do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'latas' from puntos_reciclaje where osm_id = 'node/8957868716'
on conflict do nothing;

insert into puntos_reciclaje (nombre, direccion, comuna, lat, lng, fuente, osm_id, tipo_punto, creado_por)
select 'Contenedor de reciclaje', null, null, -33.486418, -70.769549, 'osm', 'node/9152559262', 'contenedor', null
where not exists (
  select 1 from puntos_reciclaje p
  where st_dwithin(p.geog, st_setsrid(st_makepoint(-70.769549, -33.486418), 4326)::geography, 30)
)
on conflict (osm_id) do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'vidrio' from puntos_reciclaje where osm_id = 'node/9152559262'
on conflict do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'plastico' from puntos_reciclaje where osm_id = 'node/9152559262'
on conflict do nothing;

insert into puntos_reciclaje (nombre, direccion, comuna, lat, lng, fuente, osm_id, tipo_punto, creado_por)
select 'Punto Limpio', null, null, -33.63101, -70.76109, 'osm', 'node/10102270873', 'contenedor', null
where not exists (
  select 1 from puntos_reciclaje p
  where st_dwithin(p.geog, st_setsrid(st_makepoint(-70.76109, -33.63101), 4326)::geography, 30)
)
on conflict (osm_id) do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'vidrio' from puntos_reciclaje where osm_id = 'node/10102270873'
on conflict do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'papel' from puntos_reciclaje where osm_id = 'node/10102270873'
on conflict do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'plastico' from puntos_reciclaje where osm_id = 'node/10102270873'
on conflict do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'latas' from puntos_reciclaje where osm_id = 'node/10102270873'
on conflict do nothing;

insert into puntos_reciclaje (nombre, direccion, comuna, lat, lng, fuente, osm_id, tipo_punto, creado_por)
select 'Contenedor de reciclaje', null, null, -33.751006, -70.906552, 'osm', 'node/10220188623', 'contenedor', null
where not exists (
  select 1 from puntos_reciclaje p
  where st_dwithin(p.geog, st_setsrid(st_makepoint(-70.906552, -33.751006), 4326)::geography, 30)
)
on conflict (osm_id) do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'vidrio' from puntos_reciclaje where osm_id = 'node/10220188623'
on conflict do nothing;

insert into puntos_reciclaje (nombre, direccion, comuna, lat, lng, fuente, osm_id, tipo_punto, creado_por)
select 'Contenedor de reciclaje', null, null, -33.755452, -70.897436, 'osm', 'node/10220192456', 'contenedor', null
where not exists (
  select 1 from puntos_reciclaje p
  where st_dwithin(p.geog, st_setsrid(st_makepoint(-70.897436, -33.755452), 4326)::geography, 30)
)
on conflict (osm_id) do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'vidrio' from puntos_reciclaje where osm_id = 'node/10220192456'
on conflict do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'papel' from puntos_reciclaje where osm_id = 'node/10220192456'
on conflict do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'plastico' from puntos_reciclaje where osm_id = 'node/10220192456'
on conflict do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'latas' from puntos_reciclaje where osm_id = 'node/10220192456'
on conflict do nothing;

insert into puntos_reciclaje (nombre, direccion, comuna, lat, lng, fuente, osm_id, tipo_punto, creado_por)
select 'Punto Verde Los Sauces Portales', 'Portales', 'El Bosque', -33.562744, -70.663306, 'osm', 'node/10647331983', 'punto_limpio', null
where not exists (
  select 1 from puntos_reciclaje p
  where st_dwithin(p.geog, st_setsrid(st_makepoint(-70.663306, -33.562744), 4326)::geography, 30)
)
on conflict (osm_id) do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'vidrio' from puntos_reciclaje where osm_id = 'node/10647331983'
on conflict do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'papel' from puntos_reciclaje where osm_id = 'node/10647331983'
on conflict do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'latas' from puntos_reciclaje where osm_id = 'node/10647331983'
on conflict do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'pilas' from puntos_reciclaje where osm_id = 'node/10647331983'
on conflict do nothing;

insert into puntos_reciclaje (nombre, direccion, comuna, lat, lng, fuente, osm_id, tipo_punto, creado_por)
select 'Punto Verde Javiera Carrera', 'Javiera Carrera 550', 'El Bosque', -33.557397, -70.664443, 'osm', 'node/10647349900', 'punto_limpio', null
where not exists (
  select 1 from puntos_reciclaje p
  where st_dwithin(p.geog, st_setsrid(st_makepoint(-70.664443, -33.557397), 4326)::geography, 30)
)
on conflict (osm_id) do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'vidrio' from puntos_reciclaje where osm_id = 'node/10647349900'
on conflict do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'papel' from puntos_reciclaje where osm_id = 'node/10647349900'
on conflict do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'plastico' from puntos_reciclaje where osm_id = 'node/10647349900'
on conflict do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'latas' from puntos_reciclaje where osm_id = 'node/10647349900'
on conflict do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'pilas' from puntos_reciclaje where osm_id = 'node/10647349900'
on conflict do nothing;

insert into puntos_reciclaje (nombre, direccion, comuna, lat, lng, fuente, osm_id, tipo_punto, creado_por)
select 'Punto Verde OMIL General Korner', 'General Korner 286', 'El Bosque', -33.550428, -70.676867, 'osm', 'node/10647349902', 'punto_limpio', null
where not exists (
  select 1 from puntos_reciclaje p
  where st_dwithin(p.geog, st_setsrid(st_makepoint(-70.676867, -33.550428), 4326)::geography, 30)
)
on conflict (osm_id) do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'vidrio' from puntos_reciclaje where osm_id = 'node/10647349902'
on conflict do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'papel' from puntos_reciclaje where osm_id = 'node/10647349902'
on conflict do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'plastico' from puntos_reciclaje where osm_id = 'node/10647349902'
on conflict do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'latas' from puntos_reciclaje where osm_id = 'node/10647349902'
on conflict do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'pilas' from puntos_reciclaje where osm_id = 'node/10647349902'
on conflict do nothing;

insert into puntos_reciclaje (nombre, direccion, comuna, lat, lng, fuente, osm_id, tipo_punto, creado_por)
select 'Punto limpio Avenida Padre Hurtado', 'Avenida Padre Hurtado', 'El Bosque', -33.546813, -70.666643, 'osm', 'node/10647349904', 'punto_limpio', null
where not exists (
  select 1 from puntos_reciclaje p
  where st_dwithin(p.geog, st_setsrid(st_makepoint(-70.666643, -33.546813), 4326)::geography, 30)
)
on conflict (osm_id) do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'vidrio' from puntos_reciclaje where osm_id = 'node/10647349904'
on conflict do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'papel' from puntos_reciclaje where osm_id = 'node/10647349904'
on conflict do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'plastico' from puntos_reciclaje where osm_id = 'node/10647349904'
on conflict do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'latas' from puntos_reciclaje where osm_id = 'node/10647349904'
on conflict do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'pilas' from puntos_reciclaje where osm_id = 'node/10647349904'
on conflict do nothing;

insert into puntos_reciclaje (nombre, direccion, comuna, lat, lng, fuente, osm_id, tipo_punto, creado_por)
select 'Contenedor de reciclaje', null, null, -33.444709, -70.564471, 'osm', 'node/10671839956', 'contenedor', null
where not exists (
  select 1 from puntos_reciclaje p
  where st_dwithin(p.geog, st_setsrid(st_makepoint(-70.564471, -33.444709), 4326)::geography, 30)
)
on conflict (osm_id) do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'vidrio' from puntos_reciclaje where osm_id = 'node/10671839956'
on conflict do nothing;

insert into puntos_reciclaje (nombre, direccion, comuna, lat, lng, fuente, osm_id, tipo_punto, creado_por)
select 'Contenedor de reciclaje', null, null, -33.444567, -70.565609, 'osm', 'node/10671839957', 'contenedor', null
where not exists (
  select 1 from puntos_reciclaje p
  where st_dwithin(p.geog, st_setsrid(st_makepoint(-70.565609, -33.444567), 4326)::geography, 30)
)
on conflict (osm_id) do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'vidrio' from puntos_reciclaje where osm_id = 'node/10671839957'
on conflict do nothing;

insert into puntos_reciclaje (nombre, direccion, comuna, lat, lng, fuente, osm_id, tipo_punto, creado_por)
select 'Punto Limpio - Villa Macul Poeta Augusto Winter', 'Poeta Augusto Winter', 'Macul', -33.491165, -70.593631, 'osm', 'node/10823517336', 'punto_limpio', null
where not exists (
  select 1 from puntos_reciclaje p
  where st_dwithin(p.geog, st_setsrid(st_makepoint(-70.593631, -33.491165), 4326)::geography, 30)
)
on conflict (osm_id) do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'vidrio' from puntos_reciclaje where osm_id = 'node/10823517336'
on conflict do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'papel' from puntos_reciclaje where osm_id = 'node/10823517336'
on conflict do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'latas' from puntos_reciclaje where osm_id = 'node/10823517336'
on conflict do nothing;

insert into puntos_reciclaje (nombre, direccion, comuna, lat, lng, fuente, osm_id, tipo_punto, creado_por)
select 'Contenedor de reciclaje', null, null, -33.490179, -70.592699, 'osm', 'node/10823517345', 'contenedor', null
where not exists (
  select 1 from puntos_reciclaje p
  where st_dwithin(p.geog, st_setsrid(st_makepoint(-70.592699, -33.490179), 4326)::geography, 30)
)
on conflict (osm_id) do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'vidrio' from puntos_reciclaje where osm_id = 'node/10823517345'
on conflict do nothing;

insert into puntos_reciclaje (nombre, direccion, comuna, lat, lng, fuente, osm_id, tipo_punto, creado_por)
select 'Contenedor de reciclaje', null, null, -33.487743, -70.663969, 'osm', 'node/11141639522', 'contenedor', null
where not exists (
  select 1 from puntos_reciclaje p
  where st_dwithin(p.geog, st_setsrid(st_makepoint(-70.663969, -33.487743), 4326)::geography, 30)
)
on conflict (osm_id) do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'vidrio' from puntos_reciclaje where osm_id = 'node/11141639522'
on conflict do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'papel' from puntos_reciclaje where osm_id = 'node/11141639522'
on conflict do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'plastico' from puntos_reciclaje where osm_id = 'node/11141639522'
on conflict do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'latas' from puntos_reciclaje where osm_id = 'node/11141639522'
on conflict do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'tetra_pak' from puntos_reciclaje where osm_id = 'node/11141639522'
on conflict do nothing;

insert into puntos_reciclaje (nombre, direccion, comuna, lat, lng, fuente, osm_id, tipo_punto, creado_por)
select 'Contenedor de reciclaje', null, null, -33.429087, -70.715303, 'osm', 'node/11359040202', 'contenedor', null
where not exists (
  select 1 from puntos_reciclaje p
  where st_dwithin(p.geog, st_setsrid(st_makepoint(-70.715303, -33.429087), 4326)::geography, 30)
)
on conflict (osm_id) do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'plastico' from puntos_reciclaje where osm_id = 'node/11359040202'
on conflict do nothing;

insert into puntos_reciclaje (nombre, direccion, comuna, lat, lng, fuente, osm_id, tipo_punto, creado_por)
select 'Contenedor de reciclaje', null, null, -33.429488, -70.716142, 'osm', 'node/11359040206', 'contenedor', null
where not exists (
  select 1 from puntos_reciclaje p
  where st_dwithin(p.geog, st_setsrid(st_makepoint(-70.716142, -33.429488), 4326)::geography, 30)
)
on conflict (osm_id) do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'vidrio' from puntos_reciclaje where osm_id = 'node/11359040206'
on conflict do nothing;

insert into puntos_reciclaje (nombre, direccion, comuna, lat, lng, fuente, osm_id, tipo_punto, creado_por)
select 'Contenedor de reciclaje', null, null, -33.423715, -70.603214, 'osm', 'node/11376993927', 'contenedor', null
where not exists (
  select 1 from puntos_reciclaje p
  where st_dwithin(p.geog, st_setsrid(st_makepoint(-70.603214, -33.423715), 4326)::geography, 30)
)
on conflict (osm_id) do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'papel' from puntos_reciclaje where osm_id = 'node/11376993927'
on conflict do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'plastico' from puntos_reciclaje where osm_id = 'node/11376993927'
on conflict do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'latas' from puntos_reciclaje where osm_id = 'node/11376993927'
on conflict do nothing;

insert into puntos_reciclaje (nombre, direccion, comuna, lat, lng, fuente, osm_id, tipo_punto, creado_por)
select 'Contenedor de reciclaje', null, null, -33.424011, -70.60301, 'osm', 'node/11376993928', 'contenedor', null
where not exists (
  select 1 from puntos_reciclaje p
  where st_dwithin(p.geog, st_setsrid(st_makepoint(-70.60301, -33.424011), 4326)::geography, 30)
)
on conflict (osm_id) do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'papel' from puntos_reciclaje where osm_id = 'node/11376993928'
on conflict do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'plastico' from puntos_reciclaje where osm_id = 'node/11376993928'
on conflict do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'latas' from puntos_reciclaje where osm_id = 'node/11376993928'
on conflict do nothing;

insert into puntos_reciclaje (nombre, direccion, comuna, lat, lng, fuente, osm_id, tipo_punto, creado_por)
select 'Contenedor de reciclaje', null, null, -33.424125, -70.603258, 'osm', 'node/11383043117', 'contenedor', null
where not exists (
  select 1 from puntos_reciclaje p
  where st_dwithin(p.geog, st_setsrid(st_makepoint(-70.603258, -33.424125), 4326)::geography, 30)
)
on conflict (osm_id) do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'papel' from puntos_reciclaje where osm_id = 'node/11383043117'
on conflict do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'plastico' from puntos_reciclaje where osm_id = 'node/11383043117'
on conflict do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'latas' from puntos_reciclaje where osm_id = 'node/11383043117'
on conflict do nothing;

insert into puntos_reciclaje (nombre, direccion, comuna, lat, lng, fuente, osm_id, tipo_punto, creado_por)
select 'Contenedor de reciclaje', null, null, -33.466548, -70.613068, 'osm', 'node/11829371760', 'contenedor', null
where not exists (
  select 1 from puntos_reciclaje p
  where st_dwithin(p.geog, st_setsrid(st_makepoint(-70.613068, -33.466548), 4326)::geography, 30)
)
on conflict (osm_id) do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'vidrio' from puntos_reciclaje where osm_id = 'node/11829371760'
on conflict do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'plastico' from puntos_reciclaje where osm_id = 'node/11829371760'
on conflict do nothing;

insert into puntos_reciclaje (nombre, direccion, comuna, lat, lng, fuente, osm_id, tipo_punto, creado_por)
select 'Contenedor de reciclaje', null, null, -33.35466, -70.754702, 'osm', 'node/11860250103', 'contenedor', null
where not exists (
  select 1 from puntos_reciclaje p
  where st_dwithin(p.geog, st_setsrid(st_makepoint(-70.754702, -33.35466), 4326)::geography, 30)
)
on conflict (osm_id) do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'vidrio' from puntos_reciclaje where osm_id = 'node/11860250103'
on conflict do nothing;

insert into puntos_reciclaje (nombre, direccion, comuna, lat, lng, fuente, osm_id, tipo_punto, creado_por)
select 'Contenedor de reciclaje', null, null, -33.354666, -70.754705, 'osm', 'node/11860250104', 'contenedor', null
where not exists (
  select 1 from puntos_reciclaje p
  where st_dwithin(p.geog, st_setsrid(st_makepoint(-70.754705, -33.354666), 4326)::geography, 30)
)
on conflict (osm_id) do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'vidrio' from puntos_reciclaje where osm_id = 'node/11860250104'
on conflict do nothing;

insert into puntos_reciclaje (nombre, direccion, comuna, lat, lng, fuente, osm_id, tipo_punto, creado_por)
select 'Contenedor de reciclaje', null, null, -33.630511, -70.614681, 'osm', 'node/11953285259', 'contenedor', null
where not exists (
  select 1 from puntos_reciclaje p
  where st_dwithin(p.geog, st_setsrid(st_makepoint(-70.614681, -33.630511), 4326)::geography, 30)
)
on conflict (osm_id) do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'plastico' from puntos_reciclaje where osm_id = 'node/11953285259'
on conflict do nothing;

insert into puntos_reciclaje (nombre, direccion, comuna, lat, lng, fuente, osm_id, tipo_punto, creado_por)
select 'Contenedor de reciclaje', null, null, -33.613354, -70.622133, 'osm', 'node/11969546888', 'contenedor', null
where not exists (
  select 1 from puntos_reciclaje p
  where st_dwithin(p.geog, st_setsrid(st_makepoint(-70.622133, -33.613354), 4326)::geography, 30)
)
on conflict (osm_id) do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'plastico' from puntos_reciclaje where osm_id = 'node/11969546888'
on conflict do nothing;

insert into puntos_reciclaje (nombre, direccion, comuna, lat, lng, fuente, osm_id, tipo_punto, creado_por)
select 'Contenedor de reciclaje', null, null, -33.613659, -70.620838, 'osm', 'node/12003252949', 'contenedor', null
where not exists (
  select 1 from puntos_reciclaje p
  where st_dwithin(p.geog, st_setsrid(st_makepoint(-70.620838, -33.613659), 4326)::geography, 30)
)
on conflict (osm_id) do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'plastico' from puntos_reciclaje where osm_id = 'node/12003252949'
on conflict do nothing;

insert into puntos_reciclaje (nombre, direccion, comuna, lat, lng, fuente, osm_id, tipo_punto, creado_por)
select 'Contenedor de reciclaje', null, null, -33.612957, -70.625739, 'osm', 'node/12003341309', 'contenedor', null
where not exists (
  select 1 from puntos_reciclaje p
  where st_dwithin(p.geog, st_setsrid(st_makepoint(-70.625739, -33.612957), 4326)::geography, 30)
)
on conflict (osm_id) do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'plastico' from puntos_reciclaje where osm_id = 'node/12003341309'
on conflict do nothing;

insert into puntos_reciclaje (nombre, direccion, comuna, lat, lng, fuente, osm_id, tipo_punto, creado_por)
select 'Contenedor de reciclaje', null, null, -33.6151, -70.619045, 'osm', 'node/12003357393', 'contenedor', null
where not exists (
  select 1 from puntos_reciclaje p
  where st_dwithin(p.geog, st_setsrid(st_makepoint(-70.619045, -33.6151), 4326)::geography, 30)
)
on conflict (osm_id) do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'plastico' from puntos_reciclaje where osm_id = 'node/12003357393'
on conflict do nothing;

insert into puntos_reciclaje (nombre, direccion, comuna, lat, lng, fuente, osm_id, tipo_punto, creado_por)
select 'Contenedor de reciclaje', null, null, -33.43026, -70.636063, 'osm', 'node/12109244665', 'contenedor', null
where not exists (
  select 1 from puntos_reciclaje p
  where st_dwithin(p.geog, st_setsrid(st_makepoint(-70.636063, -33.43026), 4326)::geography, 30)
)
on conflict (osm_id) do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'vidrio' from puntos_reciclaje where osm_id = 'node/12109244665'
on conflict do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'papel' from puntos_reciclaje where osm_id = 'node/12109244665'
on conflict do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'latas' from puntos_reciclaje where osm_id = 'node/12109244665'
on conflict do nothing;

insert into puntos_reciclaje (nombre, direccion, comuna, lat, lng, fuente, osm_id, tipo_punto, creado_por)
select 'Contenedor de reciclaje', null, null, -33.389721, -70.601672, 'osm', 'node/12115910299', 'contenedor', null
where not exists (
  select 1 from puntos_reciclaje p
  where st_dwithin(p.geog, st_setsrid(st_makepoint(-70.601672, -33.389721), 4326)::geography, 30)
)
on conflict (osm_id) do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'vidrio' from puntos_reciclaje where osm_id = 'node/12115910299'
on conflict do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'plastico' from puntos_reciclaje where osm_id = 'node/12115910299'
on conflict do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'latas' from puntos_reciclaje where osm_id = 'node/12115910299'
on conflict do nothing;

insert into puntos_reciclaje (nombre, direccion, comuna, lat, lng, fuente, osm_id, tipo_punto, creado_por)
select 'Contenedor de reciclaje', null, null, -33.46611, -70.611102, 'osm', 'node/12138221268', 'contenedor', null
where not exists (
  select 1 from puntos_reciclaje p
  where st_dwithin(p.geog, st_setsrid(st_makepoint(-70.611102, -33.46611), 4326)::geography, 30)
)
on conflict (osm_id) do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'vidrio' from puntos_reciclaje where osm_id = 'node/12138221268'
on conflict do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'plastico' from puntos_reciclaje where osm_id = 'node/12138221268'
on conflict do nothing;

insert into puntos_reciclaje (nombre, direccion, comuna, lat, lng, fuente, osm_id, tipo_punto, creado_por)
select 'Contenedor de reciclaje', null, null, -33.463521, -70.611676, 'osm', 'node/12138221269', 'contenedor', null
where not exists (
  select 1 from puntos_reciclaje p
  where st_dwithin(p.geog, st_setsrid(st_makepoint(-70.611676, -33.463521), 4326)::geography, 30)
)
on conflict (osm_id) do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'vidrio' from puntos_reciclaje where osm_id = 'node/12138221269'
on conflict do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'plastico' from puntos_reciclaje where osm_id = 'node/12138221269'
on conflict do nothing;

insert into puntos_reciclaje (nombre, direccion, comuna, lat, lng, fuente, osm_id, tipo_punto, creado_por)
select 'Contenedor de reciclaje', null, null, -33.463293, -70.609958, 'osm', 'node/12138726303', 'contenedor', null
where not exists (
  select 1 from puntos_reciclaje p
  where st_dwithin(p.geog, st_setsrid(st_makepoint(-70.609958, -33.463293), 4326)::geography, 30)
)
on conflict (osm_id) do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'vidrio' from puntos_reciclaje where osm_id = 'node/12138726303'
on conflict do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'plastico' from puntos_reciclaje where osm_id = 'node/12138726303'
on conflict do nothing;

insert into puntos_reciclaje (nombre, direccion, comuna, lat, lng, fuente, osm_id, tipo_punto, creado_por)
select 'Centro de Reciclaje', null, null, -33.406835, -70.548885, 'osm', 'node/12147127158', 'punto_limpio', null
where not exists (
  select 1 from puntos_reciclaje p
  where st_dwithin(p.geog, st_setsrid(st_makepoint(-70.548885, -33.406835), 4326)::geography, 30)
)
on conflict (osm_id) do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'vidrio' from puntos_reciclaje where osm_id = 'node/12147127158'
on conflict do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'papel' from puntos_reciclaje where osm_id = 'node/12147127158'
on conflict do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'plastico' from puntos_reciclaje where osm_id = 'node/12147127158'
on conflict do nothing;

insert into puntos_reciclaje (nombre, direccion, comuna, lat, lng, fuente, osm_id, tipo_punto, creado_por)
select 'Contenedor de reciclaje', null, null, -33.395601, -70.607253, 'osm', 'node/12181228564', 'contenedor', null
where not exists (
  select 1 from puntos_reciclaje p
  where st_dwithin(p.geog, st_setsrid(st_makepoint(-70.607253, -33.395601), 4326)::geography, 30)
)
on conflict (osm_id) do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'vidrio' from puntos_reciclaje where osm_id = 'node/12181228564'
on conflict do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'plastico' from puntos_reciclaje where osm_id = 'node/12181228564'
on conflict do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'latas' from puntos_reciclaje where osm_id = 'node/12181228564'
on conflict do nothing;

insert into puntos_reciclaje (nombre, direccion, comuna, lat, lng, fuente, osm_id, tipo_punto, creado_por)
select 'Contenedor de reciclaje', null, null, -33.407275, -70.611529, 'osm', 'node/12181228599', 'contenedor', null
where not exists (
  select 1 from puntos_reciclaje p
  where st_dwithin(p.geog, st_setsrid(st_makepoint(-70.611529, -33.407275), 4326)::geography, 30)
)
on conflict (osm_id) do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'vidrio' from puntos_reciclaje where osm_id = 'node/12181228599'
on conflict do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'plastico' from puntos_reciclaje where osm_id = 'node/12181228599'
on conflict do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'latas' from puntos_reciclaje where osm_id = 'node/12181228599'
on conflict do nothing;

insert into puntos_reciclaje (nombre, direccion, comuna, lat, lng, fuente, osm_id, tipo_punto, creado_por)
select 'Contenedor de reciclaje', null, null, -33.7274, -70.916428, 'osm', 'node/12287330568', 'contenedor', null
where not exists (
  select 1 from puntos_reciclaje p
  where st_dwithin(p.geog, st_setsrid(st_makepoint(-70.916428, -33.7274), 4326)::geography, 30)
)
on conflict (osm_id) do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'plastico' from puntos_reciclaje where osm_id = 'node/12287330568'
on conflict do nothing;

insert into puntos_reciclaje (nombre, direccion, comuna, lat, lng, fuente, osm_id, tipo_punto, creado_por)
select 'Contenedor de reciclaje', null, null, -33.49601, -70.699748, 'osm', 'node/12289364709', 'contenedor', null
where not exists (
  select 1 from puntos_reciclaje p
  where st_dwithin(p.geog, st_setsrid(st_makepoint(-70.699748, -33.49601), 4326)::geography, 30)
)
on conflict (osm_id) do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'vidrio' from puntos_reciclaje where osm_id = 'node/12289364709'
on conflict do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'papel' from puntos_reciclaje where osm_id = 'node/12289364709'
on conflict do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'plastico' from puntos_reciclaje where osm_id = 'node/12289364709'
on conflict do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'latas' from puntos_reciclaje where osm_id = 'node/12289364709'
on conflict do nothing;

insert into puntos_reciclaje (nombre, direccion, comuna, lat, lng, fuente, osm_id, tipo_punto, creado_por)
select 'Contenedor de reciclaje', null, null, -33.490587, -70.697433, 'osm', 'node/12289364713', 'contenedor', null
where not exists (
  select 1 from puntos_reciclaje p
  where st_dwithin(p.geog, st_setsrid(st_makepoint(-70.697433, -33.490587), 4326)::geography, 30)
)
on conflict (osm_id) do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'vidrio' from puntos_reciclaje where osm_id = 'node/12289364713'
on conflict do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'papel' from puntos_reciclaje where osm_id = 'node/12289364713'
on conflict do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'plastico' from puntos_reciclaje where osm_id = 'node/12289364713'
on conflict do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'latas' from puntos_reciclaje where osm_id = 'node/12289364713'
on conflict do nothing;

insert into puntos_reciclaje (nombre, direccion, comuna, lat, lng, fuente, osm_id, tipo_punto, creado_por)
select 'Contenedor de reciclaje', null, null, -33.486648, -70.692447, 'osm', 'node/12289364719', 'contenedor', null
where not exists (
  select 1 from puntos_reciclaje p
  where st_dwithin(p.geog, st_setsrid(st_makepoint(-70.692447, -33.486648), 4326)::geography, 30)
)
on conflict (osm_id) do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'vidrio' from puntos_reciclaje where osm_id = 'node/12289364719'
on conflict do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'papel' from puntos_reciclaje where osm_id = 'node/12289364719'
on conflict do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'plastico' from puntos_reciclaje where osm_id = 'node/12289364719'
on conflict do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'latas' from puntos_reciclaje where osm_id = 'node/12289364719'
on conflict do nothing;

insert into puntos_reciclaje (nombre, direccion, comuna, lat, lng, fuente, osm_id, tipo_punto, creado_por)
select 'Contenedor de reciclaje', null, null, -33.436699, -70.750697, 'osm', 'node/12333464357', 'contenedor', null
where not exists (
  select 1 from puntos_reciclaje p
  where st_dwithin(p.geog, st_setsrid(st_makepoint(-70.750697, -33.436699), 4326)::geography, 30)
)
on conflict (osm_id) do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'papel' from puntos_reciclaje where osm_id = 'node/12333464357'
on conflict do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'latas' from puntos_reciclaje where osm_id = 'node/12333464357'
on conflict do nothing;

insert into puntos_reciclaje (nombre, direccion, comuna, lat, lng, fuente, osm_id, tipo_punto, creado_por)
select 'Contenedor de reciclaje', null, null, -33.441155, -70.753773, 'osm', 'node/12333930177', 'contenedor', null
where not exists (
  select 1 from puntos_reciclaje p
  where st_dwithin(p.geog, st_setsrid(st_makepoint(-70.753773, -33.441155), 4326)::geography, 30)
)
on conflict (osm_id) do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'papel' from puntos_reciclaje where osm_id = 'node/12333930177'
on conflict do nothing;

insert into puntos_reciclaje (nombre, direccion, comuna, lat, lng, fuente, osm_id, tipo_punto, creado_por)
select 'Contenedor de reciclaje', null, null, -33.452484, -70.660887, 'osm', 'node/12334612528', 'contenedor', null
where not exists (
  select 1 from puntos_reciclaje p
  where st_dwithin(p.geog, st_setsrid(st_makepoint(-70.660887, -33.452484), 4326)::geography, 30)
)
on conflict (osm_id) do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'vidrio' from puntos_reciclaje where osm_id = 'node/12334612528'
on conflict do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'papel' from puntos_reciclaje where osm_id = 'node/12334612528'
on conflict do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'plastico' from puntos_reciclaje where osm_id = 'node/12334612528'
on conflict do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'latas' from puntos_reciclaje where osm_id = 'node/12334612528'
on conflict do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'tetra_pak' from puntos_reciclaje where osm_id = 'node/12334612528'
on conflict do nothing;

insert into puntos_reciclaje (nombre, direccion, comuna, lat, lng, fuente, osm_id, tipo_punto, creado_por)
select 'Contenedor de reciclaje', null, null, -33.46401, -70.662522, 'osm', 'node/12384861123', 'contenedor', null
where not exists (
  select 1 from puntos_reciclaje p
  where st_dwithin(p.geog, st_setsrid(st_makepoint(-70.662522, -33.46401), 4326)::geography, 30)
)
on conflict (osm_id) do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'vidrio' from puntos_reciclaje where osm_id = 'node/12384861123'
on conflict do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'papel' from puntos_reciclaje where osm_id = 'node/12384861123'
on conflict do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'latas' from puntos_reciclaje where osm_id = 'node/12384861123'
on conflict do nothing;

insert into puntos_reciclaje (nombre, direccion, comuna, lat, lng, fuente, osm_id, tipo_punto, creado_por)
select 'Contenedor de reciclaje', null, null, -33.462562, -70.663938, 'osm', 'node/12384861127', 'contenedor', null
where not exists (
  select 1 from puntos_reciclaje p
  where st_dwithin(p.geog, st_setsrid(st_makepoint(-70.663938, -33.462562), 4326)::geography, 30)
)
on conflict (osm_id) do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'vidrio' from puntos_reciclaje where osm_id = 'node/12384861127'
on conflict do nothing;

insert into puntos_reciclaje (nombre, direccion, comuna, lat, lng, fuente, osm_id, tipo_punto, creado_por)
select 'Contenedor de reciclaje', null, null, -33.469313, -70.611581, 'osm', 'node/12427684617', 'contenedor', null
where not exists (
  select 1 from puntos_reciclaje p
  where st_dwithin(p.geog, st_setsrid(st_makepoint(-70.611581, -33.469313), 4326)::geography, 30)
)
on conflict (osm_id) do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'vidrio' from puntos_reciclaje where osm_id = 'node/12427684617'
on conflict do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'plastico' from puntos_reciclaje where osm_id = 'node/12427684617'
on conflict do nothing;

insert into puntos_reciclaje (nombre, direccion, comuna, lat, lng, fuente, osm_id, tipo_punto, creado_por)
select 'Contenedor de reciclaje', null, null, -33.466945, -70.634117, 'osm', 'node/12549271020', 'contenedor', null
where not exists (
  select 1 from puntos_reciclaje p
  where st_dwithin(p.geog, st_setsrid(st_makepoint(-70.634117, -33.466945), 4326)::geography, 30)
)
on conflict (osm_id) do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'vidrio' from puntos_reciclaje where osm_id = 'node/12549271020'
on conflict do nothing;

insert into puntos_reciclaje (nombre, direccion, comuna, lat, lng, fuente, osm_id, tipo_punto, creado_por)
select 'Contenedor de reciclaje', null, null, -33.580538, -70.583167, 'osm', 'node/12723558863', 'contenedor', null
where not exists (
  select 1 from puntos_reciclaje p
  where st_dwithin(p.geog, st_setsrid(st_makepoint(-70.583167, -33.580538), 4326)::geography, 30)
)
on conflict (osm_id) do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'plastico' from puntos_reciclaje where osm_id = 'node/12723558863'
on conflict do nothing;

insert into puntos_reciclaje (nombre, direccion, comuna, lat, lng, fuente, osm_id, tipo_punto, creado_por)
select 'Contenedor de reciclaje', null, null, -33.354894, -70.317312, 'osm', 'node/12777781779', 'contenedor', null
where not exists (
  select 1 from puntos_reciclaje p
  where st_dwithin(p.geog, st_setsrid(st_makepoint(-70.317312, -33.354894), 4326)::geography, 30)
)
on conflict (osm_id) do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'vidrio' from puntos_reciclaje where osm_id = 'node/12777781779'
on conflict do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'plastico' from puntos_reciclaje where osm_id = 'node/12777781779'
on conflict do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'latas' from puntos_reciclaje where osm_id = 'node/12777781779'
on conflict do nothing;

insert into puntos_reciclaje (nombre, direccion, comuna, lat, lng, fuente, osm_id, tipo_punto, creado_por)
select 'Contenedor de reciclaje', null, null, -33.49799, -70.609495, 'osm', 'node/12852001738', 'contenedor', null
where not exists (
  select 1 from puntos_reciclaje p
  where st_dwithin(p.geog, st_setsrid(st_makepoint(-70.609495, -33.49799), 4326)::geography, 30)
)
on conflict (osm_id) do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'papel' from puntos_reciclaje where osm_id = 'node/12852001738'
on conflict do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'plastico' from puntos_reciclaje where osm_id = 'node/12852001738'
on conflict do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'latas' from puntos_reciclaje where osm_id = 'node/12852001738'
on conflict do nothing;

insert into puntos_reciclaje (nombre, direccion, comuna, lat, lng, fuente, osm_id, tipo_punto, creado_por)
select 'Contenedor de reciclaje', null, null, -33.499194, -70.614455, 'osm', 'node/13067139941', 'contenedor', null
where not exists (
  select 1 from puntos_reciclaje p
  where st_dwithin(p.geog, st_setsrid(st_makepoint(-70.614455, -33.499194), 4326)::geography, 30)
)
on conflict (osm_id) do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'vidrio' from puntos_reciclaje where osm_id = 'node/13067139941'
on conflict do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'papel' from puntos_reciclaje where osm_id = 'node/13067139941'
on conflict do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'plastico' from puntos_reciclaje where osm_id = 'node/13067139941'
on conflict do nothing;

insert into puntos_reciclaje (nombre, direccion, comuna, lat, lng, fuente, osm_id, tipo_punto, creado_por)
select 'Contenedor de reciclaje', null, null, -33.495346, -70.727822, 'osm', 'node/13256678445', 'contenedor', null
where not exists (
  select 1 from puntos_reciclaje p
  where st_dwithin(p.geog, st_setsrid(st_makepoint(-70.727822, -33.495346), 4326)::geography, 30)
)
on conflict (osm_id) do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'vidrio' from puntos_reciclaje where osm_id = 'node/13256678445'
on conflict do nothing;

insert into puntos_reciclaje (nombre, direccion, comuna, lat, lng, fuente, osm_id, tipo_punto, creado_por)
select 'Contenedor de reciclaje', null, null, -33.762799, -70.899249, 'osm', 'node/13395476023', 'contenedor', null
where not exists (
  select 1 from puntos_reciclaje p
  where st_dwithin(p.geog, st_setsrid(st_makepoint(-70.899249, -33.762799), 4326)::geography, 30)
)
on conflict (osm_id) do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'vidrio' from puntos_reciclaje where osm_id = 'node/13395476023'
on conflict do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'papel' from puntos_reciclaje where osm_id = 'node/13395476023'
on conflict do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'plastico' from puntos_reciclaje where osm_id = 'node/13395476023'
on conflict do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'latas' from puntos_reciclaje where osm_id = 'node/13395476023'
on conflict do nothing;

insert into puntos_reciclaje (nombre, direccion, comuna, lat, lng, fuente, osm_id, tipo_punto, creado_por)
select 'Contenedor de reciclaje', null, null, -33.453404, -70.67236, 'osm', 'node/13482646351', 'contenedor', null
where not exists (
  select 1 from puntos_reciclaje p
  where st_dwithin(p.geog, st_setsrid(st_makepoint(-70.67236, -33.453404), 4326)::geography, 30)
)
on conflict (osm_id) do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'vidrio' from puntos_reciclaje where osm_id = 'node/13482646351'
on conflict do nothing;

insert into puntos_reciclaje (nombre, direccion, comuna, lat, lng, fuente, osm_id, tipo_punto, creado_por)
select 'Contenedor de reciclaje', null, null, -33.452824, -70.670497, 'osm', 'node/13721567954', 'contenedor', null
where not exists (
  select 1 from puntos_reciclaje p
  where st_dwithin(p.geog, st_setsrid(st_makepoint(-70.670497, -33.452824), 4326)::geography, 30)
)
on conflict (osm_id) do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'vidrio' from puntos_reciclaje where osm_id = 'node/13721567954'
on conflict do nothing;

insert into puntos_reciclaje (nombre, direccion, comuna, lat, lng, fuente, osm_id, tipo_punto, creado_por)
select 'Contenedor de reciclaje', null, null, -33.452037, -70.667544, 'osm', 'node/13721642287', 'contenedor', null
where not exists (
  select 1 from puntos_reciclaje p
  where st_dwithin(p.geog, st_setsrid(st_makepoint(-70.667544, -33.452037), 4326)::geography, 30)
)
on conflict (osm_id) do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'vidrio' from puntos_reciclaje where osm_id = 'node/13721642287'
on conflict do nothing;

insert into puntos_reciclaje (nombre, direccion, comuna, lat, lng, fuente, osm_id, tipo_punto, creado_por)
select 'Contenedor de reciclaje', null, null, -33.452244, -70.660555, 'osm', 'node/13724446476', 'contenedor', null
where not exists (
  select 1 from puntos_reciclaje p
  where st_dwithin(p.geog, st_setsrid(st_makepoint(-70.660555, -33.452244), 4326)::geography, 30)
)
on conflict (osm_id) do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'vidrio' from puntos_reciclaje where osm_id = 'node/13724446476'
on conflict do nothing;

insert into puntos_reciclaje (nombre, direccion, comuna, lat, lng, fuente, osm_id, tipo_punto, creado_por)
select 'Contenedor de reciclaje', null, null, -33.452864, -70.657629, 'osm', 'node/13724466927', 'contenedor', null
where not exists (
  select 1 from puntos_reciclaje p
  where st_dwithin(p.geog, st_setsrid(st_makepoint(-70.657629, -33.452864), 4326)::geography, 30)
)
on conflict (osm_id) do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'vidrio' from puntos_reciclaje where osm_id = 'node/13724466927'
on conflict do nothing;

insert into puntos_reciclaje (nombre, direccion, comuna, lat, lng, fuente, osm_id, tipo_punto, creado_por)
select 'Contenedor de reciclaje', null, null, -33.452333, -70.652934, 'osm', 'node/13724491512', 'contenedor', null
where not exists (
  select 1 from puntos_reciclaje p
  where st_dwithin(p.geog, st_setsrid(st_makepoint(-70.652934, -33.452333), 4326)::geography, 30)
)
on conflict (osm_id) do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'vidrio' from puntos_reciclaje where osm_id = 'node/13724491512'
on conflict do nothing;

insert into puntos_reciclaje (nombre, direccion, comuna, lat, lng, fuente, osm_id, tipo_punto, creado_por)
select 'Contenedor de reciclaje', null, null, -33.451514, -70.652852, 'osm', 'node/13724491513', 'contenedor', null
where not exists (
  select 1 from puntos_reciclaje p
  where st_dwithin(p.geog, st_setsrid(st_makepoint(-70.652852, -33.451514), 4326)::geography, 30)
)
on conflict (osm_id) do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'vidrio' from puntos_reciclaje where osm_id = 'node/13724491513'
on conflict do nothing;

insert into puntos_reciclaje (nombre, direccion, comuna, lat, lng, fuente, osm_id, tipo_punto, creado_por)
select 'Contenedor de reciclaje', null, null, -33.451336, -70.650583, 'osm', 'node/13724501189', 'contenedor', null
where not exists (
  select 1 from puntos_reciclaje p
  where st_dwithin(p.geog, st_setsrid(st_makepoint(-70.650583, -33.451336), 4326)::geography, 30)
)
on conflict (osm_id) do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'vidrio' from puntos_reciclaje where osm_id = 'node/13724501189'
on conflict do nothing;

insert into puntos_reciclaje (nombre, direccion, comuna, lat, lng, fuente, osm_id, tipo_punto, creado_por)
select 'Contenedor de reciclaje', null, null, -33.511703, -70.691985, 'osm', 'node/13726278314', 'contenedor', null
where not exists (
  select 1 from puntos_reciclaje p
  where st_dwithin(p.geog, st_setsrid(st_makepoint(-70.691985, -33.511703), 4326)::geography, 30)
)
on conflict (osm_id) do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'vidrio' from puntos_reciclaje where osm_id = 'node/13726278314'
on conflict do nothing;

insert into puntos_reciclaje (nombre, direccion, comuna, lat, lng, fuente, osm_id, tipo_punto, creado_por)
select 'Contenedor de reciclaje', null, null, -33.467719, -70.642431, 'osm', 'node/13783165801', 'contenedor', null
where not exists (
  select 1 from puntos_reciclaje p
  where st_dwithin(p.geog, st_setsrid(st_makepoint(-70.642431, -33.467719), 4326)::geography, 30)
)
on conflict (osm_id) do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'vidrio' from puntos_reciclaje where osm_id = 'node/13783165801'
on conflict do nothing;

insert into puntos_reciclaje (nombre, direccion, comuna, lat, lng, fuente, osm_id, tipo_punto, creado_por)
select 'Contenedor de reciclaje', null, null, -33.337175, -70.290194, 'osm', 'node/14001196634', 'contenedor', null
where not exists (
  select 1 from puntos_reciclaje p
  where st_dwithin(p.geog, st_setsrid(st_makepoint(-70.290194, -33.337175), 4326)::geography, 30)
)
on conflict (osm_id) do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'vidrio' from puntos_reciclaje where osm_id = 'node/14001196634'
on conflict do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'papel' from puntos_reciclaje where osm_id = 'node/14001196634'
on conflict do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'plastico' from puntos_reciclaje where osm_id = 'node/14001196634'
on conflict do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'latas' from puntos_reciclaje where osm_id = 'node/14001196634'
on conflict do nothing;

insert into puntos_reciclaje (nombre, direccion, comuna, lat, lng, fuente, osm_id, tipo_punto, creado_por)
select 'municipalidad de maipú', null, null, -33.480885, -70.76057, 'osm', 'node/14025104718', 'punto_limpio', null
where not exists (
  select 1 from puntos_reciclaje p
  where st_dwithin(p.geog, st_setsrid(st_makepoint(-70.76057, -33.480885), 4326)::geography, 30)
)
on conflict (osm_id) do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'vidrio' from puntos_reciclaje where osm_id = 'node/14025104718'
on conflict do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'papel' from puntos_reciclaje where osm_id = 'node/14025104718'
on conflict do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'plastico' from puntos_reciclaje where osm_id = 'node/14025104718'
on conflict do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'latas' from puntos_reciclaje where osm_id = 'node/14025104718'
on conflict do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'tetra_pak' from puntos_reciclaje where osm_id = 'node/14025104718'
on conflict do nothing;

insert into puntos_reciclaje (nombre, direccion, comuna, lat, lng, fuente, osm_id, tipo_punto, creado_por)
select 'Contenedor de reciclaje', null, null, -33.534277, -70.663695, 'osm', 'node/14175954015', 'contenedor', null
where not exists (
  select 1 from puntos_reciclaje p
  where st_dwithin(p.geog, st_setsrid(st_makepoint(-70.663695, -33.534277), 4326)::geography, 30)
)
on conflict (osm_id) do nothing;

insert into puntos_reciclaje_materiales (punto_id, material_codigo)
select id, 'vidrio' from puntos_reciclaje where osm_id = 'node/14175954015'
on conflict do nothing;
commit;
