-- ============================================================================
-- TP4 — PARTE 3 — CONSULTA A: Ranking con función de ventana vs subconsulta
-- Base de datos: Food Store (UTN FRM - PostgreSQL 17)
-- Alumno: Máximo Juan Cruz Quiroga
-- Docente: Sergio Neira
-- ============================================================================

-- ----------------------------------------------------------------------------
-- ESPECIFICACIÓN
-- ----------------------------------------------------------------------------
-- "Genera una consulta SQL sobre el esquema de Food Store que devuelva, para
-- cada cliente que haya realizado pedidos, su nombre y apellido completos,
-- el total gastado (suma de dp.cantidad * dp.precio_unitario) y su puesto
-- en un ranking ordenado de mayor a menor gasto, sin colapsar filas.
-- Las tablas clientes y detalles_pedido no tienen borrado lógico en nuestro
-- modelo relacional, por lo que no llevan filtro de ese tipo. En caso de
-- empate en el gasto, deben compartir exactamente el mismo puesto sin saltar
-- números en los puestos subsiguientes (semántica DENSE_RANK). No uses SELECT *."

-- ----------------------------------------------------------------------------
-- VERSIÓN 1 — Función de Ventana DENSE_RANK()
-- Técnica: Agrupación canónica por cliente y aplicación de la función analítica
-- DENSE_RANK() OVER (...) en la cláusula SELECT. Si dos clientes empatan en
-- el gasto, comparten el puesto y el siguiente cliente recibe el entero inmediato.
-- ----------------------------------------------------------------------------
SELECT
    cl.nombre || ' ' || cl.apellido AS cliente,
    SUM(dp.cantidad * dp.precio_unitario) AS total_gastado,
    DENSE_RANK() OVER (ORDER BY SUM(dp.cantidad * dp.precio_unitario) DESC) AS puesto
FROM clientes cl
JOIN pedidos pe ON pe.id_cliente = cl.id_cliente
JOIN detalles_pedido dp ON dp.id_pedido = pe.id_pedido
GROUP BY cl.id_cliente, cl.nombre, cl.apellido
ORDER BY puesto;

-- Muestra representativa de los primeros resultados:
--               cliente              | total_gastado | puesto
-- -----------------------------------+---------------+--------
--  Nombre_7456 Apellido_7456         |     412879.32 |      1
--  Nombre_14847 Apellido_14847       |     395037.65 |      2
--  Nombre_17542 Apellido_17542       |     388685.93 |      3
--  Nombre_5484 Apellido_5484         |     386983.76 |      4
--  Nombre_7060 Apellido_7060         |     383973.53 |      5
--  Nombre_994 Apellido_994           |     382885.21 |      6


-- ----------------------------------------------------------------------------
-- NOTA METODOLÓGICA / ERROR DE LA IA: Intento fallido con COUNT(*)
-- ----------------------------------------------------------------------------
-- Inicialmente, la IA propuso la siguiente subconsulta correlacionada:
-- (SELECT COUNT(*) + 1 FROM totales t2 WHERE t2.total_gastado > t1.total_gastado)
-- RESULTADO DE LA VALIDACIÓN CON EXCEPT: ¡19.433 filas de discrepancia!
-- CAUSA: COUNT(*) cuenta todas las filas con gasto mayor, lo cual replica
-- la semántica de RANK() (con huecos tras empates), violando la especificación.
-- Para replicar DENSE_RANK(), se deben contar los VALORES DISTINTOS de gasto.


-- ----------------------------------------------------------------------------
-- VERSIÓN 2 — Alternativa Equivalente con Subconsulta Correlacionada (Sin Ventana)
-- Técnica: CTE que precalcula los totales por cliente, seguido de una subconsulta
-- correlacionada que cuenta cuántos montos DISTINTOS son estrictamente mayores
-- al del cliente en curso.
-- ----------------------------------------------------------------------------
WITH totales AS (
    SELECT
        cl.id_cliente,
        cl.nombre || ' ' || cl.apellido AS cliente,
        SUM(dp.cantidad * dp.precio_unitario) AS total_gastado
    FROM clientes cl
    JOIN pedidos pe ON pe.id_cliente = cl.id_cliente
    JOIN detalles_pedido dp ON dp.id_pedido = pe.id_pedido
    GROUP BY cl.id_cliente, cl.nombre, cl.apellido
)
SELECT
    t1.cliente,
    t1.total_gastado,
    (
        SELECT COUNT(DISTINCT t2.total_gastado) + 1
        FROM totales t2
        WHERE t2.total_gastado > t1.total_gastado
    ) AS puesto
FROM totales t1
ORDER BY puesto;


-- ----------------------------------------------------------------------------
-- PRUEBA FORMAL DE EQUIVALENCIA MEDIANTE EXCEPT BIDIRECCIONAL
-- Ambas consultas deben devolver exactamente el mismo conjunto de datos.
-- ----------------------------------------------------------------------------

-- Sentido 1: Filas en V1 que no estén en V2 (Debe retornar 0 filas)
(
    SELECT
        cl.nombre || ' ' || cl.apellido AS cliente,
        SUM(dp.cantidad * dp.precio_unitario) AS total_gastado,
        DENSE_RANK() OVER (ORDER BY SUM(dp.cantidad * dp.precio_unitario) DESC) AS puesto
    FROM clientes cl
    JOIN pedidos pe ON pe.id_cliente = cl.id_cliente
    JOIN detalles_pedido dp ON dp.id_pedido = pe.id_pedido
    GROUP BY cl.id_cliente, cl.nombre, cl.apellido
)
EXCEPT
(
    WITH totales AS (
        SELECT
            cl.id_cliente,
            cl.nombre || ' ' || cl.apellido AS cliente,
            SUM(dp.cantidad * dp.precio_unitario) AS total_gastado
        FROM clientes cl
        JOIN pedidos pe ON pe.id_cliente = cl.id_cliente
        JOIN detalles_pedido dp ON dp.id_pedido = pe.id_pedido
        GROUP BY cl.id_cliente, cl.nombre, cl.apellido
    )
    SELECT
        t1.cliente,
        t1.total_gastado,
        (
            SELECT COUNT(DISTINCT t2.total_gastado) + 1
            FROM totales t2
            WHERE t2.total_gastado > t1.total_gastado
        ) AS puesto
    FROM totales t1
);
-- Resultado en motor: (0 rows)

-- Sentido 2: Filas en V2 que no estén en V1 (Debe retornar 0 filas)
(
    WITH totales AS (
        SELECT
            cl.id_cliente,
            cl.nombre || ' ' || cl.apellido AS cliente,
            SUM(dp.cantidad * dp.precio_unitario) AS total_gastado
        FROM clientes cl
        JOIN pedidos pe ON pe.id_cliente = cl.id_cliente
        JOIN detalles_pedido dp ON dp.id_pedido = pe.id_pedido
        GROUP BY cl.id_cliente, cl.nombre, cl.apellido
    )
    SELECT
        t1.cliente,
        t1.total_gastado,
        (
            SELECT COUNT(DISTINCT t2.total_gastado) + 1
            FROM totales t2
            WHERE t2.total_gastado > t1.total_gastado
        ) AS puesto
    FROM totales t1
)
EXCEPT
(
    SELECT
        cl.nombre || ' ' || cl.apellido AS cliente,
        SUM(dp.cantidad * dp.precio_unitario) AS total_gastado,
        DENSE_RANK() OVER (ORDER BY SUM(dp.cantidad * dp.precio_unitario) DESC) AS puesto
    FROM clientes cl
    JOIN pedidos pe ON pe.id_cliente = cl.id_cliente
    JOIN detalles_pedido dp ON dp.id_pedido = pe.id_pedido
    GROUP BY cl.id_cliente, cl.nombre, cl.apellido
);
-- Resultado en motor: (0 rows)

-- CONCLUSIÓN: Equivalencia matemática y relacional demostrada empíricamente.

