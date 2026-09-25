-- ==========================================
-- TP5 - Parte A: Medición de costo de escritura (INSERTs)
-- Ejecuta este bloque completo y anota cuánto tiempo total tarda (Execution Time).
-- Hazlo ANTES de los índices y luego DESPUÉS de los índices.
-- ==========================================

EXPLAIN ANALYZE
INSERT INTO detalles_pedido (id_pedido, id_producto, cantidad, precio_unitario)
SELECT 
    p.id_pedido,
    floor(random() * 50000 + 1)::int,
    1,
    1500.00
FROM pedidos p
-- Solo tomamos 5000 pedidos al azar para simular una carga pesada transaccional
WHERE p.id_pedido IN (
    SELECT id_pedido FROM pedidos ORDER BY random() LIMIT 5000
)
ON CONFLICT DO NOTHING;

