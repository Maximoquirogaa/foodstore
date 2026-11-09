-- ============================================================================
-- TP7 — Función de Autenticación de Usuarios (fn_autenticar)
-- Proyecto: Food Store — Base de Datos II (UTN FRM)
-- Alumno: Máximo Juan Cruz Quiroga (maximoj.quiroga@alumnos.frm.utn.edu.ar)
-- Docente: Sergio Neira
-- Motor: PostgreSQL 16+ (compatible con PostgreSQL 17)
-- ============================================================================
-- PROPÓSITO:
--   Autentica credenciales contra la tabla canónica public.usuarios usando la
--   extensión pgcrypto (crypt/bcrypt).
--   Devuelve el id_usuario si la autenticación es válida y el usuario está activo.
--   Devuelve NULL en caso de credenciales incorrectas, cuenta inexistente o inactiva.
--   Aplica SECURITY DEFINER y endurecimiento del search_path.
-- ============================================================================

CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE OR REPLACE FUNCTION public.fn_autenticar(
    p_email    VARCHAR,
    p_password VARCHAR
)
RETURNS BIGINT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, pg_temp
AS $func$
DECLARE
    v_id BIGINT;
BEGIN
    -- Validar parámetros de entrada
    IF p_email IS NULL OR p_password IS NULL
       OR pg_catalog.btrim(p_email) = '' OR pg_catalog.btrim(p_password) = '' THEN
        RETURN NULL;
    END IF;

    -- Verificar credenciales contra public.usuarios respetando baja lógica (activo = TRUE)
    SELECT u.id_usuario INTO v_id
    FROM public.usuarios AS u
    WHERE lower(u.correo_electronico) = lower(pg_catalog.btrim(p_email))
      AND u.activo = TRUE
      AND u.contrasena = public.crypt(p_password::text, u.contrasena::text)
    LIMIT 1;

    IF FOUND THEN
        RETURN v_id;
    END IF;

    RETURN NULL;
END;
$func$;

COMMENT ON FUNCTION public.fn_autenticar(VARCHAR, VARCHAR) IS
'Autentica credenciales contra public.usuarios(correo_electronico, contrasena). '
'Devuelve id_usuario activo o NULL. Definida con SECURITY DEFINER.';

-- Mínimo privilegio: revocar acceso a PUBLIC (se otorga vía roles.sql a rol_app_escritura y admin_datos)
REVOKE ALL ON FUNCTION public.fn_autenticar(VARCHAR, VARCHAR) FROM PUBLIC;
