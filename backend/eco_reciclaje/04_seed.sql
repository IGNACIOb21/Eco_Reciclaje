-- Proyecto_Eco_reciclaje (shkdlkbhpkbrfxemctdj)
-- Paso 4: datos base. Roles, categorías (con el código que usa la app y las
-- clases del modelo de Joaquín), reglas de puntuación, entidades y los puntos
-- de reciclaje de la Región Metropolitana importados de OpenStreetMap.
-- Fuente de los puntos: © colaboradores de OpenStreetMap, licencia ODbL
-- (tomados de rebin/backend/remoto/seed_osm.sql).
-- Idempotente: no duplica lo que ya existe.

begin;

insert into rol (nombre, descripcion) values
  ('ciudadano', 'Usuario de la app'),
  ('administrador', 'Administra puntos, beneficios y reportes'),
  ('trabajador', 'Atiende tickets de mantenimiento')
on conflict (nombre) do nothing;

-- Mismos colores que TipoMaterial en la app. Las tres últimas son clases del
-- modelo de Joaquín que la app aún no tiene como material del mapa.
insert into categoria_residuo (nombre_categoria, codigo, codigo_color, descripcion_categoria, destino_reciclaje) values
  ('Vidrio',           'vidrio',      '#2E9E5B', 'Botellas y frascos de vidrio, sin tapas.', 'Se funde para hacer envases nuevos.'),
  ('Papel y cartón',   'papel',       '#2E7DD1', 'Papel, diarios, cajas y cartón secos y limpios.', 'Se convierte en pulpa para papel reciclado.'),
  ('Plástico',         'plastico',    '#F2B705', 'Botellas y envases plásticos vacíos y enjuagados.', 'Se tritura y funde para nuevos productos.'),
  ('Metal',            'metal',       '#8C8F94', 'Objetos y chatarra metálica.', 'Se funde y reutiliza en la industria.'),
  ('Pilas',            'pilas',       '#E0483F', 'Pilas y baterías. Nunca a la basura común.', 'Tratamiento especial de residuos peligrosos.'),
  ('Latas',            'latas',       '#E07B39', 'Latas de aluminio y hojalata, vacías y aplastadas.', 'Se funden para fabricar latas nuevas.'),
  ('Tetra Pak',        'tetra_pak',   '#7C4DBE', 'Envases de leche y jugo, enjuagados y aplastados.', 'Se separan cartón, aluminio y plástico.'),
  ('Aceite usado',     'aceite',      '#A07A2C', 'Aceite de cocina usado, frío y en botella cerrada.', 'Se transforma en biodiésel.'),
  ('Ropa y textiles',  'textil',      '#9C6ADE', 'Ropa y telas. Si está en buen estado, mejor donarla.', 'Reutilización o fibra textil.'),
  ('Electrónicos',     'electronicos','#3B82C4', 'Aparatos eléctricos y electrónicos en desuso.', 'Recuperación de metales y componentes.'),
  ('Calzado',          'calzado',     '#8B5E3C', 'Zapatos y zapatillas. Si están en buen estado, mejor donarlos.', 'Reutilización o material de relleno.')
on conflict (nombre_categoria) do update
  set codigo = excluded.codigo,
      codigo_color = excluded.codigo_color;

insert into entidad_administradora (nombre_entidad, tipo_entidad, correo_contacto)
select v.nombre, v.tipo::tipo_entidad_enum, null
from (values
  ('Eco Reciclaje', 'organizacion'),
  ('OpenStreetMap (por confirmar)', 'otra')
) as v(nombre, tipo)
where not exists (select 1 from entidad_administradora e where e.nombre_entidad = v.nombre);

-- Rebin Points por artículo reciclado, vigentes desde el lanzamiento.
insert into regla_puntuacion (categoria_residuo_id, puntos_unitarios, fecha_inicio_vigencia)
select c.categoria_residuo_id, v.puntos, date '2026-01-01'
from (values
  ('vidrio', 10), ('papel', 8), ('plastico', 10), ('metal', 12), ('pilas', 15),
  ('latas', 10), ('tetra_pak', 10), ('aceite', 15), ('textil', 10),
  ('electronicos', 20), ('calzado', 10)
) as v(codigo, puntos)
join categoria_residuo c on c.codigo = v.codigo
where not exists (
  select 1 from regla_puntuacion r where r.categoria_residuo_id = c.categoria_residuo_id
);

-- Puntos de OpenStreetMap. Se omite un punto si su osm_id ya existe.
with candidatos (osm_id, nombre, direccion, comuna, lat, lng, categorias) as (
  values
  ('way/544370772', 'Punto Limpio Parque de los Reyes Avenida Presidente Balmaceda', 'Avenida Presidente Balmaceda', 'Santiago', -33.428326, -70.668573, array['Papel y cartón', 'Plástico']::text[]),
  ('way/646368338', 'Romerelli Tucapel', 'Tucapel 1695', 'La Pintana', -33.588426, -70.656612, array['Latas', 'Metal']::text[]),
  ('way/764468589', 'Centro Laboral Oreste Plath Avenida Lo Errázuriz', 'Avenida Lo Errázuriz 2701', 'Cerrillos', -33.483378, -70.724195, array['Vidrio', 'Papel y cartón', 'Plástico', 'Latas', 'Metal']::text[]),
  ('way/915903043', 'Punto Limpio Colegio Colonial de Pirque Avenida Concha y Toro s/n', 'Avenida Concha y Toro s/n', 'Pirque', -33.630457, -70.572266, array['Vidrio', 'Papel y cartón', 'Plástico', 'Latas']::text[]),
  ('way/992262400', 'Punto Limpio Santiago Recicla Costaneras Férreas', 'Costaneras Férreas 0495', 'Quilicura', -33.35479, -70.714138, array['Vidrio', 'Tetra Pak']::text[]),
  ('way/1330785467', 'Punto Limpio Juan Antonio Ríos Avenida Presidente Eduardo Frei Montalva', 'Avenida Presidente Eduardo Frei Montalva', 'Independencia', -33.423143, -70.672878, array['Vidrio', 'Papel y cartón', 'Plástico']::text[]),
  ('node/2287552493', 'Cooperativa de reciclaje La Reina Jorge Alessandri', 'Jorge Alessandri 680', 'Santiago', -33.457542, -70.545817, array['Papel y cartón', 'Latas', 'Metal', 'Pilas']::text[]),
  ('node/3200714438', 'Esquina El Solar Avenida Consistorial', 'Avenida Consistorial', 'Peñalolén', -33.487197, -70.549171, array['Vidrio']::text[]),
  ('node/3200714439', 'Recinto Municipal Grecia', 'Grecia', 'Peñalolén', -33.476995, -70.5417, array['Vidrio', 'Papel y cartón', 'Plástico']::text[]),
  ('node/3200714440', 'Punto de reciclaje Avenida Lincoln', 'Avenida Lincoln 1410', 'Lo Espejo', -33.514999, -70.673557, array['Vidrio']::text[]),
  ('node/3200714441', 'Punto de reciclaje Avenida Adolfo Lopez Mateo', 'Avenida Adolfo Lopez Mateo 1595', 'Lo Espejo', -33.522578, -70.679217, array['Vidrio']::text[]),
  ('node/3200714442', 'Punto de reciclaje Avenida Lo Ovalle', 'Avenida Lo Ovalle 2356', 'Lo Espejo', -33.508494, -70.677383, array['Vidrio']::text[]),
  ('node/3200714443', 'Centro Integral de Reducción de Residuos Sólidos Punta Arenas', 'Punta Arenas 6711', 'La Granja', -33.518451, -70.611548, array['Vidrio', 'Papel y cartón', 'Plástico']::text[]),
  ('node/3200714444', 'Punto de reciclaje Avenida Valparaíso', 'Avenida Valparaíso 7171', 'Lo Espejo', -33.516589, -70.678453, array['Vidrio']::text[]),
  ('node/3200714445', 'Punto de reciclaje Avenida Central', 'Avenida Central 8321', 'Lo Espejo', -33.522808, -70.698378, array['Plástico']::text[]),
  ('node/3200714447', 'Punto Limpio Club de Campo Entel', null, 'Peñalolén', -33.499687, -70.574316, array['Vidrio', 'Papel y cartón', 'Plástico']::text[]),
  ('node/3200714448', 'Punto Limpio Colegio Pedro de Valdivia', null, 'Peñalolén', -33.491866, -70.576312, array['Vidrio', 'Papel y cartón', 'Plástico']::text[]),
  ('node/3200714450', 'Punto Limpio Piedra Roja Avenida Paseo Colina Sur', 'Avenida Paseo Colina Sur 14500', 'Colina', -33.276871, -70.62662, array['Vidrio', 'Papel y cartón', 'Plástico']::text[]),
  ('node/3200714451', 'Punto Limpio Walmart Quilin', null, 'Peñalolén', -33.486146, -70.579027, array['Vidrio', 'Papel y cartón', 'Plástico']::text[]),
  ('node/3200714456', 'Punto de reciclaje', null, 'Peñalolén', -33.498181, -70.560755, array['Vidrio', 'Papel y cartón', 'Plástico']::text[]),
  ('node/3200714457', 'Contenedor de reciclaje Los Presidentes', 'Los Presidentes', 'Peñalolén', -33.486771, -70.557037, array['Vidrio']::text[]),
  ('node/3200714458', 'Punto de reciclaje Avenida Santa María', 'Avenida Santa María', 'Vitacura', -33.377749, -70.572155, array['Vidrio', 'Papel y cartón', 'Plástico']::text[]),
  ('node/3200714459', 'Contenedor de reciclaje Costanera Sur San Josemaría Escrivá de Balaguer', 'Costanera Sur San Josemaría Escrivá de Balaguer', 'Vitacura', -33.379406, -70.572168, array['Vidrio', 'Papel y cartón', 'Plástico']::text[]),
  ('node/3200715961', 'Punto de reciclaje Talinay', 'Talinay', 'Peñalolén', -33.459023, -70.531819, array['Vidrio']::text[]),
  ('node/3200715962', 'Punto de reciclaje Orientales', 'Orientales', 'Peñalolén', -33.466962, -70.558662, array['Vidrio', 'Papel y cartón', 'Plástico']::text[]),
  ('node/3200715963', 'Punto de reciclaje Orientales', 'Orientales', 'Peñalolén', -33.469182, -70.553083, array['Vidrio']::text[]),
  ('node/3200715964', 'Punto de reciclaje Grecia', 'Grecia', 'Peñalolén', -33.469683, -70.575142, array['Vidrio']::text[]),
  ('node/3200715965', 'Punto de reciclaje Grecia', 'Grecia', 'Peñalolén', -33.47022, -70.57158, array['Vidrio']::text[]),
  ('node/3200715966', 'Punto de reciclaje Avenida Grecia', 'Avenida Grecia', 'Peñalolén', -33.47599, -70.54393, array['Vidrio']::text[]),
  ('node/3200715967', 'Punto de reciclaje El Duraznal', 'El Duraznal', 'Peñalolén', -33.47793, -70.565864, array['Vidrio']::text[]),
  ('node/3200715968', 'Punto de reciclaje Tobalaba', 'Tobalaba', 'Peñalolén', -33.48173, -70.558113, array['Vidrio']::text[]),
  ('node/3200715970', 'Contenedor de reciclaje Antupiren', 'Antupiren', 'Peñalolén', -33.483321, -70.534546, array['Vidrio', 'Papel y cartón']::text[]),
  ('node/3200715971', 'Punto de reciclaje Avenida Tobalaba', 'Avenida Tobalaba 13949', 'Peñalolén', -33.503556, -70.561241, array['Vidrio']::text[]),
  ('node/3200715973', 'Punto de reciclaje Avenida San Luis de Macul', 'Avenida San Luis de Macul', 'Peñalolén', -33.506188, -70.578568, array['Vidrio']::text[]),
  ('node/3200715976', 'Punto de reciclaje Avenida José Joaquin Prieto', 'Avenida José Joaquin Prieto', 'Lo Espejo', -33.509985, -70.671338, array['Vidrio']::text[]),
  ('node/3676456357', 'Punto de Reciclaje Avenida La Marina', 'Avenida La Marina 2500', 'Pedro Aguirre Cerda', -33.492552, -70.67047, array['Vidrio', 'Papel y cartón', 'Plástico']::text[]),
  ('node/5446265032', 'Punto Limpio Loreto Loreto', 'Loreto', 'Recoleta', -33.433915, -70.642377, array['Vidrio', 'Papel y cartón', 'Plástico']::text[]),
  ('node/5880053276', 'Punto de Reciclaje Tongoy', 'Tongoy 2500', 'Pedro Aguirre Cerda', -33.498804, -70.679357, array['Vidrio', 'Papel y cartón', 'Plástico']::text[]),
  ('node/5975047785', 'Punto Verde CESFAM Augusto d''Halmar', 'Augusto d''Halmar 555', 'El Bosque', -33.561098, -70.674362, array['Vidrio', 'Papel y cartón', 'Plástico', 'Latas']::text[]),
  ('node/6067180555', 'Romerelli Arzobispo Subercaseaux', 'Arzobispo Subercaseaux 4169', 'Estación Central', -33.466243, -70.690886, array['Latas', 'Metal']::text[]),
  ('node/6279081237', 'Romerelli Los Yacimientos', 'Los Yacimientos 640', 'Maipú', -33.527198, -70.740539, array['Latas', 'Metal']::text[]),
  ('node/10647331983', 'Punto Verde Los Sauces Portales', 'Portales', 'El Bosque', -33.562744, -70.663306, array['Vidrio', 'Papel y cartón', 'Latas', 'Pilas']::text[]),
  ('node/10647349900', 'Punto Verde Javiera Carrera', 'Javiera Carrera 550', 'El Bosque', -33.557397, -70.664443, array['Vidrio', 'Papel y cartón', 'Plástico', 'Latas', 'Pilas']::text[]),
  ('node/10647349902', 'Punto Verde OMIL General Korner', 'General Korner 286', 'El Bosque', -33.550428, -70.676867, array['Vidrio', 'Papel y cartón', 'Plástico', 'Latas', 'Pilas']::text[]),
  ('node/10647349904', 'Punto limpio Avenida Padre Hurtado', 'Avenida Padre Hurtado', 'El Bosque', -33.546813, -70.666643, array['Vidrio', 'Papel y cartón', 'Plástico', 'Latas', 'Pilas']::text[]),
  ('node/10823517336', 'Punto Limpio - Villa Macul Poeta Augusto Winter', 'Poeta Augusto Winter', 'Macul', -33.491165, -70.593631, array['Vidrio', 'Papel y cartón', 'Latas']::text[])
),
entidad as (
  select entidad_administradora_id as id
    from entidad_administradora
   where nombre_entidad = 'OpenStreetMap (por confirmar)'
),
nuevos as (
  insert into punto_reciclaje (
    nombre_punto, coordenada_latitud, coordenada_longitud, direccion_completa,
    entidad_administradora_id, estado_operativo, comuna, osm_id
  )
  select left(c.nombre, 100), c.lat, c.lng, c.direccion, e.id, 'operativo', c.comuna, c.osm_id
    from candidatos c, entidad e
   where not exists (select 1 from punto_reciclaje p where p.osm_id = c.osm_id)
  returning punto_reciclaje_id, osm_id
)
insert into punto_categoria (punto_reciclaje_id, categoria_residuo_id)
select n.punto_reciclaje_id, cr.categoria_residuo_id
  from nuevos n
  join candidatos c on c.osm_id = n.osm_id
  cross join lateral unnest(c.categorias) as cat(nombre)
  join categoria_residuo cr on cr.nombre_categoria = cat.nombre
on conflict do nothing;

commit;
