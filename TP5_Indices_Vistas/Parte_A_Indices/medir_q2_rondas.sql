-- ============================================================================
-- medir_q2_rondas.sql — Medición de 3 rondas controladas para Consulta Q2
-- Filtro de productos por categoría y rango de precio
-- ============================================================================

\echo '=== RONDA 1 - BASELINE (Sin índice) ==='
EXPLAIN (ANALYZE, BUFFERS)
SELECT id_producto, nombre, precio_actual, stock
FROM productos
WHERE id_categoria = 1 AND precio_actual BETWEEN 1000 AND 3000
ORDER BY precio_actual;

\echo '=== RONDA 1 - CON ÍNDICE (En transacción) ==='
BEGIN;
CREATE INDEX idx_productos_categoria_precio ON productos (id_categoria, precio_actual);
ANALYZE productos;

EXPLAIN (ANALYZE, BUFFERS)
SELECT id_producto, nombre, precio_actual, stock
FROM productos
WHERE id_categoria = 1 AND precio_actual BETWEEN 1000 AND 3000
ORDER BY precio_actual;
ROLLBACK;

\echo '=== RONDA 2 - BASELINE (Sin índice) ==='
EXPLAIN (ANALYZE, BUFFERS)
SELECT id_producto, nombre, precio_actual, stock
FROM productos
WHERE id_categoria = 1 AND precio_actual BETWEEN 1000 AND 3000
ORDER BY precio_actual;

\echo '=== RONDA 2 - CON ÍNDICE (En transacción) ==='
BEGIN;
CREATE INDEX idx_productos_categoria_precio ON productos (id_categoria, precio_actual);
ANALYZE productos;

EXPLAIN (ANALYZE, BUFFERS)
SELECT id_producto, nombre, precio_actual, stock
FROM productos
WHERE id_categoria = 1 AND precio_actual BETWEEN 1000 AND 3000
ORDER BY precio_actual;
ROLLBACK;

\echo '=== RONDA 3 - BASELINE (Sin índice) ==='
EXPLAIN (ANALYZE, BUFFERS)
SELECT id_producto, nombre, precio_actual, stock
FROM productos
WHERE id_categoria = 1 AND precio_actual BETWEEN 1000 AND 3000
ORDER BY precio_actual;

\echo '=== RONDA 3 - CON ÍNDICE (En transacción) ==='
BEGIN;
CREATE INDEX idx_productos_categoria_precio ON productos (id_categoria, precio_actual);
ANALYZE productos;

EXPLAIN (ANALYZE, BUFFERS)
SELECT id_producto, nombre, precio_actual, stock
FROM productos
WHERE id_categoria = 1 AND precio_actual BETWEEN 1000 AND 3000
ORDER BY precio_actual;
ROLLBACK;
