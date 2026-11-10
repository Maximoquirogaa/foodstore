# Spec 04 — Vistas Analíticas, Ocultamiento de Credenciales y Seguridad por Roles

## 1. Contexto de Negocio
Se requiere proveer un esquema de seguridad y simplificación analítica para la aplicación Food Store mediante vistas relacionales y un rol restringido para auditoría y reportes.

## 2. Requerimientos de Vistas
1. **`v_usuario_publico`**: Proyectar los datos de usuarios (`id_usuario`, `nombre`, `apellido`, `correo_electronico`, `telefono`, `rol`, `fecha_creacion`), **omitiendo deliberadamente la columna de contraseña** (`contrasena`).
2. **`v_reporte_ventas_cliente`**: Listar cada cliente con su total de pedidos y monto facturado acumulado (`SUM(cantidad * precio_unitario)`), manejando clientes sin pedidos mediante `LEFT JOIN` y `COALESCE`.
3. **`v_catalogo_productos`**: Exponer los productos vigentes (`activo = TRUE`) y sus categorías activas.
4. **`v_detalle_pedido_producto`**: Detalle de cada renglón de pedido con el nombre del producto, cantidad, precio unitario y subtotal calculado.
5. **`v_pedido_cliente`**: Cruce fila a fila de pedidos con los datos del cliente comprador.

## 3. Requerimientos de Seguridad y Roles
- Crear un rol grupal `TP5_reportes` (NOLOGIN).
- Revocar todo acceso a las tablas base (`usuarios`, `clientes`, `pedidos`, `detalles_pedido`, `productos`, `categorias`).
- Otorgar privilegio `SELECT` exclusivamente a las vistas y a la vista materializada de la Parte C.
- Demostrar que al consultar directamente una tabla base bajo este rol, PostgreSQL bloquea el acceso emitiendo error de permiso denegado.

## 4. Requerimiento de Equivalencia Formal
- Probar cada vista contra su consulta SQL equivalente mediante el operador `EXCEPT`, verificando que la diferencia sea de exactamente 0 filas.

