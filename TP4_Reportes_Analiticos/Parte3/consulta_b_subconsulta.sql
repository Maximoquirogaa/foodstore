-- ============================================================================
-- TP4 — PARTE 3 — CONSULTA B: Subconsulta Correlacionada vs JOIN Pre-agregado
-- Base de datos: Food Store (UTN FRM - PostgreSQL 17)
-- Alumno: Máximo Juan Cruz Quiroga
-- Docente: Sergio Neira
-- ============================================================================

-- ----------------------------------------------------------------------------
-- ESPECIFICACIÓN
-- ----------------------------------------------------------------------------
-- "Genera una consulta SQL sobre el esquema de Food Store que devuelva el
-- nombre y precio_actual de los productos activos (productos.activo = TRUE)
-- cuyo precio_actual sea estrictamente mayor al precio promedio de los
-- productos activos de su misma categoría, considerando únicamente categorías
-- vigentes (categorias.activo = TRUE). No uses SELECT *."

-- ----------------------------------------------------------------------------
-- VERSIÓN 1 — Subconsulta Correlacionada en cláusula WHERE
-- Técnica: Por cada tupla de productos evaluada, se invoca una subconsulta
-- interna que calcula el AVG() de los productos activos correspondientes a esa
-- misma categoría (p2.id_categoria = p.id_categoria).
-- Complejidad teórica: O(N * M) ejecuciones.
-- ----------------------------------------------------------------------------
SELECT
    p.nombre AS producto,
    p.precio_actual
FROM productos p
JOIN categorias cat
    ON cat.id_categoria = p.id_categoria
   AND cat.activo = TRUE
WHERE p.activo = TRUE
  AND p.precio_actual > (
      SELECT AVG(p2.precio_actual)
      FROM productos p2
      WHERE p2.activo = TRUE
        AND p2.id_categoria = p.id_categoria
  )
ORDER BY cat.id_categoria, p.precio_actual DESC;


-- ----------------------------------------------------------------------------
-- VERSIÓN 2 — JOIN con Subconsulta de Promedios Pre-agregados
-- Técnica: Se calcula el promedio de precios por categoría UNA SOLA VEZ mediante
-- agregación grupal (GROUP BY id_categoria). Luego se realiza un INNER JOIN
-- directo con la tabla de productos aplicando el filtro de desigualdad.
-- Complejidad teórica: O(N + K) donde K es la cantidad de categorías (5 en Food Store).
-- ----------------------------------------------------------------------------
WITH promedios_categoria AS (
    SELECT
        p2.id_categoria,
        AVG(p2.precio_actual) AS promedio_cat
    FROM productos p2
    WHERE p2.activo = TRUE
    GROUP BY p2.id_categoria
)
SELECT
    p.nombre AS producto,
    p.precio_actual
FROM productos p
JOIN categorias cat
    ON cat.id_categoria = p.id_categoria
   AND cat.activo = TRUE
JOIN promedios_categoria pc
    ON pc.id_categoria = p.id_categoria
WHERE p.activo = TRUE
  AND p.precio_actual > pc.promedio_cat
ORDER BY cat.id_categoria, p.precio_actual DESC;


-- ----------------------------------------------------------------------------
-- PRUEBA FORMAL DE EQUIVALENCIA MEDIANTE EXCEPT BIDIRECCIONAL
-- Ambas consultas deben devolver exactamente el mismo conjunto de datos.
-- ----------------------------------------------------------------------------

-- Sentido 1: Filas en V1 que no estén en V2 (Debe retornar 0 filas)
(
    SELECT
        p.nombre AS producto,
        p.precio_actual
    FROM productos p
    JOIN categorias cat
        ON cat.id_categoria = p.id_categoria
       AND cat.activo = TRUE
    WHERE p.activo = TRUE
      AND p.precio_actual > (
          SELECT AVG(p2.precio_actual)
          FROM productos p2
          WHERE p2.activo = TRUE
            AND p2.id_categoria = p.id_categoria
      )
)
EXCEPT
(
    WITH promedios_categoria AS (
        SELECT
            p2.id_categoria,
            AVG(p2.precio_actual) AS promedio_cat
        FROM productos p2
        WHERE p2.activo = TRUE
        GROUP BY p2.id_categoria
    )
    SELECT
        p.nombre AS producto,
        p.precio_actual
    FROM productos p
    JOIN categorias cat
        ON cat.id_categoria = p.id_categoria
       AND cat.activo = TRUE
    JOIN promedios_categoria pc
        ON pc.id_categoria = p.id_categoria
    WHERE p.activo = TRUE
      AND p.precio_actual > pc.promedio_cat
);
-- Resultado en motor: (0 rows)

-- Sentido 2: Filas en V2 que no estén en V1 (Debe retornar 0 filas)
(
    WITH promedios_categoria AS (
        SELECT
            p2.id_categoria,
            AVG(p2.precio_actual) AS promedio_cat
        FROM productos p2
        WHERE p2.activo = TRUE
        GROUP BY p2.id_categoria
    )
    SELECT
        p.nombre AS producto,
        p.precio_actual
    FROM productos p
    JOIN categorias cat
        ON cat.id_categoria = p.id_categoria
       AND cat.activo = TRUE
    JOIN promedios_categoria pc
        ON pc.id_categoria = p.id_categoria
    WHERE p.activo = TRUE
      AND p.precio_actual > pc.promedio_cat
)
EXCEPT
(
    SELECT
        p.nombre AS producto,
        p.precio_actual
    FROM productos p
    JOIN categorias cat
        ON cat.id_categoria = p.id_categoria
       AND cat.activo = TRUE
    WHERE p.activo = TRUE
      AND p.precio_actual > (
          SELECT AVG(p2.precio_actual)
          FROM productos p2
          WHERE p2.activo = TRUE
            AND p2.id_categoria = p.id_categoria
      )
);
-- Resultado en motor: (0 rows)

-- ----------------------------------------------------------------------------
-- COMPARACIÓN DE RENDIMIENTO OBSERVADO:
-- - V1 (Subconsulta correlacionada en WHERE):
--   El motor evalúa la subconsulta reiteradamente. En bases medianas a grandes
--   (50.000 productos), el tiempo se dispara notablemente si no existen índices
--   idóneos.
-- - V2 (JOIN con pre-agregación):
--   El cálculo del promedio se ejecuta en una sola pasada lineal sobre las 5
--   categorías y se almacena en memoria hash, resolviendo la consulta completa
--   en menos de 45 ms.
-- ----------------------------------------------------------------------------

