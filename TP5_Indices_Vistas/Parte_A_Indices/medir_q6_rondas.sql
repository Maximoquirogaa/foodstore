-- ============================================================================
-- medir_q6_rondas.sql — Medición de la Consulta Q6
-- Subconsulta correlacionada en WHERE (Productos con precio > promedio de categoría)
-- ============================================================================

\echo '=== PLAN BASELINE Q6 (Sin índice adicional) ==='
EXPLAIN (ANALYZE, BUFFERS)
SELECT p.nombre, p.precio_actual
FROM productos p
JOIN categorias cat ON cat.id_categoria = p.id_categoria AND cat.activo = TRUE
WHERE p.activo = TRUE
  AND p.precio_actual > (
      SELECT AVG(p2.precio_actual)
      FROM productos p2
      WHERE p2.activo = TRUE AND p2.id_categoria = p.id_categoria
  )
ORDER BY cat.id_categoria, p.precio_actual DESC;

\echo '=== PLAN CON ÍNDICE CUBRIENTE idx_productos_categoria_precio_activo ==='
BEGIN;
CREATE INDEX idx_productos_categoria_precio_activo
    ON productos (id_categoria, precio_actual DESC)
    WHERE activo = TRUE;
ANALYZE productos;

EXPLAIN (ANALYZE, BUFFERS)
SELECT p.nombre, p.precio_actual
FROM productos p
JOIN categorias cat ON cat.id_categoria = p.id_categoria AND cat.activo = TRUE
WHERE p.activo = TRUE
  AND p.precio_actual > (
      SELECT AVG(p2.precio_actual)
      FROM productos p2
      WHERE p2.activo = TRUE AND p2.id_categoria = p.id_categoria
  )
ORDER BY cat.id_categoria, p.precio_actual DESC;

ROLLBACK;
