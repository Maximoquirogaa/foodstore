-- ============================================================================
-- Parte_B_Vistas/verificacion_vistas.sql — Script de Validación de Vistas y Permisos
-- ============================================================================

\echo '=== 1. Verificar que v_usuario_publico NO expone la columna contrasena ==='
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'v_usuario_publico'
ORDER BY ordinal_position;

\echo '=== 2. Comprobación de Privilegios con SET ROLE TP5_reportes ==='
SET ROLE TP5_reportes;

-- Estas consultas deben ejecutarse con éxito:
SELECT * FROM v_usuario_publico LIMIT 2;
SELECT * FROM v_reporte_ventas_cliente LIMIT 2;
SELECT * FROM v_catalogo_productos LIMIT 2;
SELECT * FROM v_detalle_pedido_producto LIMIT 2;
SELECT * FROM v_pedido_cliente LIMIT 2;
SELECT * FROM mv_resumen_ventas_categoria_mes LIMIT 2;

-- Esta consulta DEBE FALLAR con ERROR de permiso denegado:
-- SELECT * FROM usuarios;

RESET ROLE;

\echo '=== 3. Comprobación Formal de Equivalencia Relacional con EXCEPT ==='

-- 3.1 v_catalogo_productos
(
    SELECT id_producto, producto, categoria, precio_actual, stock
    FROM v_catalogo_productos
    EXCEPT
    SELECT p.id_producto, p.nombre, c.nombre, p.precio_actual, p.stock
    FROM productos AS p
    JOIN categorias AS c ON c.id_categoria = p.id_categoria
    WHERE p.activo = TRUE AND c.activo = TRUE
)
UNION ALL
(
    SELECT p.id_producto, p.nombre, c.nombre, p.precio_actual, p.stock
    FROM productos AS p
    JOIN categorias AS c ON c.id_categoria = p.id_categoria
    WHERE p.activo = TRUE AND c.activo = TRUE
    EXCEPT
    SELECT id_producto, producto, categoria, precio_actual, stock
    FROM v_catalogo_productos
);

-- 3.2 v_detalle_pedido_producto
(
    SELECT id_pedido, id_producto, producto, cantidad, precio_unitario, subtotal
    FROM v_detalle_pedido_producto
    EXCEPT
    SELECT dp.id_pedido, dp.id_producto, pr.nombre, dp.cantidad, dp.precio_unitario, (dp.cantidad * dp.precio_unitario)::NUMERIC(12,2)
    FROM detalles_pedido dp
    JOIN productos pr ON pr.id_producto = dp.id_producto
)
UNION ALL
(
    SELECT dp.id_pedido, dp.id_producto, pr.nombre, dp.cantidad, dp.precio_unitario, (dp.cantidad * dp.precio_unitario)::NUMERIC(12,2)
    FROM detalles_pedido dp
    JOIN productos pr ON pr.id_producto = dp.id_producto
    EXCEPT
    SELECT id_pedido, id_producto, producto, cantidad, precio_unitario, subtotal
    FROM v_detalle_pedido_producto
);

-- 3.3 v_pedido_cliente
(
    SELECT id_pedido, fecha_pedido, forma_pago, id_cliente, cliente, correo_electronico
    FROM v_pedido_cliente
    EXCEPT
    SELECT p.id_pedido, p.fecha_pedido, p.forma_pago, c.id_cliente, c.nombre || ' ' || c.apellido, c.correo_electronico
    FROM pedidos p
    JOIN clientes c ON c.id_cliente = p.id_cliente
)
UNION ALL
(
    SELECT p.id_pedido, p.fecha_pedido, p.forma_pago, c.id_cliente, c.nombre || ' ' || c.apellido, c.correo_electronico
    FROM pedidos p
    JOIN clientes c ON c.id_cliente = p.id_cliente
    EXCEPT
    SELECT id_pedido, fecha_pedido, forma_pago, id_cliente, cliente, correo_electronico
    FROM v_pedido_cliente
);

