-- ==========================================
-- TP4 - Parte 3: Rankings y Subconsultas Correlacionadas
-- ==========================================

-- ---------------------------------------------------------
-- ESPECIFICACIÓN A: Ranking con Función de Ventana
-- ---------------------------------------------------------
/*
Spec: 
Genera una consulta SQL que devuelva el nombre, apellido, la cantidad total de pedidos realizados
por cada cliente y su puesto en un ranking (de mayor a menor cantidad de pedidos). 
En caso de empate en cantidad, deben compartir el mismo puesto sin saltar números (usar DENSE_RANK).
*/

-- VERSIÓN 1: Usando función de ventana (DENSE_RANK)
SELECT 
    c.nombre, 
    c.apellido, 
    COUNT(p.id_pedido) AS total_pedidos,
    DENSE_RANK() OVER (ORDER BY COUNT(p.id_pedido) DESC) AS puesto_ranking
FROM clientes c
JOIN pedidos p ON c.id_cliente = p.id_cliente
GROUP BY c.id_cliente, c.nombre, c.apellido;

-- VERSIÓN 2: Alternativa equivalente sin funciones de ventana (Subconsulta correlacionada)
SELECT 
    c.nombre, 
    c.apellido, 
    COUNT(p.id_pedido) AS total_pedidos,
    (
        SELECT COUNT(DISTINCT conteos.ped) + 1
        FROM (
            SELECT COUNT(id_pedido) AS ped 
            FROM pedidos 
            GROUP BY id_cliente
        ) AS conteos
        WHERE conteos.ped > COUNT(p.id_pedido)
    ) AS puesto_ranking
FROM clientes c
JOIN pedidos p ON c.id_cliente = p.id_cliente
GROUP BY c.id_cliente, c.nombre, c.apellido;

-- PRUEBA DE EQUIVALENCIA (Except) - Debe dar 0 filas.
(
    SELECT c.nombre, c.apellido, COUNT(p.id_pedido) AS tp, DENSE_RANK() OVER (ORDER BY COUNT(p.id_pedido) DESC)
    FROM clientes c JOIN pedidos p ON c.id_cliente = p.id_cliente GROUP BY c.id_cliente, c.nombre, c.apellido
) EXCEPT (
    SELECT c.nombre, c.apellido, COUNT(p.id_pedido) AS tp, (SELECT COUNT(DISTINCT ped) + 1 FROM (SELECT COUNT(id_pedido) AS ped FROM pedidos GROUP BY id_cliente) AS c2 WHERE c2.ped > COUNT(p.id_pedido))
    FROM clientes c JOIN pedidos p ON c.id_cliente = p.id_cliente GROUP BY c.id_cliente, c.nombre, c.apellido
);


-- ---------------------------------------------------------
-- ESPECIFICACIÓN B: Subconsulta Correlacionada
-- ---------------------------------------------------------
/*
Spec:
Para cada categoría, encuentra qué producto (o productos) tiene el mayor precio actual dentro de esa categoría.
Devuelve el nombre de la categoría, el nombre del producto y su precio.
*/

-- VERSIÓN 1: Usando subconsulta correlacionada en el WHERE
SELECT 
    c.nombre AS categoria, 
    pr.nombre AS producto_mas_caro, 
    pr.precio_actual
FROM productos pr
JOIN categorias c ON pr.id_categoria = c.id_categoria
WHERE pr.precio_actual = (
    SELECT MAX(p2.precio_actual)
    FROM productos p2
    WHERE p2.id_categoria = pr.id_categoria
)
ORDER BY c.nombre;

-- VERSIÓN 2: Alternativa equivalente usando funciones de ventana (RANK) y CTE
WITH RankedProductos AS (
    SELECT 
        id_categoria, 
        nombre, 
        precio_actual,
        RANK() OVER(PARTITION BY id_categoria ORDER BY precio_actual DESC) as rnk
    FROM productos
)
SELECT 
    c.nombre AS categoria, 
    rp.nombre AS producto_mas_caro, 
    rp.precio_actual
FROM RankedProductos rp
JOIN categorias c ON rp.id_categoria = c.id_categoria
WHERE rp.rnk = 1
ORDER BY c.nombre;

-- PRUEBA DE EQUIVALENCIA (Except) - Debe dar 0 filas.
(
    SELECT c.nombre, pr.nombre, pr.precio_actual
    FROM productos pr JOIN categorias c ON pr.id_categoria = c.id_categoria
    WHERE pr.precio_actual = (SELECT MAX(precio_actual) FROM productos p2 WHERE p2.id_categoria = pr.id_categoria)
) EXCEPT (
    WITH RankedProductos AS (SELECT id_categoria, nombre, precio_actual, RANK() OVER(PARTITION BY id_categoria ORDER BY precio_actual DESC) as rnk FROM productos)
    SELECT c.nombre, rp.nombre, rp.precio_actual
    FROM RankedProductos rp JOIN categorias c ON rp.id_categoria = c.id_categoria WHERE rp.rnk = 1
);

