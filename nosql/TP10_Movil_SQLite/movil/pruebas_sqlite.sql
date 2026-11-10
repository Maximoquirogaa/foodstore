-- ============================================================================
-- TRABAJO PRÁCTICO N.º 10 (UNIDAD 8): Food Store en la Feria (Móvil & SQLite)
-- Base de Datos II - Tecnicatura Universitaria en Programación (UTN FRM)
-- Alumno: Máximo Juan Cruz Quiroga (maximoj.quiroga@alumnos.frm.utn.edu.ar)
-- Consigna 1.c: Pruebas de Transacciones, Caso C1 (Offline) y Caso C7 (Restricciones)
-- ============================================================================

PRAGMA foreign_keys = ON;

-- ----------------------------------------------------------------------------
-- 0. Carga de datos de catálogo inicial en la caché de la tablet
-- ----------------------------------------------------------------------------
INSERT INTO producto_cache (
    id, nombre, precio_centavos, stock_visto, disponible, eliminado, fecha_copia
) VALUES
    (1, 'Hamburguesa Clásica', 450000, 50, 1, 0, '2026-11-02T18:00:00Z'),
    (2, 'Hamburguesa Doble Queso', 620000, 35, 1, 0, '2026-11-02T18:00:00Z'),
    (3, 'Papas Fritas Medianas', 220000, 100, 1, 0, '2026-11-02T18:00:00Z'),
    (4, 'Gaseosa Cola 500ml', 150000, 80, 1, 0, '2026-11-02T18:00:00Z'),
    (99, 'Producto Descontinuado', 100000, 0, 0, 1, '2026-11-02T18:00:00Z');

-- ----------------------------------------------------------------------------
-- 1. Transacción confirmada (BEGIN ... COMMIT): Borrador completo con ítems y cola
-- ----------------------------------------------------------------------------
BEGIN;

INSERT INTO pedido_borrador (id_local, usuario, forma_pago, fecha)
VALUES (
    '11111111-1111-4111-8111-111111111111',
    'maximo_quiroga',
    'EFECTIVO',
    '2026-11-02T18:05:00Z'
);

INSERT INTO item_borrador (id_local, producto_id, cantidad, precio_centavos_visto)
VALUES
    ('11111111-1111-4111-8111-111111111111', 1, 2, 450000),
    ('11111111-1111-4111-8111-111111111111', 3, 1, 220000);

INSERT INTO cola_sync (solicitud_uuid, id_local, estado, motivo)
VALUES (
    '22222222-2222-4222-8222-222222222222',
    '11111111-1111-4111-8111-111111111111',
    'PENDIENTE',
    NULL
);

COMMIT;

-- Verificación de que el borrador quedó persistido
SELECT
    p.id_local,
    p.usuario,
    p.forma_pago,
    COUNT(i.producto_id) AS items_totales,
    SUM(i.cantidad * i.precio_centavos_visto) AS total_centavos,
    c.estado
FROM pedido_borrador AS p
JOIN item_borrador AS i ON i.id_local = p.id_local
JOIN cola_sync AS c ON c.id_local = p.id_local
WHERE p.id_local = '11111111-1111-4111-8111-111111111111'
GROUP BY p.id_local, p.usuario, p.forma_pago, c.estado;


-- ----------------------------------------------------------------------------
-- 2. Transacción revertida (BEGIN ... ROLLBACK): No debe dejar filas residuales
-- ----------------------------------------------------------------------------
BEGIN;

INSERT INTO pedido_borrador (id_local, usuario, forma_pago, fecha)
VALUES (
    '33333333-3333-4333-8333-333333333333',
    'maximo_quiroga',
    'TARJETA',
    '2026-11-02T18:10:00Z'
);

INSERT INTO item_borrador (id_local, producto_id, cantidad, precio_centavos_visto)
VALUES (
    '33333333-3333-4333-8333-333333333333',
    2,
    1,
    620000
);

ROLLBACK;

-- Verificación de reversión: los conteos deben dar exactamente 0
SELECT
    (SELECT COUNT(*) FROM pedido_borrador WHERE id_local = '33333333-3333-4333-8333-333333333333') AS borradores_revertidos,
    (SELECT COUNT(*) FROM item_borrador WHERE id_local = '33333333-3333-4333-8333-333333333333') AS items_revertidos;


-- ----------------------------------------------------------------------------
-- 3. Caso C1: Consulta del catálogo disponible sin conexión al servidor
-- ----------------------------------------------------------------------------
-- Filtra exclusivamente productos activos, no eliminados y con stock positivo
SELECT
    id,
    nombre,
    precio_centavos / 100.0 AS precio_pesos,
    stock_visto,
    disponible,
    fecha_copia
FROM producto_cache
WHERE disponible = 1
  AND eliminado = 0
  AND stock_visto > 0
ORDER BY id;


-- ----------------------------------------------------------------------------
-- 4. Caso C7: Violación de restricciones (Cantidad 0 y Producto inexistente)
-- ----------------------------------------------------------------------------
-- Prueba C7.a: Intento de insertar ítem con cantidad = 0 (viola CHECK (cantidad > 0))
-- Debe arrojar: CHECK constraint failed: cantidad > 0
-- (Envuelto en bloque SAVEPOINT / prueba de error)
SAVEPOINT prueba_c7_a;
-- INSERT INTO item_borrador (id_local, producto_id, cantidad, precio_centavos_visto)
-- VALUES ('11111111-1111-4111-8111-111111111111', 1, 0, 450000);
-- ROLLBACK TO prueba_c7_a;

-- Prueba C7.b: Intento de insertar ítem con producto_id inexistente (id = 9999)
-- Debe arrojar: FOREIGN KEY constraint failed
SAVEPOINT prueba_c7_b;
-- INSERT INTO item_borrador (id_local, producto_id, cantidad, precio_centavos_visto)
-- VALUES ('11111111-1111-4111-8111-111111111111', 9999, 1, 450000);
-- ROLLBACK TO prueba_c7_b;
