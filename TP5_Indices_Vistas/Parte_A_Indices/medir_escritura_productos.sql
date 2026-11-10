-- ============================================================================
-- medir_escritura_productos.sql — Medición de Penalización en Escritura (INSERTs)
-- Evalúa el costo de insertar 10.000 tuplas en productos bajo 3 escenarios:
--   1. Sin índices secundarios (solo PK)
--   2. Con 1 índice secundario (idx_productos_categoria_precio)
--   3. Con 2 índices secundarios (+ idx_productos_categoria_precio_activo)
-- ============================================================================

-- Tabla temporal idéntica para aislar pruebas sin ensuciar la base oficial
CREATE TEMP TABLE temp_productos (LIKE productos INCLUDING DEFAULTS INCLUDING CONSTRAINTS);
ALTER TABLE temp_productos ADD PRIMARY KEY (id_producto);

\echo '=== 1. Inserción de 10.000 filas SIN índices secundarios ==='
\timing on
INSERT INTO temp_productos (id_categoria, nombre, precio_actual, stock, activo)
SELECT 
    floor(random() * 5 + 1)::int,
    'Prod_Test_' || i,
    (random() * 4500 + 500)::numeric(12,2),
    100,
    true
FROM generate_series(1, 10000) AS t(i);
\timing off
TRUNCATE temp_productos;

\echo '=== 2. Inserción de 10.000 filas CON 1 índice secundario ==='
CREATE INDEX idx_temp_prod_1 ON temp_productos (id_categoria, precio_actual);
\timing on
INSERT INTO temp_productos (id_categoria, nombre, precio_actual, stock, activo)
SELECT 
    floor(random() * 5 + 1)::int,
    'Prod_Test_' || i,
    (random() * 4500 + 500)::numeric(12,2),
    100,
    true
FROM generate_series(1, 10000) AS t(i);
\timing off
TRUNCATE temp_productos;

\echo '=== 3. Inserción de 10.000 filas CON 2 índices secundarios ==='
CREATE INDEX idx_temp_prod_2 ON temp_productos (id_categoria, precio_actual DESC) WHERE activo = TRUE;
\timing on
INSERT INTO temp_productos (id_categoria, nombre, precio_actual, stock, activo)
SELECT 
    floor(random() * 5 + 1)::int,
    'Prod_Test_' || i,
    (random() * 4500 + 500)::numeric(12,2),
    100,
    true
FROM generate_series(1, 10000) AS t(i);
\timing off
DROP TABLE temp_productos;
