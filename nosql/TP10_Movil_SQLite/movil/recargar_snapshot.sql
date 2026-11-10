-- ============================================================================
-- TRABAJO PRÁCTICO N.º 10 (UNIDAD 8): Food Store en la Feria (Móvil & SQLite)
-- Base de Datos II - Tecnicatura Universitaria en Programación (UTN FRM)
-- Alumno: Máximo Juan Cruz Quiroga (maximoj.quiroga@alumnos.frm.utn.edu.ar)
-- Consigna 2.c: Recarga atómica del snapshot en la tablet sin romper FKs
-- ============================================================================

PRAGMA foreign_keys = ON;

BEGIN;

-- 1. Vaciar snapshot_servidor y cargar el nuevo lote de importación
DELETE FROM snapshot_servidor;

INSERT INTO snapshot_servidor (
    id,
    nombre,
    precio_centavos,
    stock,
    disponible,
    eliminado,
    fecha_copia
)
SELECT
    CAST(id AS INTEGER),
    nombre,
    CAST(precio_centavos AS INTEGER),
    CAST(stock AS INTEGER),
    CASE disponible WHEN 't' THEN 1 WHEN '1' THEN 1 WHEN 'true' THEN 1 ELSE 0 END,
    CASE eliminado WHEN 't' THEN 1 WHEN '1' THEN 1 WHEN 'true' THEN 1 ELSE 0 END,
    fecha_copia
FROM snapshot_servidor_import;

-- 2. Actualizar producto_cache mediante UPSERT (ON CONFLICT DO UPDATE)
-- Evita borrar filas que están siendo referenciadas por pedidos_borrador en item_borrador
INSERT INTO producto_cache (
    id,
    nombre,
    precio_centavos,
    stock_visto,
    disponible,
    eliminado,
    fecha_copia
)
SELECT
    id,
    nombre,
    precio_centavos,
    stock,
    disponible,
    eliminado,
    fecha_copia
FROM snapshot_servidor
WHERE true
ON CONFLICT (id) DO UPDATE SET
    nombre = excluded.nombre,
    precio_centavos = excluded.precio_centavos,
    stock_visto = excluded.stock_visto,
    disponible = excluded.disponible,
    eliminado = excluded.eliminado,
    fecha_copia = excluded.fecha_copia;

COMMIT;
