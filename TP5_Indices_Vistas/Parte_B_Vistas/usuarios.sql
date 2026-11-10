-- ============================================================================
-- Parte_B_Vistas/usuarios.sql — Extensión de Seguridad para Usuarios y Roles
-- Compatible con el esquema canónico de Food Store (UTN FRM)
-- ============================================================================

DO $$
BEGIN
    CREATE TYPE rol_usuario AS ENUM ('ADMIN', 'VENDEDOR', 'USUARIO');
EXCEPTION
    WHEN duplicate_object THEN NULL;
END
$$;

CREATE TABLE IF NOT EXISTS usuarios (
    id_usuario BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    apellido VARCHAR(100) NOT NULL,
    correo_electronico VARCHAR(150) NOT NULL UNIQUE,
    telefono VARCHAR(30),
    contrasena VARCHAR(255) NOT NULL, -- Representa el hash criptográfico (bcrypt/argon2), nunca texto plano
    rol rol_usuario NOT NULL DEFAULT 'USUARIO',
    activo BOOLEAN NOT NULL DEFAULT TRUE,
    fecha_creacion TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT chk_usuario_nombre_no_vacio CHECK (trim(nombre) <> ''),
    CONSTRAINT chk_usuario_apellido_no_vacio CHECK (trim(apellido) <> ''),
    CONSTRAINT chk_usuario_email_no_vacio CHECK (trim(correo_electronico) <> ''),
    CONSTRAINT chk_usuario_contrasena_no_vacia CHECK (trim(contrasena) <> '')
);

COMMENT ON TABLE usuarios IS 'Cuentas de acceso al sistema; contrasena contiene hash irreversible.';
COMMENT ON COLUMN usuarios.contrasena IS 'Hash criptográfico seguro, nunca texto plano.';
