-- ============================================================================
-- correlacion_fecha_pedido.sql — Medición de correlación física en pg_stats
-- Evalúa si la columna fecha_pedido de la tabla pedidos es apta para índice BRIN
-- ============================================================================

SELECT
    tablename,
    attname AS columna,
    correlation
FROM pg_stats
WHERE tablename = 'pedidos'
  AND attname = 'fecha_pedido';
