-- ============================================================================
-- medir_indice_redundante_q5.sql — Prueba de Índice Redundante en detalles_pedido
-- Demuestra que crear idx_detalles_id_pedido es redundante con la PK compuesta
-- PRIMARY KEY (id_pedido, id_producto)
-- ============================================================================

\echo '=== 1. Prueba de búsqueda por id_pedido solo con la PK compuesta ==='
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM detalles_pedido WHERE id_pedido = 100;

\echo '=== 2. Prueba de la consulta Q5 creando el índice redundante dentro de transacción ==='
BEGIN;
CREATE INDEX idx_detalles_id_pedido_redundante ON detalles_pedido (id_pedido);
ANALYZE detalles_pedido;

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
