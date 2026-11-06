#!/usr/bin/env node
'use strict';

// Convierte el GeoJSON exportado desde Overpass (amenity=recycling en la
// Región Metropolitana) a un archivo .sql de inserciones para
// puntos_reciclaje / puntos_reciclaje_materiales, siguiendo la misma
// convención que backend/supabase/seed.sql (insert ... values, sin ORM).
// No inserta directo en la base: solo genera el .sql, que se aplica a mano
// (ver backend/docs o el mensaje de este script al terminar).
//
// Uso:
//   node importar_osm_geojson.js [entrada.geojson] [salida.sql]
// Por defecto:
//   entrada = backend/data/osm/rm_reciclaje_AAAA-MM-DD.geojson
//   salida  = backend/supabase/seed_osm.sql
//
// Sin dependencias externas: solo módulos incluidos de Node (fs, path).

const fs = require('fs');
const path = require('path');

const ENTRADA_POR_DEFECTO = path.join(__dirname, '..', 'data', 'osm', 'rm_reciclaje_AAAA-MM-DD.geojson');
const SALIDA_POR_DEFECTO = path.join(__dirname, '..', 'supabase', 'seed_osm.sql');

// Rango razonable de la Región Metropolitana, para descartar puntos con
// coordenadas erróneas o fuera de zona.
const LAT_MIN = -34.3;
const LAT_MAX = -32.9;
const LNG_MIN = -71.8;
const LNG_MAX = -69.7;

// Mapeo fijo acordado: solo estas etiquetas recycling:*=yes cuentan.
// Los códigos son los que ya existen en la tabla materiales (ver
// backend/supabase/migrations/20260908232413_puntos_reciclaje.sql).
const MATERIAL_TAGS = {
  vidrio: ['recycling:glass_bottles', 'recycling:glass'],
  papel: ['recycling:paper', 'recycling:cardboard'],
  plastico: ['recycling:plastic_bottles', 'recycling:plastic', 'recycling:plastic_packaging'],
  latas: ['recycling:cans'],
  metal: ['recycling:scrap_metal'],
  pilas: ['recycling:batteries'],
  tetra_pak: ['recycling:beverage_cartons'],
};

// Comunas de la Región Metropolitana (forma canónica, con tilde) contra las
// que se valida addr:city. Si no calza con ninguna, comuna queda en null
// (no se usa geocodificación externa).
const RM_COMUNAS = [
  'Santiago', 'Cerrillos', 'Cerro Navia', 'Conchalí', 'El Bosque', 'Estación Central',
  'Huechuraba', 'Independencia', 'La Cisterna', 'La Florida', 'La Granja', 'La Pintana',
  'La Reina', 'Las Condes', 'Lo Barnechea', 'Lo Espejo', 'Lo Prado', 'Macul', 'Maipú',
  'Ñuñoa', 'Pedro Aguirre Cerda', 'Peñalolén', 'Providencia', 'Pudahuel', 'Quilicura',
  'Quinta Normal', 'Recoleta', 'Renca', 'San Joaquín', 'San Miguel', 'San Ramón',
  'Vitacura', 'Puente Alto', 'Pirque', 'San José de Maipo', 'Colina', 'Lampa', 'Tiltil',
  'San Bernardo', 'Buin', 'Calera de Tango', 'Paine', 'Melipilla', 'Alhué', 'Curacaví',
  'María Pinto', 'San Pedro', 'Talagante', 'El Monte', 'Isla de Maipo', 'Padre Hurtado',
  'Peñaflor',
];

function normalizarComuna(s) {
  return s
    .normalize('NFKD')
    .replace(/[̀-ͯ]/g, '') // quita tildes
    .toLowerCase()
    .trim()
    .replace(/^comuna de /, '');
}

const COMUNAS_POR_NOMBRE_NORMALIZADO = new Map(
  RM_COMUNAS.map((c) => [normalizarComuna(c), c])
);

function resolverComuna(addrCity) {
  if (!addrCity) return { comuna: null, motivo: 'sin_addr_city' };
  const match = COMUNAS_POR_NOMBRE_NORMALIZADO.get(normalizarComuna(addrCity));
  if (match) return { comuna: match, motivo: 'match' };
  return { comuna: null, motivo: 'no_coincide', valorOriginal: addrCity };
}

function escaparSql(s) {
  return s.replace(/'/g, "''");
}

function sqlTexto(s) {
  return s === null || s === undefined ? 'null' : `'${escaparSql(s)}'`;
}

function resolverTipoPunto(recyclingType) {
  if (recyclingType === 'centre') return 'punto_limpio';
  if (recyclingType === 'container') return 'contenedor';
  return null;
}

function resolverNombre(props, tipoPunto) {
  const nombreBase =
    props.name ||
    (tipoPunto === 'punto_limpio'
      ? 'Punto limpio'
      : tipoPunto === 'contenedor'
      ? 'Contenedor de reciclaje'
      : 'Punto de reciclaje');
  const calle = props['addr:street'];
  return calle ? `${nombreBase} ${calle}` : nombreBase;
}

function resolverDireccion(props) {
  const calle = props['addr:street'];
  const numero = props['addr:housenumber'];
  if (calle && numero) return `${calle} ${numero}`;
  if (calle) return calle;
  return null;
}

function main() {
  const entrada = process.argv[2] || ENTRADA_POR_DEFECTO;
  const salida = process.argv[3] || SALIDA_POR_DEFECTO;

  const geojson = JSON.parse(fs.readFileSync(entrada, 'utf8'));
  const features = geojson.features || [];

  const stats = {
    total: features.length,
    fueraDeRango: 0,
    sinMaterial: {
      sinNingunaEtiqueta: 0,
      conEtiquetasNoReconocidas: 0,
      etiquetasNoReconocidas: new Map(), // tag -> count
    },
    importados: 0,
    porMaterial: new Map(),
    comuna: {
      conComuna: 0,
      sinAddrCity: 0,
      addrCityNoCoincide: new Map(), // valor original -> count
    },
    tipoPunto: new Map(),
  };

  const sentencias = [];

  for (const feature of features) {
    const props = feature.properties || {};
    const coords = (feature.geometry && feature.geometry.coordinates) || null;
    if (!coords) continue;
    const [lng, lat] = coords;

    if (lat < LAT_MIN || lat > LAT_MAX || lng < LNG_MIN || lng > LNG_MAX) {
      stats.fueraDeRango += 1;
      continue;
    }

    const materiales = Object.entries(MATERIAL_TAGS)
      .filter(([, tags]) => tags.some((t) => props[t] === 'yes'))
      .map(([codigo]) => codigo);

    if (materiales.length === 0) {
      const tagsPresentes = Object.keys(props).filter(
        (k) => k.startsWith('recycling:') && props[k] === 'yes'
      );
      if (tagsPresentes.length === 0) {
        stats.sinMaterial.sinNingunaEtiqueta += 1;
      } else {
        stats.sinMaterial.conEtiquetasNoReconocidas += 1;
        for (const tag of tagsPresentes) {
          stats.sinMaterial.etiquetasNoReconocidas.set(
            tag,
            (stats.sinMaterial.etiquetasNoReconocidas.get(tag) || 0) + 1
          );
        }
      }
      continue;
    }

    const osmId = props['@id'] || feature.id;
    if (!osmId) continue; // sin identificador OSM no hay forma de deduplicar en reimportaciones

    const tipoPunto = resolverTipoPunto(props.recycling_type);
    stats.tipoPunto.set(tipoPunto || '(sin especificar)', (stats.tipoPunto.get(tipoPunto || '(sin especificar)') || 0) + 1);

    const { comuna, motivo, valorOriginal } = resolverComuna(props['addr:city']);
    if (comuna) {
      stats.comuna.conComuna += 1;
    } else if (motivo === 'sin_addr_city') {
      stats.comuna.sinAddrCity += 1;
    } else {
      stats.comuna.addrCityNoCoincide.set(
        valorOriginal,
        (stats.comuna.addrCityNoCoincide.get(valorOriginal) || 0) + 1
      );
    }

    const nombre = resolverNombre(props, tipoPunto);
    const direccion = resolverDireccion(props);
    const latRedondeada = Number(lat.toFixed(6));
    const lngRedondeada = Number(lng.toFixed(6));

    stats.importados += 1;
    for (const codigo of materiales) {
      stats.porMaterial.set(codigo, (stats.porMaterial.get(codigo) || 0) + 1);
    }

    sentencias.push(
      `insert into puntos_reciclaje (nombre, direccion, comuna, lat, lng, fuente, osm_id, tipo_punto, creado_por)\n` +
        `select ${sqlTexto(nombre)}, ${sqlTexto(direccion)}, ${sqlTexto(comuna)}, ${latRedondeada}, ${lngRedondeada}, 'osm', ${sqlTexto(osmId)}, ${sqlTexto(tipoPunto)}, null\n` +
        `where not exists (\n` +
        `  select 1 from puntos_reciclaje p\n` +
        `  where st_dwithin(p.geog, st_setsrid(st_makepoint(${lngRedondeada}, ${latRedondeada}), 4326)::geography, 30)\n` +
        `)\n` +
        `on conflict (osm_id) do nothing;`
    );

    for (const codigo of materiales) {
      sentencias.push(
        `insert into puntos_reciclaje_materiales (punto_id, material_codigo)\n` +
          `select id, ${sqlTexto(codigo)} from puntos_reciclaje where osm_id = ${sqlTexto(osmId)}\n` +
          `on conflict do nothing;`
      );
    }
  }

  const encabezado =
    `-- Puntos de reciclaje importados desde OpenStreetMap (Overpass).\n` +
    `-- Generado por backend/scripts/importar_osm_geojson.js a partir de\n` +
    `-- ${path.relative(path.join(__dirname, '..', '..'), entrada)}\n` +
    `-- No editar a mano: si cambian los datos de origen, correr el script de nuevo.\n` +
    `-- Fuente: © colaboradores de OpenStreetMap, datos bajo licencia ODbL.\n` +
    `-- Generado: ${new Date().toISOString()}\n` +
    `--\n` +
    `-- Idempotente: cada punto se omite si ya existe otro a menos de 30m\n` +
    `-- (st_dwithin sobre geog) o si su osm_id ya fue importado antes.\n\n` +
    `begin;\n\n`;

  const pie = `\ncommit;\n`;

  fs.writeFileSync(salida, encabezado + sentencias.join('\n\n') + pie, 'utf8');

  // --- Reporte ---
  console.log(`Features totales:          ${stats.total}`);
  console.log(`Fuera de rango RM:         ${stats.fueraDeRango}`);
  console.log(`Sin material reconocido:   ${stats.sinMaterial.sinNingunaEtiqueta + stats.sinMaterial.conEtiquetasNoReconocidas}`);
  console.log(`  - sin ninguna etiqueta recycling:*:      ${stats.sinMaterial.sinNingunaEtiqueta}`);
  console.log(`  - con etiquetas no reconocidas:          ${stats.sinMaterial.conEtiquetasNoReconocidas}`);
  if (stats.sinMaterial.etiquetasNoReconocidas.size > 0) {
    console.log(`    detalle de etiquetas no reconocidas (recycling:*=yes):`);
    for (const [tag, count] of [...stats.sinMaterial.etiquetasNoReconocidas.entries()].sort((a, b) => b[1] - a[1])) {
      console.log(`      ${tag}: ${count}`);
    }
  }
  console.log(`Candidatos generados (SQL): ${stats.importados}`);
  console.log(`  por material:`);
  for (const [codigo, count] of [...stats.porMaterial.entries()].sort((a, b) => b[1] - a[1])) {
    console.log(`    ${codigo}: ${count}`);
  }
  console.log(`  por tipo_punto:`);
  for (const [tipo, count] of [...stats.tipoPunto.entries()].sort((a, b) => b[1] - a[1])) {
    console.log(`    ${tipo}: ${count}`);
  }
  console.log(`Comuna:`);
  console.log(`  con comuna reconocida:    ${stats.comuna.conComuna}`);
  console.log(`  sin addr:city:            ${stats.comuna.sinAddrCity}`);
  console.log(`  addr:city sin coincidir:  ${[...stats.comuna.addrCityNoCoincide.values()].reduce((a, b) => a + b, 0)}`);
  if (stats.comuna.addrCityNoCoincide.size > 0) {
    for (const [valor, count] of stats.comuna.addrCityNoCoincide.entries()) {
      console.log(`    "${valor}": ${count}`);
    }
  }
  console.log(`\nSQL escrito en: ${salida}`);
  console.log(`Nota: la exclusión de puntos existentes a <30m se resuelve al aplicar el SQL contra la base (st_dwithin), no en este reporte.`);
}

main();
