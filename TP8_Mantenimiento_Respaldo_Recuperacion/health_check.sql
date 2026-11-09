-- ============================================================================
-- TP8 — Chequeo de Salud y Diagnóstico Operativo de Base de Datos
-- Proyecto: Food Store — Base de Datos II (UTN FRM)
-- Alumno: Máximo Juan Cruz Quiroga (maximoj.quiroga@alumnos.frm.utn.edu.ar)
-- Docente: Sergio Neira
-- Motor: PostgreSQL 16+ (compatible con PostgreSQL 17)
-- ============================================================================
\set ON_ERROR_STOP on
\pset pager off
\pset null '(NULL)'

BEGIN TRANSACTION READ ONLY;

-- 1. Identificación del motor y base
SELECT current_database() AS base, current_timestamp AS fecha, version() AS motor;

-- 2. Tamaño total de la base de datos en disco
SELECT 
    current_database() AS base, 
    pg_database_size(current_database()) AS bytes, 
    pg_size_pretty(pg_database_size(current_database())) AS tamano_legible;

-- 3. Métricas de transacciones, lecturas y aciertos de caché (Buffer Cache Hit Ratio)
SELECT 
    datname, 
    numbackends, 
    xact_commit, 
    xact_rollback, 
    blks_read, 
    blks_hit, 
    ROUND(100.0 * blks_hit / NULLIF(blks_hit + blks_read, 0), 2) AS cache_hit_ratio,
    tup_returned, 
    tup_fetched, 
    tup_inserted, 
    tup_updated, 
    tup_deleted, 
    deadlocks, 
    stats_reset 
FROM pg_stat_database 
WHERE datname = current_database();

-- 4. Estado de conexiones concurrentes
SELECT 
    state, 
    count(*) AS total_conexiones 
FROM pg_stat_activity 
WHERE datname = current_database() 
GROUP BY state 
ORDER BY state NULLS LAST;

-- 5. Tuplas vivas, muertas y actividad de autovacuum por relación
SELECT 
    schemaname, 
    relname, 
    n_live_tup, 
    n_dead_tup, 
    n_mod_since_analyze, 
    last_vacuum, 
    last_autovacuum, 
    last_analyze, 
    last_autoanalyze, 
    vacuum_count, 
    autovacuum_count, 
    analyze_count, 
    autoanalyze_count 
FROM pg_stat_user_tables 
ORDER BY schemaname, relname;

-- 6. Relaciones más pesadas en disco
SELECT 
    schemaname, 
    relname, 
    pg_size_pretty(pg_total_relation_size(relid)) AS tamano_total, 
    pg_total_relation_size(relid) AS bytes 
FROM pg_stat_user_tables 
ORDER BY pg_total_relation_size(relid) DESC;

-- 7. Consultas activas de larga duración (excluye la propia sesión)
SELECT 
    pid, 
    usename, 
    application_name, 
    state, 
    clock_timestamp() - query_start AS duracion, 
    wait_event_type, 
    wait_event 
FROM pg_stat_activity 
WHERE datname = current_database() 
  AND state = 'active' 
  AND pid <> pg_backend_pid() 
ORDER BY query_start;

-- 8. Parámetros de configuración de autovacuum
SELECT 
    name, 
    setting, 
    unit, 
    source 
FROM pg_settings 
WHERE name IN (
    'autovacuum', 
    'track_counts', 
    'autovacuum_analyze_threshold', 
    'autovacuum_analyze_scale_factor', 
    'autovacuum_vacuum_threshold', 
    'autovacuum_vacuum_scale_factor', 
    'autovacuum_naptime', 
    'autovacuum_max_workers'
) 
ORDER BY name;

-- 9. Opciones personalizadas de almacenamiento por relación
SELECT 
    n.nspname AS esquema, 
    c.relname AS tabla, 
    c.reloptions AS opciones_especificas 
FROM pg_class c 
JOIN pg_namespace n ON n.oid = c.relnamespace 
WHERE c.relkind IN ('r', 'p') 
  AND n.nspname NOT IN ('pg_catalog', 'information_schema') 
ORDER BY 1, 2;

ROLLBACK;
