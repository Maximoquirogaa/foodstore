-- ============================================================================
-- medir_refresh_parte_c.sql — Comparación de Rendimiento y Análisis de Bloqueos
-- Compara la consulta directa cruzando 4 tablas vs la lectura de la vista materializada
-- y analiza el comportamiento de los bloqueos en REFRESH vs REFRESH CONCURRENTLY
-- ============================================================================

\echo '=== 1. Tiempo de la consulta directa cruzando 4 tablas masivas ==='
EXPLAIN (ANALYZE, BUFFERS)
SELECT
    c.id_categoria,
    c.nombre AS categoria,
    DATE_TRUNC('month', p.fecha_pedido) AS mes,
    COUNT(DISTINCT p.id_pedido) AS cantidad_pedidos,
    SUM(dp.cantidad) AS unidades_vendidas,
    SUM(dp.cantidad * dp.precio_unitario)::NUMERIC(14, 2) AS facturacion_total
FROM pedidos p
JOIN detalles_pedido dp ON dp.id_pedido = p.id_pedido
JOIN productos pr ON pr.id_producto = dp.id_producto
JOIN categorias c ON c.id_categoria = pr.id_categoria
GROUP BY c.id_categoria, c.nombre, DATE_TRUNC('month', p.fecha_pedido);

\echo '=== 2. Tiempo de lectura desde la Vista Materializada precalculada ==='
EXPLAIN (ANALYZE, BUFFERS)
SELECT *
FROM mv_resumen_ventas_categoria_mes;

\echo '=== 3. Medición del tiempo de REFRESH estándar vs CONCURRENTLY ==='
\timing on
REFRESH MATERIALIZED VIEW mv_resumen_ventas_categoria_mes;
REFRESH MATERIALIZED VIEW CONCURRENTLY mv_resumen_ventas_categoria_mes;
\timing off
