-- ============================================================================
-- TRABAJO PRÁCTICO N.º 10 (UNIDAD 8): Food Store en la Feria (Móvil & SQLite)
-- Base de Datos II - Tecnicatura Universitaria en Programación (UTN FRM)
-- Alumno: Máximo Juan Cruz Quiroga (maximoj.quiroga@alumnos.frm.utn.edu.ar)
-- Consigna 2.c: Simulación Completa de los Casos C2 a C6 del Semáforo
-- ============================================================================

PRAGMA foreign_keys = ON;

-- Limpieza de borradores y solicitudes de prueba previas
DELETE FROM cola_sync;
DELETE FROM item_borrador;
DELETE FROM pedido_borrador;

-- ----------------------------------------------------------------------------
-- Caso C2: Borrador creado con precio de catálogo anterior ($4.500 = 450.000 centavos)
-- ----------------------------------------------------------------------------
INSERT INTO pedido_borrador (id_local, usuario, forma_pago, fecha)
VALUES ('c2-local-01', 'maximo_quiroga', 'EFECTIVO', '2026-11-04T12:00:00Z');

INSERT INTO item_borrador (id_local, producto_id, cantidad, precio_centavos_visto)
VALUES ('c2-local-01', 1, 1, 450000); -- Precio observado: 450000

INSERT INTO cola_sync (solicitud_uuid, id_local, estado, motivo)
VALUES ('c2-solicitud-1', 'c2-local-01', 'PENDIENTE', NULL);

-- ----------------------------------------------------------------------------
-- Caso C3: Borrador con cantidad superior al stock disponible (Pide 99 unidades de Hamb. Doble Queso)
-- ----------------------------------------------------------------------------
INSERT INTO pedido_borrador (id_local, usuario, forma_pago, fecha)
VALUES ('c3-local-01', 'maximo_quiroga', 'TARJETA', '2026-11-04T12:05:00Z');

INSERT INTO item_borrador (id_local, producto_id, cantidad, precio_centavos_visto)
VALUES ('c3-local-01', 2, 99, 620000); -- Stock en servidor es 35

INSERT INTO cola_sync (solicitud_uuid, id_local, estado, motivo)
VALUES ('c3-solicitud-1', 'c3-local-01', 'PENDIENTE', NULL);

-- ----------------------------------------------------------------------------
-- Caso C4: Borrador con producto que luego es dado de baja en el servidor (Papas Fritas id=3)
-- ----------------------------------------------------------------------------
INSERT INTO pedido_borrador (id_local, usuario, forma_pago, fecha)
VALUES ('c4-local-01', 'maximo_quiroga', 'TRANSFERENCIA', '2026-11-04T12:10:00Z');

INSERT INTO item_borrador (id_local, producto_id, cantidad, precio_centavos_visto)
VALUES ('c4-local-01', 3, 1, 220000);

INSERT INTO cola_sync (solicitud_uuid, id_local, estado, motivo)
VALUES ('c4-solicitud-1', 'c4-local-01', 'PENDIENTE', NULL);

-- ----------------------------------------------------------------------------
-- Recarga de la instantánea nueva del servidor (servidor_snapshot_2c):
-- En el servidor:
-- - Producto 1 aumentó de 450000 a 480000 centavos ($4.800).
-- - Producto 3 fue dado de baja lógica (disponible=0, eliminado=1).
-- ----------------------------------------------------------------------------
-- (En ejecución interactiva se importa servidor_snapshot_2c.csv y se corre recargar_snapshot.sql)

-- ----------------------------------------------------------------------------
-- Caso C5: Borrador emitido con los datos actualizados del servidor (Sin cambios)
-- ----------------------------------------------------------------------------
INSERT INTO pedido_borrador (id_local, usuario, forma_pago, fecha)
VALUES ('c5-local-01', 'maximo_quiroga', 'EFECTIVO', '2026-11-04T12:15:00Z');

INSERT INTO item_borrador (id_local, producto_id, cantidad, precio_centavos_visto)
VALUES ('c5-local-01', 1, 1, 480000); -- Precio nuevo coincide con el servidor

INSERT INTO cola_sync (solicitud_uuid, id_local, estado, motivo)
VALUES ('c5-solicitud-1', 'c5-local-01', 'PENDIENTE', NULL);

-- ----------------------------------------------------------------------------
-- Resolución de C2: El cliente acepta el nuevo precio ($4.800)
-- Se actualiza el borrador local y se despacha una nueva solicitud (UUID nuevo)
-- ----------------------------------------------------------------------------
-- UPDATE item_borrador SET precio_centavos_visto = 480000 WHERE id_local = 'c2-local-01' AND producto_id = 1;
-- INSERT INTO cola_sync (solicitud_uuid, id_local, estado, motivo) VALUES ('c2-solicitud-2', 'c2-local-01', 'PENDIENTE', NULL);

-- ----------------------------------------------------------------------------
-- Caso C6: Idempotencia y protección ante reenvíos con el mismo UUID
-- Si se intenta reinsertar 'c5-solicitud-1', la PRIMARY KEY de cola_sync lo rechaza.
-- Asimismo, ejecutar el semáforo sobre solicitudes ya procesadas no las reevalúa.
-- ----------------------------------------------------------------------------
