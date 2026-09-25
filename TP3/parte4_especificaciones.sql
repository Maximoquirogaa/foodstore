-- ==========================================
-- TP3 - Parte 4: Especificaciones y Subconsultas
-- ==========================================

-- ---------------------------------------------------------
-- ESPECIFICACIÓN 1: Agregación
-- ---------------------------------------------------------
/*
Spec: 
Genera una consulta SQL sobre Food Store que devuelva, para cada cliente (nombre y apellido concatenados), 
la cantidad total de pedidos realizados y el monto histórico total gastado (suma de cantidad * precio_unitario).
Solo se deben incluir aquellos clientes que hayan gastado estrictamente más de $5000 en total.
Ordená el resultado de mayor a menor monto gastado. No uses SELECT *.
*/

-- VERSIÓN 1 (Generada por IA usando JOIN y HAVING clásico)
SELECT 
    c.nombre || ' ' || c.apellido AS cliente_nombre,
    COUNT(DISTINCT p.id_pedido) AS total_pedidos,
    SUM(dp.cantidad * dp.precio_unitario) AS monto_total
FROM clientes c
JOIN pedidos p ON c.id_cliente = p.id_cliente
JOIN detalles_pedido dp ON p.id_pedido = dp.id_pedido
GROUP BY c.id_cliente, c.nombre, c.apellido
HAVING SUM(dp.cantidad * dp.precio_unitario) > 5000
ORDER BY monto_total DESC;

-- VERSIÓN 2 (Alternativa propia usando CTEs / Subconsultas en FROM)
WITH GastosPorPedido AS (
    SELECT id_pedido, SUM(cantidad * precio_unitario) as total_pedido
    FROM detalles_pedido
    GROUP BY id_pedido
), GastosPorCliente AS (
    SELECT p.id_cliente, COUNT(p.id_pedido) as total_pedidos, SUM(gp.total_pedido) as monto_total
    FROM pedidos p
    JOIN GastosPorPedido gp ON p.id_pedido = gp.id_pedido
    GROUP BY p.id_cliente
)
SELECT 
    c.nombre || ' ' || c.apellido AS cliente_nombre,
    gc.total_pedidos,
    gc.monto_total
FROM clientes c
JOIN GastosPorCliente gc ON c.id_cliente = gc.id_cliente
WHERE gc.monto_total > 5000
ORDER BY gc.monto_total DESC;

-- PRUEBA DE EQUIVALENCIA (Except) - Debe dar 0 filas.
(
    SELECT c.nombre || ' ' || c.apellido, COUNT(DISTINCT p.id_pedido), SUM(dp.cantidad * dp.precio_unitario)
    FROM clientes c
    JOIN pedidos p ON c.id_cliente = p.id_cliente
    JOIN detalles_pedido dp ON p.id_pedido = dp.id_pedido
    GROUP BY c.id_cliente, c.nombre, c.apellido
    HAVING SUM(dp.cantidad * dp.precio_unitario) > 5000
) EXCEPT (
    WITH GastosPorPedido AS (
        SELECT id_pedido, SUM(cantidad * precio_unitario) as tp FROM detalles_pedido GROUP BY id_pedido
    ), GastosPorCliente AS (
        SELECT p.id_cliente, COUNT(p.id_pedido) as cant_ped, SUM(gp.tp) as monto FROM pedidos p
        JOIN GastosPorPedido gp ON p.id_pedido = gp.id_pedido GROUP BY p.id_cliente
    )
    SELECT c.nombre || ' ' || c.apellido, gc.cant_ped, gc.monto
    FROM clientes c JOIN GastosPorCliente gc ON c.id_cliente = gc.id_cliente
    WHERE gc.monto > 5000
);


-- ---------------------------------------------------------
-- ESPECIFICACIÓN 2: Subconsulta
-- ---------------------------------------------------------
/*
Spec:
Devuelve el nombre de la categoría, el nombre del producto y el precio_actual, solo para aquellos 
productos vigentes (activo = true) cuyo precio_actual supere el precio promedio de TODOS los 
productos activos en la tienda. Ordená el resultado alfabéticamente por categoría y luego producto.
*/

-- VERSIÓN 1 (Generada por IA usando subconsulta en el WHERE)
SELECT 
    c.nombre AS categoria,
    p.nombre AS producto,
    p.precio_actual
FROM productos p
JOIN categorias c ON p.id_categoria = c.id_categoria
WHERE p.activo = TRUE 
  AND p.precio_actual > (SELECT AVG(precio_actual) FROM productos WHERE activo = TRUE)
ORDER BY c.nombre ASC, p.nombre ASC;

-- VERSIÓN 2 (Alternativa propia usando funciones de ventana / CTE)
WITH PromedioGlobal AS (
    SELECT AVG(precio_actual) as promedio_tienda FROM productos WHERE activo = TRUE
)
SELECT 
    c.nombre AS categoria,
    p.nombre AS producto,
    p.precio_actual
FROM productos p
JOIN categorias c ON p.id_categoria = c.id_categoria
CROSS JOIN PromedioGlobal pg
WHERE p.activo = TRUE 
  AND p.precio_actual > pg.promedio_tienda
ORDER BY c.nombre ASC, p.nombre ASC;

-- PRUEBA DE EQUIVALENCIA (Except) - Debe dar 0 filas.
(
    SELECT c.nombre, p.nombre, p.precio_actual
    FROM productos p JOIN categorias c ON p.id_categoria = c.id_categoria
    WHERE p.activo = TRUE AND p.precio_actual > (SELECT AVG(precio_actual) FROM productos WHERE activo = TRUE)
) EXCEPT (
    WITH PromedioGlobal AS (SELECT AVG(precio_actual) as pt FROM productos WHERE activo = TRUE)
    SELECT c.nombre, p.nombre, p.precio_actual
    FROM productos p JOIN categorias c ON p.id_categoria = c.id_categoria CROSS JOIN PromedioGlobal pg
    WHERE p.activo = TRUE AND p.precio_actual > pg.pt
);

