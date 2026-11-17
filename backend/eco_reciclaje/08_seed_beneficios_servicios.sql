-- Proyecto_Eco_reciclaje (shkdlkbhpkbrfxemctdj)
-- Paso 8: datos de ejemplo para Beneficios (canjeo_beneficio) y Servicios
-- (servicio_tercero), que estaban vacíos. Son datos de demostración: los
-- nombres y contactos son ficticios.
-- Idempotente: no duplica (se compara por nombre) y actualiza los textos.
-- Materiales: códigos de categoria_residuo.codigo que la app conoce
-- (vidrio, papel, plastico, metal, pilas, latas, tetra_pak, aceite).
-- Comunas: nombres exactos de la Región Metropolitana (como en la app).
-- Horario: jsonb día → tramo, con claves lun..dom ('lun-vie', 'sáb').

begin;

-- Beneficios: los administra la entidad 'Eco Reciclaje' (sembrada en 04).
-- cantidad_disponible null = sin tope de stock.
with v (nombre, descripcion, costo, stock) as (values
  ('Bolsa reutilizable Eco Reciclaje',
   'Bolsa de tela para tus compras. Retírala en el punto de entrega indicado al canjear.', 150, 50),
  ('Descuento 10% en tienda a granel',
   'Cupón de 10% de descuento en una compra en una tienda a granel adherida (ejemplo).', 200, null),
  ('Botella reutilizable',
   'Botella de acero inoxidable de 500 ml.', 400, 30),
  ('Kit de compostaje doméstico',
   'Compostera pequeña con guía para empezar a compostar en casa.', 800, 10),
  ('Entrada a taller de reciclaje creativo',
   'Cupo para un taller presencial de reutilización de materiales (ejemplo).', 300, 20),
  ('Plantar un árbol a tu nombre',
   'Aporte para plantar un árbol nativo en una campaña de reforestación (ejemplo).', 1000, null)
),
entidad as (
  select entidad_administradora_id as id
  from entidad_administradora
  where nombre_entidad = 'Eco Reciclaje'
  limit 1
),
actualizados as (
  update canjeo_beneficio b
  set descripcion = v.descripcion,
      costo_puntos = v.costo,
      activo = true
  from v
  where b.nombre_beneficio = v.nombre
  returning b.nombre_beneficio
)
insert into canjeo_beneficio
  (nombre_beneficio, descripcion, costo_puntos, cantidad_disponible, entidad_administradora_id, activo)
select v.nombre, v.descripcion, v.costo, v.stock, entidad.id, true
from v cross join entidad
where not exists (
  select 1 from canjeo_beneficio b where b.nombre_beneficio = v.nombre
);

-- Servicios de recolectores (ficticios), ya aprobados para que se listen.
with v (nombre, contacto, descripcion, comunas, materiales, domicilio, horario) as (values
  ('Reciclaje Vecinal Ñuñoa (ejemplo)', '+56 9 0000 0001',
   'Retiro a domicilio de papel, cartón y plástico limpios. Coordina por WhatsApp.',
   array['Ñuñoa', 'Providencia', 'La Reina'],
   array['papel', 'plastico'],
   true, '{"lun-vie": "9:00-18:00", "sáb": "10:00-14:00"}'::jsonb),
  ('Recolectora de Vidrio Sur (ejemplo)', '+56 9 0000 0002',
   'Retiramos botellas y frascos de vidrio. Mínimo una bolsa llena.',
   array['La Florida', 'Puente Alto', 'La Pintana'],
   array['vidrio'],
   true, '{"mar": "10:00-17:00", "jue": "10:00-17:00"}'::jsonb),
  ('Aceite Limpio RM (ejemplo)', 'contacto@ejemplo.cl',
   'Recibimos aceite de cocina usado, frío y en botella cerrada, para hacer biodiésel.',
   array['Santiago', 'Estación Central', 'Independencia', 'Recoleta'],
   array['aceite'],
   false, '{"lun-vie": "9:00-17:00"}'::jsonb),
  ('Latas y Metales Maipú (ejemplo)', '+56 9 0000 0004',
   'Compramos latas de aluminio y chatarra metálica. Retiro sobre 5 kg.',
   array['Maipú', 'Cerrillos', 'Pudahuel'],
   array['latas', 'metal'],
   true, '{"lun-sáb": "10:00-19:00"}'::jsonb),
  ('Punto Pilas Oriente (ejemplo)', '+56 9 0000 0005',
   'Recibimos pilas y baterías para su tratamiento seguro. Solo entrega en el local.',
   array['Las Condes', 'Vitacura', 'Lo Barnechea'],
   array['pilas'],
   false, '{"lun-vie": "10:00-18:00"}'::jsonb),
  ('Tetra y Más Peñalolén (ejemplo)', '+56 9 0000 0006',
   'Retiro de Tetra Pak, plástico y papel. Enjuagados y aplastados, por favor.',
   array['Peñalolén', 'Macul', 'La Reina'],
   array['tetra_pak', 'plastico', 'papel'],
   true, '{"mié": "9:00-13:00", "sáb": "9:00-13:00"}'::jsonb)
),
actualizados as (
  update servicio_tercero s
  set contacto = v.contacto,
      descripcion = v.descripcion,
      comunas = v.comunas,
      materiales = v.materiales,
      retira_a_domicilio = v.domicilio,
      horario = v.horario,
      estado = 'activo',
      motivo_rechazo = null
  from v
  where s.nombre = v.nombre
  returning s.nombre
)
insert into servicio_tercero
  (usuario_id, nombre, contacto, descripcion, comunas, materiales, retira_a_domicilio, horario, estado)
select null, v.nombre, v.contacto, v.descripcion, v.comunas, v.materiales, v.domicilio, v.horario, 'activo'
from v
where not exists (
  select 1 from servicio_tercero s where s.nombre = v.nombre
);

commit;
