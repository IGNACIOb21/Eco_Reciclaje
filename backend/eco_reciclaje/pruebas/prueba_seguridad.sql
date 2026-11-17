-- Prueba de 09_seguridad.sql (correr después de aplicarlo). Termina con ROLLBACK.
begin;

do $$
begin
  if has_function_privilege('authenticated', 'public._racha(integer)', 'execute') then
    raise exception '_racha sigue expuesta a authenticated';
  end if;
  if exists (
    select 1 from information_schema.role_table_grants
     where table_schema = 'public'
       and grantee in ('anon', 'authenticated')
       and privilege_type in ('INSERT', 'UPDATE', 'DELETE', 'TRUNCATE')
  ) then
    raise exception 'quedan permisos de escritura directa en tablas';
  end if;
  if position('for update' in pg_get_functiondef('public.app_generar_canje(integer)'::regprocedure)) = 0
     or (length(pg_get_functiondef('public.app_generar_canje(integer)'::regprocedure))
         - length(replace(pg_get_functiondef('public.app_generar_canje(integer)'::regprocedure), 'for update', ''))) / 10 < 2 then
    raise exception 'app_generar_canje no bloquea el beneficio';
  end if;
  if position('for update' in pg_get_functiondef('public.app_calificar(integer,integer,text[],text)'::regprocedure)) = 0 then
    raise exception 'app_calificar no bloquea al usuario';
  end if;
end $$;

-- Un usuario normal sigue pudiendo calificar (una sola vez paga) y canjear.
insert into auth.users (id, instance_id, aud, role, is_anonymous, created_at, updated_at)
values ('11111111-2222-3333-4444-555555555555', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', false, now(), now());
insert into movimiento_punto (usuario_id, tipo_movimiento, cantidad_puntos)
select usuario_id, 'reciclaje_personal', 2000
from usuario where auth_id = '11111111-2222-3333-4444-555555555555';
set local role authenticated;
select set_config('request.jwt.claims', '{"sub":"11111111-2222-3333-4444-555555555555","role":"authenticated","is_anonymous":false}', true);

select app_calificar((select min(punto_reciclaje_id) from punto_reciclaje), 5)::text as primera;  -- {"puntos": 3}
select app_calificar((select min(punto_reciclaje_id) from punto_reciclaje), 4)::text as segunda;  -- {"puntos": 0}
select app_generar_canje(
  (select id_beneficio from app_beneficios() order by costo_en_puntos limit 1)
)::text as canje;

-- La escritura directa en una tabla debe fallar.
do $$
begin
  insert into movimiento_punto (usuario_id, tipo_movimiento, cantidad_puntos)
  values (public.app_usuario_id(), 'reciclaje_personal', 999);
  raise exception 'la escritura directa no debió pasar';
exception when insufficient_privilege then
  null;
end $$;

-- _racha ya no se puede llamar desde la app.
do $$
begin
  perform public._racha(1);
  raise exception '_racha no debió poder llamarse';
exception when insufficient_privilege then
  null;
end $$;

rollback;
