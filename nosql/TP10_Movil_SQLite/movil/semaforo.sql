-- ============================================================================
-- TRABAJO PRÁCTICO N.º 10 (UNIDAD 8): Food Store en la Feria (Móvil & SQLite)
-- Base de Datos II - Tecnicatura Universitaria en Programación (UTN FRM)
-- Alumno: Máximo Juan Cruz Quiroga (maximoj.quiroga@alumnos.frm.utn.edu.ar)
-- Consigna 2.b: Algoritmo de Sincronización del Semáforo en SQLite
-- ============================================================================

PRAGMA foreign_keys = ON;

-- Solo evalúa solicitudes en estado 'PENDIENTE'.
-- El servidor PostgreSQL dispone; esta simulación sobre la tablet valida borradores
-- sin alterar existencias ni emitir ventas definitivas.

DROP TABLE IF EXISTS temp.evaluacion_semaforo;

CREATE TEMP TABLE evaluacion_semaforo AS
SELECT
    c.solicitud_uuid,
    c.id_local,
    COUNT(i.producto_id) AS cantidad_items,
    SUM(
        CASE
            WHEN s.id IS NULL
              OR s.disponible <> 1
              OR s.eliminado <> 0
              OR i.cantidad > s.stock
            THEN 1 ELSE 0
        END
    ) AS cantidad_rojos,
    SUM(CASE WHEN s.id IS NULL THEN 1 ELSE 0 END) AS productos_inexistentes,
    SUM(CASE WHEN s.id IS NOT NULL AND s.disponible <> 1 THEN 1 ELSE 0 END) AS productos_no_disponibles,
    SUM(CASE WHEN s.id IS NOT NULL AND s.eliminado <> 0 THEN 1 ELSE 0 END) AS productos_dados_de_baja,
    SUM(CASE WHEN s.id IS NOT NULL AND i.cantidad > s.stock THEN 1 ELSE 0 END) AS stocks_insuficientes,
    SUM(
        CASE WHEN s.id IS NOT NULL AND i.precio_centavos_visto <> s.precio_centavos
             THEN 1 ELSE 0 END
    ) AS conflictos_precio
FROM cola_sync AS c
LEFT JOIN item_borrador AS i
    ON i.id_local = c.id_local
LEFT JOIN snapshot_servidor AS s
    ON s.id = i.producto_id
WHERE c.estado = 'PENDIENTE'
GROUP BY c.solicitud_uuid, c.id_local;

-- Actualización atómica del estado según precedencia:
-- 1. Rojo (RECHAZADO): Inexistente, no disponible, dado de baja o stock insuficiente.
-- 2. Amarillo (CONFLICTO): No hay rojo, pero difiere el precio en centavos.
-- 3. Verde (SIMULADO_APROBADO): Todas las condiciones coinciden.
UPDATE cola_sync AS c
SET
    estado = (
        SELECT CASE
            WHEN e.cantidad_items = 0 OR e.cantidad_rojos > 0 THEN 'RECHAZADO'
            WHEN e.conflictos_precio > 0 THEN 'CONFLICTO'
            ELSE 'SIMULADO_APROBADO'
        END
        FROM evaluacion_semaforo AS e
        WHERE e.solicitud_uuid = c.solicitud_uuid
    ),
    motivo = (
        SELECT CASE
            WHEN e.cantidad_items = 0 THEN 'Solicitud sin ítems'
            WHEN e.productos_inexistentes > 0 THEN 'Producto inexistente en la instantánea'
            WHEN e.productos_no_disponibles > 0 THEN 'Producto no disponible'
            WHEN e.productos_dados_de_baja > 0 THEN 'Producto dado de baja'
            WHEN e.stocks_insuficientes > 0 THEN 'Stock insuficiente'
            WHEN e.conflictos_precio > 0 THEN 'Cambió el precio observado'
            ELSE 'Precio, disponibilidad y stock coinciden'
        END
        FROM evaluacion_semaforo AS e
        WHERE e.solicitud_uuid = c.solicitud_uuid
    )
WHERE c.estado = 'PENDIENTE'
  AND c.solicitud_uuid IN (SELECT solicitud_uuid FROM evaluacion_semaforo);
