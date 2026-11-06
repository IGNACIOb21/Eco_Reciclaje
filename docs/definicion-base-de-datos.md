# Definición de base de datos — Recircula

Este documento detalla el esquema de PostgreSQL/Supabase del proyecto: tipos, constraints y el estado de implementación de cada tabla. Complementa la descripción de alto nivel en `CLAUDE.md`.

## Implementado

Migración: `backend/supabase/migrations/20260908232413_puntos_reciclaje.sql`. Datos de demostración: `backend/supabase/seed.sql` (49 puntos: 7 por comuna en Santiago, Providencia, Ñuñoa, La Reina, Las Condes, Peñalolén y Macul).

### `materiales`

Catálogo fijo de materiales aceptados.

| Columna  | Tipo      | Constraints                  |
|----------|-----------|-------------------------------|
| `codigo` | `text`    | PK. Valores: `vidrio`, `papel`, `plastico`, `metal`, `pilas`, `latas`, `tetra_pak` |
| `nombre` | `text`    | `not null` — etiqueta legible |
| `orden`  | `smallint`| `not null default 0` — orden de despliegue en UI |

RLS: lectura pública (`select` para cualquiera). Sin políticas de escritura — el catálogo se modifica solo vía migraciones.

### `puntos_reciclaje`

| Columna                  | Tipo                        | Constraints |
|---------------------------|------------------------------|-------------|
| `id`                       | `uuid`                       | PK, `default gen_random_uuid()` |
| `nombre`                   | `text`                       | `not null` |
| `direccion`                | `text`                       | nullable |
| `comuna`                   | `text`                       | `not null` — texto libre, no enum (indexada) |
| `lat`                      | `double precision`           | `not null`, `check between -90 and 90` |
| `lng`                      | `double precision`           | `not null`, `check between -180 and 180` |
| `geog`                     | `geography(point,4326)`      | columna generada (`generated always as ... stored`) desde `lat`/`lng`, indexada con GiST — es la que usa PostGIS para distancia/radio |
| `fuente`                   | `text`                       | `not null default 'comunidad'`, `check in ('oficial','comunidad')` |
| `estado_actual`            | `text`                       | `not null default 'disponible'`, `check in ('disponible','lleno','danado','sin_senalizacion','mal_mantenimiento','fuera_de_uso')` |
| `calificacion_promedio`    | `numeric(2,1)`               | `not null default 0`, `check between 0 and 5` |
| `num_calificaciones`       | `integer`                    | `not null default 0`, `check >= 0` |
| `creado_por`               | `uuid`                       | FK → `auth.users(id)`, nullable |
| `creado_en`                | `timestamptz`                | `not null default now()` |

**Simplificación deliberada:** `estado_actual`, `calificacion_promedio` y `num_calificaciones` viven denormalizados en esta tabla por ahora, en vez de derivarse de `reportes_estado`/`calificaciones` (ver sección Pendiente). Es correcto para el mapa/filtros de hoy; cuando se construyan esas features, estos campos pasan a calcularse (trigger o vista) a partir del historial real en vez de escribirse directo.

RLS: lectura pública; inserción solo si `auth.uid() is not null` (cualquier sesión autenticada, incluida anónima). Sin políticas de `update`/`delete` todavía.

### `puntos_reciclaje_materiales`

Relación muchos-a-muchos entre puntos y materiales.

| Columna            | Tipo   | Constraints |
|---------------------|--------|-------------|
| `punto_id`           | `uuid` | FK → `puntos_reciclaje(id)` `on delete cascade` |
| `material_codigo`    | `text` | FK → `materiales(codigo)` `on delete restrict` |

PK compuesta `(punto_id, material_codigo)`. Índice adicional por `material_codigo` para filtrar por material eficientemente. RLS: lectura pública, inserción solo autenticado.

### Función RPC `puntos_cercanos`

```
puntos_cercanos(
  p_lat double precision,
  p_lng double precision,
  radio_km double precision default 5,
  comuna_filtro text default null,
  materiales_filtro text[] default null,
  solo_disponibles boolean default false,
  calificacion_minima numeric default 0
) returns table (... , distancia_km double precision)
```

Calcula puntos dentro de `radio_km` de `(p_lat, p_lng)` usando `ST_DWithin`/`ST_Distance` sobre la columna `geog`, con filtros opcionales de comuna, materiales (coincide si el punto tiene al menos uno de los indicados), disponibilidad y calificación mínima. Ordena por distancia ascendente. **No está limitada a las 7 comunas de la demo** — `comuna_filtro` es un parámetro opcional de la función, no una restricción estructural; funciona con cualquier coordenada y cualquier comuna que exista en la tabla.

Los parámetros llevan el prefijo `p_` para no colisionar con las columnas homónimas `lat`/`lng` de `puntos_reciclaje` (un choque real que causaba que la función midiera la distancia de cada punto consigo mismo — se detectó y corrigió validando la migración contra un Postgres+PostGIS descartable antes de darla por buena).

`GRANT EXECUTE` a `anon` y `authenticated`.

## Pendiente (diseño futuro, sin migración todavía)

Tablas descritas en `CLAUDE.md` que no se necesitan para el mapa/filtros actual y cuyo esquema detallado se define cuando se construya cada feature:

- **`usuarios`** — perfil de gamificación (device_id, email nullable, puntos_totales). `creado_por` en `puntos_reciclaje` referencia directamente `auth.users` de Supabase mientras tanto; esta tabla se suma cuando se implemente perfil/niveles con backend real.
- **`reportes_estado`** — histórico de reportes por punto (categorías: disponible, lleno, dañado, sin señalización, mal mantenimiento, fuera de uso). Reemplazará el campo denormalizado `estado_actual`.
- **`calificaciones`** — puntaje 1-5 por usuario y punto, único por `(punto, usuario)`. Reemplazará `calificacion_promedio`/`num_calificaciones` denormalizados.
- **`transacciones_puntos`** — ledger de movimientos del sistema de puntos/niveles.
