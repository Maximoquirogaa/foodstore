-- ============================================================================
-- TRABAJO PRÁCTICO N.º 10 (UNIDAD 8): Food Store en la Feria (Móvil & SQLite)
-- Base de Datos II - Tecnicatura Universitaria en Programación (UTN FRM)
-- Alumno: Máximo Juan Cruz Quiroga (maximoj.quiroga@alumnos.frm.utn.edu.ar)
-- Consigna 2.a: Importación inicial del snapshot del servidor a SQLite
-- ============================================================================

PRAGMA foreign_keys = ON;

-- 1. Vaciar tabla de snapshot anterior
DELETE FROM snapshot_servidor;

-- 2. Cargar en snapshot_servidor convirtiendo booleanos t/f de Postgres a 1/0 enteros
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

-- 3. Poblar la caché local del catálogo (producto_cache)
DELETE FROM producto_cache;

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
FROM snapshot_servidor;
