-- Soporte para importar puntos de reciclaje desde OpenStreetMap:
-- - fuente admite 'osm' además de 'oficial'/'comunidad'.
-- - osm_id identifica el elemento de origen (formato node/<id> o way/<id>)
--   para no duplicar en reimportaciones futuras (ver
--   backend/scripts/importar_osm_geojson.js).
-- - tipo_punto distingue punto limpio de contenedor, derivado de
--   recycling_type en OSM (centre -> punto_limpio, container -> contenedor).
-- - comuna pasa a ser nullable: OSM no siempre trae addr:city y el proyecto
--   no usa geocodificación externa para completarla.
-- No se agrega índice espacial nuevo: puntos_reciclaje_geog_idx (gist sobre
-- geog, ver 20260908232413_puntos_reciclaje.sql) ya cubre las coordenadas.

alter table puntos_reciclaje
  alter column comuna drop not null;

alter table puntos_reciclaje
  drop constraint puntos_reciclaje_fuente_check;

alter table puntos_reciclaje
  add constraint puntos_reciclaje_fuente_check check (fuente in ('oficial', 'comunidad', 'osm'));

alter table puntos_reciclaje
  add column osm_id text unique;

alter table puntos_reciclaje
  add column tipo_punto text check (tipo_punto is null or tipo_punto in ('punto_limpio', 'contenedor'));

comment on column puntos_reciclaje.osm_id is
  'Identificador OSM (node/<id> o way/<id>). Nulo para puntos que no vienen de OSM. Único para poder reimportar sin duplicar.';

comment on column puntos_reciclaje.tipo_punto is
  'Deriva de recycling_type de OSM: centre -> punto_limpio, container -> contenedor. Nulo si OSM no lo especifica.';
