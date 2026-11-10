-- ============================================================================
-- TRABAJO PRÁCTICO N.º 10 (UNIDAD 8): Food Store en la Feria (Móvil & SQLite)
-- Base de Datos II - Tecnicatura Universitaria en Programación (UTN FRM)
-- Alumno: Máximo Juan Cruz Quiroga (maximoj.quiroga@alumnos.frm.utn.edu.ar)
-- Consigna 2.a: Vista de lectura en PostgreSQL para la exportación de la instantánea
-- ============================================================================

-- No modifica datos de tablas: define la vista de lectura para exportar a CSV
CREATE OR REPLACE VIEW v_snapshot_movil AS
SELECT
    p.id_producto AS id,
    p.nombre,
    (p.precio_actual * 100)::bigint AS precio_centavos,
    p.stock::bigint AS stock,
    p.activo AS disponible,
    (NOT p.activo) AS eliminado,
    CURRENT_TIMESTAMP AS fecha_copia
FROM public.productos AS p
ORDER BY p.id_producto;

-- Instrucción para exportar la instantánea desde psql:
-- \copy (SELECT * FROM v_snapshot_movil) TO 'nosql/TP10/movil/servidor_snapshot.csv' CSV HEADER
