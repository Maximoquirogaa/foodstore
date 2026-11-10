-- ============================================================================
-- Parte_B_Vistas/vistas.sql — Definición de Vistas Analíticas y de Exposición Segura
-- Proyecto: Food Store (UTN FRM - Base de Datos II)
-- Alumno: Máximo Juan Cruz Quiroga
-- Docente: Sergio Neira
-- ============================================================================

-- 1. Vista Pública de Usuarios (Seguridad: omite deliberadamente la contraseña)
CREATE OR REPLACE VIEW v_usuario_publico AS
SELECT
    id_usuario,
    nombre,
    apellido,
    correo_electronico,
    telefono,
    rol,
    fecha_creacion
FROM usuarios
WHERE activo = TRUE;

COMMENT ON VIEW v_usuario_publico IS 'Vista segura de usuarios: excluye la columna contrasena.';


-- 2. Vista de Reporte de Ventas por Cliente (Con agregación y total facturado)
CREATE OR REPLACE VIEW v_reporte_ventas_cliente AS
SELECT
    c.id_cliente,
    c.nombre || ' ' || c.apellido AS cliente,
    COUNT(DISTINCT p.id_pedido) AS total_pedidos,
    COALESCE(SUM(dp.cantidad * dp.precio_unitario), 0)::NUMERIC(12, 2) AS total_facturado
FROM clientes AS c
LEFT JOIN pedidos AS p
    ON p.id_cliente = c.id_cliente
LEFT JOIN detalles_pedido AS dp
    ON dp.id_pedido = p.id_pedido
GROUP BY c.id_cliente, c.nombre, c.apellido;

COMMENT ON VIEW v_reporte_ventas_cliente IS 'Reporte agregado de facturación y pedidos por cliente.';


-- 3. Vista de Catálogo de Productos y Categorías Activas
CREATE OR REPLACE VIEW v_catalogo_productos AS
SELECT
    p.id_producto,
    p.nombre AS producto,
    c.nombre AS categoria,
    p.precio_actual,
    p.stock
FROM productos AS p
JOIN categorias AS c ON c.id_categoria = p.id_categoria
WHERE p.activo = TRUE
  AND c.activo = TRUE;

COMMENT ON VIEW v_catalogo_productos IS 'Catálogo operativo de productos y categorías vigentes.';


-- 4. Vista de Detalle de Pedido con Producto Desglosado
CREATE OR REPLACE VIEW v_detalle_pedido_producto AS
SELECT
    dp.id_pedido,
    dp.id_producto,
    pr.nombre AS producto,
    dp.cantidad,
    dp.precio_unitario,
    (dp.cantidad * dp.precio_unitario)::NUMERIC(12, 2) AS subtotal
FROM detalles_pedido AS dp
JOIN productos AS pr ON pr.id_producto = dp.id_producto;

COMMENT ON VIEW v_detalle_pedido_producto IS 'Renglones de pedido desglosados con descripción de producto y subtotal.';


-- 5. Vista de Pedidos y Clientes Fila a Fila
CREATE OR REPLACE VIEW v_pedido_cliente AS
SELECT
    p.id_pedido,
    p.fecha_pedido,
    p.forma_pago,
    c.id_cliente,
    c.nombre || ' ' || c.apellido AS cliente,
    c.correo_electronico
FROM pedidos AS p
JOIN clientes AS c ON c.id_cliente = p.id_cliente;

COMMENT ON VIEW v_pedido_cliente IS 'Historial de pedidos cruzado fila a fila con datos de cliente.';
