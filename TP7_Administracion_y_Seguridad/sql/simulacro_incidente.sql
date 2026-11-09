-- ============================================================================
-- TP7 — Parte C: Laboratorio de Simulacro de Incidente de Seguridad
-- Proyecto: Food Store — Base de Datos II (UTN FRM)
-- Alumno: Máximo Juan Cruz Quiroga (maximoj.quiroga@alumnos.frm.utn.edu.ar)
-- Docente: Sergio Neira
-- Motor: PostgreSQL 16+ (compatible con PostgreSQL 17)
-- ============================================================================
-- SECUENCIA SIMULADA:
--   1. Múltiples intentos fallidos de autenticación contra fn_autenticar (fuerza bruta).
--   2. Un inicio de sesión exitoso con cuenta legítima.
--   3. Lectura masiva de datos autorizados de usuarios.
--   4. Intento de escalamiento de privilegios (asignar admin_datos a app_web),
--      el cual DEBE SER RECHAZADO por el motor con SQLSTATE 42501 (privilegios insuficientes).
--   5. Toda la prueba se ejecuta en transacción con ROLLBACK final para no persistir cambios.
-- ============================================================================

\set ON_ERROR_STOP on

BEGIN;

SET LOCAL search_path TO public, pg_temp;

-- §0. Comprobación de prerrequisitos de laboratorio
DO $$
BEGIN
  IF to_regprocedure('public.fn_autenticar(varchar,varchar)') IS NULL THEN
    RAISE EXCEPTION 'Prerrequisito ausente: función fn_autenticar no encontrada.';
  END IF;
  IF to_regclass('public.usuarios') IS NULL THEN
    RAISE EXCEPTION 'Prerrequisito ausente: tabla public.usuarios no encontrada.';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'app_web') THEN
    RAISE EXCEPTION 'Prerrequisito ausente: rol app_web no encontrado.';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'admin_datos') THEN
    RAISE EXCEPTION 'Prerrequisito ausente: rol admin_datos no encontrado.';
  END IF;
END
$$;

-- Marca de inicio para delimitación en el log del motor
SELECT 'SIMULACRO_INCIDENTE_INICIO_C' AS marca, clock_timestamp() AS ts;

-- §1. Tres intentos fallidos de inicio de sesión con contraseñas erróneas
DO $$
DECLARE
  v_res BIGINT;
BEGIN
  -- Intento 1
  SELECT public.fn_autenticar('admin@foodstore.utn.edu.ar', 'password123') INTO v_res;
  IF v_res IS NOT NULL THEN RAISE EXCEPTION 'Fallo en la prueba: se esperaba NULL'; END IF;
  RAISE LOG 'SIMULACRO C: Intento 1 fallido para admin@foodstore.utn.edu.ar (resultado=NULL)';

  -- Intento 2
  SELECT public.fn_autenticar('admin@foodstore.utn.edu.ar', 'admin2026') INTO v_res;
  IF v_res IS NOT NULL THEN RAISE EXCEPTION 'Fallo en la prueba: se esperaba NULL'; END IF;
  RAISE LOG 'SIMULACRO C: Intento 2 fallido para admin@foodstore.utn.edu.ar (resultado=NULL)';

  -- Intento 3
  SELECT public.fn_autenticar('admin@foodstore.utn.edu.ar', 'secreto1234') INTO v_res;
  IF v_res IS NOT NULL THEN RAISE EXCEPTION 'Fallo en la prueba: se esperaba NULL'; END IF;
  RAISE LOG 'SIMULACRO C: Intento 3 fallido para admin@foodstore.utn.edu.ar (resultado=NULL)';
END
$$;

-- §2. Un intento exitoso simulado con usuario activo
DO $$
DECLARE
  v_uid BIGINT;
  v_email TEXT;
BEGIN
  SELECT id_usuario, correo_electronico INTO v_uid, v_email
  FROM public.usuarios
  WHERE activo = TRUE
  ORDER BY id_usuario
  LIMIT 1;

  IF v_uid IS NOT NULL THEN
    RAISE LOG 'SIMULACRO C: Autenticación exitosa confirmada para usuario ID=% (%)', v_uid, v_email;
    RAISE NOTICE 'SIMULACRO C: Login exitoso para ID=%', v_uid;
  END IF;
END
$$;

-- §3. Lectura masiva de columnas autorizadas sobre usuarios
DO $$
DECLARE
  v_cant INTEGER;
BEGIN
  SELECT count(*) INTO v_cant
  FROM public.usuarios
  WHERE activo = TRUE;

  RAISE LOG 'SIMULACRO C: Lectura masiva realizada sobre % registros de usuarios', v_cant;
  RAISE NOTICE 'SIMULACRO C: Registros consultados: %', v_cant;
END
$$;

-- §4. Intento de escalamiento de privilegios: otorgar admin_datos a app_web
-- Debe fallar con SQLSTATE 42501 (insufficient_privilege)
DO $$
BEGIN
  BEGIN
    SET LOCAL ROLE app_web;
    GRANT admin_datos TO app_web;
    RESET ROLE;
    -- Si la línea anterior tiene éxito, significa que hay un fallo crítico de seguridad
    RAISE EXCEPTION 'HALLAZGO CRÍTICO: El escalamiento tuvo éxito. El modelo de seguridad falló.';
  EXCEPTION
    WHEN insufficient_privilege THEN
      RESET ROLE;
      RAISE LOG 'SIMULACRO C: Escalamiento RECHAZADO satisfactoriamente (SQLSTATE 42501: privilegios insuficientes)';
      RAISE NOTICE 'SIMULACRO C: Escalamiento bloqueado por el motor (42501).';
  END;
END
$$;

-- Marca de fin en el log
SELECT 'SIMULACRO_INCIDENTE_FIN_C' AS marca, clock_timestamp() AS ts;

ROLLBACK;
