-- Proyecto_Eco_reciclaje (shkdlkbhpkbrfxemctdj)
-- Paso 7: pestañas Hoy, Actividad y Ranking de Comunidad.
--
-- La comuna de cada usuario es la que elige en la app (Perfil › Personalizar);
-- app_comunidad_hoy la guarda en usuario.comuna cada vez que se consulta, así
-- la meta y la actividad de la comuna incluyen a sus vecinos.
-- Idempotente.

begin;

alter table usuario
  add column if not exists comuna varchar(60),
  add column if not exists oculto_ranking boolean not null default false;

-- Meta del mes de la comuna, en objetos reciclados por sus vecinos.
create or replace function public.app_comunidad_hoy(p_comuna text)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_usuario integer := public.app_usuario_id();
  v_comuna text := nullif(btrim(p_comuna), '');
  v_hoy date := (now() at time zone 'America/Santiago')::date;
  v_mes date := date_trunc('month', v_hoy)::date;
  v_actual integer;
  v_vecinos integer;
  v_tuyo integer;
begin
  if v_usuario is null then
    raise exception 'sesion_requerida';
  end if;
  if v_comuna is not null and char_length(v_comuna) <= 60 then
    update usuario set comuna = v_comuna
     where usuario_id = v_usuario and comuna is distinct from v_comuna;
  end if;

  select coalesce(sum(coalesce(r.cantidad_articulos, 1)), 0),
         count(distinct r.usuario_id)
    into v_actual, v_vecinos
    from reciclaje r
    join usuario u on u.usuario_id = r.usuario_id
    left join punto_reciclaje p on p.punto_reciclaje_id = r.punto_reciclaje_id
   where (r.fecha_reciclaje at time zone 'America/Santiago')::date >= v_mes
     and (u.comuna = v_comuna or p.comuna = v_comuna);

  select coalesce(sum(coalesce(cantidad_articulos, 1)), 0) into v_tuyo
    from reciclaje
   where usuario_id = v_usuario
     and (fecha_reciclaje at time zone 'America/Santiago')::date >= v_mes;

  return jsonb_build_object(
    'comuna', v_comuna,
    -- Sin metas por comuna en este esquema: la app muestra solo el total.
    'objetivo', null,
    'actual', v_actual,
    'vecinos', v_vecinos,
    'tu_aporte', v_tuyo,
    'dias_restantes', ((v_mes + interval '1 month')::date - v_hoy),
    'mes', v_mes
  );
end;
$$;

-- Lo último que pasó en la comuna: reciclajes y reportes de sus vecinos.
create or replace function public.app_actividad_comuna(p_comuna text, p_limite integer default 30)
returns table (tipo text, alias text, texto text, fecha timestamptz)
language sql
stable
security definer
set search_path = public
as $$
  select * from (
    select
      'reciclaje'::text,
      case when u.oculto_ranking then 'Un vecino' else u.nombre_usuario::text end,
      'recicló ' || coalesce(r.cantidad_articulos, 1) || ' ' ||
        case when coalesce(r.cantidad_articulos, 1) = 1 then 'objeto' else 'objetos' end ||
        ' de ' || lower(c.nombre_categoria),
      r.fecha_reciclaje
    from reciclaje r
    join usuario u on u.usuario_id = r.usuario_id
    join categoria_residuo c on c.categoria_residuo_id = r.categoria_residuo_id
    left join punto_reciclaje p on p.punto_reciclaje_id = r.punto_reciclaje_id
    where r.fecha_reciclaje > now() - interval '14 days'
      and (u.comuna = p_comuna or p.comuna = p_comuna)
    union all
    select
      'reporte'::text,
      case when u.oculto_ranking then 'Un vecino' else u.nombre_usuario::text end,
      'avisó un problema en ' || p.nombre_punto,
      rp.fecha_reporte
    from reporte_punto rp
    join usuario u on u.usuario_id = rp.usuario_id
    join punto_reciclaje p on p.punto_reciclaje_id = rp.punto_reciclaje_id
    where rp.fecha_reporte > now() - interval '14 days'
      and p.comuna = p_comuna
  ) a (tipo, alias, texto, fecha)
  order by fecha desc
  limit greatest(least(coalesce(p_limite, 30), 100), 1)
$$;

-- Ranking de la semana (desde el lunes): Rebin Points ganados, sin canjes.
-- Si la persona no está en el top, se agrega al final con su posición real.
create or replace function public.app_ranking_semana(p_limite integer default 20)
returns table (posicion integer, alias text, puntos integer, es_tuyo boolean)
language sql
stable
security definer
set search_path = public
as $$
  with semana as (
    select
      m.usuario_id,
      sum(m.cantidad_puntos)::int as pts
    from movimiento_punto m
    join usuario u on u.usuario_id = m.usuario_id
    where m.fecha_movimiento >= date_trunc('week', now() at time zone 'America/Santiago') at time zone 'America/Santiago'
      and m.cantidad_puntos > 0
      and m.tipo_movimiento not in ('canje_beneficio', 'devolucion_canje')
      and not u.oculto_ranking
    group by m.usuario_id
  ),
  ordenado as (
    select
      (row_number() over (order by s.pts desc, s.usuario_id))::int as pos,
      u.nombre_usuario::text as alias,
      s.pts,
      s.usuario_id = public.app_usuario_id() as yo
    from semana s
    join usuario u on u.usuario_id = s.usuario_id
  )
  select pos, alias, pts, yo
    from ordenado
   where pos <= greatest(least(coalesce(p_limite, 20), 100), 1) or yo
   order by pos
$$;

create or replace function public.app_ocultar_ranking(p_oculto boolean)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if public.app_usuario_id() is null then
    raise exception 'sesion_requerida';
  end if;
  update usuario set oculto_ranking = coalesce(p_oculto, false)
   where usuario_id = public.app_usuario_id();
end;
$$;

revoke all on function public.app_comunidad_hoy(text) from public, anon;
revoke all on function public.app_actividad_comuna(text, integer) from public, anon;
revoke all on function public.app_ranking_semana(integer) from public, anon;
revoke all on function public.app_ocultar_ranking(boolean) from public, anon;
grant execute on function public.app_comunidad_hoy(text) to authenticated;
grant execute on function public.app_actividad_comuna(text, integer) to authenticated;
grant execute on function public.app_ranking_semana(integer) to authenticated;
grant execute on function public.app_ocultar_ranking(boolean) to authenticated;

commit;
