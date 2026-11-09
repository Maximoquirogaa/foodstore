-- ============================================================================
-- TP7 — Función de Reseteo de Contraseñas (fn_resetear_password)
-- Proyecto: Food Store — Base de Datos II (UTN FRM)
-- Alumno: Máximo Juan Cruz Quiroga (maximoj.quiroga@alumnos.frm.utn.edu.ar)
-- Docente: Sergio Neira
-- Motor: PostgreSQL 16+ (compatible con PostgreSQL 17)
-- ============================================================================
-- PROPÓSITO:
--   Permite al rol de soporte restablecer la contraseña de un usuario activo
--   almacenándola como un hash seguro bcrypt usando pgcrypto.
--   Aplica validación de longitud mínima (≥ 8 caracteres).
--   Devuelve TRUE si se actualizó exactamente una fila; FALSE en caso contrario.
-- ============================================================================

CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE OR REPLACE FUNCTION public.fn_resetear_password(
    p_id_usuario     BIGINT,
    p_nueva_password VARCHAR
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, pg_temp
AS $func$
DECLARE
    v_actualizadas INTEGER;
BEGIN
    -- Validación de parámetros y longitud mínima de seguridad (≥ 8 caracteres)
    IF p_id_usuario IS NULL
       OR p_nueva_password IS NULL
       OR pg_catalog.char_length(pg_catalog.btrim(p_nueva_password)) < 8 THEN
        RETURN FALSE;
    END IF;

    -- Actualización del hash bcrypt sobre la cuenta activa
    UPDATE public.usuarios AS u
    SET contrasena = public.crypt(pg_catalog.btrim(p_nueva_password)::text, public.gen_salt('bf'::text))
    WHERE u.id_usuario = p_id_usuario
      AND u.activo = TRUE;

    GET DIAGNOSTICS v_actualizadas = ROW_COUNT;

    RETURN (v_actualizadas = 1);
END;
$func$;

COMMENT ON FUNCTION public.fn_resetear_password(BIGINT, VARCHAR) IS
'Resetea la contraseña con hash bcrypt para un usuario activo en public.usuarios. '
'Requiere longitud >= 8 caracteres. Devuelve TRUE en caso de éxito. SECURITY DEFINER.';

-- Mínimo privilegio: revocar acceso a PUBLIC (se otorga vía roles.sql a rol_soporte y admin_datos)
REVOKE ALL ON FUNCTION public.fn_resetear_password(BIGINT, VARCHAR) FROM PUBLIC;
