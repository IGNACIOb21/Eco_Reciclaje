-- Prueba de app_resumen_hoy con un usuario de prueba. Termina con ROLLBACK.
begin;
insert into auth.users (id, instance_id, aud, role, is_anonymous, created_at, updated_at)
values ('11111111-2222-3333-4444-555555555555', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', true, now(), now());
set local role authenticated;
select set_config('request.jwt.claims', '{"sub":"11111111-2222-3333-4444-555555555555","role":"authenticated"}', true);
create temp table r on commit drop as select app_registrar_reciclaje('vidrio') as x;
select app_resumen_hoy()::text as resumen;
rollback;
