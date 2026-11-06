# RLS necesario para el Perfil (esquema remoto real)

El esquema real de la nube es el de `docs/esquema-remoto.md` del repo `rebin`
(`usuarios`, `movimientos_puntos`, ...). Hoy la publishable key recibe `42501`
(acceso denegado) en todas las tablas, así que **el Perfil de la APK no carga
contra la base real hasta que el dueño aplique estas políticas**.

> La versión anterior de este documento tenía SQL para el esquema antiguo
> (`usuario`, `movimiento_punto`, `auth_user_id`). Ese SQL falla en la base
> real: no usarlo.

## Qué hace la APK

`app/lib/repositories/usuario_repository_supabase.dart`, con sesión anónima o
con correo (ambas usan el rol `authenticated`):

| Tabla | Operación | Filtro |
|---|---|---|
| `usuarios` | select de `id_usuario, correo_electronico, alias, fecha_creacion` | `id_usuario = auth.uid()` |
| `usuarios` | update de `alias` (bienvenida) | `id_usuario = auth.uid()` |
| `movimientos_puntos` | select de `tipo_referencia, cantidad, fecha` (suma el saldo) | `id_usuario = auth.uid()` |
| `reciclajes`, `reportes_punto`, `logros_usuario` | conteo | `id_usuario = auth.uid()` |

No hace falta:
- **insert en `usuarios`**: la fila la crea el trigger `handle_new_auth_user` al registrarse, también en sesiones anónimas.
- **escritura en `movimientos_puntos`**: los puntos se acreditan con funciones en Postgres o desde la Web API.
- **la columna del nombre real**: el nombre va a `user_metadata.nombre` de Supabase Auth.

## SQL propuesto

El archivo listo para el dueño es `20261008120000_rls_perfil_app.sql`, con
destino `rebin/backend/remoto/`. No está en este repo: se manda aparte. Lo
aplica el dueño en el SQL Editor; **nunca con `supabase db push` desde
`backend/`**.

Resumen de lo que contiene:

```sql
alter table public.usuarios enable row level security;  -- y las otras 4

create policy "usuarios_select_propio" on public.usuarios
  for select to authenticated using (id_usuario = auth.uid());

create policy "usuarios_update_propio" on public.usuarios
  for update to authenticated
  using (id_usuario = auth.uid()) with check (id_usuario = auth.uid());

revoke update on public.usuarios from authenticated;
grant update (alias, imagen_perfil_url) on public.usuarios to authenticated;

-- select de lo propio en movimientos_puntos, reciclajes, reportes_punto
-- y logros_usuario: using (id_usuario = auth.uid())
```

## Antes de aplicar

- Revisar las políticas existentes con `pg_policies` (la consulta está al
  inicio del `.sql`) para no duplicar ni chocar con nada.
- Confirmar el `revoke update`: quita el UPDATE de tabla completa que Supabase
  da por defecto a `authenticated`. A la Web API no le afecta (usa
  `service_role`).
- Revisar en el dashboard (Advisors → Security) que todas las tablas de
  `public` tengan RLS activo: una tabla sin RLS queda abierta a cualquiera con
  la publishable key, que va dentro de la APK.

## Pendiente aparte

- **Mapa**: la APK llama a la RPC `puntos_cercanos`, que no existe en la base
  real. `api_puntos_cercanos_a` existe pero es solo `service_role`. Hay que
  acordar con el dueño una función de cercanía que la APK pueda llamar.
