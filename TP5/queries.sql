-- ==========================================
-- TP5 - Parte A: Consultas frecuentes (Queries base)
-- Ejecuta EXPLAIN ANALYZE para cada una antes de crear los índices.
-- ==========================================

-- Consulta 1: Buscar producto por nombre exacto
-- Al no ser UNIQUE, no tiene índice automático. Forzará Seq Scan.
EXPLAIN ANALYZE
SELECT id_producto, precio_actual, stock
FROM productos
WHERE nombre = 'Producto_Gen_45000';

-- Consulta 2: Listar todos los pedidos pagados en EFECTIVO
-- (Esta la usaremos para evaluar la SOBREINDEXACIÓN)
EXPLAIN ANALYZE
SELECT id_pedido, fecha_pedido
FROM pedidos
WHERE forma_pago = 'EFECTIVO';

-- Consulta 3: Buscar detalles de pedido de alto valor unitario
EXPLAIN ANALYZE
SELECT id_pedido, id_producto, precio_unitario
FROM detalles_pedido
WHERE precio_unitario > 4800.00;

