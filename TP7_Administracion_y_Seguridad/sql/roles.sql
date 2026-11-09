-- ============================================================================
-- TP7 — Administración y Seguridad: Modelo Canónico de Roles PostgreSQL
-- Proyecto: Food Store — Base de Datos II (UTN FRM)
-- Alumno: Máximo Juan Cruz Quiroga (maximoj.quiroga@alumnos.frm.utn.edu.ar)
-- Docente: Sergio Neira
-- Motor: PostgreSQL 16+ (compatible con PostgreSQL 17)
-- Base de destino: foodstore_dev / foodstore
-- Especificación Kiro:
--   docs/kiro_roles_spec/requirements.md
--   docs/kiro_roles_spec/design.md
-- ============================================================================
-- PROPÓSITO:
--   Implementa la política de roles de grupo (NOLOGIN) y roles de login (LOGIN)
--   con mínimo privilegio, sin otorgar permisos excesivos (sin GRANT ALL en roles operativos).
--
-- PRERREQUISITOS (orden de ejecución):
--   1. schema.sql (TP2/TP5) + usuarios.sql (TP5 Parte_B_Vistas/usuarios.sql)
--   2. vistas.sql (TP5) + vista_materializada.sql (TP5 Parte_C)
--   3. fn_autenticar y fn_resetear_password (TP7 Clase 2 / sql/).
--
-- ESQUEMA CANÓNICO RELACIONAL DE FOOD STORE (UTN FRM):
--   - Tablas: categorias, clientes, productos, pedidos, detalles_pedido, usuarios
--   - Columna sensible: usuarios.contrasena (hash bcrypt/argon2, nunca texto plano)
--   - Secuencias identity: categorias_id_categoria_seq, clientes_id_cliente_seq,
--                          productos_id_producto_seq, pedidos_id_pedido_seq,
--                          usuarios_id_usuario_seq
--
-- IDEMPOTENCIA:
--   - DO ... EXCEPTION WHEN duplicate_object THEN NULL para creación de roles.
--   - REVOKE / GRANT / ALTER DEFAULT PRIVILEGES son re-ejecutables sin error.
-- ============================================================================

-- ============================================================================
-- SECCIÓN 0 — Comprobación de seguridad de entorno
-- ============================================================================
DO $$
BEGIN
    -- Informar entorno de ejecución
    RAISE NOTICE 'Aplicando modelo de roles TP7 Food Store en base: %', current_database();
END
$$;

-- ============================================================================
-- SECCIÓN 1 — Revocación de permisos inseguros por defecto
-- ============================================================================
-- 1a. Revocaciones exigidas sobre el esquema público:
REVOKE ALL ON SCHEMA public FROM PUBLIC;
REVOKE ALL ON ALL TABLES IN SCHEMA public FROM PUBLIC;

-- 1b. Endurecimiento complementario sobre secuencias y funciones:
REVOKE ALL ON ALL SEQUENCES IN SCHEMA public FROM PUBLIC;
REVOKE ALL ON ALL FUNCTIONS IN SCHEMA public FROM PUBLIC;

-- 1c. Revocación explícita sobre tablas base de Food Store (defensa en profundidad):
DO $$
BEGIN
    IF to_regclass('public.usuarios') IS NOT NULL THEN
        EXECUTE 'REVOKE ALL ON TABLE categorias, clientes, productos, pedidos, detalles_pedido, usuarios FROM PUBLIC';
    END IF;
EXCEPTION WHEN OTHERS THEN NULL;
END $$;

-- ============================================================================
-- SECCIÓN 2 — Creación idempotente de roles
-- ============================================================================
-- 2A. Roles de grupo (NOLOGIN)
DO $$ BEGIN CREATE ROLE rol_app_lectura   NOLOGIN; EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN CREATE ROLE rol_app_escritura  NOLOGIN; EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN CREATE ROLE rol_soporte       NOLOGIN; EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN CREATE ROLE rol_reportes      NOLOGIN; EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN CREATE ROLE rol_auditoria     NOLOGIN; EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- 2B. Roles de conexión / aplicación (LOGIN)
-- Se definen con PASSWORD NULL para gestión externa segura (Vault / variables de entorno)
DO $$ BEGIN
    CREATE ROLE app_web LOGIN PASSWORD NULL CONNECTION LIMIT 20;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
    CREATE ROLE admin_datos LOGIN PASSWORD NULL CONNECTION LIMIT 5;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- ============================================================================
-- SECCIÓN 3 — Permisos de Schema (Namespace)
-- ============================================================================
GRANT USAGE ON SCHEMA public TO
    rol_app_lectura, rol_app_escritura, rol_soporte,
    rol_reportes, rol_auditoria, app_web, admin_datos;

-- DDL controlado: únicamente admin_datos puede crear nuevos objetos en public
GRANT CREATE ON SCHEMA public TO admin_datos;

-- ============================================================================
-- SECCIÓN 4 — Permisos a nivel de tabla (Mínimo Privilegio - RF-01)
-- ============================================================================
-- 4a. rol_app_lectura: solo SELECT sobre catálogo transaccional
DO $$
BEGIN
    IF to_regclass('public.pedidos') IS NOT NULL THEN
        EXECUTE 'GRANT SELECT ON TABLE categorias, clientes, productos, pedidos, detalles_pedido TO rol_app_lectura';
    END IF;
END $$;

-- 4b. rol_app_escritura: INSERT y UPDATE para transacciones comerciales.
-- IMPORTANTE: No se concede DELETE bajo el modelo de auditoría y baja lógica (R7).
DO $$
BEGIN
    IF to_regclass('public.pedidos') IS NOT NULL THEN
        EXECUTE 'GRANT INSERT, UPDATE ON TABLE clientes, pedidos, detalles_pedido TO rol_app_escritura';
        EXECUTE 'GRANT INSERT, UPDATE ON TABLE categorias, productos TO rol_app_escritura';
    END IF;
END $$;

-- 4c. admin_datos: administración completa sobre tablas canónicas
DO $$
BEGIN
    IF to_regclass('public.usuarios') IS NOT NULL THEN
        EXECUTE 'GRANT ALL ON TABLE categorias, clientes, productos, pedidos, detalles_pedido, usuarios TO admin_datos';
    END IF;
END $$;

-- ============================================================================
-- SECCIÓN 5 — Permisos a nivel de columna sobre usuarios (RF-03)
-- rol_soporte NUNCA recibe acceso a la contraseña/hash (contrasena).
-- Solo columnas de soporte operativo + UPDATE(activo) para baja lógica.
-- ============================================================================
DO $$
BEGIN
    IF to_regclass('public.usuarios') IS NOT NULL THEN
        EXECUTE 'REVOKE ALL ON TABLE public.usuarios FROM rol_soporte';
        EXECUTE 'GRANT SELECT (id_usuario, nombre, apellido, correo_electronico, telefono, rol, activo, fecha_creacion)
                 ON TABLE public.usuarios TO rol_soporte';
        EXECUTE 'GRANT UPDATE (activo) ON TABLE public.usuarios TO rol_soporte';
    END IF;
END $$;

-- ============================================================================
-- SECCIÓN 6 — Permisos sobre secuencias (GENERATED ALWAYS AS IDENTITY - RF-04)
-- ============================================================================
DO $$
DECLARE
    seq_name text;
BEGIN
    -- Otorgar secuencias de escritura a rol_app_escritura (excluyendo usuarios_id_usuario_seq)
    FOR seq_name IN
        SELECT sequence_name FROM information_schema.sequences
        WHERE sequence_schema = 'public'
          AND sequence_name NOT LIKE '%usuario%'
    LOOP
        EXECUTE format('GRANT USAGE, SELECT ON SEQUENCE public.%I TO rol_app_escritura', seq_name);
    END LOOP;

    -- Otorgar todas las secuencias a admin_datos
    FOR seq_name IN
        SELECT sequence_name FROM information_schema.sequences
        WHERE sequence_schema = 'public'
    LOOP
        EXECUTE format('GRANT ALL ON SEQUENCE public.%I TO admin_datos', seq_name);
    END LOOP;
END $$;

-- ============================================================================
-- SECCIÓN 7 — Permisos sobre vistas analíticas y materializadas (RF-02)
-- ============================================================================
DO $$
BEGIN
    -- Vistas operativas para rol_app_lectura
    IF to_regclass('public.v_catalogo_productos') IS NOT NULL THEN
        EXECUTE 'GRANT SELECT ON v_catalogo_productos, v_pedido_cliente, v_detalle_pedido_producto TO rol_app_lectura';
    END IF;

    -- Vistas de análisis y reporte seguro para rol_reportes
    -- (v_usuario_publico excluye la contraseña por definición)
    IF to_regclass('public.v_reporte_ventas_cliente') IS NOT NULL THEN
        EXECUTE 'GRANT SELECT ON v_reporte_ventas_cliente, v_usuario_publico TO rol_reportes';
    END IF;
    IF to_regclass('public.mv_resumen_ventas_categoria_mes') IS NOT NULL THEN
        EXECUTE 'GRANT SELECT ON mv_resumen_ventas_categoria_mes TO rol_reportes';
    END IF;

    -- Administración integral de vistas para admin_datos
    IF to_regclass('public.v_usuario_publico') IS NOT NULL THEN
        EXECUTE 'GRANT ALL ON v_usuario_publico, v_reporte_ventas_cliente, v_catalogo_productos, v_detalle_pedido_producto, v_pedido_cliente TO admin_datos';
    END IF;
    IF to_regclass('public.mv_resumen_ventas_categoria_mes') IS NOT NULL THEN
        EXECUTE 'GRANT ALL ON mv_resumen_ventas_categoria_mes TO admin_datos';
    END IF;
END $$;

-- ============================================================================
-- SECCIÓN 8 — Permisos de ejecución de funciones de seguridad (RF-05)
-- ============================================================================
DO $$
BEGIN
    IF to_regprocedure('public.fn_autenticar(varchar,varchar)') IS NOT NULL THEN
        EXECUTE 'REVOKE ALL ON FUNCTION public.fn_autenticar(varchar,varchar) FROM PUBLIC';
        EXECUTE 'GRANT EXECUTE ON FUNCTION public.fn_autenticar(varchar,varchar) TO rol_app_escritura, admin_datos';
    END IF;

    IF to_regprocedure('public.fn_resetear_password(bigint,varchar)') IS NOT NULL THEN
        EXECUTE 'REVOKE ALL ON FUNCTION public.fn_resetear_password(bigint,varchar) FROM PUBLIC';
        EXECUTE 'GRANT EXECUTE ON FUNCTION public.fn_resetear_password(bigint,varchar) TO rol_soporte, admin_datos';
    END IF;
END $$;

-- ============================================================================
-- SECCIÓN 9 — Permisos de monitoreo y auditoría (RF-06)
-- rol_auditoria recibe el rol del sistema pg_monitor para supervisión,
-- sin acceso a información sensible de credenciales ni catálogos privados.
-- ============================================================================
GRANT pg_monitor TO rol_auditoria;

-- ============================================================================
-- SECCIÓN 10 — Privilegios por defecto en esquema público (RF-07)
-- ============================================================================
ALTER DEFAULT PRIVILEGES IN SCHEMA public
    GRANT INSERT, UPDATE ON TABLES TO rol_app_escritura;

ALTER DEFAULT PRIVILEGES IN SCHEMA public
    GRANT SELECT ON TABLES TO rol_app_lectura;

ALTER DEFAULT PRIVILEGES IN SCHEMA public
    GRANT USAGE, SELECT ON SEQUENCES TO rol_app_escritura;

-- Para objetos creados bajo admin_datos:
ALTER DEFAULT PRIVILEGES FOR ROLE admin_datos IN SCHEMA public
    GRANT INSERT, UPDATE ON TABLES TO rol_app_escritura;

ALTER DEFAULT PRIVILEGES FOR ROLE admin_datos IN SCHEMA public
    GRANT SELECT ON TABLES TO rol_app_lectura;

ALTER DEFAULT PRIVILEGES FOR ROLE admin_datos IN SCHEMA public
    GRANT USAGE, SELECT ON SEQUENCES TO rol_app_escritura;

-- ============================================================================
-- SECCIÓN 11 — Asignación de membresías a roles de conexión
-- app_web hereda lectura y escritura de negocio
-- ============================================================================
GRANT rol_app_lectura   TO app_web;
GRANT rol_app_escritura TO app_web;

-- ============================================================================
-- SECCIÓN 12 — Consultas de verificación recomendadas
-- ============================================================================
-- SELECT grantee, table_name, privilege_type
-- FROM information_schema.role_table_grants
-- WHERE grantee IN ('rol_app_lectura','rol_app_escritura','rol_soporte','rol_reportes','rol_auditoria','app_web','admin_datos')
-- ORDER BY grantee, table_name;
--
-- SELECT grantee, column_name, privilege_type
-- FROM information_schema.column_privileges
-- WHERE table_name = 'usuarios' AND grantee = 'rol_soporte';
