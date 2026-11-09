-- ============================================================================
-- TP6 — Parte 1: Normalización en Forma Normal de Boyce-Codd (FNBC)
-- Control de Lotes y Depósitos en Food Store
-- Proyecto: Food Store (UTN FRM - Base de Datos II)
-- Alumno: Máximo Juan Cruz Quiroga
-- Docente: Sergio Neira
-- Motor: PostgreSQL 17
-- Script de validación en transacción reversible (ROLLBACK final)
-- ============================================================================

\set ON_ERROR_STOP on

BEGIN;

-- ============================================================
-- 1. Comprobaciones previas de seguridad y consistencia
-- ============================================================
DO $$
DECLARE
    v_nombre TEXT;
    v_usuario_oid OID;
BEGIN
    -- Comprobamos existencia de la tabla usuarios (de TP7 / TP5)
    SELECT c.oid
      INTO v_usuario_oid
      FROM pg_catalog.pg_class AS c
      JOIN pg_catalog.pg_namespace AS n ON n.oid = c.relnamespace
     WHERE n.nspname = 'public'
       AND c.relname = 'usuarios'
       AND c.relkind IN ('r', 'p');

    IF v_usuario_oid IS NULL THEN
        RAISE EXCEPTION 'No existe la tabla public.usuarios. Revisar esquema antes de continuar.';
    END IF;

    -- Verificar que no existan objetos previos con nombres que utilizaremos
    SELECT c.relname
      INTO v_nombre
      FROM pg_catalog.pg_class AS c
      JOIN pg_catalog.pg_namespace AS n ON n.oid = c.relnamespace
     WHERE n.nspname = 'public'
       AND c.relname IN (
           'lotes',
           'depositos',
           'control_lote_almacen',
           'responsable_deposito',
           'control_lote',
           'v_control_lote_almacen'
       )
     ORDER BY c.relname
     LIMIT 1;

    IF v_nombre IS NOT NULL THEN
        RAISE EXCEPTION 'Ya existe el objeto public.%. Se detiene la prueba para evitar colisiones.', v_nombre;
    END IF;
END;
$$;

-- Bloqueo preventivo sobre usuarios durante la prueba
LOCK TABLE public.usuarios IN SHARE ROW EXCLUSIVE MODE NOWAIT;

-- ============================================================
-- 2. Comprobar que no haya conflictos con IDs de prueba
-- ============================================================
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM public.usuarios WHERE id_usuario IN (801, 802)) THEN
        RAISE EXCEPTION 'Conflicto: ya existen usuarios con IDs 801 o 802 en usuarios.';
    END IF;
END;
$$;

-- ============================================================
-- 3. Tablas maestras mínimas y relación original no-FNBC
-- ============================================================
-- Relación de negocio: R(lote_id, deposito_id, responsable_control_id)
-- Dependencias funcionales del dominio:
--   1) (lote_id, deposito_id) -> responsable_control_id
--   2) responsable_control_id -> deposito_id
-- Claves candidatas: (lote_id, deposito_id) y (lote_id, responsable_control_id).
-- Cumple 3FN (todos los atributos son primos), pero VIOLA FNBC porque en la
-- dependencia responsable_control_id -> deposito_id, el determinante no es superclave.

CREATE TABLE public.lotes (
    id_lote BIGINT PRIMARY KEY
);

CREATE TABLE public.depositos (
    id_deposito BIGINT PRIMARY KEY
);

CREATE TABLE public.control_lote_almacen (
    id_lote BIGINT NOT NULL,
    id_deposito BIGINT NOT NULL,
    id_responsable_control BIGINT NOT NULL,

    CONSTRAINT pk_control_lote_almacen
        PRIMARY KEY (id_lote, id_deposito),

    CONSTRAINT fk_cla_lote
        FOREIGN KEY (id_lote)
        REFERENCES public.lotes (id_lote)
        ON DELETE RESTRICT,

    CONSTRAINT fk_cla_deposito
        FOREIGN KEY (id_deposito)
        REFERENCES public.depositos (id_deposito)
        ON DELETE RESTRICT,

    CONSTRAINT fk_cla_responsable
        FOREIGN KEY (id_responsable_control)
        REFERENCES public.usuarios (id_usuario)
        ON DELETE RESTRICT
);

-- ============================================================
-- 4. Inserción de datos maestros y usuarios de prueba
-- ============================================================
INSERT INTO public.lotes (id_lote) VALUES (501), (502), (503);
INSERT INTO public.depositos (id_deposito) VALUES (30), (31);

INSERT INTO public.usuarios (
    id_usuario,
    nombre,
    apellido,
    correo_electronico,
    telefono,
    contrasena,
    rol,
    activo
)
OVERRIDING SYSTEM VALUE
VALUES
(801, 'Responsable', 'Prueba801', 'responsable801.fnbc@utn.edu.ar', NULL, 'HASH_PRUEBA_801', 'USUARIO', TRUE),
(802, 'Responsable', 'Prueba802', 'responsable802.fnbc@utn.edu.ar', NULL, 'HASH_PRUEBA_802', 'USUARIO', TRUE);

-- ============================================================
-- 5. Carga de instancia original (Demostración de redundancia)
-- ============================================================
INSERT INTO public.control_lote_almacen (id_lote, id_deposito, id_responsable_control)
VALUES
    (501, 30, 801),
    (502, 30, 801), -- El responsable 801 repite su asociación al depósito 30
    (503, 31, 802);

-- ============================================================
-- 6. Validación de la dependencia funcional antes de descomponer
-- ============================================================
DO $$
BEGIN
    IF EXISTS (
        SELECT id_responsable_control
          FROM public.control_lote_almacen
         GROUP BY id_responsable_control
        HAVING COUNT(DISTINCT id_deposito) > 1
    ) THEN
        RAISE EXCEPTION 'La relación original viola id_responsable_control -> id_deposito.';
    END IF;
END;
$$;

-- ============================================================
-- 7. Descomposición en Forma Normal de Boyce-Codd (FNBC)
-- ============================================================
-- R1: responsable_deposito (id_responsable_control, id_deposito) [PK: id_responsable_control]
-- R2: control_lote (id_lote, id_responsable_control) [PK: (id_lote, id_responsable_control)]

CREATE TABLE public.responsable_deposito (
    id_responsable_control BIGINT NOT NULL,
    id_deposito BIGINT NOT NULL,

    CONSTRAINT pk_responsable_deposito
        PRIMARY KEY (id_responsable_control),

    CONSTRAINT fk_rd_responsable
        FOREIGN KEY (id_responsable_control)
        REFERENCES public.usuarios (id_usuario)
        ON DELETE RESTRICT,

    CONSTRAINT fk_rd_deposito
        FOREIGN KEY (id_deposito)
        REFERENCES public.depositos (id_deposito)
        ON DELETE RESTRICT
);

CREATE TABLE public.control_lote (
    id_lote BIGINT NOT NULL,
    id_responsable_control BIGINT NOT NULL,

    CONSTRAINT pk_control_lote
        PRIMARY KEY (id_lote, id_responsable_control),

    CONSTRAINT fk_cl_lote
        FOREIGN KEY (id_lote)
        REFERENCES public.lotes (id_lote)
        ON DELETE RESTRICT,

    CONSTRAINT fk_cl_responsable_deposito
        FOREIGN KEY (id_responsable_control)
        REFERENCES public.responsable_deposito (id_responsable_control)
        ON DELETE RESTRICT
);

-- ============================================================
-- 8. Migración sin pérdida de información
-- ============================================================
INSERT INTO public.responsable_deposito (id_responsable_control, id_deposito)
SELECT DISTINCT id_responsable_control, id_deposito
FROM public.control_lote_almacen;

INSERT INTO public.control_lote (id_lote, id_responsable_control)
SELECT DISTINCT id_lote, id_responsable_control
FROM public.control_lote_almacen;

-- ============================================================
-- 9. Vista de reconstrucción y prueba formal de equivalencia
-- ============================================================
CREATE VIEW public.v_control_lote_almacen AS
SELECT
    cl.id_lote,
    rd.id_deposito,
    cl.id_responsable_control
FROM public.control_lote cl
JOIN public.responsable_deposito rd
  ON rd.id_responsable_control = cl.id_responsable_control;

-- Comprobación con EXCEPT bidireccional (Reunión sin pérdida)
DO $$
DECLARE
    v_diff INTEGER;
BEGIN
    SELECT COUNT(*) INTO v_diff
    FROM (
        (SELECT id_lote, id_deposito, id_responsable_control FROM public.control_lote_almacen
         EXCEPT
         SELECT id_lote, id_deposito, id_responsable_control FROM public.v_control_lote_almacen)
        UNION ALL
        (SELECT id_lote, id_deposito, id_responsable_control FROM public.v_control_lote_almacen
         EXCEPT
         SELECT id_lote, id_deposito, id_responsable_control FROM public.control_lote_almacen)
    ) t;

    IF v_diff <> 0 THEN
        RAISE EXCEPTION 'La descomposición sufrió pérdida de información. Diferencias: %', v_diff;
    ELSE
        RAISE NOTICE 'VALIDACIÓN EXITOSA: Descomposición en FNBC con reunión sin pérdida confirmada (0 filas de diferencia).';
    END IF;
END;
$$;

-- Protocolo de reversibilidad estricto
ROLLBACK;

