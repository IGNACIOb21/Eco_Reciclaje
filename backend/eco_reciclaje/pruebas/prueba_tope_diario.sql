-- El tope diario es de 30 artículos (no de 30 llamadas). Termina con ROLLBACK.
begin;
insert into auth.users (id, instance_id, aud, role, is_anonymous, created_at, updated_at)
values ('11111111-2222-3333-4444-555555555555', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', true, now(), now());
set local role authenticated;
select set_config('request.jwt.claims', '{"sub":"11111111-2222-3333-4444-555555555555","role":"authenticated"}', true);
create temp table r on commit drop as select app_registrar_reciclaje('electronicos', null, 5) from generate_series(1, 6);
do $$ begin
  perform app_registrar_reciclaje('electronicos', null, 1);
  raise exception 'FALLA: dejó pasar el artículo 31';
exception when others then
  if sqlerrm <> 'limite_diario' then raise; end if;
end $$;
do $$ begin
  perform app_registrar_reciclaje('vidrio', null, 6);
  raise exception 'FALLA: aceptó cantidad 6';
exception when others then
  if sqlerrm <> 'cantidad_invalida' then raise; end if;
end $$;
select (select count(*) from r) as registros, app_mi_perfil()->>'saldo' as saldo_maximo_del_dia;
rollback;
