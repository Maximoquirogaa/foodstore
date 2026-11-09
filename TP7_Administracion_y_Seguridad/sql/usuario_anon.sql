-- ============================================================================
-- TP7 — Parte D: Protección de Datos Personales, Anonimización y Equivalencia
-- Proyecto: Food Store — Base de Datos II (UTN FRM)
-- Alumno: Máximo Juan Cruz Quiroga (maximoj.quiroga@alumnos.frm.utn.edu.ar)
-- Docente: Sergio Neira
-- Motor: PostgreSQL 16+ (compatible con PostgreSQL 17)
-- ============================================================================
-- PROPÓSITO:
--   1. Crear una tabla de usuarios anonimizada (usuarios_anon) mediante datos
--      sintéticos deterministas, eliminando todo identificador real (teléfono,
--      apellido real, correo real) y omitiendo por completo la contraseña/hash.
--   2. Preservar atributos de agregación: rol, estado activo y mes de alta (DATE truncado).
--   3. Ejecutar consultas analíticas equivalentes sobre usuarios_anon y usuarios.
--   4. Verificar rigurosamente la equivalencia matemática (EXCEPT ALL en ambas
--      direcciones) para demostrar que la anonimización no distorsiona el análisis.
--   5. Finaliza en ROLLBACK para no persistir tablas temporales de laboratorio.
-- ============================================================================

\set ON_ERROR_STOP on

BEGIN ISOLATION LEVEL REPEATABLE READ;

SET LOCAL search_path TO public, pg_temp;
SET LOCAL TIME ZONE 'America/Argentina/Buenos_Aires';

-- §0. Comprobación de prerrequisitos
DO $$
BEGIN
  IF to_regclass('public.usuarios') IS NULL THEN
    RAISE EXCEPTION 'Prerrequisito ausente: tabla public.usuarios no encontrada.';
  END IF;
  IF to_regclass('public.usuarios_anon') IS NOT NULL THEN
    RAISE EXCEPTION 'Conflicto: la tabla public.usuarios_anon ya existe.';
  END IF;
END
$$;

-- §1. Creación de la estructura anonimizada
CREATE TABLE public.usuarios_anon (
    id_anon BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombre_anon VARCHAR(80) NOT NULL,
    mail_anon VARCHAR(150) NOT NULL UNIQUE,
    rol public.rol_usuario NOT NULL,
    activo BOOLEAN NOT NULL,
    mes_alta DATE NOT NULL
);

COMMENT ON TABLE public.usuarios_anon IS
'Tabla anonimizada para analítica: datos sintéticos deterministas sin información personal sensible.';

-- §2. Población determinista a partir de public.usuarios
INSERT INTO public.usuarios_anon (nombre_anon, mail_anon, rol, activo, mes_alta)
SELECT
    ('UsuarioAnon-' || u.id_usuario),
    ('anon_' || u.id_usuario || '@foodstore-anon.invalid'),
    u.rol,
    u.activo,
    (date_trunc('month', u.fecha_creacion)::date)
FROM public.usuarios AS u
ORDER BY u.id_usuario;

-- §3a. Consulta analítica sobre la tabla anonimizada: distribución por rol y mes de alta
SELECT
    rol,
    mes_alta,
    COUNT(*) AS cantidad
FROM public.usuarios_anon
GROUP BY rol, mes_alta
ORDER BY rol, mes_alta;

-- §3b. Consulta analítica equivalente sobre la tabla real public.usuarios
SELECT
    rol,
    (date_trunc('month', fecha_creacion)::date) AS mes_alta,
    COUNT(*) AS cantidad
FROM public.usuarios
GROUP BY rol, (date_trunc('month', fecha_creacion)::date)
ORDER BY rol, mes_alta;

-- §3c. Comparación lado a lado mediante FULL JOIN
WITH anon AS (
    SELECT rol, mes_alta, COUNT(*) AS cantidad
    FROM public.usuarios_anon
    GROUP BY rol, mes_alta
), real_data AS (
    SELECT rol, (date_trunc('month', fecha_creacion)::date) AS mes_alta, COUNT(*) AS cantidad
    FROM public.usuarios
    GROUP BY rol, (date_trunc('month', fecha_creacion)::date)
)
SELECT
    COALESCE(a.rol, r.rol) AS rol,
    COALESCE(a.mes_alta, r.mes_alta) AS mes_alta,
    a.cantidad AS total_anonimizado,
    r.cantidad AS total_real
FROM anon AS a
FULL OUTER JOIN real_data AS r
  ON a.rol = r.rol AND a.mes_alta = r.mes_alta
ORDER BY rol, mes_alta;

-- §4. Verificación rigurosa de equivalencia matemática (abortar ante cualquier discrepancia)
DO $$
DECLARE
  v_diff_anon_menos_real INT;
  v_diff_real_menos_anon INT;
  v_tot_anon INT;
  v_tot_real INT;
BEGIN
  -- Comprobar si hay filas en anon que no estén en real con exactamente la misma cantidad
  SELECT count(*) INTO v_diff_anon_menos_real FROM (
    (SELECT rol, mes_alta, COUNT(*) AS cantidad FROM public.usuarios_anon GROUP BY rol, mes_alta)
    EXCEPT ALL
    (SELECT rol, (date_trunc('month', fecha_creacion)::date) AS mes_alta, COUNT(*) AS cantidad FROM public.usuarios GROUP BY rol, (date_trunc('month', fecha_creacion)::date))
  ) AS d1;

  -- Comprobar si hay filas en real que no estén en anon
  SELECT count(*) INTO v_diff_real_menos_anon FROM (
    (SELECT rol, (date_trunc('month', fecha_creacion)::date) AS mes_alta, COUNT(*) AS cantidad FROM public.usuarios GROUP BY rol, (date_trunc('month', fecha_creacion)::date))
    EXCEPT ALL
    (SELECT rol, mes_alta, COUNT(*) AS cantidad FROM public.usuarios_anon GROUP BY rol, mes_alta)
  ) AS d2;

  SELECT count(*) INTO v_tot_anon FROM public.usuarios_anon;
  SELECT count(*) INTO v_tot_real FROM public.usuarios;

  IF v_diff_anon_menos_real <> 0 OR v_diff_real_menos_anon <> 0 OR v_tot_anon <> v_tot_real THEN
    RAISE EXCEPTION 'FALLO DE EQUIVALENCIA: diferencias detectadas entre datos reales y anonimizados.';
  END IF;

  RAISE NOTICE 'EQUIVALENCIA MATEMÁTICA DEMOSTRADA: % filas totales analizadas sin discrepancias.', v_tot_real;
END
$$;

ROLLBACK;
