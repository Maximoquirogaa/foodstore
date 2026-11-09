-- ============================================================================
-- TP7 — Parte B / C: Activación de Auditoría Nativa a Nivel Motor
-- Proyecto: Food Store — Base de Datos II (UTN FRM)
-- Alumno: Máximo Juan Cruz Quiroga (maximoj.quiroga@alumnos.frm.utn.edu.ar)
-- Docente: Sergio Neira
-- Motor: PostgreSQL 16+ (compatible con PostgreSQL 17)
-- ============================================================================
-- PROPÓSITO:
--   Activa los parámetros de auditoría nativa mediante ALTER SYSTEM + pg_reload_conf()
--   sin requerir reinicio del servicio (contexto SIGHUP, con logging_collector = on).
--
-- PARÁMETROS CONFIGURADOS:
--   - log_connections = 'on'
--   - log_disconnections = 'on'
--   - log_statement = 'all'
--   - log_line_prefix = '%m [%p] %u@%d %r %a '
-- ============================================================================

\set ON_ERROR_STOP on

-- §0. Guardas previas de entorno
DO $$
BEGIN
  IF current_database() <> 'foodstore_dev' THEN
    RAISE EXCEPTION 'Abortado: base actual=% (se esperaba foodstore_dev)', current_database();
  END IF;
  IF current_setting('logging_collector') <> 'on' THEN
    RAISE EXCEPTION 'logging_collector=%: se requiere on sin reinicio.', current_setting('logging_collector');
  END IF;
END
$$;

-- §1. Activación a nivel instancia (postgresql.auto.conf)
ALTER SYSTEM SET log_connections = 'on';
ALTER SYSTEM SET log_disconnections = 'on';
ALTER SYSTEM SET log_statement = 'all';
ALTER SYSTEM SET log_line_prefix = '%m [%p] %u@%d %r %a ';

-- §2. Recarga en caliente sin reinicio
SELECT pg_reload_conf() AS recarga_ok;

-- §3. Comprobación posterior desde una conexión nueva
\c foodstore_dev
SHOW log_connections;
SHOW log_disconnections;
SHOW log_statement;
SHOW log_line_prefix;
SELECT name, setting, unit, context, source, sourcefile
FROM pg_settings
WHERE name IN ('log_connections','log_disconnections','log_statement','log_line_prefix','logging_collector')
ORDER BY name;
SELECT pg_current_logfile() AS log_activo;
