-- ============================================================================
-- medir_q5_rondas.sql — Medición de 3 rondas controladas para Consulta Q5
-- Compara: Baseline vs Índice propuesto vs Ajuste work_mem = '16MB'
-- ============================================================================

\echo '=== RONDA 1 - BASELINE ==='
EXPLAIN (ANALYZE, BUFFERS)
SELECT
    c.nombre || ' ' || c.apellido AS cliente,
    SUM(dp.cantidad * dp.precio_unitario) AS total_gastado,
    DENSE_RANK() OVER (ORDER BY SUM(dp.cantidad * dp.precio_unitario) DESC) AS puesto
FROM clientes c
JOIN pedidos p ON p.id_cliente = c.id_cliente
JOIN detalles_pedido dp ON dp.id_pedido = p.id_pedido
GROUP BY c.id_cliente, c.nombre, c.apellido
ORDER BY puesto;

\echo '=== RONDA 1 - CON ÍNDICE PROPUESTO (En transacción) ==='
BEGIN;
CREATE INDEX idx_pedidos_cliente_q5 ON pedidos (id_cliente);
ANALYZE pedidos;
EXPLAIN (ANALYZE, BUFFERS)
SELECT
    c.nombre || ' ' || c.apellido AS cliente,
    SUM(dp.cantidad * dp.precio_unitario) AS total_gastado,
    DENSE_RANK() OVER (ORDER BY SUM(dp.cantidad * dp.precio_unitario) DESC) AS puesto
FROM clientes c
JOIN pedidos p ON p.id_cliente = c.id_cliente
JOIN detalles_pedido dp ON dp.id_pedido = p.id_pedido
GROUP BY c.id_cliente, c.nombre, c.apellido
ORDER BY puesto;
ROLLBACK;

\echo '=== RONDA 1 - CON WORK_MEM = 16MB (En transacción) ==='
BEGIN;
SET LOCAL work_mem = '16MB';
EXPLAIN (ANALYZE, BUFFERS)
SELECT
    c.nombre || ' ' || c.apellido AS cliente,
    SUM(dp.cantidad * dp.precio_unitario) AS total_gastado,
    DENSE_RANK() OVER (ORDER BY SUM(dp.cantidad * dp.precio_unitario) DESC) AS puesto
FROM clientes c
JOIN pedidos p ON p.id_cliente = c.id_cliente
JOIN detalles_pedido dp ON dp.id_pedido = p.id_pedido
GROUP BY c.id_cliente, c.nombre, c.apellido
ORDER BY puesto;
ROLLBACK;

\echo '=== RONDA 2 - BASELINE ==='
EXPLAIN (ANALYZE, BUFFERS)
SELECT
    c.nombre || ' ' || c.apellido AS cliente,
    SUM(dp.cantidad * dp.precio_unitario) AS total_gastado,
    DENSE_RANK() OVER (ORDER BY SUM(dp.cantidad * dp.precio_unitario) DESC) AS puesto
FROM clientes c
JOIN pedidos p ON p.id_cliente = c.id_cliente
JOIN detalles_pedido dp ON dp.id_pedido = p.id_pedido
GROUP BY c.id_cliente, c.nombre, c.apellido
ORDER BY puesto;

\echo '=== RONDA 2 - CON ÍNDICE PROPUESTO (En transacción) ==='
BEGIN;
CREATE INDEX idx_pedidos_cliente_q5 ON pedidos (id_cliente);
ANALYZE pedidos;
EXPLAIN (ANALYZE, BUFFERS)
SELECT
    c.nombre || ' ' || c.apellido AS cliente,
    SUM(dp.cantidad * dp.precio_unitario) AS total_gastado,
    DENSE_RANK() OVER (ORDER BY SUM(dp.cantidad * dp.precio_unitario) DESC) AS puesto
FROM clientes c
JOIN pedidos p ON p.id_cliente = c.id_cliente
JOIN detalles_pedido dp ON dp.id_pedido = p.id_pedido
GROUP BY c.id_cliente, c.nombre, c.apellido
ORDER BY puesto;
ROLLBACK;

\echo '=== RONDA 2 - CON WORK_MEM = 16MB (En transacción) ==='
BEGIN;
SET LOCAL work_mem = '16MB';
EXPLAIN (ANALYZE, BUFFERS)
SELECT
    c.nombre || ' ' || c.apellido AS cliente,
    SUM(dp.cantidad * dp.precio_unitario) AS total_gastado,
    DENSE_RANK() OVER (ORDER BY SUM(dp.cantidad * dp.precio_unitario) DESC) AS puesto
FROM clientes c
JOIN pedidos p ON p.id_cliente = c.id_cliente
JOIN detalles_pedido dp ON dp.id_pedido = p.id_pedido
GROUP BY c.id_cliente, c.nombre, c.apellido
ORDER BY puesto;
ROLLBACK;

\echo '=== RONDA 3 - BASELINE ==='
EXPLAIN (ANALYZE, BUFFERS)
SELECT
    c.nombre || ' ' || c.apellido AS cliente,
    SUM(dp.cantidad * dp.precio_unitario) AS total_gastado,
    DENSE_RANK() OVER (ORDER BY SUM(dp.cantidad * dp.precio_unitario) DESC) AS puesto
FROM clientes c
JOIN pedidos p ON p.id_cliente = c.id_cliente
JOIN detalles_pedido dp ON dp.id_pedido = p.id_pedido
GROUP BY c.id_cliente, c.nombre, c.apellido
ORDER BY puesto;

\echo '=== RONDA 3 - CON ÍNDICE PROPUESTO (En transacción) ==='
BEGIN;
CREATE INDEX idx_pedidos_cliente_q5 ON pedidos (id_cliente);
ANALYZE pedidos;
EXPLAIN (ANALYZE, BUFFERS)
SELECT
    c.nombre || ' ' || c.apellido AS cliente,
    SUM(dp.cantidad * dp.precio_unitario) AS total_gastado,
    DENSE_RANK() OVER (ORDER BY SUM(dp.cantidad * dp.precio_unitario) DESC) AS puesto
FROM clientes c
JOIN pedidos p ON p.id_cliente = c.id_cliente
JOIN detalles_pedido dp ON dp.id_pedido = p.id_pedido
GROUP BY c.id_cliente, c.nombre, c.apellido
ORDER BY puesto;
ROLLBACK;

\echo '=== RONDA 3 - CON WORK_MEM = 16MB (En transacción) ==='
BEGIN;
SET LOCAL work_mem = '16MB';
EXPLAIN (ANALYZE, BUFFERS)
SELECT
    c.nombre || ' ' || c.apellido AS cliente,
    SUM(dp.cantidad * dp.precio_unitario) AS total_gastado,
    DENSE_RANK() OVER (ORDER BY SUM(dp.cantidad * dp.precio_unitario) DESC) AS puesto
FROM clientes c
JOIN pedidos p ON p.id_cliente = c.id_cliente
JOIN detalles_pedido dp ON dp.id_pedido = p.id_pedido
GROUP BY c.id_cliente, c.nombre, c.apellido
ORDER BY puesto;
ROLLBACK;
