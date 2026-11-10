-- ==========================================
-- TP3 - Parte 1: Script de carga masiva
-- ==========================================

-- Se recomienda ejecutar esto dentro de una transacción en tu cliente SQL:
-- BEGIN;
-- ... (todo el código) ...
-- COMMIT;

-- 1. Insertamos categorías base (ID 1 al 5)
INSERT INTO categorias (nombre, activo)
VALUES 
    ('Pizzas', true), 
    ('Bebidas', true), 
    ('Postres', true), 
    ('Empanadas', true), 
    ('Ensaladas', true);

-- 2. Insertamos 20.000 Clientes usando generate_series
INSERT INTO clientes (nombre, apellido, correo_electronico)
SELECT 
    'Nombre_' || i, 
    'Apellido_' || i, 
    'usuario_' || i || '_' || extract(epoch from now())::int || '@utn.edu.ar'
FROM generate_series(1, 20000) AS t(i);

-- 3. Insertamos 50.000 Productos distribuidos en las 5 categorías
INSERT INTO productos (id_categoria, nombre, precio_actual, stock, activo)
SELECT 
    floor(random() * 5 + 1)::int, -- Categoría aleatoria entre 1 y 5
    'Producto_Gen_' || i,
    (random() * 4500 + 500)::numeric(12,2), -- Precio entre 500 y 5000
    floor(random() * 500 + 100)::int, -- Stock entre 100 y 600 (alto para evitar errores de restricción al crear pedidos)
    true
FROM generate_series(1, 50000) AS t(i);

-- 4. Insertamos 200.000 Pedidos
INSERT INTO pedidos (id_cliente, forma_pago, fecha_pedido)
SELECT 
    floor(random() * 20000 + 1)::int, -- Cliente aleatorio entre 1 y 20.000
    ('{EFECTIVO, TARJETA, TRANSFERENCIA}'::forma_pago[])[floor(random() * 3 + 1)::int], -- Forma de pago aleatoria
    now() - (random() * 365 || ' days')::interval -- Fecha aleatoria en el último año
FROM generate_series(1, 200000) AS t(i);

-- 5. Insertamos los Detalles de Pedido (Asegurando al menos 1 producto por pedido)
-- Atención: Le asignamos cantidad=1 para que no haya posibilidad de que el stock caiga a negativo 
-- por los triggers que hiciste en el TP2, respetando así la restricción CHECK.
INSERT INTO detalles_pedido (id_pedido, id_producto, cantidad, precio_unitario)
SELECT 
    id_pedido,
    floor(random() * 50000 + 1)::int, -- Producto aleatorio
    1, -- Cantidad fija pequeña
    (random() * 4500 + 500)::numeric(12,2) -- Precio histórico congelado
FROM pedidos
ON CONFLICT (id_pedido, id_producto) DO NOTHING;

-- 6. Actualizar estadísticas para que el optimizador de PostgreSQL pueda trabajar correctamente
ANALYZE categorias;
ANALYZE clientes;
ANALYZE productos;
ANALYZE pedidos;
ANALYZE detalles_pedido;
