-- ============================================================================
-- TP8 — Mantenimiento Justificado de Base de Datos
-- Proyecto: Food Store — Base de Datos II (UTN FRM)
-- Alumno: Máximo Juan Cruz Quiroga (maximoj.quiroga@alumnos.frm.utn.edu.ar)
-- Docente: Sergio Neira
-- ============================================================================
\set ON_ERROR_STOP on
\pset pager off

-- Guarda de seguridad: ejecutar exclusivamente contra la copia restaurada de prueba
DO $$ 
BEGIN 
    IF current_database() <> 'foodstore_restore_test' THEN 
        RAISE EXCEPTION 'Destino incorrecto para mantenimiento: %. Se esperaba foodstore_restore_test.', current_database(); 
    END IF; 
END $$;

SET lock_timeout = '5s';
SET statement_timeout = '60s';

SELECT current_database() AS base, current_timestamp AS inicio_mantenimiento;

-- 1. Diagnóstico previo del estado de autovacuum y estadísticas de relaciones
SELECT 
    schemaname,
    relname, 
    n_live_tup, 
    n_dead_tup, 
    n_mod_since_analyze, 
    last_vacuum, 
    last_autovacuum, 
    last_analyze, 
    last_autoanalyze 
FROM pg_stat_user_tables 
WHERE schemaname = 'public' 
ORDER BY relname;

-- 2. Inspección de cobertura estadística previa en relaciones analizadas
SELECT 
    c.relname AS relacion,
    c.reltuples AS tuplas_estimadas,
    (SELECT count(*) FROM pg_stats s WHERE s.schemaname = n.nspname AND s.tablename = c.relname) AS columnas_con_estadisticas 
FROM pg_class c 
JOIN pg_namespace n ON n.oid = c.relnamespace 
WHERE n.nspname = 'public' 
  AND c.relname IN ('categoria', 'categorias', 'usuario', 'usuarios', 'mv_resumen_ventas_categoria_mes') 
ORDER BY c.relname;

-- 3. Captura transaccional de conteos previos
DO $$
BEGIN
    -- Mapeo temporal si las tablas son plurales
    IF to_regclass('public.categorias') IS NOT NULL AND to_regclass('public.categoria') IS NULL THEN
        CREATE TEMP VIEW categoria AS SELECT * FROM public.categorias;
    END IF;
    IF to_regclass('public.usuarios') IS NOT NULL AND to_regclass('public.usuario') IS NULL THEN
        CREATE TEMP VIEW usuario AS SELECT * FROM public.usuarios;
    END IF;
END $$;

SELECT 
    (SELECT count(*) FROM categoria) AS categoria,
    (SELECT count(*) FROM usuario) AS usuario,
    (SELECT count(*) FROM public.mv_resumen_ventas_categoria_mes) AS vista_materializada 
\gset antes_

\echo Conteos previos capturados: categoria=:antes_categoria usuario=:antes_usuario vista_materializada=:antes_vista_materializada

-- 4. Ejecución del ANALYZE justificado (relaciones pequeñas que escapan al umbral de autovacuum)
DO $$
BEGIN
    IF to_regclass('public.categorias') IS NOT NULL THEN
        EXECUTE 'ANALYZE VERBOSE public.categorias';
    ELSIF to_regclass('public.categoria') IS NOT NULL THEN
        EXECUTE 'ANALYZE VERBOSE public.categoria';
    END IF;

    IF to_regclass('public.usuarios') IS NOT NULL THEN
        EXECUTE 'ANALYZE VERBOSE public.usuarios';
    ELSIF to_regclass('public.usuario') IS NOT NULL THEN
        EXECUTE 'ANALYZE VERBOSE public.usuario';
    END IF;

    IF to_regclass('public.mv_resumen_ventas_categoria_mes') IS NOT NULL THEN
        EXECUTE 'ANALYZE VERBOSE public.mv_resumen_ventas_categoria_mes';
    END IF;
END $$;

-- 5. Verificación de actualización del planificador
SELECT 
    schemaname,
    relname, 
    n_live_tup, 
    n_dead_tup, 
    n_mod_since_analyze, 
    last_vacuum, 
    last_autovacuum, 
    last_analyze, 
    last_autoanalyze 
FROM pg_stat_user_tables 
WHERE schemaname = 'public' 
  AND relname IN ('categoria', 'categorias', 'usuario', 'usuarios', 'mv_resumen_ventas_categoria_mes')
ORDER BY relname;

-- 6. Verificación estricta: los conteos deben permanecer intactos tras ANALYZE
SELECT 
    (SELECT count(*) FROM categoria) = :antes_categoria 
    AND (SELECT count(*) FROM usuario) = :antes_usuario 
    AND (SELECT count(*) FROM public.mv_resumen_ventas_categoria_mes) = :antes_vista_materializada 
    AS conteos_sin_cambios 
\gset

\if :conteos_sin_cambios
    \echo VALIDACION EXITOSA: Los conteos exactos de filas fueron rigurosamente preservados.
\else
    \echo ERROR CRITICO: Discrepancia detectada en conteos tras ANALYZE.
    \quit 3
\endif

-- 7. Cobertura estadística posterior
SELECT 
    c.relname AS relacion,
    c.reltuples AS tuplas_estimadas,
    (SELECT count(*) FROM pg_stats s WHERE s.schemaname = n.nspname AND s.tablename = c.relname) AS columnas_con_estadisticas 
FROM pg_class c 
JOIN pg_namespace n ON n.oid = c.relnamespace 
WHERE n.nspname = 'public' 
  AND c.relname IN ('categoria', 'categorias', 'usuario', 'usuarios', 'mv_resumen_ventas_categoria_mes') 
ORDER BY c.relname;

SELECT current_database() AS base, current_timestamp AS fin_mantenimiento;
