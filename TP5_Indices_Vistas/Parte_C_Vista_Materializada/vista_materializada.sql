-- ============================================================================
-- Parte_C_Vista_Materializada/vista_materializada.sql — Vista Materializada
-- Proyecto: Food Store (UTN FRM - Base de Datos II)
-- Alumno: Máximo Juan Cruz Quiroga
-- Docente: Sergio Neira
-- Motor: PostgreSQL 17
-- ============================================================================

-- 1. Creación de la Vista Materializada con los datos precalculados
CREATE MATERIALIZED VIEW IF NOT EXISTS mv_resumen_ventas_categoria_mes AS
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
GROUP BY c.id_categoria, c.nombre, DATE_TRUNC('month', p.fecha_pedido)
WITH DATA;

COMMENT ON MATERIALIZED VIEW mv_resumen_ventas_categoria_mes IS 'Resumen pre-agregado de ventas por categoría y mes para reportes analíticos.';

-- 2. Índice Único Mandatorio para Habilitar Refresco Concurrente
-- PostgreSQL exige un índice único sin condiciones WHERE para poder ejecutar
-- REFRESH MATERIALIZED VIEW CONCURRENTLY sin bloquear lectores.
CREATE UNIQUE INDEX IF NOT EXISTS idx_mv_resumen_ventas_categoria_mes
    ON mv_resumen_ventas_categoria_mes (id_categoria, mes);

-- 3. Cargar / Actualizar los Datos Iniciales
REFRESH MATERIALIZED VIEW mv_resumen_ventas_categoria_mes;

-- 4. Consultas Típicas de Reporte sobre la Vista Materializada
SELECT *
FROM mv_resumen_ventas_categoria_mes
ORDER BY mes DESC, facturacion_total DESC;

SELECT categoria, mes, facturacion_total
FROM mv_resumen_ventas_categoria_mes
WHERE id_categoria = 1
ORDER BY mes DESC;

-- 5. Protocolo de Refresco No Bloqueante en Producción
-- Toma ExclusiveLock en lugar de AccessExclusiveLock, por lo que los SELECT concurrentes
-- siguen respondiendo sin interrupciones ni bloqueos de lectura.
-- Frecuencia recomendada: Ejecución diaria nocturna mediante cron o scheduler de base de datos.
REFRESH MATERIALIZED VIEW CONCURRENTLY mv_resumen_ventas_categoria_mes;
