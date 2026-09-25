-- ==========================================
-- TP4 - Parte 1: Optimización de Joins (Reescrituras e Índices)
-- ==========================================

-- 1. CREACIÓN DE ÍNDICES PARA LAS CLAVES FORÁNEAS
-- (Ayudan al motor a realizar Hash Joins y Nested Loops más rápidos)
CREATE INDEX IF NOT EXISTS idx_pedidos_id_cliente ON pedidos(id_cliente);
CREATE INDEX IF NOT EXISTS idx_detalles_id_producto ON detalles_pedido(id_producto);

-- 2. CONSULTA 1 OPTIMIZADA (Reescritura: eliminación de JOIN inútil)
-- Al quitar la tabla "pedidos" que no se usaba, evitamos un Parallel Hash Join gigante de 200.000 filas.
EXPLAIN ANALYZE
SELECT 
    c.nombre AS categoria,
    SUM(dp.cantidad * dp.precio_unitario) AS facturacion_total
FROM categorias c
JOIN productos pr ON c.id_categoria = pr.id_categoria
JOIN detalles_pedido dp ON pr.id_producto = dp.id_producto
GROUP BY c.nombre
ORDER BY facturacion_total DESC;


-- 3. CONSULTA 2 OPTIMIZADA (Reescritura: Pre-agregación con CTE)
-- En vez de cruzar los detalles con clientes y luego agrupar, agrupamos los pedidos primero
-- (reduciendo drásticamente las filas) y luego hacemos un solo JOIN limpio con clientes.
EXPLAIN ANALYZE
WITH GastoPorCliente AS (
    SELECT pe.id_cliente, SUM(dp.cantidad * dp.precio_unitario) AS gasto_total
    FROM pedidos pe
    JOIN detalles_pedido dp ON pe.id_pedido = dp.id_pedido
    GROUP BY pe.id_cliente
)
SELECT 
    cl.nombre, 
    cl.apellido,
    gc.gasto_total
FROM GastoPorCliente gc
JOIN clientes cl ON gc.id_cliente = cl.id_cliente
ORDER BY gc.gasto_total DESC
LIMIT 50;

