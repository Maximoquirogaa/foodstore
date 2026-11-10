-- ============================================================================
-- views.sql — Punto de entrada para las Partes B y C (Vistas y Seguridad)
-- Proyecto: Food Store (UTN FRM - Base de Datos II)
-- Alumno: Máximo Juan Cruz Quiroga
-- Docente: Sergio Neira
-- Motor: PostgreSQL 17
-- ============================================================================
-- Carga en el orden riguroso de dependencias:
--   1. Parte_B_Vistas/usuarios.sql          (Tabla de usuarios y enum de roles)
--   2. Parte_B_Vistas/usuarios_datos.sql    (Semilla de usuarios de prueba)
--   3. Parte_B_Vistas/vistas.sql            (Las 5 vistas analíticas y seguras)
--   4. Parte_C_Vista_Materializada/vista_materializada.sql (MV y UNIQUE INDEX)
--   5. Parte_B_Vistas/seguridad_roles.sql   (Rol TP5_reportes con acceso exclusivo a vistas)
-- ============================================================================

\ir Parte_B_Vistas/usuarios.sql
\ir Parte_B_Vistas/usuarios_datos.sql
\ir Parte_B_Vistas/vistas.sql
\ir Parte_C_Vista_Materializada/vista_materializada.sql
\ir Parte_B_Vistas/seguridad_roles.sql

