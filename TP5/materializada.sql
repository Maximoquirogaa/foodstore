-- ==========================================
-- TP5 - Parte C: Vista Materializada
-- ==========================================

-- PASO 1: Mide el tiempo de la consulta original (cruda)
-- Ejecuta esto y anota el "Execution Time" (va a tardar bastante porque cruza 4 tablas y agrupa meses)
EXPLAIN ANALYZE
SELECT 
    c.id_categoria,
    c.nombre AS categoria,
    to_char(date_trunc('month', pe.fecha_pedido), 'YYYY-MM') AS mes,
    SUM(dp.cantidad * dp.precio_unitario) AS facturacion_total
FROM categorias c
JOIN productos pr ON c.id_categoria = pr.id_categoria
JOIN detalles_pedido dp ON pr.id_producto = dp.id_producto
JOIN pedidos pe ON dp.id_pedido = pe.id_pedido
GROUP BY c.id_categoria, c.nombre, date_trunc('month', pe.fecha_pedido);

-- PASO 2: Crea la Vista Materializada (ejecuta todo este bloque)
CREATE MATERIALIZED VIEW mv_facturacion_categoria_mes AS
SELECT 
    c.id_categoria,
    c.nombre AS categoria,
    to_char(date_trunc('month', pe.fecha_pedido), 'YYYY-MM') AS mes,
    SUM(dp.cantidad * dp.precio_unitario) AS facturacion_total
FROM categorias c
JOIN productos pr ON c.id_categoria = pr.id_categoria
JOIN detalles_pedido dp ON pr.id_producto = dp.id_producto
JOIN pedidos pe ON dp.id_pedido = pe.id_pedido
GROUP BY c.id_categoria, c.nombre, date_trunc('month', pe.fecha_pedido)
WITH DATA;

-- Para permitir REFRESH CONCURRENTLY (que actualiza la vista sin bloquear consultas en vivo),
-- PostgreSQL exige crear un índice único que identifique cada fila de la vista de forma unívoca:
CREATE UNIQUE INDEX idx_mv_facturacion_unique ON mv_facturacion_categoria_mes (id_categoria, mes);

-- PASO 3: Mide consultar directamente la vista materializada
-- Ejecuta esto y anota el "Execution Time" (debería ser instantáneo)
EXPLAIN ANALYZE
SELECT * FROM mv_facturacion_categoria_mes;

-- Nota: A futuro, para actualizar los datos sin que los usuarios noten cortes de servicio, se usará:
-- REFRESH MATERIALIZED VIEW CONCURRENTLY mv_facturacion_categoria_mes;

