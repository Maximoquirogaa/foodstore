-- ============================================================================
-- TP7 — Parte D (Cobertura Ampliada): Validación de Equivalencia con Fixtures
-- Proyecto: Food Store — Base de Datos II (UTN FRM)
-- Alumno: Máximo Juan Cruz Quiroga (maximoj.quiroga@alumnos.frm.utn.edu.ar)
-- Docente: Sergio Neira
-- Motor: PostgreSQL 16+ (compatible con PostgreSQL 17)
-- ============================================================================

\set ON_ERROR_STOP on
BEGIN ISOLATION LEVEL REPEATABLE READ;
SET LOCAL search_path TO pg_catalog, pg_temp;
SET LOCAL TIME ZONE 'America/Argentina/Buenos_Aires';

DO $$
BEGIN
  IF to_regclass('public.usuarios') IS NULL THEN
    RAISE EXCEPTION 'STOP: falta tabla public.usuarios';
  END IF;
  IF to_regclass('public.usuarios_anon_cobertura_tp7') IS NOT NULL
     OR to_regclass('pg_temp.tp7_d_fixtures') IS NOT NULL THEN
    RAISE EXCEPTION 'STOP: nombre de ensayo ocupado';
  END IF;
END $$;

LOCK TABLE public.usuarios IN SHARE ROW EXCLUSIVE MODE;

CREATE TEMP TABLE tp7_d_fixtures (
  id_usuario bigint PRIMARY KEY,
  nombre varchar(100),
  apellido varchar(100),
  correo_electronico varchar(150),
  telefono varchar(30),
  contrasena varchar(255),
  rol public.rol_usuario,
  activo boolean,
  fecha_creacion timestamptz
) ON COMMIT DROP;

-- Inserción de fixtures sintéticos de prueba
INSERT INTO pg_temp.tp7_d_fixtures
SELECT -770700-n, 'LabD-Cobertura', 'Fixture-' || n,
       'lab_d_cobertura_' || n || '@foodstore-anon.invalid', '+54 261 4000000',
       '!TP7_D_COBERTURA_SIN_LOGIN!', rol::public.rol_usuario, activo, fecha
FROM (VALUES
 (1,'ADMIN',TRUE,TIMESTAMPTZ '2026-01-10 12:00:00-03'),
 (2,'ADMIN',FALSE,TIMESTAMPTZ '2026-01-20 12:00:00-03'),
 (3,'VENDEDOR',TRUE,TIMESTAMPTZ '2026-02-10 12:00:00-03'),
 (4,'VENDEDOR',TRUE,TIMESTAMPTZ '2026-02-20 12:00:00-03'),
 (5,'USUARIO',TRUE,TIMESTAMPTZ '2026-03-10 12:00:00-03'),
 (6,'USUARIO',FALSE,TIMESTAMPTZ '2026-03-20 12:00:00-03')
) AS f(n,rol,activo,fecha);

INSERT INTO public.usuarios
  (id_usuario, nombre, apellido, correo_electronico, telefono, contrasena, rol, activo, fecha_creacion)
OVERRIDING SYSTEM VALUE
SELECT id_usuario, nombre, apellido, correo_electronico, telefono, contrasena, rol, activo, fecha_creacion
FROM pg_temp.tp7_d_fixtures;

CREATE TABLE public.usuarios_anon_cobertura_tp7 AS
SELECT ('LabD-Anon-' || u.id_usuario)::varchar(80) AS nombre_lab,
       ('lab_d_anon_' || u.id_usuario || '@foodstore-anon.invalid')::varchar(150) AS mail_lab,
       u.rol, u.activo, date_trunc('month', u.fecha_creacion)::date AS mes_alta
FROM public.usuarios u WITH NO DATA;

INSERT INTO public.usuarios_anon_cobertura_tp7
SELECT ('LabD-Anon-' || u.id_usuario), ('lab_d_anon_' || u.id_usuario || '@foodstore-anon.invalid'),
       u.rol, u.activo, date_trunc('month', u.fecha_creacion)::date
FROM public.usuarios u ORDER BY u.id_usuario;

SELECT rol, mes_alta, count(*) AS cantidad FROM public.usuarios_anon_cobertura_tp7
GROUP BY rol, mes_alta ORDER BY rol, mes_alta;

SELECT rol, date_trunc('month', fecha_creacion)::date AS mes_alta, count(*) AS cantidad
FROM public.usuarios GROUP BY rol, date_trunc('month', fecha_creacion)::date ORDER BY rol, mes_alta;

DO $$
DECLARE d1 bigint; d2 bigint; na bigint; nr bigint;
BEGIN
 SELECT count(*) INTO d1 FROM (
  (SELECT rol, mes_alta, count(*) FROM public.usuarios_anon_cobertura_tp7 GROUP BY rol, mes_alta)
  EXCEPT ALL
  (SELECT rol, date_trunc('month', fecha_creacion)::date, count(*) FROM public.usuarios
   GROUP BY rol, date_trunc('month', fecha_creacion)::date)) d;

 SELECT count(*) INTO d2 FROM (
  (SELECT rol, date_trunc('month', fecha_creacion)::date, count(*) FROM public.usuarios
   GROUP BY rol, date_trunc('month', fecha_creacion)::date)
  EXCEPT ALL
  (SELECT rol, mes_alta, count(*) FROM public.usuarios_anon_cobertura_tp7 GROUP BY rol, mes_alta)) d;

 SELECT count(*) INTO na FROM public.usuarios_anon_cobertura_tp7;
 SELECT count(*) INTO nr FROM public.usuarios;

 IF d1 <> 0 OR d2 <> 0 OR na <> nr THEN
   RAISE EXCEPTION 'STOP: no equivalencia detectada; diferencias %/%, totales %/%', d1, d2, na, nr;
 END IF;
 RAISE NOTICE 'Comparación con fixtures validada con éxito: diferencias %/%, totales %/%', d1, d2, na, nr;
END $$;

ROLLBACK;
