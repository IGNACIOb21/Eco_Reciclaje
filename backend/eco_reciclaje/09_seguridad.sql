-- Proyecto_Eco_reciclaje (shkdlkbhpkbrfxemctdj)
-- Paso 9: endurecimiento de seguridad (revisión del 2026-11-17).
--   1. _racha(usuario) es interna: authenticated la podía llamar por RPC con
--      cualquier id y ver la racha de otros. Se le quita el permiso.
--   2. app_generar_canje bloquea la fila del beneficio: antes dos usuarios
--      podían canjear a la vez la última unidad del stock.
--   3. app_calificar bloquea al usuario: antes dos llamadas simultáneas a la
--      misma calificación podían pagar los 3 puntos dos veces.
--   4. Defensa en profundidad: la APK escribe solo por funciones app_*
--      (security definer), así que anon y authenticated no necesitan
--      insert/update/delete directo en las tablas (RLS ya lo bloqueaba: no
--      hay políticas de escritura).
-- Idempotente: se puede correr de nuevo sin efectos extra.

begin;

revoke all on function public._racha(integer) from public, anon, authenticated;

create or replace function public.app_generar_canje(p_id_beneficio integer)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_usuario integer := public.app_usuario_id();
  v_beneficio canjeo_beneficio%rowtype;
  v_saldo integer;
  v_canjeados integer;
  v_codigo text;
  v_canje integer;
begin
  if v_usuario is null then
    raise exception 'sesion_requerida';
  end if;
  -- Las cuentas anónimas no canjean: hay que registrar un correo primero.
  if coalesce((auth.jwt() ->> 'is_anonymous')::boolean, false) then
    raise exception 'requiere_cuenta';
  end if;

  -- Bloquea al usuario para que dos canjes simultáneos no gasten el mismo saldo.
  perform 1 from usuario where usuario_id = v_usuario for update;

  -- Bloquea también el beneficio: dos usuarios no pueden llevarse la última
  -- unidad del stock al mismo tiempo.
  select * into v_beneficio from canjeo_beneficio
   where canjeo_beneficio_id = p_id_beneficio
     for update;
  if not found or not coalesce(v_beneficio.activo, true) then
    raise exception 'beneficio_no_disponible';
  end if;
  if v_beneficio.cantidad_disponible is not null then
    select count(*) into v_canjeados from canjeo
     where canjeo_beneficio_id = p_id_beneficio
       and estado_canje not in ('cancelado', 'rechazado');
    if v_canjeados >= v_beneficio.cantidad_disponible then
      raise exception 'sin_stock';
    end if;
  end if;
  select coalesce(sum(cantidad_puntos), 0) into v_saldo
    from movimiento_punto where usuario_id = v_usuario;
  if v_saldo < v_beneficio.costo_puntos then
    raise exception 'saldo_insuficiente';
  end if;

  loop
    v_codigo := upper(substr(md5(gen_random_uuid()::text), 1, 8));
    exit when not exists (select 1 from canjeo where codigo_canje = v_codigo);
  end loop;

  insert into canjeo (usuario_id, canjeo_beneficio_id, estado_canje, codigo_canje)
  values (v_usuario, p_id_beneficio, 'pendiente', v_codigo)
  returning canjeo_id into v_canje;

  insert into movimiento_punto (usuario_id, tipo_movimiento, cantidad_puntos, id_referencia)
  values (v_usuario, 'canje_beneficio', -v_beneficio.costo_puntos, v_canje);

  return jsonb_build_object(
    'codigo_canje', v_codigo,
    'costo', v_beneficio.costo_puntos,
    'saldo', v_saldo - v_beneficio.costo_puntos
  );
end;
$$;

create or replace function public.app_calificar(
  p_id_punto integer,
  p_puntuacion integer,
  p_etiquetas text[] default null,
  p_comentario text default null
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_usuario integer := public.app_usuario_id();
  v_comentario text := nullif(btrim(p_comentario), '');
  v_nueva boolean;
  v_puntos integer := 0;
begin
  if v_usuario is null then
    raise exception 'sesion_requerida';
  end if;
  if not exists (select 1 from punto_reciclaje where punto_reciclaje_id = p_id_punto) then
    raise exception 'punto_no_encontrado';
  end if;
  if p_puntuacion is null or p_puntuacion < 1 or p_puntuacion > 5 then
    raise exception 'puntuacion_invalida';
  end if;
  if v_comentario is not null and char_length(v_comentario) > 500 then
    raise exception 'comentario_invalido';
  end if;
  if p_etiquetas is not null and (
    cardinality(p_etiquetas) > 6
    or exists (select 1 from unnest(p_etiquetas) e where char_length(e) not between 1 and 40)
  ) then
    raise exception 'etiquetas_invalidas';
  end if;

  -- Bloquea al usuario: dos llamadas simultáneas no pueden ver ambas la
  -- calificación como nueva y pagar dos veces.
  perform 1 from usuario where usuario_id = v_usuario for update;

  v_nueva := not exists (
    select 1 from calificacion_punto
     where punto_reciclaje_id = p_id_punto and usuario_id = v_usuario
  );

  insert into calificacion_punto (punto_reciclaje_id, usuario_id, puntuacion, comentario, etiquetas)
  values (p_id_punto, v_usuario, p_puntuacion, v_comentario, p_etiquetas)
  on conflict (punto_reciclaje_id, usuario_id) do update
    set puntuacion = excluded.puntuacion,
        comentario = excluded.comentario,
        etiquetas = excluded.etiquetas,
        fecha_calificacion = now();

  -- Solo la primera calificación de cada punto da puntos.
  if v_nueva then
    v_puntos := 3;
    insert into movimiento_punto (usuario_id, tipo_movimiento, cantidad_puntos, id_referencia)
    values (v_usuario, 'calificacion_punto', v_puntos, p_id_punto);
  end if;

  return jsonb_build_object('puntos', v_puntos);
end;
$$;

revoke all on function public.app_generar_canje(integer) from public, anon;
grant execute on function public.app_generar_canje(integer) to authenticated;
revoke all on function public.app_calificar(integer, integer, text[], text) from public, anon;
grant execute on function public.app_calificar(integer, integer, text[], text) to authenticated;

revoke insert, update, delete, truncate on all tables in schema public from anon, authenticated;

commit;
