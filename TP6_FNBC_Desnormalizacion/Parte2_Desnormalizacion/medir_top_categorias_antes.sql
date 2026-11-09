-- ============================================================================
-- TP6 — Parte 2: Medición Inicial Normalizada (Top Categorías)
-- Consulta analítica normalizada con filtros de borrado lógico
-- ============================================================================

\set ON_ERROR_STOP on

BEGIN;

-- Añadimos las columnas de borrado lógico en transacción para el ensayo
ALTER TABLE pedidos ADD COLUMN IF NOT EXISTS eliminado BOOLEAN NOT NULL DEFAULT FALSE;
ALTER TABLE detalles_pedido ADD COLUMN IF NOT EXISTS eliminado BOOLEAN NOT NULL DEFAULT FALSE;

ANALYZE pedidos;
ANALYZE detalles_pedido;

-- Medición inicial de la consulta normalizada para la fecha analítica 2026-06-25
EXPLAIN (ANALYZE, BUFFERS, VERBOSE)
SELECT
    c.id_categoria,
    c.nombre AS categoria,
    SUM(dp.cantidad * dp.precio_unitario) AS monto_total
FROM detalles_pedido dp
JOIN pedidos ped ON ped.id_pedido = dp.id_pedido
JOIN productos pr ON pr.id_producto = dp.id_producto
JOIN categorias c ON c.id_categoria = pr.id_categoria
WHERE ped.fecha_pedido >= '2026-06-25 00:00:00-03'::timestamptz
  AND ped.fecha_pedido <  '2026-06-26 00:00:00-03'::timestamptz
  AND dp.eliminado = FALSE
  AND ped.eliminado = FALSE
GROUP BY c.id_categoria, c.nombre
ORDER BY monto_total DESC
LIMIT 5;

ROLLBACK;

