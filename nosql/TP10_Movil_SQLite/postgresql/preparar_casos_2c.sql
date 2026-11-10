-- ============================================================================
-- TRABAJO PRÁCTICO N.º 10 (UNIDAD 8): Food Store en la Feria (Móvil & SQLite)
-- Base de Datos II - Tecnicatura Universitaria en Programación (UTN FRM)
-- Alumno: Máximo Juan Cruz Quiroga (maximoj.quiroga@alumnos.frm.utn.edu.ar)
-- Consigna 2.c: Preparación de cambios en el servidor PostgreSQL (Copia de Pruebas)
-- ============================================================================

-- IMPORTANTE: Ejecutar únicamente en la base de pruebas (ej: foodstore_feria_test)
-- Aplica los cambios que provocan el conflicto C2 (suba de precio) y C4 (baja lógica)

BEGIN;

-- 1. C2: Subir el precio de 'Hamburguesa Clásica' (id_producto = 1) de $4.500 a $4.800
UPDATE public.productos
SET precio_actual = 4800.00
WHERE id_producto = 1;

-- 2. C4: Dar de baja lógica 'Papas Fritas Medianas' (id_producto = 3)
UPDATE public.productos
SET activo = FALSE
WHERE id_producto = 3;

COMMIT;

-- Instrucción para exportar la segunda instantánea desde psql:
-- \copy (SELECT * FROM v_snapshot_movil) TO 'nosql/TP10/movil/servidor_snapshot_2c.csv' CSV HEADER
