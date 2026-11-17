-- Proyecto_Eco_reciclaje (shkdlkbhpkbrfxemctdj)
-- Paso 6: logros (insignias de Perfil, pestaña Logros de Retos y "Para
-- reclamar") sobre las tablas logro y logro_usuario.
--
-- Cada fila de `logro` es un escalón: las filas con el mismo `codigo` son los
-- niveles de una misma insignia (el umbral sube). `metrica` dice qué se cuenta
-- y `puntos_recompensa` cuánto paga reclamarlo.
-- Las misiones semanales no existen en este esquema: app_misiones_semana
-- devuelve una lista vacía.
-- Idempotente.

begin;

alter table logro
  add column if not exists codigo varchar(40),
  add column if not exists metrica varchar(30),
  add column if not exists puntos_recompensa integer not null default 20;

-- Racha más larga del usuario (días seguidos con al menos un reciclaje).
create or replace function public._racha_maxima(p_usuario integer)
returns integer
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(max(largo), 0)::int
    from (
      select count(*) as largo
        from (
          select d, d - (row_number() over (order by d))::int as grupo
            from (
              select distinct (fecha_reciclaje at time zone 'America/Santiago')::date as d
                from reciclaje
               where usuario_id = p_usuario
            ) dias
        ) islas
       group by grupo
    ) rachas
$$;

-- Avance del usuario en una métrica.
create or replace function public._progreso_logro(p_usuario integer, p_metrica text)
returns integer
language sql
stable
security definer
set search_path = public
as $$
  select case
    when p_metrica = 'reciclajes' then
      (select coalesce(sum(cantidad_articulos), count(*))::int from reciclaje where usuario_id = p_usuario)
    when p_metrica = 'reportes' then
      (select count(*)::int from reporte_punto where usuario_id = p_usuario)
    when p_metrica = 'calificaciones' then
      (select count(*)::int from calificacion_punto where usuario_id = p_usuario)
    when p_metrica = 'racha' then
      public._racha_maxima(p_usuario)
    when p_metrica like 'categoria:%' then
      (select coalesce(sum(coalesce(r.cantidad_articulos, 1)), 0)::int
         from reciclaje r
         join categoria_residuo c on c.categoria_residuo_id = r.categoria_residuo_id
        where r.usuario_id = p_usuario
          and c.codigo = substr(p_metrica, 11))
    else 0
  end
$$;

create or replace function public.app_logros()
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_usuario integer := public.app_usuario_id();
begin
  if v_usuario is null then
    raise exception 'sesion_requerida';
  end if;
  return coalesce((
    select jsonb_agg(jsonb_build_object(
             'codigo', g.codigo,
             'nombre', g.nombre,
             'descripcion', g.descripcion,
             'progreso', public._progreso_logro(v_usuario, g.metrica),
             'niveles', g.niveles,
             'nivel_obtenido', g.obtenidos
           ) order by g.orden)
      from (
        select
          l.codigo,
          (array_agg(l.nombre order by l.umbral_logro))[1] as nombre,
          (array_agg(l.descripcion order by l.umbral_logro))[1] as descripcion,
          max(l.metrica) as metrica,
          jsonb_agg(jsonb_build_object('meta', l.umbral_logro, 'puntos', l.puntos_recompensa)
                    order by l.umbral_logro) as niveles,
          count(lu.logro_usuario_id) as obtenidos,
          min(l.logro_id) as orden
        from logro l
        left join logro_usuario lu
          on lu.logro_id = l.logro_id and lu.usuario_id = v_usuario
        where l.codigo is not null and l.metrica is not null
        group by l.codigo
      ) g
  ), '[]'::jsonb);
end;
$$;

-- Reclama el siguiente nivel alcanzado de una insignia y paga sus puntos.
create or replace function public.app_reclamar_logro(p_codigo text)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_usuario integer := public.app_usuario_id();
  v_logro logro%rowtype;
begin
  if v_usuario is null then
    raise exception 'sesion_requerida';
  end if;
  -- Evita cobrar dos veces el mismo nivel con dos toques simultáneos.
  perform 1 from usuario where usuario_id = v_usuario for update;

  select l.* into v_logro
    from logro l
   where l.codigo = p_codigo
     and not exists (
       select 1 from logro_usuario lu
        where lu.logro_id = l.logro_id and lu.usuario_id = v_usuario
     )
   order by l.umbral_logro
   limit 1;
  if not found then
    if exists (select 1 from logro where codigo = p_codigo) then
      raise exception 'logro_maximo';
    end if;
    raise exception 'logro_no_encontrado';
  end if;
  if public._progreso_logro(v_usuario, v_logro.metrica) < v_logro.umbral_logro then
    raise exception 'logro_no_alcanzado';
  end if;

  insert into logro_usuario (usuario_id, logro_id) values (v_usuario, v_logro.logro_id);
  insert into movimiento_punto (usuario_id, tipo_movimiento, cantidad_puntos, id_referencia)
  values (v_usuario, 'recompensa_logro', v_logro.puntos_recompensa, v_logro.logro_id);

  return jsonb_build_object('puntos', v_logro.puntos_recompensa);
end;
$$;

create or replace function public.app_misiones_semana()
returns jsonb
language sql
stable
as $$
  select '[]'::jsonb
$$;

revoke all on function public._racha_maxima(integer) from public, anon, authenticated;
revoke all on function public._progreso_logro(integer, text) from public, anon, authenticated;
revoke all on function public.app_logros() from public, anon;
revoke all on function public.app_reclamar_logro(text) from public, anon;
revoke all on function public.app_misiones_semana() from public, anon;
grant execute on function public.app_logros() to authenticated;
grant execute on function public.app_reclamar_logro(text) to authenticated;
grant execute on function public.app_misiones_semana() to authenticated;

-- Insignias iniciales (códigos con ícono propio en la app). Se insertan solo
-- si ese código todavía no existe.
insert into logro (codigo, metrica, nombre, descripcion, umbral_logro, puntos_recompensa)
select v.codigo, v.metrica, v.nombre, v.descripcion, v.umbral, v.puntos
from (values
  ('explorador', 'reciclajes',          'Reciclador',          'Registra artículos reciclados escaneándolos.', 1, 10),
  ('explorador', 'reciclajes',          'Reciclador',          'Registra artículos reciclados escaneándolos.', 25, 50),
  ('explorador', 'reciclajes',          'Reciclador',          'Registra artículos reciclados escaneándolos.', 100, 150),
  ('vidriero',   'categoria:vidrio',    'Vidriero',            'Recicla botellas y frascos de vidrio.', 5, 20),
  ('vidriero',   'categoria:vidrio',    'Vidriero',            'Recicla botellas y frascos de vidrio.', 20, 50),
  ('vidriero',   'categoria:vidrio',    'Vidriero',            'Recicla botellas y frascos de vidrio.', 50, 100),
  ('papelero',   'categoria:papel',     'Papelero',            'Recicla papel y cartón.', 5, 20),
  ('papelero',   'categoria:papel',     'Papelero',            'Recicla papel y cartón.', 20, 50),
  ('papelero',   'categoria:papel',     'Papelero',            'Recicla papel y cartón.', 50, 100),
  ('pilas',      'categoria:pilas',     'Cazador de pilas',    'Lleva pilas y baterías a un punto de recolección.', 3, 30),
  ('pilas',      'categoria:pilas',     'Cazador de pilas',    'Lleva pilas y baterías a un punto de recolección.', 10, 60),
  ('racha_7',    'racha',               'Constancia',          'Recicla varios días seguidos.', 3, 20),
  ('racha_7',    'racha',               'Constancia',          'Recicla varios días seguidos.', 7, 50),
  ('racha_7',    'racha',               'Constancia',          'Recicla varios días seguidos.', 30, 200),
  ('guardian',   'reportes',            'Guardián del barrio', 'Avisa cuando un punto está lleno o dañado.', 1, 10),
  ('guardian',   'reportes',            'Guardián del barrio', 'Avisa cuando un punto está lleno o dañado.', 5, 30),
  ('guardian',   'reportes',            'Guardián del barrio', 'Avisa cuando un punto está lleno o dañado.', 20, 80),
  ('vecino',     'calificaciones',      'Buen vecino',         'Califica los puntos de reciclaje que visitas.', 1, 10),
  ('vecino',     'calificaciones',      'Buen vecino',         'Califica los puntos de reciclaje que visitas.', 5, 30)
) as v(codigo, metrica, nombre, descripcion, umbral, puntos)
where not exists (select 1 from logro l where l.codigo = v.codigo);

commit;
