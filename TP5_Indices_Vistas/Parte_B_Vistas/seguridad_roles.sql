-- ============================================================================
-- Parte_B_Vistas/seguridad_roles.sql — Configuración de Roles y Privilegios
-- Proyecto: Food Store (UTN FRM - Base de Datos II)
-- Alumno: Máximo Juan Cruz Quiroga
-- Docente: Sergio Neira
-- ============================================================================

-- 1. Crear el rol grupal para usuarios de reportes (sin login directo)
DO $$
BEGIN
    CREATE ROLE TP5_reportes NOLOGIN;
EXCEPTION
    WHEN duplicate_object THEN NULL;
END
$$;

-- 2. Revocar todo acceso público o directo a las tablas base
REVOKE ALL ON TABLE usuarios, clientes, pedidos, detalles_pedido, productos, categorias
    FROM PUBLIC, TP5_reportes;

-- 3. Habilitar uso del esquema público y conceder SELECT exclusivo sobre las vistas
GRANT USAGE ON SCHEMA public TO TP5_reportes;

GRANT SELECT ON
    v_usuario_publico,
    v_reporte_ventas_cliente,
    v_catalogo_productos,
    v_detalle_pedido_producto,
    v_pedido_cliente,
    mv_resumen_ventas_categoria_mes
    TO TP5_reportes;

