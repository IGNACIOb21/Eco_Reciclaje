-- Prueba de 08_seed_beneficios_servicios.sql (correr después de aplicarlo).
-- Revisa que la app vea los beneficios y servicios de ejemplo, sin
-- duplicados, y que se pueda canjear uno. Termina con ROLLBACK.
begin;

do $$
begin
  if (select count(*) from canjeo_beneficio where activo) < 6 then
    raise exception 'faltan beneficios de ejemplo';
  end if;
  if exists (select nombre_beneficio from canjeo_beneficio group by 1 having count(*) > 1) then
    raise exception 'beneficios duplicados';
  end if;
  if (select count(*) from servicio_tercero where estado = 'activo') < 6 then
    raise exception 'faltan servicios de ejemplo';
  end if;
  if exists (select nombre from servicio_tercero group by 1 having count(*) > 1) then
    raise exception 'servicios duplicados';
  end if;
end $$;

-- Lo que ve la app sin sesión (rol anon).
set local role anon;
select count(*) as beneficios from app_beneficios();
select count(*) as servicios from app_servicios();
select count(*) as servicios_nunoa_papel from app_servicios('Ñuñoa', array['papel']);
reset role;

-- Un usuario con saldo canjea el beneficio más barato.
insert into auth.users (id, instance_id, aud, role, is_anonymous, created_at, updated_at)
values ('11111111-2222-3333-4444-555555555555', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', true, now(), now());
-- Saldo de prueba suficiente para cualquier beneficio de ejemplo.
insert into movimiento_punto (usuario_id, tipo_movimiento, cantidad_puntos)
select usuario_id, 'reciclaje_personal', 2000
from usuario where auth_id = '11111111-2222-3333-4444-555555555555';
set local role authenticated;
select set_config('request.jwt.claims', '{"sub":"11111111-2222-3333-4444-555555555555","role":"authenticated"}', true);
select app_generar_canje(
  (select id_beneficio from app_beneficios() order by costo_en_puntos limit 1)
)::text as canje;

rollback;
