-- ============================================================================
-- queries.sql — Consultas de Negocio y Analíticas (Carga de Trabajo Real)
-- Proyecto: Food Store (UTN FRM - Base de Datos II)
-- Alumno: Máximo Juan Cruz Quiroga
-- Docente: Sergio Neira
-- Motor: PostgreSQL 17
-- Base de trabajo: Esquema masivo Food Store (~20k clientes, ~50k productos, ~200k pedidos, ~500k detalles)
-- ============================================================================

-- Q1: Pedidos recientes por forma de pago (Panel operativo de despachos)
SELECT id_pedido, fecha_pedido, forma_pago, id_cliente
FROM pedidos
WHERE forma_pago = 'EFECTIVO'
ORDER BY fecha_pedido DESC
LIMIT 50;

-- Q2: Productos de una categoría específica en un rango de precio
SELECT id_producto, nombre, precio_actual, stock
FROM productos
WHERE id_categoria = 1 AND precio_actual BETWEEN 1000 AND 3000
ORDER BY precio_actual;

-- Q3: Total facturado por cliente en un rango de fechas
SELECT 
    c.id_cliente, 
    c.nombre || ' ' || c.apellido AS cliente, 
    SUM(dp.cantidad * dp.precio_unitario) AS total_facturado
FROM clientes c
JOIN pedidos p ON p.id_cliente = c.id_cliente
JOIN detalles_pedido dp ON dp.id_pedido = p.id_pedido
WHERE p.fecha_pedido BETWEEN '2025-06-01' AND '2025-12-31'
GROUP BY c.id_cliente, c.nombre, c.apellido
ORDER BY total_facturado DESC
LIMIT 20;

-- Q4: Top 3 productos por facturación dentro de cada categoría (últimos 6 meses)
-- Consulta analítica compleja utilizada en la competencia de optimización
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
SELECT * 
FROM ranking 
WHERE ranking_en_categoria <= 3 
ORDER BY categoria, ranking_en_categoria;

-- Q5: Ranking de clientes por gasto acumulado total (Función de ventana DENSE_RANK)
SELECT
    c.nombre || ' ' || c.apellido AS cliente,
    SUM(dp.cantidad * dp.precio_unitario) AS total_gastado,
    DENSE_RANK() OVER (ORDER BY SUM(dp.cantidad * dp.precio_unitario) DESC) AS puesto
FROM clientes c
JOIN pedidos p ON p.id_cliente = c.id_cliente
JOIN detalles_pedido dp ON dp.id_pedido = p.id_pedido
GROUP BY c.id_cliente, c.nombre, c.apellido
ORDER BY puesto;

-- Q6: Productos activos con precio actual superior al promedio de su categoría
-- (Subconsulta correlacionada en WHERE)
SELECT p.nombre, p.precio_actual
FROM productos p
JOIN categorias cat ON cat.id_categoria = p.id_categoria AND cat.activo = TRUE
WHERE p.activo = TRUE
  AND p.precio_actual > (
      SELECT AVG(p2.precio_actual)
      FROM productos p2
      WHERE p2.activo = TRUE AND p2.id_categoria = p.id_categoria
  )
ORDER BY cat.id_categoria, p.precio_actual DESC;
