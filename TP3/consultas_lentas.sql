-- ==========================================
-- TP3 - Parte 2: Consultas Lentas
-- Ejecuta cada una copiando también el resultado del "EXPLAIN ANALYZE"
-- ==========================================

-- Consulta 1: Listado de productos por un rango de precio específico, ordenados por stock.
-- Al no haber índice en precio_actual, forzará a leer toda la tabla de 50.000 productos.
EXPLAIN ANALYZE
SELECT nombre, precio_actual, stock
FROM productos
WHERE precio_actual BETWEEN 1000 AND 2000
  AND activo = TRUE
ORDER BY stock DESC;


-- Consulta 2: Ingresos totales agrupados por forma de pago en los últimos 30 días.
-- El motor tendrá que escanear los 200.000 pedidos filtrando por la fecha sin un índice, y luego cruzar con detalles.
EXPLAIN ANALYZE
SELECT p.forma_pago, SUM(dp.cantidad * dp.precio_unitario) as total_ingresos
FROM pedidos p
JOIN detalles_pedido dp ON p.id_pedido = dp.id_pedido
WHERE p.fecha_pedido >= now() - interval '30 days'
GROUP BY p.forma_pago;


-- Consulta 3: Buscar los últimos 100 pedidos que incluyan productos de la categoría 2 (Bebidas, por ejemplo).
-- Cruza 4 tablas y filtra por categoría y fecha. 
EXPLAIN ANALYZE
SELECT p.id_pedido, p.fecha_pedido, c.nombre, c.apellido
FROM pedidos p
JOIN clientes c ON p.id_cliente = c.id_cliente
JOIN detalles_pedido dp ON p.id_pedido = dp.id_pedido
JOIN productos pr ON dp.id_producto = pr.id_producto
WHERE pr.id_categoria = 2
ORDER BY p.fecha_pedido DESC
LIMIT 100;

