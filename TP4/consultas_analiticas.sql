-- ==========================================
-- TP4 - Parte 1: Consultas Analíticas Lentas
-- Ejecuta cada una copiando también el resultado del "EXPLAIN ANALYZE"
-- Presta especial atención a los nodos de JOIN (Hash Join, Nested Loop, Merge Join)
-- ==========================================

-- Consulta 1: Facturación histórica total agrupada por categoría
-- Cruza 4 tablas: categorias, productos, detalles_pedido, y pedidos.
EXPLAIN ANALYZE
SELECT 
    c.nombre AS categoria,
    SUM(dp.cantidad * dp.precio_unitario) AS facturacion_total
FROM categorias c
JOIN productos pr ON c.id_categoria = pr.id_categoria
JOIN detalles_pedido dp ON pr.id_producto = dp.id_producto
JOIN pedidos pe ON dp.id_pedido = pe.id_pedido
GROUP BY c.nombre
ORDER BY facturacion_total DESC;


-- Consulta 2: Los 50 clientes que más gastaron históricamente
-- Cruza 3 tablas: clientes, pedidos, detalles_pedido.
EXPLAIN ANALYZE
SELECT 
    cl.nombre, 
    cl.apellido,
    SUM(dp.cantidad * dp.precio_unitario) AS gasto_total
FROM clientes cl
JOIN pedidos pe ON cl.id_cliente = pe.id_cliente
JOIN detalles_pedido dp ON pe.id_pedido = dp.id_pedido
GROUP BY cl.id_cliente, cl.nombre, cl.apellido
ORDER BY gasto_total DESC
LIMIT 50;

