-- Proyecto_Eco_reciclaje (shkdlkbhpkbrfxemctdj)
-- Paso 2: funciones app_* que llama la APK. Todas validan la sesión con
-- auth.uid() y avisan errores con `raise exception '<codigo>'`, que la app
-- traduce a mensajes. Requiere 00_tipos.sql y 01_conexion_app.sql.
-- Idempotente.

begin;

-- ===========================================================================
-- Perfil y Rebin Points
-- ===========================================================================

create or replace function public.app_niveles()
returns table (nombre text, puntos_minimos integer)
language sql
immutable
as $$
  values ('Novato', 0), ('Aprendiz', 200), ('Pro', 600), ('Experto', 1500), ('Maestro', 3000)
$$;

-- Días seguidos (hasta hoy o ayer, hora de Chile) con al menos un reciclaje.
create or replace function public._racha(p_usuario integer)
returns integer
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_hoy date := (now() at time zone 'America/Santiago')::date;
  v_dia date;
  v_racha integer := 0;
begin
  if exists (
    select 1 from reciclaje
     where usuario_id = p_usuario
       and (fecha_reciclaje at time zone 'America/Santiago')::date = v_hoy
  ) then
    v_dia := v_hoy;
  else
    v_dia := v_hoy - 1;
  end if;
  while exists (
    select 1 from reciclaje
     where usuario_id = p_usuario
       and (fecha_reciclaje at time zone 'America/Santiago')::date = v_dia
  ) loop
    v_racha := v_racha + 1;
    v_dia := v_dia - 1;
  end loop;
  return v_racha;
end;
$$;

-- Saldo (lo que se puede gastar) y acumulado (lo ganado, define el nivel).
create or replace function public.app_mi_resumen()
returns table (saldo integer, acumulado integer, racha integer)
language sql
stable
security definer
set search_path = public
as $$
  select
    coalesce(sum(m.cantidad_puntos), 0)::integer,
    coalesce(sum(m.cantidad_puntos) filter (
      where m.cantidad_puntos > 0
        and m.tipo_movimiento not in ('canje_beneficio', 'devolucion_canje')
    ), 0)::integer,
    public._racha(public.app_usuario_id())
  from movimiento_punto m
  where m.usuario_id = public.app_usuario_id()
$$;

-- Todo lo que muestra Perfil en una sola llamada.
create or replace function public.app_mi_perfil(p_movimientos integer default 10)
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_usuario usuario%rowtype;
  v_resumen record;
begin
  select * into v_usuario from usuario where auth_id = auth.uid();
  if not found then
    raise exception 'usuario_no_registrado';
  end if;
  select * into v_resumen from public.app_mi_resumen();

  return jsonb_build_object(
    'id_usuario', auth.uid()::text,
    'correo_electronico', v_usuario.correo_electronico,
    'alias', v_usuario.nombre_usuario,
    'url_imagen_perfil', v_usuario.url_imagen_perfil,
    'fecha_creacion', v_usuario.fecha_registro,
    'saldo', greatest(v_resumen.saldo, 0),
    'acumulado', greatest(v_resumen.acumulado, 0),
    'racha', v_resumen.racha,
    'escaneados', (select count(*) from reciclaje where usuario_id = v_usuario.usuario_id),
    'reportes', (select count(*) from reporte_punto where usuario_id = v_usuario.usuario_id),
    'logros', (select count(*) from logro_usuario where usuario_id = v_usuario.usuario_id),
    'movimientos', coalesce((
      select jsonb_agg(x order by x.fecha desc)
        from (
          select
            case m.tipo_movimiento::text
              when 'reciclaje_personal' then
                case when r.punto_reciclaje_id is null then 'escaneo' else 'deposito' end
              when 'canje_beneficio' then 'canje'
              when 'devolucion_canje' then 'canje'
              when 'reporte_punto' then 'reporte'
              when 'calificacion_punto' then 'valoracion'
              when 'recompensa_logro' then 'racha'
              else 'ajuste'
            end as tipo_referencia,
            m.cantidad_puntos as cantidad,
            m.fecha_movimiento as fecha
          from movimiento_punto m
          left join reciclaje r
            on m.tipo_movimiento = 'reciclaje_personal'
           and r.reciclaje_id = m.id_referencia
          where m.usuario_id = v_usuario.usuario_id
          order by m.fecha_movimiento desc
          limit greatest(least(p_movimientos, 50), 0)
        ) x
    ), '[]'::jsonb)
  );
end;
$$;

create or replace function public.app_guardar_alias(p_alias text)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_alias text := btrim(p_alias);
begin
  if public.app_usuario_id() is null then
    raise exception 'sesion_requerida';
  end if;
  if v_alias is null or char_length(v_alias) < 3 or char_length(v_alias) > 30 then
    raise exception 'alias_invalido';
  end if;
  update usuario set nombre_usuario = v_alias where auth_id = auth.uid();
end;
$$;

-- ===========================================================================
-- Mapa
-- ===========================================================================

create or replace function public.app_puntos_cercanos(
  p_lat double precision,
  p_lng double precision,
  radio_km double precision default 10,
  comuna_filtro text default null,
  materiales_filtro text[] default null,
  solo_disponibles boolean default false,
  calificacion_minima double precision default 0
)
returns table (
  id text,
  nombre text,
  comuna text,
  direccion text,
  lat double precision,
  lng double precision,
  fuente text,
  materiales text[],
  estado_actual text,
  calificacion_promedio double precision,
  num_calificaciones integer,
  avisos text[],
  distancia_km double precision
)
language sql
stable
security definer
set search_path = public
as $$
  with base as (
    select
      p.punto_reciclaje_id,
      p.nombre_punto,
      p.comuna as comuna_punto,
      p.direccion_completa,
      p.coordenada_latitud::float8 as plat,
      p.coordenada_longitud::float8 as plng,
      p.osm_id,
      p.estado_operativo,
      2 * 6371 * asin(sqrt(
        power(sin(radians(p.coordenada_latitud::float8 - p_lat) / 2), 2)
        + cos(radians(p_lat)) * cos(radians(p.coordenada_latitud::float8))
        * power(sin(radians(p.coordenada_longitud::float8 - p_lng) / 2), 2)
      )) as dist
    from punto_reciclaje p
    where p.estado_operativo <> 'fuera_servicio'
       or not coalesce(solo_disponibles, false)
  ),
  detalle as (
    select
      b.*,
      coalesce((
        select array_agg(c.codigo::text order by c.codigo)
          from punto_categoria pc
          join categoria_residuo c on c.categoria_residuo_id = pc.categoria_residuo_id
         where pc.punto_reciclaje_id = b.punto_reciclaje_id
           and c.codigo is not null
      ), '{}') as mats,
      (select avg(cp.puntuacion)::float8 from calificacion_punto cp
        where cp.punto_reciclaje_id = b.punto_reciclaje_id) as prom,
      (select count(*)::int from calificacion_punto cp
        where cp.punto_reciclaje_id = b.punto_reciclaje_id) as n
    from base b
    where b.dist <= coalesce(radio_km, 10)
      and (comuna_filtro is null or b.comuna_punto = comuna_filtro)
      and (not coalesce(solo_disponibles, false) or b.estado_operativo = 'operativo')
  )
  select
    d.punto_reciclaje_id::text,
    d.nombre_punto::text,
    d.comuna_punto::text,
    d.direccion_completa,
    d.plat,
    d.plng,
    case when d.osm_id is null then 'oficial' else 'osm' end,
    d.mats,
    case d.estado_operativo::text
      when 'operativo' then 'disponible'
      when 'lleno' then 'lleno'
      when 'mantenimiento' then 'mal_mantenimiento'
      else 'fuera_de_uso'
    end,
    coalesce(d.prom, 0),
    d.n,
    '{}'::text[],
    d.dist
  from detalle d
  where (materiales_filtro is null or d.mats && materiales_filtro)
    and coalesce(d.prom, 0) >= coalesce(calificacion_minima, 0)
  order by d.dist
  limit 300
$$;

-- ===========================================================================
-- Escaneo (modelo de Joaquín) → reciclaje + Rebin Points
-- ===========================================================================

create or replace function public.app_registrar_reciclaje(
  p_codigo_categoria text,
  p_id_punto integer default null,
  p_cantidad integer default 1,
  p_confianza_ia double precision default null
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_usuario integer := public.app_usuario_id();
  v_cantidad integer := coalesce(p_cantidad, 1);
  v_categoria integer;
  v_unitarios integer;
  v_puntos integer;
  v_reciclaje integer;
  v_hoy date := (now() at time zone 'America/Santiago')::date;
begin
  if v_usuario is null then
    raise exception 'sesion_requerida';
  end if;
  if v_cantidad < 1 or v_cantidad > 5 then
    raise exception 'cantidad_invalida';
  end if;
  select categoria_residuo_id into v_categoria
    from categoria_residuo where codigo = p_codigo_categoria;
  if v_categoria is null then
    raise exception 'categoria_invalida';
  end if;
  if p_id_punto is not null
     and not exists (select 1 from punto_reciclaje where punto_reciclaje_id = p_id_punto) then
    raise exception 'punto_no_encontrado';
  end if;
  -- Tope anti-abuso sobre lo que se acredita, no sobre la cantidad de
  -- llamadas: el escaneo no prueba el depósito, así que se limitan los
  -- artículos (y con eso los puntos) por día. Se bloquea la fila del usuario
  -- para que dos llamadas simultáneas no pasen el tope.
  perform 1 from usuario where usuario_id = v_usuario for update;
  if (select coalesce(sum(coalesce(cantidad_articulos, 1)), 0) from reciclaje
       where usuario_id = v_usuario
         and (fecha_reciclaje at time zone 'America/Santiago')::date = v_hoy)
     + v_cantidad > 30 then
    raise exception 'limite_diario';
  end if;

  select r.puntos_unitarios into v_unitarios
    from regla_puntuacion r
   where r.categoria_residuo_id = v_categoria
     and r.fecha_inicio_vigencia <= current_date
     and (r.fecha_fin_vigencia is null or r.fecha_fin_vigencia >= current_date)
   order by r.fecha_inicio_vigencia desc
   limit 1;
  v_puntos := coalesce(v_unitarios, 5) * v_cantidad;

  insert into reciclaje (usuario_id, punto_reciclaje_id, categoria_residuo_id, cantidad_articulos, puntos_obtenidos)
  values (v_usuario, p_id_punto, v_categoria, v_cantidad, v_puntos)
  returning reciclaje_id into v_reciclaje;

  insert into movimiento_punto (usuario_id, tipo_movimiento, cantidad_puntos, id_referencia)
  values (v_usuario, 'reciclaje_personal', v_puntos, v_reciclaje);

  return jsonb_build_object(
    'id_reciclaje', v_reciclaje,
    'puntos', v_puntos,
    'saldo', (select coalesce(sum(cantidad_puntos), 0) from movimiento_punto where usuario_id = v_usuario)
  );
end;
$$;

-- ===========================================================================
-- Reportes y calificaciones de puntos
-- ===========================================================================

create or replace function public.app_reportar_estado(
  p_id_punto integer,
  p_tipo text,
  p_comentario text default null,
  p_lat double precision default null,
  p_lng double precision default null,
  p_precision_gps double precision default null,
  p_ubicacion_simulada boolean default null,
  p_foto_ruta text default null
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_usuario integer := public.app_usuario_id();
  v_comentario text := nullif(btrim(p_comentario), '');
  v_grupo tipo_reporte_enum;
  v_hoy date := (now() at time zone 'America/Santiago')::date;
  v_puntos integer := 5;
begin
  if v_usuario is null then
    raise exception 'sesion_requerida';
  end if;
  if not exists (select 1 from punto_reciclaje where punto_reciclaje_id = p_id_punto) then
    raise exception 'punto_no_encontrado';
  end if;

  v_grupo := case p_tipo
    when 'lleno_saturado' then 'contenedor_lleno'
    when 'sucio_residuos_afuera' then 'suciedad_alrededor'
    when 'dañado_destruido' then 'danio_estructura'
    when 'ubicacion_incorrecta' then 'ubicacion_incorrecta'
    else 'otro'
  end::tipo_reporte_enum;

  if v_comentario is not null and char_length(v_comentario) > 500 then
    raise exception 'comentario_invalido';
  end if;
  if p_tipo = 'otro' and v_comentario is null then
    raise exception 'comentario_obligatorio';
  end if;

  if p_foto_ruta is null then
    raise exception 'foto_obligatoria';
  end if;
  -- La foto debe estar en la carpeta del propio usuario y no estar usada.
  if (storage.foldername(p_foto_ruta))[1] is distinct from auth.uid()::text
     or not exists (select 1 from storage.objects where bucket_id = 'reportes' and name = p_foto_ruta)
     or exists (select 1 from reporte_punto where ruta_foto = p_foto_ruta) then
    raise exception 'foto_invalida';
  end if;

  if exists (
    select 1 from reporte_punto
     where usuario_id = v_usuario
       and punto_reciclaje_id = p_id_punto
       and subtipo = p_tipo
       and fecha_reporte > now() - interval '24 hours'
  ) then
    raise exception 'reporte_repetido';
  end if;
  if (select count(*) from reporte_punto
       where usuario_id = v_usuario
         and (fecha_reporte at time zone 'America/Santiago')::date = v_hoy) >= 5 then
    raise exception 'limite_diario_reportes';
  end if;

  insert into reporte_punto (punto_reciclaje_id, usuario_id, tipo_reporte, subtipo, descripcion_reporte, ruta_foto)
  values (p_id_punto, v_usuario, v_grupo, p_tipo, v_comentario, p_foto_ruta);

  insert into movimiento_punto (usuario_id, tipo_movimiento, cantidad_puntos, id_referencia)
  values (v_usuario, 'reporte_punto', v_puntos, p_id_punto);

  -- Dos personas distintas lo reportan lleno en 12 h: el mapa lo marca lleno.
  if p_tipo = 'lleno_saturado' and (
    select count(distinct usuario_id) from reporte_punto
     where punto_reciclaje_id = p_id_punto
       and subtipo = 'lleno_saturado'
       and fecha_reporte > now() - interval '12 hours'
  ) >= 2 then
    update punto_reciclaje
       set estado_operativo = 'lleno'
     where punto_reciclaje_id = p_id_punto
       and estado_operativo = 'operativo';
  end if;

  return jsonb_build_object('puntos', v_puntos);
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

create or replace function public.app_opiniones_punto(p_id_punto integer)
returns jsonb
language sql
stable
security definer
set search_path = public
as $$
  select jsonb_build_object(
    'etiquetas', coalesce((
      select jsonb_agg(jsonb_build_object('etiqueta', e.etiqueta, 'cantidad', e.cantidad) order by e.cantidad desc)
        from (
          select et as etiqueta, count(*) as cantidad
            from calificacion_punto cp, unnest(cp.etiquetas) et
           where cp.punto_reciclaje_id = p_id_punto
           group by et
        ) e
    ), '[]'::jsonb),
    'opiniones', coalesce((
      select jsonb_agg(jsonb_build_object(
               'alias', u.nombre_usuario,
               'puntuacion', cp.puntuacion,
               'comentario', cp.comentario,
               'fecha', cp.fecha_calificacion
             ) order by cp.fecha_calificacion desc)
        from calificacion_punto cp
        join usuario u on u.usuario_id = cp.usuario_id
       where cp.punto_reciclaje_id = p_id_punto
         and cp.comentario is not null
    ), '[]'::jsonb)
  )
$$;

create or replace function public.app_mis_reportes()
returns table (
  id_punto integer,
  punto text,
  tipo_reporte text,
  comentario text,
  fecha timestamptz,
  estado_alerta text,
  fue_fundada boolean
)
language sql
stable
security definer
set search_path = public
as $$
  select
    r.punto_reciclaje_id,
    p.nombre_punto::text,
    coalesce(r.subtipo, r.tipo_reporte::text),
    r.descripcion_reporte,
    r.fecha_reporte,
    case r.estado_reporte::text
      when 'pendiente' then 'recibida'
      when 'en_revision' then 'en_atencion'
      else 'resuelta'
    end,
    case r.estado_reporte::text
      when 'resuelto' then true
      when 'rechazado' then false
    end
  from reporte_punto r
  join punto_reciclaje p on p.punto_reciclaje_id = r.punto_reciclaje_id
  where r.usuario_id = public.app_usuario_id()
  order by r.fecha_reporte desc
  limit 100
$$;

-- ===========================================================================
-- Beneficios y canjes
-- ===========================================================================

create or replace function public.app_beneficios()
returns table (
  id_beneficio integer,
  nombre text,
  descripcion text,
  costo_en_puntos integer,
  tipo text,
  entidad text,
  vigencia_fin timestamptz,
  tope_por_usuario integer,
  stock integer,
  canjeados integer
)
language sql
stable
security definer
set search_path = public
as $$
  select
    b.canjeo_beneficio_id,
    b.nombre_beneficio::text,
    b.descripcion,
    b.costo_puntos,
    'canje',
    e.nombre_entidad::text,
    timestamptz '2099-12-31 23:59:59-03',
    null::integer,
    b.cantidad_disponible,
    (select count(*)::int from canjeo c
      where c.canjeo_beneficio_id = b.canjeo_beneficio_id
        and c.estado_canje not in ('cancelado', 'rechazado'))
  from canjeo_beneficio b
  join entidad_administradora e on e.entidad_administradora_id = b.entidad_administradora_id
  where coalesce(b.activo, true)
  order by b.costo_puntos
$$;

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

  select * into v_beneficio from canjeo_beneficio where canjeo_beneficio_id = p_id_beneficio;
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

create or replace function public.app_mis_canjes()
returns table (
  id_canje integer,
  codigo_canje text,
  estado text,
  beneficio text,
  entidad text,
  costo integer,
  fecha_generacion timestamptz,
  fecha_validacion timestamptz
)
language sql
stable
security definer
set search_path = public
as $$
  select
    c.canjeo_id,
    coalesce(c.codigo_canje, '')::text,
    case c.estado_canje::text
      when 'entregado' then 'validado'
      when 'cancelado' then 'cancelado'
      when 'rechazado' then 'cancelado'
      else 'pendiente'
    end,
    b.nombre_beneficio::text,
    e.nombre_entidad::text,
    b.costo_puntos,
    c.fecha,
    c.fecha_validacion
  from canjeo c
  join canjeo_beneficio b on b.canjeo_beneficio_id = c.canjeo_beneficio_id
  join entidad_administradora e on e.entidad_administradora_id = b.entidad_administradora_id
  where c.usuario_id = public.app_usuario_id()
  order by c.fecha desc
$$;

-- ===========================================================================
-- Comunidad
-- ===========================================================================

create or replace function public.app_comunidades(p_comuna text default null)
returns table (
  id integer,
  nombre text,
  descripcion text,
  comuna text,
  tipo text,
  miembros integer,
  es_miembro boolean,
  mi_rol text,
  puntos_semana integer
)
language sql
stable
security definer
set search_path = public
as $$
  select
    c.comunidad_id,
    c.nombre_comunidad::text,
    c.descripcion_comunidad,
    c.comuna::text,
    c.tipo_comunidad::text,
    (select count(*)::int from miembro_comunidad m where m.comunidad_id = c.comunidad_id),
    exists (select 1 from miembro_comunidad m
             where m.comunidad_id = c.comunidad_id and m.usuario_id = public.app_usuario_id()),
    (select m.rol_miembro::text from miembro_comunidad m
      where m.comunidad_id = c.comunidad_id and m.usuario_id = public.app_usuario_id()),
    (select coalesce(sum(r.puntos_obtenidos), 0)::int
       from reciclaje r
       join miembro_comunidad m on m.usuario_id = r.usuario_id and m.comunidad_id = c.comunidad_id
      where r.fecha_reciclaje > now() - interval '7 days')
  from comunidad c
  where p_comuna is null or c.comuna = p_comuna
  order by 7 desc, 6 desc, c.nombre_comunidad
  limit 100
$$;

create or replace function public.app_crear_comunidad(
  p_nombre text,
  p_descripcion text default null,
  p_comuna text default null
)
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  v_usuario integer := public.app_usuario_id();
  v_nombre text := btrim(p_nombre);
  v_id integer;
begin
  if v_usuario is null then
    raise exception 'sesion_requerida';
  end if;
  if v_nombre is null or char_length(v_nombre) not between 3 and 100 then
    raise exception 'nombre_invalido';
  end if;
  if char_length(coalesce(p_descripcion, '')) > 500 then
    raise exception 'descripcion_invalida';
  end if;
  if (select count(*) from comunidad where creador_id = v_usuario) >= 3 then
    raise exception 'limite_comunidades';
  end if;

  insert into comunidad (nombre_comunidad, descripcion_comunidad, tipo_comunidad, creador_id, comuna)
  values (v_nombre, nullif(btrim(p_descripcion), ''), 'junta_vecinos', v_usuario, nullif(btrim(p_comuna), ''))
  returning comunidad_id into v_id;

  insert into foro (comunidad_id, nombre) values (v_id, 'Anuncios de ' || left(v_nombre, 80));
  insert into miembro_comunidad (comunidad_id, usuario_id, rol_miembro)
  values (v_id, v_usuario, 'administrador');
  return v_id;
end;
$$;

create or replace function public.app_unirse_comunidad(p_id integer)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_usuario integer := public.app_usuario_id();
begin
  if v_usuario is null then
    raise exception 'sesion_requerida';
  end if;
  if not exists (select 1 from comunidad where comunidad_id = p_id) then
    raise exception 'comunidad_no_encontrada';
  end if;
  insert into miembro_comunidad (comunidad_id, usuario_id)
  values (p_id, v_usuario)
  on conflict (comunidad_id, usuario_id) do nothing;
end;
$$;

create or replace function public.app_salir_comunidad(p_id integer)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  delete from miembro_comunidad
   where comunidad_id = p_id and usuario_id = public.app_usuario_id();
end;
$$;

create or replace function public.app_miembros_comunidad(p_id integer)
returns table (alias text, puntos integer, rol text, es_yo boolean)
language sql
stable
security definer
set search_path = public
as $$
  select
    u.nombre_usuario::text,
    coalesce((select sum(mp.cantidad_puntos)::int from movimiento_punto mp
               where mp.usuario_id = u.usuario_id and mp.cantidad_puntos > 0
                 and mp.tipo_movimiento not in ('canje_beneficio', 'devolucion_canje')), 0),
    m.rol_miembro::text,
    u.usuario_id = public.app_usuario_id()
  from miembro_comunidad m
  join usuario u on u.usuario_id = m.usuario_id
  where m.comunidad_id = p_id
  order by 2 desc
  limit 100
$$;

create or replace function public.app_publicaciones_comunidad(p_id integer, p_limite integer default 50)
returns table (id integer, autor text, texto text, fecha timestamptz, es_propio boolean)
language sql
stable
security definer
set search_path = public
as $$
  select
    pf.publicacion_foro_id,
    u.nombre_usuario::text,
    pf.contenido,
    pf.fecha_publicacion,
    pf.usuario_id = public.app_usuario_id()
  from publicacion_foro pf
  join foro f on f.foro_id = pf.foro_id
  join usuario u on u.usuario_id = pf.usuario_id
  where f.comunidad_id = p_id
  order by pf.fecha_publicacion desc
  limit greatest(least(p_limite, 100), 1)
$$;

create or replace function public.app_publicar_comunidad(p_id integer, p_texto text)
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  v_usuario integer := public.app_usuario_id();
  v_texto text := btrim(p_texto);
  v_foro integer;
  v_id integer;
begin
  if v_usuario is null then
    raise exception 'sesion_requerida';
  end if;
  if not exists (select 1 from miembro_comunidad where comunidad_id = p_id and usuario_id = v_usuario) then
    raise exception 'no_es_miembro';
  end if;
  if v_texto is null or char_length(v_texto) not between 1 and 1000 then
    raise exception 'texto_invalido';
  end if;
  if (select count(*) from publicacion_foro
       where usuario_id = v_usuario and fecha_publicacion > now() - interval '24 hours') >= 20 then
    raise exception 'limite_publicaciones';
  end if;

  select foro_id into v_foro from foro where comunidad_id = p_id;
  if v_foro is null then
    insert into foro (comunidad_id, nombre) values (p_id, 'Anuncios') returning foro_id into v_foro;
  end if;

  insert into publicacion_foro (foro_id, usuario_id, titulo, contenido)
  values (v_foro, v_usuario, left(v_texto, 150), v_texto)
  returning publicacion_foro_id into v_id;
  return v_id;
end;
$$;

-- ===========================================================================
-- Servicios de terceros
-- ===========================================================================

create or replace function public.app_servicios(
  comuna_filtro text default null,
  materiales_filtro text[] default null
)
returns table (
  id text,
  nombre text,
  materiales text[],
  comunas text[],
  descripcion text,
  contacto text,
  retira_a_domicilio boolean,
  horario jsonb,
  puntos jsonb
)
language sql
stable
security definer
set search_path = public
as $$
  select
    s.servicio_tercero_id::text,
    s.nombre::text,
    s.materiales,
    s.comunas,
    s.descripcion,
    s.contacto::text,
    s.retira_a_domicilio,
    s.horario,
    '[]'::jsonb
  from servicio_tercero s
  where s.estado = 'activo'
    and (comuna_filtro is null or comuna_filtro = any (s.comunas))
    and (materiales_filtro is null or s.materiales && materiales_filtro)
  order by s.nombre
$$;

create or replace function public.app_postular_servicio(
  p_nombre text,
  p_contacto text,
  p_comunas text[],
  p_materiales text[],
  p_descripcion text default null,
  p_retira_a_domicilio boolean default false,
  p_horario jsonb default null
)
returns text
language plpgsql
security definer
set search_path = public
as $$
declare
  v_usuario integer := public.app_usuario_id();
  v_id integer;
begin
  if v_usuario is null then
    raise exception 'sesion_requerida';
  end if;
  if char_length(coalesce(btrim(p_nombre), '')) not between 3 and 100 then
    raise exception 'nombre_invalido';
  end if;
  if char_length(coalesce(btrim(p_contacto), '')) not between 5 and 150 then
    raise exception 'contacto_invalido';
  end if;
  if char_length(coalesce(p_descripcion, '')) > 500 then
    raise exception 'descripcion_invalida';
  end if;
  if coalesce(cardinality(p_comunas), 0) not between 1 and 10 then
    raise exception 'comunas_invalidas';
  end if;
  if coalesce(cardinality(p_materiales), 0) not between 1 and 10
     or exists (select 1 from unnest(p_materiales) m
                 where m not in (select codigo from categoria_residuo where codigo is not null)) then
    raise exception 'categorias_invalidas';
  end if;
  if p_horario is not null and jsonb_typeof(p_horario) <> 'object' then
    raise exception 'horario_invalido';
  end if;
  if (select count(*) from servicio_tercero where usuario_id = v_usuario and estado = 'pendiente') >= 3 then
    raise exception 'limite_postulaciones';
  end if;

  insert into servicio_tercero (usuario_id, nombre, contacto, descripcion, comunas, materiales, retira_a_domicilio, horario)
  values (v_usuario, btrim(p_nombre), btrim(p_contacto), nullif(btrim(p_descripcion), ''),
          p_comunas, p_materiales, coalesce(p_retira_a_domicilio, false), p_horario)
  returning servicio_tercero_id into v_id;
  return v_id::text;
end;
$$;

create or replace function public.app_mis_postulaciones()
returns table (id text, nombre text, estado text, motivo_rechazo text, fecha_registro timestamptz)
language sql
stable
security definer
set search_path = public
as $$
  select s.servicio_tercero_id::text, s.nombre::text, s.estado::text, s.motivo_rechazo, s.fecha_registro
    from servicio_tercero s
   where s.usuario_id = public.app_usuario_id()
   order by s.fecha_registro desc
$$;

-- ===========================================================================
-- Permisos de ejecución
-- ===========================================================================

do $$
declare
  f record;
begin
  for f in
    select p.oid::regprocedure as firma, p.proname
      from pg_proc p
     where p.pronamespace = 'public'::regnamespace
       and (p.proname like 'app\_%' or p.proname = '_racha')
  loop
    execute format('revoke all on function %s from public, anon', f.firma);
    if f.proname <> '_racha' then
      execute format('grant execute on function %s to authenticated', f.firma);
    end if;
  end loop;
end $$;

-- Lo que se puede ver sin sesión (si falló el login anónimo).
grant execute on function public.app_niveles() to anon;
grant execute on function public.app_puntos_cercanos(double precision, double precision, double precision, text, text[], boolean, double precision) to anon;
grant execute on function public.app_servicios(text, text[]) to anon;
grant execute on function public.app_beneficios() to anon;
grant execute on function public.app_opiniones_punto(integer) to anon;
grant execute on function public.app_comunidades(text) to anon;

commit;
