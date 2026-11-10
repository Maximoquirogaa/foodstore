-- ============================================================================
-- Parte_B_Vistas/usuarios_datos.sql — Datos Semilla de Usuarios
-- Inserta usuarios de prueba con contraseñas hasheadas para validar permisos
-- ============================================================================

INSERT INTO usuarios (nombre, apellido, correo_electronico, telefono, contrasena, rol, activo)
VALUES
    ('Administrador', 'General', 'admin@foodstore.utn.edu.ar', '+54 261 4123456', '$2a$12$e8Y6bFj6s8X.x2Z9W1Y2Zu0v1w2x3y4z5a6b7c8d9e0f1g2h3i4j', 'ADMIN', TRUE),
    ('Carlos', 'Ventas', 'carlos.ventas@foodstore.utn.edu.ar', '+54 261 4234567', '$2a$12$kJ87gH65fD43sA21qW09.u1v2w3x4y5z6a7b8c9d0e1f2g3h4i5j', 'VENDEDOR', TRUE),
    ('Laura', 'Reportes', 'laura.analista@foodstore.utn.edu.ar', '+54 261 4345678', '$2a$12$pL09oK87iJ65uY43tR21.v1w2x3y4z5a6b7c8d9e0f1g2h3i4j5k', 'USUARIO', TRUE)
ON CONFLICT (correo_electronico) DO NOTHING;
