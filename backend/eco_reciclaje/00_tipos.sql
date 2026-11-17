-- Proyecto_Eco_reciclaje (shkdlkbhpkbrfxemctdj)
-- Paso 0: valores de enum que usa la app. Va en su propio archivo porque un
-- valor agregado con ALTER TYPE no se puede usar en la misma transacción.
-- Idempotente.

alter type tipo_movimiento_enum add value if not exists 'reporte_punto';
alter type tipo_movimiento_enum add value if not exists 'calificacion_punto';
alter type tipo_movimiento_enum add value if not exists 'devolucion_canje';
