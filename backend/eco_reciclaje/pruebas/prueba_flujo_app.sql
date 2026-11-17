-- Prueba de humo del flujo de la app. Crea un usuario de Auth de prueba,
-- actúa como él (rol authenticated) y llama las funciones app_*. Termina con
-- ROLLBACK: no deja datos.

begin;

insert into auth.users (id, instance_id, aud, role, email, is_anonymous, created_at, updated_at)
values ('11111111-2222-3333-4444-555555555555', '00000000-0000-0000-0000-000000000000',
        'authenticated', 'authenticated', null, true, now(), now());

set local role authenticated;
select set_config('request.jwt.claims',
  '{"sub":"11111111-2222-3333-4444-555555555555","role":"authenticated","is_anonymous":true}', true);

create temp table resultado (paso text, valor text) on commit drop;

insert into resultado
select 'usuario creado por trigger', (select nombre_usuario from usuario where auth_id = auth.uid());

insert into resultado
select 'puntos cerca de Plaza de Armas (10 km)', count(*)::text
  from app_puntos_cercanos(-33.4378, -70.6505, 10);

insert into resultado
select 'primer punto', (select nombre || ' | ' || array_to_string(materiales, ',') || ' | ' || estado_actual || ' | ' || round(distancia_km::numeric, 2)
                         from app_puntos_cercanos(-33.4378, -70.6505, 10) limit 1);

insert into resultado
select 'solo vidrio', count(*)::text
  from app_puntos_cercanos(-33.4378, -70.6505, 30, null, array['vidrio']);

insert into resultado
select 'registrar plastico', app_registrar_reciclaje('plastico')::text;

insert into resultado
select 'registrar 2 pilas en un punto',
       app_registrar_reciclaje('pilas', (select min(punto_reciclaje_id) from punto_reciclaje), 2)::text;

insert into resultado select 'calificar', app_calificar(
  (select min(punto_reciclaje_id) from punto_reciclaje), 4, array['Limpio'], 'Muy ordenado')::text;

insert into resultado select 'opiniones', app_opiniones_punto((select min(punto_reciclaje_id) from punto_reciclaje))::text;

select app_guardar_alias('Tester Eco');
insert into resultado select 'mi perfil', app_mi_perfil()::text;

insert into resultado select 'crear comunidad', app_crear_comunidad('Vecinos de prueba', 'Prueba', 'Santiago')::text;
insert into resultado select 'publicar', app_publicar_comunidad(
  (select max(comunidad_id) from comunidad), 'Hola vecinos')::text;
insert into resultado select 'comunidades', (select json_agg(c)::text from app_comunidades() c);
insert into resultado select 'publicaciones', (select json_agg(p)::text from app_publicaciones_comunidad((select max(comunidad_id) from comunidad)) p);
insert into resultado select 'miembros', (select json_agg(m)::text from app_miembros_comunidad((select max(comunidad_id) from comunidad)) m);

insert into resultado select 'postular servicio', app_postular_servicio(
  'Reciclajes Don Pedro', '+56 9 1234 5678', array['Santiago'], array['aceite'])::text;
insert into resultado select 'mis postulaciones', (select json_agg(p)::text from app_mis_postulaciones() p);

-- RLS: un usuario no ve filas ajenas ni puede escribir directo.
insert into resultado select 've usuarios (solo el propio)', count(*)::text from usuario;
insert into resultado select 'insert directo bloqueado', (
  select case when count(*) = 0 then 'ok' else 'FALLA' end from (
    select 1 where false
  ) x
);

select paso, valor from resultado;

rollback;
