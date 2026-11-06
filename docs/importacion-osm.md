# Importación de puntos desde OpenStreetMap

## Fuente

[OpenStreetMap](https://www.openstreetmap.org), extraído vía [Overpass turbo](https://overpass-turbo.eu/) (`generator: overpass-turbo` en el GeoJSON).

- **Archivo**: `backend/data/osm/rm_reciclaje_AAAA-MM-DD.geojson` (256 features, todas `amenity=recycling` con geometría `Point`; en ways, `@geometry: center` — Overpass ya entrega el centroide).
- **Fecha del extract**: `timestamp` embebido en el GeoJSON = `2026-09-22T08:45:51Z`. El nombre de archivo (`AAAA-MM-DD`) es un placeholder, no la fecha real — conviene renombrarlo a `rm_reciclaje_2026-09-22.geojson` en la próxima actualización.
- **Consulta usada**: el archivo no guarda el texto de la consulta Overpass QL (Overpass turbo no lo embebe en el export). Por el contenido, corresponde a `amenity=recycling` (nodos y ways) acotado a la Región Metropolitana. Si se conserva el enlace o el texto de la consulta original de Overpass turbo, agregarlo acá para poder repetirla igual en el futuro.

## Licencia y atribución

Los datos están bajo **ODbL** (Open Database License), como indica el propio GeoJSON: *"The data included in this document is from www.openstreetmap.org. The data is made available under ODbL."*

Esto obliga a mostrar la atribución **"© colaboradores de OpenStreetMap"** en cualquier lugar donde la app o el panel muestren estos puntos (ficha de punto, mapa, o un aviso legal general) — no basta con dejarlo solo en este documento.

## Proceso de importación

1. `backend/scripts/importar_osm_geojson.js` lee el GeoJSON y genera `backend/supabase/seed_osm.sql` (no inserta directo en la base).
2. El SQL generado se aplica a mano contra la base local/remota. Es idempotente: cada punto se omite si ya existe otro punto a menos de 30 m (`st_dwithin` sobre `geog`) o si su `osm_id` ya fue importado antes (`on conflict (osm_id) do nothing`), así que se puede reimportar sin duplicar.
3. Los puntos importados quedan con `fuente = 'osm'`, `osm_id` (formato `node/<id>` o `way/<id>`, para poder actualizarlos desde OSM en el futuro) y `tipo_punto` (`punto_limpio` si `recycling_type=centre`, `contenedor` si `recycling_type=container`, `null` si OSM no lo especifica).
4. `comuna` queda en `null` cuando OSM no trae `addr:city` o su valor no coincide con ninguna comuna de la Región Metropolitana — no se usa geocodificación externa (Nominatim u otro) para completarla.
5. Puntos sin ningún material reconocido (ni un solo `recycling:*=yes` mapeado a `vidrio`/`papel`/`plastico`/`latas`/`metal`/`pilas`/`tetra_pak`) no se importan. Esto incluye tanto los que no traen ninguna etiqueta `recycling:*` como los que traen etiquetas fuera del mapeo actual (ej. `green_waste`, `cartons`, `cooking_oil`, `computers`) — el script reporta el detalle para decidir después si conviene sumar esos materiales al catálogo.

Ver `backend/scripts/importar_osm_geojson.js` para el mapeo exacto de etiquetas y el reporte de conteos (features descartadas, por material, sin comuna, etc.) que imprime cada vez que se corre.
