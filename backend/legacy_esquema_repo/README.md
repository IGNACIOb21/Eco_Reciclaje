# Esquema anterior del repo (archivado 2026-10-01)

Migraciones y seeds del primer esquema (`materiales`, `puntos_reciclaje`,
RPC `puntos_cercanos`). **Nunca se aplicaron al proyecto de la nube**, que usa
el esquema del modelo UML (`usuario`, `punto_reciclaje`, `categoria_residuo`,
...). Se decidió que la nube es la fuente de verdad, así que se sacaron de
`supabase/migrations/` para que `supabase db pull` genere la migración base.

Se conservan como referencia para portar al esquema nuevo:
- La función de cercanía con PostGIS (`puntos_cercanos`) y su índice GIST.
- Los 428 puntos de OpenStreetMap (`seed_osm.sql`) y los 49 del seed manual.
  `scripts/importar_osm_geojson.js` todavía genera SQL para estas tablas
  antiguas; hay que adaptarlo a `punto_reciclaje` / `punto_categoria`.

No mover de vuelta a `supabase/migrations/` ni aplicar contra la nube.

## `20261005120000_usuario_nombre.sql` (archivada 2026-10-07)

Agregaba `usuario.nombre`. Nunca se aplicó a la nube y está escrita contra la
tabla `usuario`, que no existe en el esquema remoto real (`usuarios`). La APK
ahora guarda el nombre real en `user_metadata` de Supabase Auth, así que no
hace falta. No aplicar.
