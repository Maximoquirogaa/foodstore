-- ============================================================================
-- TP7 — Parte B Punto 2: Secuencia de Operaciones de Prueba para Auditoría
-- Proyecto: Food Store — Base de Datos II (UTN FRM)
-- Alumno: Máximo Juan Cruz Quiroga (maximoj.quiroga@alumnos.frm.utn.edu.ar)
-- Docente: Sergio Neira
-- Motor: PostgreSQL 16+ (compatible con PostgreSQL 17)
-- ============================================================================
-- SECUENCIA DE COMPROBACIÓN:
--   1. Operación de Lectura (SELECT) sobre columnas no sensibles de usuarios.
--   2. Inserción (INSERT) de prueba en la tabla categorias.
--   3. Modificación (UPDATE) sobre ese mismo registro.
--   4. Reversión transaccional completa (ROLLBACK) para no alterar datos productivos.
--   5. Intento fallido de inicio de sesión vía fn_autenticar (devuelve NULL).
-- ============================================================================

-- Marca de inicio del fragmento auditable
SELECT 'AUDITORIA_TEST_INICIO_B2' AS marca, clock_timestamp() AS ts;

-- 1. Lectura: usuarios activos con columnas permitidas (sin exponer contrasena)
SELECT id_usuario, nombre, apellido, correo_electronico, rol
FROM public.usuarios
WHERE activo = TRUE
ORDER BY id_usuario
LIMIT 3;

-- 2 y 3. Inserción y actualización de prueba, encapsuladas en transacción
BEGIN;

INSERT INTO public.categorias (nombre, activo)
VALUES ('AuditoriaTestB2', TRUE)
RETURNING id_categoria;

UPDATE public.categorias
SET nombre = 'AuditoriaTestB2_Modificada'
WHERE nombre = 'AuditoriaTestB2'
RETURNING id_categoria;

ROLLBACK;

-- 4. Inicio de sesión fallido con credencial inválida (retorna NULL)
SELECT public.fn_autenticar('admin@foodstore.utn.edu.ar', 'clave_erronea_test') AS login_fallido;

-- Marca de fin del fragmento auditable
SELECT 'AUDITORIA_TEST_FIN_B2' AS marca, clock_timestamp() AS ts;
