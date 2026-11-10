-- ============================================================================
-- TP4 — PARTE 4: Consulta Oficial para la Competencia de Optimización
-- Problema: Top 3 productos más vendidos por facturación dentro de cada categoría
--           durante los últimos 6 meses, con porcentaje de aporte a su categoría.
-- Base de datos: Food Store (UTN FRM - PostgreSQL 17)
-- Alumno: Máximo Juan Cruz Quiroga
-- Docente: Sergio Neira
-- ============================================================================

-- Consulta base de la competencia:
WITH ventas_producto AS (
    SELECT
        cat.id_categoria,
        cat.nombre AS categoria,
        p.id_producto,
        p.nombre AS producto,
        SUM(dp.cantidad) AS unidades_vendidas,
        SUM(dp.cantidad * dp.precio_unitario) AS facturacion_producto
    FROM categorias cat
    JOIN productos p ON p.id_categoria = cat.id_categoria
    JOIN detalles_pedido dp ON dp.id_producto = p.id_producto
    JOIN pedidos ped ON ped.id_pedido = dp.id_pedido
    WHERE ped.fecha_pedido >= now() - interval '6 months'
      AND cat.activo = TRUE
      AND p.activo = TRUE
    GROUP BY cat.id_categoria, cat.nombre, p.id_producto, p.nombre
),
ranking AS (
    SELECT
        categoria,
        producto,
        unidades_vendidas,
        facturacion_producto,
        ROUND(100.0 * facturacion_producto / SUM(facturacion_producto) OVER (PARTITION BY id_categoria), 2) AS pct_de_su_categoria,
        RANK() OVER (PARTITION BY id_categoria ORDER BY facturacion_producto DESC) AS ranking_en_categoria
    FROM ventas_producto
)
SELECT
    categoria,
    producto,
    unidades_vendidas,
    facturacion_producto,
    pct_de_su_categoria,
    ranking_en_categoria
FROM ranking
WHERE ranking_en_categoria <= 3
ORDER BY categoria, ranking_en_categoria;


-- ============================================================================
-- PROTOCOLO DE EJECUCIÓN OPTIMIZADA (SET LOCAL work_mem = '8MB')
-- ============================================================================
-- Se ejecuta dentro de un bloque transaccional para aplicar la ampliación de
-- memoria de trabajo localmente sin afectar a otras sesiones del servidor:

BEGIN;

-- Ajuste óptimo de memoria para evitar que el operador Sort derrame a disco:
SET LOCAL work_mem = '8MB';

EXPLAIN (ANALYZE, BUFFERS, VERBOSE)
WITH ventas_producto AS (
    SELECT
        cat.id_categoria,
        cat.nombre AS categoria,
        p.id_producto,
        p.nombre AS producto,
        SUM(dp.cantidad) AS unidades_vendidas,
        SUM(dp.cantidad * dp.precio_unitario) AS facturacion_producto
    FROM categorias cat
    JOIN productos p ON p.id_categoria = cat.id_categoria
    JOIN detalles_pedido dp ON dp.id_producto = p.id_producto
    JOIN pedidos ped ON ped.id_pedido = dp.id_pedido
    WHERE ped.fecha_pedido >= now() - interval '6 months'
      AND cat.activo = TRUE
      AND p.activo = TRUE
    GROUP BY cat.id_categoria, cat.nombre, p.id_producto, p.nombre
),
ranking AS (
    SELECT
        categoria,
        producto,
        unidades_vendidas,
        facturacion_producto,
        ROUND(100.0 * facturacion_producto / SUM(facturacion_producto) OVER (PARTITION BY id_categoria), 2) AS pct_de_su_categoria,
        RANK() OVER (PARTITION BY id_categoria ORDER BY facturacion_producto DESC) AS ranking_en_categoria
    FROM ventas_producto
)
SELECT
    categoria,
    producto,
    unidades_vendidas,
    facturacion_producto,
    pct_de_su_categoria,
    ranking_en_categoria
FROM ranking
WHERE ranking_en_categoria <= 3
ORDER BY categoria, ranking_en_categoria;

ROLLBACK;

