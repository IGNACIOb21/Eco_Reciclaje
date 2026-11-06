-- ============================================================================
-- NO TOMAR COMO REFERENCIA DEL ESQUEMA ACTUAL (nota agregada 2026-10-07)
--
-- Volcado de `supabase db pull` del 2026-10-03 contra el proyecto
-- telgqotqvjzobuucahca. Ya figura como aplicada en la nube (el pull la
-- registra), por eso se queda en migrations/: sacarla haría fallar el
-- siguiente db push / db pull ("Remote migration versions not found").
--
-- Describe un esquema ANTERIOR (tablas en singular: usuario, rol,
-- movimiento_punto...). El esquema real que usan la Web API y la APK es el de
-- docs/esquema-remoto.md del repo rebin (usuarios, movimientos_puntos...).
-- Su trigger handle_new_auth_user (insert en public.usuario) es justamente el
-- que rompía el alta de usuarios y se corrigió en
-- rebin/backend/remoto/20261006140000_fix_triggers_auth.sql.
-- Para sacarla del historial remoto: `supabase migration repair --status
-- reverted 20261003035059`, solo con autorización del dueño del proyecto.
-- ============================================================================

SET local check_function_bodies = off;

CREATE TABLE "public"."beneficio_comunidad" (
  "beneficio_comunidad_id" bigint                   GENERATED ALWAYS AS IDENTITY NOT NULL,
  "meta_comunidad_id"      bigint                   NOT NULL,
  "descripcion_beneficio"  text                     NOT NULL,
  "estado_beneficio"       text                     NOT NULL DEFAULT 'pendiente'::text,
  "fecha_asignacion"       timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT "beneficio_comunidad_estado_check" CHECK ((estado_beneficio = ANY (ARRAY['pendiente'::text, 'disponible'::text, 'entregado'::text]))),
  CONSTRAINT "beneficio_comunidad_pkey" PRIMARY KEY (beneficio_comunidad_id)
);

ALTER TABLE "public"."beneficio_comunidad"
  ENABLE ROW LEVEL SECURITY;

CREATE TABLE "public"."calificacion_punto" (
  "calificacion_punto_id" bigint                   GENERATED ALWAYS AS IDENTITY NOT NULL,
  "punto_reciclaje_id"    bigint                   NOT NULL,
  "usuario_id"            bigint                   NOT NULL,
  "puntuacion"            integer                  NOT NULL,
  "comentario"            text,
  "fecha_calificacion"    timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT "calificacion_punto_pkey" PRIMARY KEY (calificacion_punto_id),
  CONSTRAINT "calificacion_punto_puntuacion_check" CHECK (((puntuacion >= 1) AND (puntuacion <= 5))),
  CONSTRAINT "calificacion_punto_unica" UNIQUE (punto_reciclaje_id, usuario_id)
);

ALTER TABLE "public"."calificacion_punto"
  ENABLE ROW LEVEL SECURITY;

CREATE TABLE "public"."canjeo_beneficio" (
  "canjeo_beneficio_id"       bigint  GENERATED ALWAYS AS IDENTITY NOT NULL,
  "nombre_beneficio"          text    NOT NULL,
  "descripcion"               text,
  "costo_puntos"              integer NOT NULL,
  "cantidad_disponible"       integer NOT NULL DEFAULT 0,
  "entidad_administradora_id" bigint  NOT NULL,
  "activo"                    boolean NOT NULL DEFAULT true,
  CONSTRAINT "canjeo_beneficio_cantidad_disponible_check" CHECK ((cantidad_disponible >= 0)),
  CONSTRAINT "canjeo_beneficio_costo_puntos_check" CHECK ((costo_puntos > 0)),
  CONSTRAINT "canjeo_beneficio_pkey" PRIMARY KEY (canjeo_beneficio_id)
);

ALTER TABLE "public"."canjeo_beneficio"
  ENABLE ROW LEVEL SECURITY;

CREATE TABLE "public"."canjeo" (
  "canjeo_id"           bigint                   GENERATED ALWAYS AS IDENTITY NOT NULL,
  "usuario_id"          bigint                   NOT NULL,
  "canjeo_beneficio_id" bigint                   NOT NULL,
  "estado_canje"        text                     NOT NULL DEFAULT 'pendiente'::text,
  "fecha"               timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT "canjeo_estado_check" CHECK ((estado_canje = ANY (ARRAY['pendiente'::text, 'aprobado'::text, 'entregado'::text, 'cancelado'::text, 'rechazado'::text]))),
  CONSTRAINT "canjeo_pkey" PRIMARY KEY (canjeo_id)
);

ALTER TABLE "public"."canjeo"
  ENABLE ROW LEVEL SECURITY;

CREATE TABLE "public"."categoria_residuo" (
  "categoria_residuo_id"  bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  "nombre_categoria"      text   NOT NULL,
  "codigo_color"          text,
  "descripcion_categoria" text,
  "destino_reciclaje"     text,
  CONSTRAINT "categoria_residuo_pkey" PRIMARY KEY (categoria_residuo_id)
);

ALTER TABLE "public"."categoria_residuo"
  ENABLE ROW LEVEL SECURITY;

CREATE TABLE "public"."comentario_foro" (
  "comentario_foro_id"  bigint                   GENERATED ALWAYS AS IDENTITY NOT NULL,
  "publicacion_foro_id" bigint                   NOT NULL,
  "usuario_id"          bigint                   NOT NULL,
  "contenido"           text                     NOT NULL,
  "fecha_comentario"    timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT "comentario_foro_pkey" PRIMARY KEY (comentario_foro_id)
);

ALTER TABLE "public"."comentario_foro"
  ENABLE ROW LEVEL SECURITY;

CREATE TABLE "public"."comunidad" (
  "comunidad_id"          bigint                   GENERATED ALWAYS AS IDENTITY NOT NULL,
  "nombre_comunidad"      text                     NOT NULL,
  "descripcion_comunidad" text,
  "tipo_comunidad"        text,
  "creador_id"            bigint,
  "url_icono"             text,
  "fecha_creacion"        timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT "comunidad_pkey" PRIMARY KEY (comunidad_id)
);

ALTER TABLE "public"."comunidad"
  ENABLE ROW LEVEL SECURITY;

CREATE TABLE "public"."configuracion_usuario" (
  "usuario_id"             bigint  NOT NULL,
  "elemento_mapa_id"       bigint,
  "elemento_avatar_id"     bigint,
  "elemento_app_id"        bigint,
  "codigo_color_fondo"     text,
  "notificaciones_activas" boolean NOT NULL DEFAULT true,
  CONSTRAINT "configuracion_usuario_pkey" PRIMARY KEY (usuario_id)
);

ALTER TABLE "public"."configuracion_usuario"
  ENABLE ROW LEVEL SECURITY;

CREATE TABLE "public"."distribucion_puntos" (
  "distribucion_puntos_id" bigint                   GENERATED ALWAYS AS IDENTITY NOT NULL,
  "usuario_id"             bigint                   NOT NULL,
  "destino"                text                     NOT NULL,
  "comunidad_destino_id"   bigint,
  "porcentaje_asignacion"  integer                  NOT NULL DEFAULT 100,
  "fecha_actualizacion"    timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT "distribucion_puntos_comunidad_requerida" CHECK (((destino <> 'comunidad'::text) OR (comunidad_destino_id IS NOT NULL))),
  CONSTRAINT "distribucion_puntos_destino_check" CHECK ((destino = ANY (ARRAY['personal'::text, 'comunidad'::text]))),
  CONSTRAINT "distribucion_puntos_pkey" PRIMARY KEY (distribucion_puntos_id),
  CONSTRAINT "distribucion_puntos_porcentaje_check" CHECK (((porcentaje_asignacion >= 0) AND (porcentaje_asignacion <= 100)))
);

ALTER TABLE "public"."distribucion_puntos"
  ENABLE ROW LEVEL SECURITY;

CREATE TABLE "public"."elemento_personalizado" (
  "elemento_personalizado_id" bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  "tipo_elemento"             text   NOT NULL,
  "nombre"                    text   NOT NULL,
  "url_recurso"               text,
  CONSTRAINT "elemento_personalizado_pkey" PRIMARY KEY (elemento_personalizado_id)
);

ALTER TABLE "public"."elemento_personalizado"
  ENABLE ROW LEVEL SECURITY;

CREATE TABLE "public"."elemento_usuario" (
  "elemento_usuario_id"       bigint                   GENERATED ALWAYS AS IDENTITY NOT NULL,
  "usuario_id"                bigint                   NOT NULL,
  "elemento_personalizado_id" bigint                   NOT NULL,
  "esta_equipado"             boolean                  NOT NULL DEFAULT false,
  "fecha_desbloqueo"          timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT "elemento_usuario_pkey" PRIMARY KEY (elemento_usuario_id),
  CONSTRAINT "elemento_usuario_unico" UNIQUE (usuario_id, elemento_personalizado_id)
);

ALTER TABLE "public"."elemento_usuario"
  ENABLE ROW LEVEL SECURITY;

CREATE TABLE "public"."entidad_administradora" (
  "entidad_administradora_id" bigint                   GENERATED ALWAYS AS IDENTITY NOT NULL,
  "nombre_entidad"            text                     NOT NULL,
  "tipo_entidad"              text,
  "correo_contacto"           text,
  "fecha_registro"            timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT "entidad_administradora_pkey" PRIMARY KEY (entidad_administradora_id)
);

ALTER TABLE "public"."entidad_administradora"
  ENABLE ROW LEVEL SECURITY;

CREATE TABLE "public"."evento_reciclaje" (
  "evento_reciclaje_id"       bigint                   GENERATED ALWAYS AS IDENTITY NOT NULL,
  "entidad_administradora_id" bigint                   NOT NULL,
  "punto_reciclaje_id"        bigint,
  "nombre_evento"             text                     NOT NULL,
  "descripcion"               text,
  "fecha_inicio"              timestamp with time zone NOT NULL,
  "fecha_fin"                 timestamp with time zone,
  "puntos_bonificacion"       integer                  NOT NULL DEFAULT 0,
  CONSTRAINT "evento_reciclaje_fechas_check" CHECK (((fecha_fin IS NULL) OR (fecha_fin >= fecha_inicio))),
  CONSTRAINT "evento_reciclaje_pkey" PRIMARY KEY (evento_reciclaje_id)
);

ALTER TABLE "public"."evento_reciclaje"
  ENABLE ROW LEVEL SECURITY;

CREATE TABLE "public"."evento_usuario" (
  "evento_reciclaje_id" bigint                   NOT NULL,
  "usuario_id"          bigint                   NOT NULL,
  "fecha_inscripcion"   timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT "evento_usuario_pkey" PRIMARY KEY (evento_reciclaje_id, usuario_id)
);

ALTER TABLE "public"."evento_usuario"
  ENABLE ROW LEVEL SECURITY;

CREATE TABLE "public"."foro" (
  "foro_id"        bigint                   GENERATED ALWAYS AS IDENTITY NOT NULL,
  "comunidad_id"   bigint                   NOT NULL,
  "nombre"         text,
  "fecha_creacion" timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT "foro_comunidad_id_key" UNIQUE (comunidad_id),
  CONSTRAINT "foro_pkey" PRIMARY KEY (foro_id)
);

ALTER TABLE "public"."foro"
  ENABLE ROW LEVEL SECURITY;

CREATE TABLE "public"."logro_usuario" (
  "logro_usuario_id" bigint                   GENERATED ALWAYS AS IDENTITY NOT NULL,
  "usuario_id"       bigint                   NOT NULL,
  "logro_id"         bigint                   NOT NULL,
  "fecha_obtenido"   timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT "logro_usuario_pkey" PRIMARY KEY (logro_usuario_id),
  CONSTRAINT "logro_usuario_unico" UNIQUE (usuario_id, logro_id)
);

ALTER TABLE "public"."logro_usuario"
  ENABLE ROW LEVEL SECURITY;

CREATE TABLE "public"."logro" (
  "logro_id"                  bigint  GENERATED ALWAYS AS IDENTITY NOT NULL,
  "nombre"                    text    NOT NULL,
  "descripcion"               text,
  "umbral_logro"              integer NOT NULL,
  "icono"                     text,
  "elemento_personalizado_id" bigint,
  CONSTRAINT "logro_pkey" PRIMARY KEY (logro_id)
);

ALTER TABLE "public"."logro"
  ENABLE ROW LEVEL SECURITY;

CREATE TABLE "public"."meta_comunidad" (
  "meta_comunidad_id"         bigint  GENERATED ALWAYS AS IDENTITY NOT NULL,
  "comunidad_id"              bigint  NOT NULL,
  "descripcion_meta"          text,
  "puntos_objetivo"           integer NOT NULL,
  "entidad_administradora_id" bigint,
  "estado_meta"               text    NOT NULL DEFAULT 'activa'::text,
  "fecha_limite"              date,
  CONSTRAINT "meta_comunidad_pkey" PRIMARY KEY (meta_comunidad_id),
  CONSTRAINT "meta_comunidad_puntos_objetivo_check" CHECK ((puntos_objetivo > 0))
);

ALTER TABLE "public"."meta_comunidad"
  ENABLE ROW LEVEL SECURITY;

CREATE TABLE "public"."miembro_comunidad" (
  "miembro_comunidad_id" bigint                   GENERATED ALWAYS AS IDENTITY NOT NULL,
  "comunidad_id"         bigint                   NOT NULL,
  "usuario_id"           bigint                   NOT NULL,
  "rol_miembro"          text                     NOT NULL DEFAULT 'miembro'::text,
  "fecha_ingreso"        timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT "miembro_comunidad_pkey" PRIMARY KEY (miembro_comunidad_id),
  CONSTRAINT "miembro_comunidad_unico" UNIQUE (comunidad_id, usuario_id)
);

ALTER TABLE "public"."miembro_comunidad"
  ENABLE ROW LEVEL SECURITY;

CREATE TABLE "public"."movimiento_punto" (
  "movimiento_punto_id" bigint                   GENERATED ALWAYS AS IDENTITY NOT NULL,
  "usuario_id"          bigint,
  "comunidad_id"        bigint,
  "tipo_movimiento"     text                     NOT NULL,
  "cantidad_puntos"     integer                  NOT NULL,
  "id_referencia"       bigint,
  "fecha_movimiento"    timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT "movimiento_punto_destino_check" CHECK (((usuario_id IS NOT NULL) OR (comunidad_id IS NOT NULL))),
  CONSTRAINT "movimiento_punto_pkey" PRIMARY KEY (movimiento_punto_id),
  CONSTRAINT "movimiento_punto_tipo_check"
    CHECK ((tipo_movimiento = ANY (ARRAY['reciclaje_personal'::text, 'aporte_comunidad'::text, 'canje_beneficio'::text, 'recompensa_logro'::text])))
);

ALTER TABLE "public"."movimiento_punto"
  ENABLE ROW LEVEL SECURITY;

CREATE TABLE "public"."notificacion" (
  "notificacion_id"   bigint                   GENERATED ALWAYS AS IDENTITY NOT NULL,
  "usuario_id"        bigint                   NOT NULL,
  "tipo_notificacion" text                     NOT NULL,
  "mensaje"           text                     NOT NULL,
  "fecha_envio"       timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT "notificacion_pkey" PRIMARY KEY (notificacion_id)
);

ALTER TABLE "public"."notificacion"
  ENABLE ROW LEVEL SECURITY;

CREATE TABLE "public"."publicacion_foro" (
  "publicacion_foro_id" bigint                   GENERATED ALWAYS AS IDENTITY NOT NULL,
  "foro_id"             bigint                   NOT NULL,
  "usuario_id"          bigint                   NOT NULL,
  "titulo"              text                     NOT NULL,
  "contenido"           text,
  "fecha_publicacion"   timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT "publicacion_foro_pkey" PRIMARY KEY (publicacion_foro_id)
);

ALTER TABLE "public"."publicacion_foro"
  ENABLE ROW LEVEL SECURITY;

CREATE TABLE "public"."punto_categoria" (
  "punto_reciclaje_id"   bigint NOT NULL,
  "categoria_residuo_id" bigint NOT NULL,
  CONSTRAINT "punto_categoria_pkey" PRIMARY KEY (punto_reciclaje_id, categoria_residuo_id)
);

ALTER TABLE "public"."punto_categoria"
  ENABLE ROW LEVEL SECURITY;

CREATE TABLE "public"."punto_reciclaje" (
  "punto_reciclaje_id"         bigint                   GENERATED ALWAYS AS IDENTITY NOT NULL,
  "nombre_punto"               text                     NOT NULL,
  "coordenada_latitud"         numeric(9,6)             NOT NULL,
  "coordenada_longitud"        numeric(9,6)             NOT NULL,
  "direccion_completa"         text,
  "entidad_administradora_id"  bigint,
  "estado_operativo"           text                     NOT NULL DEFAULT 'operativo'::text,
  "capacidad_maxima_articulos" integer,
  "fecha_registro"             timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT "punto_reciclaje_estado_check" CHECK ((estado_operativo = ANY (ARRAY['operativo'::text, 'lleno'::text, 'mantenimiento'::text, 'fuera_servicio'::text]))),
  CONSTRAINT "punto_reciclaje_pkey" PRIMARY KEY (punto_reciclaje_id)
);

ALTER TABLE "public"."punto_reciclaje"
  ENABLE ROW LEVEL SECURITY;

CREATE TABLE "public"."reciclaje" (
  "reciclaje_id"         bigint                   GENERATED ALWAYS AS IDENTITY NOT NULL,
  "usuario_id"           bigint                   NOT NULL,
  "punto_reciclaje_id"   bigint,
  "categoria_residuo_id" bigint                   NOT NULL,
  "cantidad_articulos"   integer                  NOT NULL,
  "puntos_obtenidos"     integer                  NOT NULL DEFAULT 0,
  "fecha_reciclaje"      timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT "reciclaje_cantidad_articulos_check" CHECK ((cantidad_articulos > 0)),
  CONSTRAINT "reciclaje_pkey" PRIMARY KEY (reciclaje_id)
);

ALTER TABLE "public"."reciclaje"
  ENABLE ROW LEVEL SECURITY;

CREATE TABLE "public"."regla_puntuacion" (
  "regla_puntuacion_id"       bigint  GENERATED ALWAYS AS IDENTITY NOT NULL,
  "categoria_residuo_id"      bigint  NOT NULL,
  "entidad_administradora_id" bigint,
  "puntos_unitarios"          integer NOT NULL,
  "fecha_inicio_vigencia"     date    NOT NULL DEFAULT CURRENT_DATE,
  "fecha_fin_vigencia"        date,
  CONSTRAINT "regla_puntuacion_pkey" PRIMARY KEY (regla_puntuacion_id),
  CONSTRAINT "regla_puntuacion_vigencia_check" CHECK (((fecha_fin_vigencia IS NULL) OR (fecha_fin_vigencia >= fecha_inicio_vigencia)))
);

ALTER TABLE "public"."regla_puntuacion"
  ENABLE ROW LEVEL SECURITY;

CREATE TABLE "public"."reporte_punto" (
  "reporte_punto_id"    bigint                   GENERATED ALWAYS AS IDENTITY NOT NULL,
  "punto_reciclaje_id"  bigint                   NOT NULL,
  "usuario_id"          bigint,
  "tipo_reporte"        text                     NOT NULL,
  "descripcion_reporte" text,
  "estado_reporte"      text                     NOT NULL DEFAULT 'pendiente'::text,
  "fecha_reporte"       timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT "reporte_punto_pkey" PRIMARY KEY (reporte_punto_id)
);

ALTER TABLE "public"."reporte_punto"
  ENABLE ROW LEVEL SECURITY;

CREATE TABLE "public"."rol" (
  "rol_id"      bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  "nombre"      text   NOT NULL,
  "descripcion" text,
  CONSTRAINT "rol_nombre_key" UNIQUE (nombre),
  CONSTRAINT "rol_pkey" PRIMARY KEY (rol_id)
);

ALTER TABLE "public"."rol"
  ENABLE ROW LEVEL SECURITY;

CREATE TABLE "public"."ticket_mantenimiento" (
  "ticket_mantenimiento_id" bigint                   GENERATED ALWAYS AS IDENTITY NOT NULL,
  "reporte_punto_id"        bigint                   NOT NULL,
  "trabajador_id"           bigint,
  "estado_ticket"           text                     NOT NULL DEFAULT 'pendiente'::text,
  "fecha_creacion"          timestamp with time zone NOT NULL DEFAULT now(),
  "fecha_resolucion"        timestamp with time zone,
  "notas_mantenimiento"     text,
  CONSTRAINT "ticket_mantenimiento_estado_check" CHECK ((estado_ticket = ANY (ARRAY['pendiente'::text, 'en_proceso'::text, 'resuelto'::text, 'cancelado'::text]))),
  CONSTRAINT "ticket_mantenimiento_pkey" PRIMARY KEY (ticket_mantenimiento_id)
);

ALTER TABLE "public"."ticket_mantenimiento"
  ENABLE ROW LEVEL SECURITY;

CREATE TABLE "public"."usuario_rol" (
  "usuario_id"       bigint                   NOT NULL,
  "rol_id"           bigint                   NOT NULL,
  "fecha_asignacion" timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT "usuario_rol_pkey" PRIMARY KEY (usuario_id, rol_id)
);

ALTER TABLE "public"."usuario_rol"
  ENABLE ROW LEVEL SECURITY;

CREATE TABLE "public"."usuario" (
  "usuario_id"         bigint                   GENERATED ALWAYS AS IDENTITY NOT NULL,
  "auth_user_id"       uuid                     NOT NULL,
  "correo_electronico" text,
  "nombre_usuario"     text                     NOT NULL DEFAULT 'Usuario Rebin'::text,
  "url_imagen_perfil"  text,
  "activo"             boolean                  NOT NULL DEFAULT true,
  "fecha_registro"     timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT "usuario_auth_user_id_key" UNIQUE (auth_user_id),
  CONSTRAINT "usuario_pkey" PRIMARY KEY (usuario_id)
);

ALTER TABLE "public"."usuario"
  ENABLE ROW LEVEL SECURITY;

CREATE OR REPLACE FUNCTION public.current_usuario_id()
  RETURNS bigint
  LANGUAGE sql
  STABLE
  SECURITY DEFINER
  SET search_path TO 'public'
  AS $function$
  select usuario_id from public.usuario where auth_user_id = auth.uid();
$function$;

CREATE OR REPLACE FUNCTION public.handle_auth_user_email_change()
  RETURNS TRIGGER
  LANGUAGE plpgsql
  SECURITY DEFINER
  SET search_path TO 'public'
  AS $function$
begin
  if new.email is distinct from old.email then
    update public.usuario set correo_electronico = new.email where auth_user_id = new.id;
  end if;
  return new;
end;
$function$;

CREATE OR REPLACE FUNCTION public.handle_new_auth_user()
  RETURNS TRIGGER
  LANGUAGE plpgsql
  SECURITY DEFINER
  SET search_path TO 'public'
  AS $function$
declare
  v_usuario_id bigint;
  v_rol_id     bigint;
begin
  insert into public.usuario (auth_user_id, correo_electronico, nombre_usuario)
  values (
    new.id,
    new.email,
    coalesce(new.raw_user_meta_data ->> 'nombre_usuario', 'Usuario Rebin')
  )
  on conflict (auth_user_id) do nothing
  returning usuario_id into v_usuario_id;

  if v_usuario_id is null then
    select usuario_id into v_usuario_id from public.usuario where auth_user_id = new.id;
  end if;

  select rol_id into v_rol_id from public.rol where nombre = 'usuario';

  if v_usuario_id is not null and v_rol_id is not null then
    insert into public.usuario_rol (usuario_id, rol_id)
    values (v_usuario_id, v_rol_id)
    on conflict (usuario_id, rol_id) do nothing;
  end if;

  return new;
end;
$function$;

ALTER TABLE "public"."canjeo"
  ADD CONSTRAINT "canjeo_canjeo_beneficio_id_fkey" FOREIGN KEY (canjeo_beneficio_id) REFERENCES public.canjeo_beneficio(canjeo_beneficio_id) ON DELETE RESTRICT;

ALTER TABLE "public"."distribucion_puntos"
  ADD CONSTRAINT "distribucion_puntos_comunidad_destino_id_fkey" FOREIGN KEY (comunidad_destino_id) REFERENCES public.comunidad(comunidad_id) ON DELETE SET NULL;

ALTER TABLE "public"."configuracion_usuario"
  ADD CONSTRAINT "configuracion_usuario_elemento_app_id_fkey" FOREIGN KEY (elemento_app_id) REFERENCES public.elemento_personalizado(elemento_personalizado_id) ON DELETE SET NULL;

ALTER TABLE "public"."configuracion_usuario"
  ADD CONSTRAINT "configuracion_usuario_elemento_avatar_id_fkey" FOREIGN KEY (elemento_avatar_id) REFERENCES public.elemento_personalizado(elemento_personalizado_id) ON DELETE
    SET NULL;

ALTER TABLE "public"."configuracion_usuario"
  ADD CONSTRAINT "configuracion_usuario_elemento_mapa_id_fkey" FOREIGN KEY (elemento_mapa_id) REFERENCES public.elemento_personalizado(elemento_personalizado_id) ON DELETE SET NULL;

ALTER TABLE "public"."elemento_usuario"
  ADD CONSTRAINT "elemento_usuario_elemento_personalizado_id_fkey" FOREIGN KEY (elemento_personalizado_id) REFERENCES public.elemento_personalizado(elemento_personalizado_id)
    ON DELETE CASCADE;

ALTER TABLE "public"."canjeo_beneficio"
  ADD CONSTRAINT "canjeo_beneficio_entidad_administradora_id_fkey" FOREIGN KEY (entidad_administradora_id) REFERENCES public.entidad_administradora(entidad_administradora_id)
    ON DELETE CASCADE;

ALTER TABLE "public"."evento_reciclaje"
  ADD CONSTRAINT "evento_reciclaje_entidad_administradora_id_fkey" FOREIGN KEY (entidad_administradora_id) REFERENCES public.entidad_administradora(entidad_administradora_id)
    ON DELETE CASCADE;

ALTER TABLE "public"."evento_usuario"
  ADD CONSTRAINT "evento_usuario_evento_reciclaje_id_fkey" FOREIGN KEY (evento_reciclaje_id) REFERENCES public.evento_reciclaje(evento_reciclaje_id) ON DELETE CASCADE;

ALTER TABLE "public"."foro"
  ADD CONSTRAINT "foro_comunidad_id_fkey" FOREIGN KEY (comunidad_id) REFERENCES public.comunidad(comunidad_id) ON DELETE CASCADE;

ALTER TABLE "public"."logro"
  ADD CONSTRAINT "logro_elemento_personalizado_id_fkey" FOREIGN KEY (elemento_personalizado_id) REFERENCES public.elemento_personalizado(elemento_personalizado_id) ON DELETE
    SET NULL;

ALTER TABLE "public"."logro_usuario"
  ADD CONSTRAINT "logro_usuario_logro_id_fkey" FOREIGN KEY (logro_id) REFERENCES public.logro(logro_id) ON DELETE CASCADE;

ALTER TABLE "public"."meta_comunidad"
  ADD CONSTRAINT "meta_comunidad_comunidad_id_fkey" FOREIGN KEY (comunidad_id) REFERENCES public.comunidad(comunidad_id) ON DELETE CASCADE;

ALTER TABLE "public"."meta_comunidad"
  ADD CONSTRAINT "meta_comunidad_entidad_administradora_id_fkey" FOREIGN KEY (entidad_administradora_id) REFERENCES public.entidad_administradora(entidad_administradora_id)
    ON DELETE SET NULL;

ALTER TABLE "public"."beneficio_comunidad"
  ADD CONSTRAINT "beneficio_comunidad_meta_comunidad_id_fkey" FOREIGN KEY (meta_comunidad_id) REFERENCES public.meta_comunidad(meta_comunidad_id) ON DELETE CASCADE;

ALTER TABLE "public"."miembro_comunidad"
  ADD CONSTRAINT "miembro_comunidad_comunidad_id_fkey" FOREIGN KEY (comunidad_id) REFERENCES public.comunidad(comunidad_id) ON DELETE CASCADE;

ALTER TABLE "public"."movimiento_punto"
  ADD CONSTRAINT "movimiento_punto_comunidad_id_fkey" FOREIGN KEY (comunidad_id) REFERENCES public.comunidad(comunidad_id) ON DELETE CASCADE;

ALTER TABLE "public"."publicacion_foro"
  ADD CONSTRAINT "publicacion_foro_foro_id_fkey" FOREIGN KEY (foro_id) REFERENCES public.foro(foro_id) ON DELETE CASCADE;

ALTER TABLE "public"."comentario_foro"
  ADD CONSTRAINT "comentario_foro_publicacion_foro_id_fkey" FOREIGN KEY (publicacion_foro_id) REFERENCES public.publicacion_foro(publicacion_foro_id) ON DELETE CASCADE;

ALTER TABLE "public"."punto_categoria"
  ADD CONSTRAINT "punto_categoria_categoria_residuo_id_fkey" FOREIGN KEY (categoria_residuo_id) REFERENCES public.categoria_residuo(categoria_residuo_id) ON DELETE CASCADE;

ALTER TABLE "public"."punto_reciclaje"
  ADD CONSTRAINT "punto_reciclaje_entidad_administradora_id_fkey" FOREIGN KEY (entidad_administradora_id) REFERENCES public.entidad_administradora(entidad_administradora_id)
    ON DELETE SET NULL;

ALTER TABLE "public"."calificacion_punto"
  ADD CONSTRAINT "calificacion_punto_punto_reciclaje_id_fkey" FOREIGN KEY (punto_reciclaje_id) REFERENCES public.punto_reciclaje(punto_reciclaje_id) ON DELETE CASCADE;

ALTER TABLE "public"."evento_reciclaje"
  ADD CONSTRAINT "evento_reciclaje_punto_reciclaje_id_fkey" FOREIGN KEY (punto_reciclaje_id) REFERENCES public.punto_reciclaje(punto_reciclaje_id) ON DELETE SET NULL;

ALTER TABLE "public"."punto_categoria"
  ADD CONSTRAINT "punto_categoria_punto_reciclaje_id_fkey" FOREIGN KEY (punto_reciclaje_id) REFERENCES public.punto_reciclaje(punto_reciclaje_id) ON DELETE CASCADE;

ALTER TABLE "public"."reciclaje"
  ADD CONSTRAINT "reciclaje_categoria_residuo_id_fkey" FOREIGN KEY (categoria_residuo_id) REFERENCES public.categoria_residuo(categoria_residuo_id) ON DELETE RESTRICT;

ALTER TABLE "public"."reciclaje"
  ADD CONSTRAINT "reciclaje_punto_reciclaje_id_fkey" FOREIGN KEY (punto_reciclaje_id) REFERENCES public.punto_reciclaje(punto_reciclaje_id) ON DELETE SET NULL;

ALTER TABLE "public"."regla_puntuacion"
  ADD CONSTRAINT "regla_puntuacion_categoria_residuo_id_fkey" FOREIGN KEY (categoria_residuo_id) REFERENCES public.categoria_residuo(categoria_residuo_id) ON DELETE CASCADE;

ALTER TABLE "public"."regla_puntuacion"
  ADD CONSTRAINT "regla_puntuacion_entidad_administradora_id_fkey" FOREIGN KEY (entidad_administradora_id) REFERENCES public.entidad_administradora(entidad_administradora_id)
    ON DELETE SET NULL;

ALTER TABLE "public"."reporte_punto"
  ADD CONSTRAINT "reporte_punto_punto_reciclaje_id_fkey" FOREIGN KEY (punto_reciclaje_id) REFERENCES public.punto_reciclaje(punto_reciclaje_id) ON DELETE CASCADE;

ALTER TABLE "public"."ticket_mantenimiento"
  ADD CONSTRAINT "ticket_mantenimiento_reporte_punto_id_fkey" FOREIGN KEY (reporte_punto_id) REFERENCES public.reporte_punto(reporte_punto_id) ON DELETE CASCADE;

ALTER TABLE "public"."usuario"
  ADD CONSTRAINT "usuario_auth_user_id_fkey" FOREIGN KEY (auth_user_id) REFERENCES auth.users(id) ON DELETE CASCADE;

ALTER TABLE "public"."calificacion_punto"
  ADD CONSTRAINT "calificacion_punto_usuario_id_fkey" FOREIGN KEY (usuario_id) REFERENCES public.usuario(usuario_id) ON DELETE CASCADE;

ALTER TABLE "public"."canjeo"
  ADD CONSTRAINT "canjeo_usuario_id_fkey" FOREIGN KEY (usuario_id) REFERENCES public.usuario(usuario_id) ON DELETE CASCADE;

ALTER TABLE "public"."comentario_foro"
  ADD CONSTRAINT "comentario_foro_usuario_id_fkey" FOREIGN KEY (usuario_id) REFERENCES public.usuario(usuario_id) ON DELETE CASCADE;

ALTER TABLE "public"."comunidad"
  ADD CONSTRAINT "comunidad_creador_id_fkey" FOREIGN KEY (creador_id) REFERENCES public.usuario(usuario_id) ON DELETE SET NULL;

ALTER TABLE "public"."configuracion_usuario"
  ADD CONSTRAINT "configuracion_usuario_usuario_id_fkey" FOREIGN KEY (usuario_id) REFERENCES public.usuario(usuario_id) ON DELETE CASCADE;

ALTER TABLE "public"."distribucion_puntos"
  ADD CONSTRAINT "distribucion_puntos_usuario_id_fkey" FOREIGN KEY (usuario_id) REFERENCES public.usuario(usuario_id) ON DELETE CASCADE;

ALTER TABLE "public"."elemento_usuario"
  ADD CONSTRAINT "elemento_usuario_usuario_id_fkey" FOREIGN KEY (usuario_id) REFERENCES public.usuario(usuario_id) ON DELETE CASCADE;

ALTER TABLE "public"."evento_usuario"
  ADD CONSTRAINT "evento_usuario_usuario_id_fkey" FOREIGN KEY (usuario_id) REFERENCES public.usuario(usuario_id) ON DELETE CASCADE;

ALTER TABLE "public"."logro_usuario"
  ADD CONSTRAINT "logro_usuario_usuario_id_fkey" FOREIGN KEY (usuario_id) REFERENCES public.usuario(usuario_id) ON DELETE CASCADE;

ALTER TABLE "public"."miembro_comunidad"
  ADD CONSTRAINT "miembro_comunidad_usuario_id_fkey" FOREIGN KEY (usuario_id) REFERENCES public.usuario(usuario_id) ON DELETE CASCADE;

ALTER TABLE "public"."movimiento_punto"
  ADD CONSTRAINT "movimiento_punto_usuario_id_fkey" FOREIGN KEY (usuario_id) REFERENCES public.usuario(usuario_id) ON DELETE CASCADE;

ALTER TABLE "public"."notificacion"
  ADD CONSTRAINT "notificacion_usuario_id_fkey" FOREIGN KEY (usuario_id) REFERENCES public.usuario(usuario_id) ON DELETE CASCADE;

ALTER TABLE "public"."publicacion_foro"
  ADD CONSTRAINT "publicacion_foro_usuario_id_fkey" FOREIGN KEY (usuario_id) REFERENCES public.usuario(usuario_id) ON DELETE CASCADE;

ALTER TABLE "public"."reciclaje"
  ADD CONSTRAINT "reciclaje_usuario_id_fkey" FOREIGN KEY (usuario_id) REFERENCES public.usuario(usuario_id) ON DELETE CASCADE;

ALTER TABLE "public"."reporte_punto"
  ADD CONSTRAINT "reporte_punto_usuario_id_fkey" FOREIGN KEY (usuario_id) REFERENCES public.usuario(usuario_id) ON DELETE SET NULL;

ALTER TABLE "public"."ticket_mantenimiento"
  ADD CONSTRAINT "ticket_mantenimiento_trabajador_id_fkey" FOREIGN KEY (trabajador_id) REFERENCES public.usuario(usuario_id) ON DELETE SET NULL;

ALTER TABLE "public"."usuario_rol"
  ADD CONSTRAINT "usuario_rol_rol_id_fkey" FOREIGN KEY (rol_id) REFERENCES public.rol(rol_id) ON DELETE CASCADE;

ALTER TABLE "public"."usuario_rol"
  ADD CONSTRAINT "usuario_rol_usuario_id_fkey" FOREIGN KEY (usuario_id) REFERENCES public.usuario(usuario_id) ON DELETE CASCADE;

CREATE INDEX idx_beneficio_comunidad_meta ON public.beneficio_comunidad USING btree (meta_comunidad_id);

CREATE INDEX idx_calificacion_punto_usuario ON public.calificacion_punto USING btree (usuario_id);

CREATE INDEX idx_canjeo_beneficio_entidad ON public.canjeo_beneficio USING btree (entidad_administradora_id);

CREATE INDEX idx_canjeo_beneficio ON public.canjeo USING btree (canjeo_beneficio_id);

CREATE INDEX idx_canjeo_usuario ON public.canjeo USING btree (usuario_id);

CREATE INDEX idx_comentario_foro_publicacion ON public.comentario_foro USING btree (publicacion_foro_id);

CREATE INDEX idx_comentario_foro_usuario ON public.comentario_foro USING btree (usuario_id);

CREATE INDEX idx_comunidad_creador ON public.comunidad USING btree (creador_id);

CREATE INDEX idx_distribucion_puntos_comunidad ON public.distribucion_puntos USING btree (comunidad_destino_id);

CREATE INDEX idx_distribucion_puntos_usuario ON public.distribucion_puntos USING btree (usuario_id);

CREATE INDEX idx_elemento_usuario_elemento ON public.elemento_usuario USING btree (elemento_personalizado_id);

CREATE INDEX idx_evento_reciclaje_entidad ON public.evento_reciclaje USING btree (entidad_administradora_id);

CREATE INDEX idx_evento_reciclaje_punto ON public.evento_reciclaje USING btree (punto_reciclaje_id);

CREATE INDEX idx_evento_usuario_usuario ON public.evento_usuario USING btree (usuario_id);

CREATE INDEX idx_logro_elemento ON public.logro USING btree (elemento_personalizado_id);

CREATE INDEX idx_logro_usuario_logro ON public.logro_usuario USING btree (logro_id);

CREATE INDEX idx_meta_comunidad_comunidad ON public.meta_comunidad USING btree (comunidad_id);

CREATE INDEX idx_meta_comunidad_entidad ON public.meta_comunidad USING btree (entidad_administradora_id);

CREATE INDEX idx_miembro_comunidad_usuario ON public.miembro_comunidad USING btree (usuario_id);

CREATE INDEX idx_movimiento_punto_comunidad ON public.movimiento_punto USING btree (comunidad_id);

CREATE INDEX idx_movimiento_punto_tipo ON public.movimiento_punto USING btree (tipo_movimiento);

CREATE INDEX idx_movimiento_punto_usuario ON public.movimiento_punto USING btree (usuario_id);

CREATE INDEX idx_notificacion_usuario ON public.notificacion USING btree (usuario_id);

CREATE INDEX idx_publicacion_foro_foro ON public.publicacion_foro USING btree (foro_id);

CREATE INDEX idx_publicacion_foro_usuario ON public.publicacion_foro USING btree (usuario_id);

CREATE INDEX idx_punto_categoria_categoria ON public.punto_categoria USING btree (categoria_residuo_id);

CREATE INDEX idx_punto_reciclaje_entidad ON public.punto_reciclaje USING btree (entidad_administradora_id);

CREATE INDEX idx_reciclaje_categoria ON public.reciclaje USING btree (categoria_residuo_id);

CREATE INDEX idx_reciclaje_punto ON public.reciclaje USING btree (punto_reciclaje_id);

CREATE INDEX idx_reciclaje_usuario ON public.reciclaje USING btree (usuario_id);

CREATE INDEX idx_regla_puntuacion_categoria ON public.regla_puntuacion USING btree (categoria_residuo_id);

CREATE INDEX idx_regla_puntuacion_entidad ON public.regla_puntuacion USING btree (entidad_administradora_id);

CREATE INDEX idx_reporte_punto_punto ON public.reporte_punto USING btree (punto_reciclaje_id);

CREATE INDEX idx_reporte_punto_usuario ON public.reporte_punto USING btree (usuario_id);

CREATE INDEX idx_ticket_mantenimiento_reporte ON public.ticket_mantenimiento USING btree (reporte_punto_id);

CREATE INDEX idx_ticket_mantenimiento_trabajador ON public.ticket_mantenimiento USING btree (trabajador_id);

CREATE INDEX idx_usuario_auth_user ON public.usuario USING btree (auth_user_id);

CREATE INDEX idx_usuario_rol_rol ON public.usuario_rol USING btree (rol_id);

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_auth_user();

CREATE TRIGGER on_auth_user_email_updated
  AFTER UPDATE OF email ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_auth_user_email_change();

CREATE POLICY "beneficio_comunidad_allow_all" ON "public"."beneficio_comunidad"
  FOR ALL
  TO "anon", "authenticated"
  USING (true)
  WITH CHECK (true);

CREATE POLICY "calificacion_punto_allow_all" ON "public"."calificacion_punto"
  FOR ALL
  TO "anon", "authenticated"
  USING (true)
  WITH CHECK (true);

CREATE POLICY "canjeo_allow_all" ON "public"."canjeo"
  FOR ALL
  TO "anon", "authenticated"
  USING (true)
  WITH CHECK (true);

CREATE POLICY "canjeo_beneficio_allow_all" ON "public"."canjeo_beneficio"
  FOR ALL
  TO "anon", "authenticated"
  USING (true)
  WITH CHECK (true);

CREATE POLICY "categoria_residuo_allow_all" ON "public"."categoria_residuo"
  FOR ALL
  TO "anon", "authenticated"
  USING (true)
  WITH CHECK (true);

CREATE POLICY "comentario_foro_allow_all" ON "public"."comentario_foro"
  FOR ALL
  TO "anon", "authenticated"
  USING (true)
  WITH CHECK (true);

CREATE POLICY "comunidad_allow_all" ON "public"."comunidad"
  FOR ALL
  TO "anon", "authenticated"
  USING (true)
  WITH CHECK (true);

CREATE POLICY "configuracion_usuario_allow_all" ON "public"."configuracion_usuario"
  FOR ALL
  TO "anon", "authenticated"
  USING (true)
  WITH CHECK (true);

CREATE POLICY "distribucion_puntos_allow_all" ON "public"."distribucion_puntos"
  FOR ALL
  TO "anon", "authenticated"
  USING (true)
  WITH CHECK (true);

CREATE POLICY "elemento_personalizado_allow_all" ON "public"."elemento_personalizado"
  FOR ALL
  TO "anon", "authenticated"
  USING (true)
  WITH CHECK (true);

CREATE POLICY "elemento_usuario_allow_all" ON "public"."elemento_usuario"
  FOR ALL
  TO "anon", "authenticated"
  USING (true)
  WITH CHECK (true);

CREATE POLICY "entidad_administradora_allow_all" ON "public"."entidad_administradora"
  FOR ALL
  TO "anon", "authenticated"
  USING (true)
  WITH CHECK (true);

CREATE POLICY "evento_reciclaje_allow_all" ON "public"."evento_reciclaje"
  FOR ALL
  TO "anon", "authenticated"
  USING (true)
  WITH CHECK (true);

CREATE POLICY "evento_usuario_allow_all" ON "public"."evento_usuario"
  FOR ALL
  TO "anon", "authenticated"
  USING (true)
  WITH CHECK (true);

CREATE POLICY "foro_allow_all" ON "public"."foro"
  FOR ALL
  TO "anon", "authenticated"
  USING (true)
  WITH CHECK (true);

CREATE POLICY "logro_allow_all" ON "public"."logro"
  FOR ALL
  TO "anon", "authenticated"
  USING (true)
  WITH CHECK (true);

CREATE POLICY "logro_usuario_allow_all" ON "public"."logro_usuario"
  FOR ALL
  TO "anon", "authenticated"
  USING (true)
  WITH CHECK (true);

CREATE POLICY "meta_comunidad_allow_all" ON "public"."meta_comunidad"
  FOR ALL
  TO "anon", "authenticated"
  USING (true)
  WITH CHECK (true);

CREATE POLICY "miembro_comunidad_allow_all" ON "public"."miembro_comunidad"
  FOR ALL
  TO "anon", "authenticated"
  USING (true)
  WITH CHECK (true);

CREATE POLICY "movimiento_punto_allow_all" ON "public"."movimiento_punto"
  FOR ALL
  TO "anon", "authenticated"
  USING (true)
  WITH CHECK (true);

CREATE POLICY "notificacion_allow_all" ON "public"."notificacion"
  FOR ALL
  TO "anon", "authenticated"
  USING (true)
  WITH CHECK (true);

CREATE POLICY "publicacion_foro_allow_all" ON "public"."publicacion_foro"
  FOR ALL
  TO "anon", "authenticated"
  USING (true)
  WITH CHECK (true);

CREATE POLICY "punto_categoria_allow_all" ON "public"."punto_categoria"
  FOR ALL
  TO "anon", "authenticated"
  USING (true)
  WITH CHECK (true);

CREATE POLICY "punto_reciclaje_allow_all" ON "public"."punto_reciclaje"
  FOR ALL
  TO "anon", "authenticated"
  USING (true)
  WITH CHECK (true);

CREATE POLICY "reciclaje_allow_all" ON "public"."reciclaje"
  FOR ALL
  TO "anon", "authenticated"
  USING (true)
  WITH CHECK (true);

CREATE POLICY "regla_puntuacion_allow_all" ON "public"."regla_puntuacion"
  FOR ALL
  TO "anon", "authenticated"
  USING (true)
  WITH CHECK (true);

CREATE POLICY "reporte_punto_allow_all" ON "public"."reporte_punto"
  FOR ALL
  TO "anon", "authenticated"
  USING (true)
  WITH CHECK (true);

CREATE POLICY "rol_allow_all" ON "public"."rol"
  FOR ALL
  TO "anon", "authenticated"
  USING (true)
  WITH CHECK (true);

CREATE POLICY "ticket_mantenimiento_allow_all" ON "public"."ticket_mantenimiento"
  FOR ALL
  TO "anon", "authenticated"
  USING (true)
  WITH CHECK (true);

CREATE POLICY "Permitir acceso a usuarios autenticados y anónimos" ON "public"."usuario"
  FOR ALL
  TO "anon", "authenticated"
  USING (true)
  WITH CHECK (true);

CREATE POLICY "usuario_select_own" ON "public"."usuario"
  FOR SELECT
  TO "authenticated"
  USING ((auth_user_id = auth.uid()));

CREATE POLICY "usuario_update_own" ON "public"."usuario"
  FOR UPDATE
  TO "authenticated"
  USING ((auth_user_id = auth.uid()))
  WITH CHECK ((auth_user_id = auth.uid()));

CREATE POLICY "usuario_rol_allow_all" ON "public"."usuario_rol"
  FOR ALL
  TO "anon", "authenticated"
  USING (true)
  WITH CHECK (true);

GRANT EXECUTE ON FUNCTION "public"."current_usuario_id"() TO PUBLIC, "anon", "authenticated", "postgres", "service_role";

GRANT EXECUTE ON FUNCTION "public"."handle_auth_user_email_change"() TO PUBLIC, "anon", "authenticated", "postgres", "service_role";

GRANT EXECUTE ON FUNCTION "public"."handle_new_auth_user"() TO PUBLIC, "anon", "authenticated", "postgres", "service_role";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."beneficio_comunidad" TO "anon", "authenticated", "postgres", "service_role";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."calificacion_punto" TO "anon", "authenticated", "postgres", "service_role";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."canjeo" TO "anon", "authenticated", "postgres", "service_role";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."canjeo_beneficio" TO "anon", "authenticated", "postgres", "service_role";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."categoria_residuo" TO "anon", "authenticated", "postgres", "service_role";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."comentario_foro" TO "anon", "authenticated", "postgres", "service_role";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."comunidad" TO "anon", "authenticated", "postgres", "service_role";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."configuracion_usuario" TO "anon", "authenticated", "postgres", "service_role";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."distribucion_puntos" TO "anon", "authenticated", "postgres", "service_role";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."elemento_personalizado" TO "anon", "authenticated", "postgres", "service_role";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."elemento_usuario" TO "anon", "authenticated", "postgres", "service_role";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."entidad_administradora" TO "anon", "authenticated", "postgres", "service_role";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."evento_reciclaje" TO "anon", "authenticated", "postgres", "service_role";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."evento_usuario" TO "anon", "authenticated", "postgres", "service_role";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."foro" TO "anon", "authenticated", "postgres", "service_role";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."logro" TO "anon", "authenticated", "postgres", "service_role";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."logro_usuario" TO "anon", "authenticated", "postgres", "service_role";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."meta_comunidad" TO "anon", "authenticated", "postgres", "service_role";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."miembro_comunidad" TO "anon", "authenticated", "postgres", "service_role";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."movimiento_punto" TO "anon", "authenticated", "postgres", "service_role";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."notificacion" TO "anon", "authenticated", "postgres", "service_role";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."publicacion_foro" TO "anon", "authenticated", "postgres", "service_role";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."punto_categoria" TO "anon", "authenticated", "postgres", "service_role";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."punto_reciclaje" TO "anon", "authenticated", "postgres", "service_role";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."reciclaje" TO "anon", "authenticated", "postgres", "service_role";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."regla_puntuacion" TO "anon", "authenticated", "postgres", "service_role";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."reporte_punto" TO "anon", "authenticated", "postgres", "service_role";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."rol" TO "anon", "authenticated", "postgres", "service_role";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."ticket_mantenimiento" TO "anon", "authenticated", "postgres", "service_role";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."usuario" TO "anon", "authenticated", "postgres", "service_role";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."usuario_rol" TO "anon", "authenticated", "postgres", "service_role";

