-- ==========================================
-- TP5 - Parte B: Vistas simples del sistema
-- ==========================================

-- 1. Vista de productos vigentes (oculta los dados de baja y muestra la categoría)
CREATE OR REPLACE VIEW v_productos_vigentes AS
SELECT 
    p.id_producto, 
    p.nombre AS producto, 
    c.nombre AS categoria, 
    p.precio_actual, 
    p.stock
FROM productos p
JOIN categorias c ON p.id_categoria = c.id_categoria
WHERE p.activo = TRUE;

-- 2. Vista de pedidos con usuario (Aplica criterio de seguridad)
-- Nota teórica: Se omite a propósito la columna `correo_electronico` de la tabla clientes
-- (actuando aquí como la "contraseña" o dato sensible solicitado por la consigna),
-- para permitir otorgar SELECT a un usuario de reportes sin filtrar información privada.
CREATE OR REPLACE VIEW v_pedidos_usuario AS
SELECT 
    p.id_pedido, 
    p.fecha_pedido, 
    p.forma_pago, 
    c.id_cliente, 
    c.nombre AS cliente_nombre, 
    c.apellido AS cliente_apellido
FROM pedidos p
JOIN clientes c ON p.id_cliente = c.id_cliente;

-- 3. Vista de detalles de pedido cruzado con el producto
CREATE OR REPLACE VIEW v_detalles_pedido AS
SELECT 
    dp.id_pedido, 
    dp.cantidad, 
    dp.precio_unitario, 
    pr.nombre AS producto
FROM detalles_pedido dp
JOIN productos pr ON dp.id_producto = pr.id_producto;

