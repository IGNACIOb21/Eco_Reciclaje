-- Proyecto_Eco_reciclaje (shkdlkbhpkbrfxemctdj)
-- Paso 5: resumen de Inicio (cabecera del mapa): meta del día y racha,
-- calculadas con los reciclajes reales. Los congeladores de racha todavía no
-- existen en este esquema: se informan en 0.
-- Idempotente.

begin;

create or replace function public.app_resumen_hoy()
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_usuario integer := public.app_usuario_id();
  v_hoy date := (now() at time zone 'America/Santiago')::date;
  v_lunes date := date_trunc('week', v_hoy)::date;
  v_objetivo constant integer := 3;
  v_actual integer;
  v_maxima integer;
begin
  if v_usuario is null then
    raise exception 'sesion_requerida';
  end if;

  select count(*) into v_actual
    from reciclaje
   where usuario_id = v_usuario
     and (fecha_reciclaje at time zone 'America/Santiago')::date = v_hoy;

  -- Racha más larga: islas de días consecutivos con al menos un reciclaje.
  select coalesce(max(largo), 0) into v_maxima
    from (
      select count(*) as largo
        from (
          select d, d - (row_number() over (order by d))::int as grupo
            from (
              select distinct (fecha_reciclaje at time zone 'America/Santiago')::date as d
                from reciclaje
               where usuario_id = v_usuario
            ) dias
        ) islas
       group by grupo
    ) rachas;

  return jsonb_build_object(
    'meta', jsonb_build_object(
      'cumplida', v_actual >= v_objetivo,
      'actual', v_actual,
      'objetivo', v_objetivo
    ),
    'racha', jsonb_build_object(
      'actual', public._racha(v_usuario),
      'maxima', v_maxima,
      'semana', (
        select jsonb_agg(jsonb_build_object(
                 'fecha', dia,
                 'estado', case
                   when dia > v_hoy then 'futuro'
                   when exists (
                     select 1 from reciclaje r
                      where r.usuario_id = v_usuario
                        and (r.fecha_reciclaje at time zone 'America/Santiago')::date = dia
                   ) then 'hecho'
                   when dia = v_hoy then 'hoy'
                   else 'perdido'
                 end
               ) order by dia)
          from generate_series(v_lunes, v_lunes + 6, interval '1 day') as g(dia_ts),
               lateral (select g.dia_ts::date as dia) x
      )
    ),
    'congeladores', jsonb_build_object('tienes', 0, 'maximo', 0, 'costo', 0)
  );
end;
$$;

-- La sorpresa diaria no existe en este esquema: siempre "no disponible".
create or replace function public.app_sorpresa_hoy()
returns jsonb
language sql
stable
as $$
  select jsonb_build_object('disponible', false, 'abierta', false, 'puntos', 0)
$$;

revoke all on function public.app_resumen_hoy() from public, anon;
revoke all on function public.app_sorpresa_hoy() from public, anon;
grant execute on function public.app_resumen_hoy() to authenticated;
grant execute on function public.app_sorpresa_hoy() to authenticated;

commit;
