-- ============================================================================
-- medir_escritura_detalles.sql — Medición de Penalización en detalles_pedido
-- Demuestra el costo de mantenimiento de un índice secundario redundante en
-- una tabla de alta frecuencia transaccional (detalles_pedido).
-- ============================================================================

CREATE TEMP TABLE temp_detalles (LIKE detalles_pedido INCLUDING DEFAULTS INCLUDING CONSTRAINTS);
ALTER TABLE temp_detalles ADD PRIMARY KEY (id_pedido, id_producto);

\echo '=== 1. Inserción de 20.000 detalles solo con la PK compuesta ==='
\timing on
INSERT INTO temp_detalles (id_pedido, id_producto, cantidad, precio_unitario)
SELECT 
    i,
    floor(random() * 50000 + 1)::bigint,
    1,
    (random() * 4500 + 500)::numeric(12,2)
FROM generate_series(1, 20000) AS t(i);
\timing off
TRUNCATE temp_detalles;

\echo '=== 2. Inserción de 20.000 detalles con índice redundante en id_pedido ==='
CREATE INDEX idx_temp_det_redundante ON temp_detalles (id_pedido);
\timing on
INSERT INTO temp_detalles (id_pedido, id_producto, cantidad, precio_unitario)
SELECT 
    i,
    floor(random() * 50000 + 1)::bigint,
    1,
    (random() * 4500 + 500)::numeric(12,2)
FROM generate_series(1, 20000) AS t(i);
\timing off
DROP TABLE temp_detalles;
