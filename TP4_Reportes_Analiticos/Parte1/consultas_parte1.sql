-- ============================================================================
-- TP4 - Parte 1: Consultas Analíticas Lentas y Optimización Medida
-- Proyecto: Food Store (UTN FRM - Base de Datos II)
-- Alumno: Máximo Juan Cruz Quiroga
-- Docente: Sergio Neira
-- Motor: PostgreSQL 17
-- ============================================================================

-- ============================================================================
-- CONSULTA A: Facturación mensual total por categoría activa
-- ============================================================================
-- Cruza 4 tablas: categorias, productos, detalles_pedido y pedidos.
-- Filtra por categorías activas, agrupa por categoría y mes truncado de fecha_pedido.

-- 1. Medición BASELINE (Antes de optimizar)
EXPLAIN (ANALYZE, BUFFERS, VERBOSE)
SELECT
    c.id_categoria,
    c.nombre AS categoria,
    DATE_TRUNC('month', pe.fecha_pedido) AS mes,
    SUM(dp.cantidad * dp.precio_unitario) AS total_facturado
FROM categorias AS c
JOIN productos AS p ON p.id_categoria = c.id_categoria
JOIN detalles_pedido AS dp ON dp.id_producto = p.id_producto
JOIN pedidos AS pe ON pe.id_pedido = dp.id_pedido
WHERE c.activo = TRUE
GROUP BY
    c.id_categoria,
    c.nombre,
    DATE_TRUNC('month', pe.fecha_pedido)
ORDER BY
    mes,
    total_facturado DESC;


-- 2. Prueba de Optimización para Consulta A (Transacción Reversible)
-- Hipótesis: Crear un índice que cubra pedidos (id_pedido) incluyendo fecha_pedido
-- para que el join con detalles_pedido pueda resolver la lectura de pedidos mediante
-- un Index Only Scan sin tener que tocar las páginas del Heap.
BEGIN;

CREATE INDEX idx_TP4_a_pedidos_fecha ON pedidos (id_pedido) INCLUDE (fecha_pedido);
ANALYZE pedidos;

EXPLAIN (ANALYZE, BUFFERS, VERBOSE)
SELECT
    c.id_categoria,
    c.nombre AS categoria,
    DATE_TRUNC('month', pe.fecha_pedido) AS mes,
    SUM(dp.cantidad * dp.precio_unitario) AS total_facturado
FROM categorias AS c
JOIN productos AS p ON p.id_categoria = c.id_categoria
JOIN detalles_pedido AS dp ON dp.id_producto = p.id_producto
JOIN pedidos AS pe ON pe.id_pedido = dp.id_pedido
WHERE c.activo = TRUE
GROUP BY
    c.id_categoria,
    c.nombre,
    DATE_TRUNC('month', pe.fecha_pedido)
ORDER BY
    mes,
    total_facturado DESC;

-- Revertimos para mantener el entorno limpio según protocolo de laboratorio
ROLLBACK;


-- ============================================================================
-- CONSULTA B: Ranking histórico de clientes por gasto total
-- ============================================================================
-- Cruza 3 tablas: clientes, pedidos y detalles_pedido.
-- Agrupa por cliente, calcula el total acumulado y limita a los primeros 20.

-- 1. Medición BASELINE (Antes de optimizar)
EXPLAIN (ANALYZE, BUFFERS, VERBOSE)
SELECT
    cl.id_cliente,
    cl.nombre || ' ' || cl.apellido AS cliente,
    SUM(dp.cantidad * dp.precio_unitario) AS total_gastado
FROM clientes AS cl
JOIN pedidos AS pe ON pe.id_cliente = cl.id_cliente
JOIN detalles_pedido AS dp ON dp.id_pedido = pe.id_pedido
GROUP BY
    cl.id_cliente,
    cl.nombre,
    cl.apellido
ORDER BY
    total_gastado DESC
LIMIT 20;


-- 2. Prueba de Optimización para Consulta B (Transacción Reversible)
-- Hipótesis propuesta por IA: Índice en pedidos(id_pedido) INCLUDE (id_cliente).
BEGIN;

CREATE INDEX idx_TP4_b_pedidos_cliente ON pedidos (id_pedido) INCLUDE (id_cliente);
ANALYZE pedidos;

EXPLAIN (ANALYZE, BUFFERS, VERBOSE)
SELECT
    cl.id_cliente,
    cl.nombre || ' ' || cl.apellido AS cliente,
    SUM(dp.cantidad * dp.precio_unitario) AS total_gastado
FROM clientes AS cl
JOIN pedidos AS pe ON pe.id_cliente = cl.id_cliente
JOIN detalles_pedido AS dp ON dp.id_pedido = pe.id_pedido
GROUP BY
    cl.id_cliente,
    cl.nombre,
    cl.apellido
ORDER BY
    total_gastado DESC
LIMIT 20;

-- Revertimos (Resultado: RECHAZADO, el optimizador mantuvo Parallel Seq Scan)
ROLLBACK;


-- 3. Prueba adicional de configuración de memoria sobre Consulta B
-- El plan revela derrame a disco (Disk Usage: ~720kB) en el HashAggregate.
-- Comprobamos si ampliando work_mem a 64MB se elimina el spill sin alterar índices:
BEGIN;
SET LOCAL work_mem = '64MB';

EXPLAIN (ANALYZE, BUFFERS, VERBOSE)
SELECT
    cl.id_cliente,
    cl.nombre || ' ' || cl.apellido AS cliente,
    SUM(dp.cantidad * dp.precio_unitario) AS total_gastado
FROM clientes AS cl
JOIN pedidos AS pe ON pe.id_cliente = cl.id_cliente
JOIN detalles_pedido AS dp ON dp.id_pedido = pe.id_pedido
GROUP BY
    cl.id_cliente,
    cl.nombre,
    cl.apellido
ORDER BY
    total_gastado DESC
LIMIT 20;

ROLLBACK;

