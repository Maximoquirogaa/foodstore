-- ============================================================================
-- TP6 — Parte 2: Desnormalización Controlada, Triggers y Comparación Medida
-- Consulta de Negocio: Top diario de categorías por facturación en tiempo real
-- Base de datos: Food Store (UTN FRM - PostgreSQL 17)
-- Alumno: Máximo Juan Cruz Quiroga
-- Docente: Sergio Neira
-- ============================================================================

\set ON_ERROR_STOP on

BEGIN;
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;

-- 1. Comprobaciones previas de integridad
DO $$
DECLARE
    v_tabla TEXT;
BEGIN
    FOREACH v_tabla IN ARRAY ARRAY['pedidos', 'detalles_pedido', 'productos', 'categorias', 'clientes']
    LOOP
        IF NOT EXISTS (
            SELECT 1 FROM pg_catalog.pg_class c
            JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace
            WHERE n.nspname = 'public' AND c.relname = v_tabla AND c.relkind = 'r'
        ) THEN
            RAISE EXCEPTION 'Falta la tabla ordinaria public.% para esta propuesta.', v_tabla;
        END IF;
    END LOOP;
END;
$$;

-- Bloqueo exclusivo para pruebas de laboratorio
LOCK TABLE public.categorias, public.clientes, public.pedidos, public.productos, public.detalles_pedido
IN ACCESS EXCLUSIVE MODE NOWAIT;

-- 2. Incorporar estados propios de borrado lógico
ALTER TABLE public.pedidos ADD COLUMN IF NOT EXISTS eliminado BOOLEAN NOT NULL DEFAULT FALSE;
ALTER TABLE public.detalles_pedido ADD COLUMN IF NOT EXISTS eliminado BOOLEAN NOT NULL DEFAULT FALSE;

-- 3. Incorporar columnas desnormalizadas (caché precalculado) en detalles_pedido
-- Copiamos: fecha_pedido, id_categoria y pedido_eliminado
ALTER TABLE public.detalles_pedido
    ADD COLUMN fecha_pedido_cache TIMESTAMPTZ,
    ADD COLUMN id_categoria_cache BIGINT,
    ADD COLUMN pedido_eliminado_cache BOOLEAN;

-- 4. Carga inicial / sincronización de datos existentes
UPDATE public.detalles_pedido dp
SET fecha_pedido_cache    = ped.fecha_pedido,
    pedido_eliminado_cache = ped.eliminado,
    id_categoria_cache    = pr.id_categoria
FROM public.pedidos ped, public.productos pr
WHERE dp.id_pedido = ped.id_pedido
  AND dp.id_producto = pr.id_producto;

-- Fijamos restricciones NOT NULL y FK
ALTER TABLE public.detalles_pedido
    ALTER COLUMN fecha_pedido_cache SET NOT NULL,
    ALTER COLUMN pedido_eliminado_cache SET NOT NULL,
    ALTER COLUMN id_categoria_cache SET NOT NULL,
    ADD CONSTRAINT fk_dp_categoria_cache FOREIGN KEY (id_categoria_cache) REFERENCES public.categorias(id_categoria);

-- 5. Crear índice B-Tree sobre la fecha desnormalizada
CREATE INDEX idx_TP6_detalle_fecha_cache ON public.detalles_pedido (fecha_pedido_cache);

ANALYZE public.pedidos;
ANALYZE public.productos;
ANALYZE public.detalles_pedido;

-- 6. Triggers de sincronización en tiempo real

-- Trigger A: Al insertar o actualizar un detalle_pedido
CREATE OR REPLACE FUNCTION fn_sincronizar_cache_detalle()
RETURNS TRIGGER AS $$
BEGIN
    SELECT ped.fecha_pedido, ped.eliminado
      INTO NEW.fecha_pedido_cache, NEW.pedido_eliminado_cache
      FROM public.pedidos ped
     WHERE ped.id_pedido = NEW.id_pedido;

    SELECT pr.id_categoria
      INTO NEW.id_categoria_cache
      FROM public.productos pr
     WHERE pr.id_producto = NEW.id_producto;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_sincronizar_cache_detalle
BEFORE INSERT OR UPDATE OF id_pedido, id_producto
ON public.detalles_pedido
FOR EACH ROW EXECUTE FUNCTION fn_sincronizar_cache_detalle();

-- Trigger B: Al cambiar fecha_pedido o eliminado en pedidos
CREATE OR REPLACE FUNCTION fn_propagar_cambios_pedido()
RETURNS TRIGGER AS $$
BEGIN
    IF (OLD.fecha_pedido IS DISTINCT FROM NEW.fecha_pedido) OR
       (OLD.eliminado IS DISTINCT FROM NEW.eliminado) THEN
        UPDATE public.detalles_pedido
           SET fecha_pedido_cache = NEW.fecha_pedido,
               pedido_eliminado_cache = NEW.eliminado
         WHERE id_pedido = NEW.id_pedido;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_propagar_cambios_pedido
AFTER UPDATE OF fecha_pedido, eliminado
ON public.pedidos
FOR EACH ROW EXECUTE FUNCTION fn_propagar_cambios_pedido();

-- Trigger C: Al cambiar la categoría de un producto
CREATE OR REPLACE FUNCTION fn_propagar_categoria_producto()
RETURNS TRIGGER AS $$
BEGIN
    IF OLD.id_categoria IS DISTINCT FROM NEW.id_categoria THEN
        UPDATE public.detalles_pedido
           SET id_categoria_cache = NEW.id_categoria
         WHERE id_producto = NEW.id_producto;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_propagar_categoria_producto
AFTER UPDATE OF id_categoria
ON public.productos
FOR EACH ROW EXECUTE FUNCTION fn_propagar_categoria_producto();

-- ============================================================
-- 7. Pruebas de funcionamiento y auditoría de sincronización
-- ============================================================
SAVEPOINT sp_pruebas_sync;

-- Caso prueba: Actualizar fecha de un pedido y verificar propagación inmediata
UPDATE public.pedidos
   SET fecha_pedido = '2026-06-25 15:30:00-03'
 WHERE id_pedido = 1;

DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM public.detalles_pedido
        WHERE id_pedido = 1
          AND fecha_pedido_cache <> '2026-06-25 15:30:00-03'::timestamptz
    ) THEN
        RAISE EXCEPTION 'Fallo de sincronización en trigger de pedidos.';
    END IF;
END;
$$;

ROLLBACK TO SAVEPOINT sp_pruebas_sync;

-- ============================================================
-- 8. Verificación formal de equivalencia relacional (EXCEPT)
-- ============================================================
DO $$
DECLARE
    v_diff INTEGER;
BEGIN
    SELECT COUNT(*) INTO v_diff
    FROM (
        -- Consulta Normalizada
        (SELECT c.id_categoria, c.nombre, SUM(dp.cantidad * dp.precio_unitario) AS monto
           FROM public.detalles_pedido dp
           JOIN public.pedidos ped ON ped.id_pedido = dp.id_pedido
           JOIN public.productos pr ON pr.id_producto = dp.id_producto
           JOIN public.categorias c ON c.id_categoria = pr.id_categoria
          WHERE ped.fecha_pedido >= '2026-06-25 00:00:00-03'::timestamptz
            AND ped.fecha_pedido <  '2026-06-26 00:00:00-03'::timestamptz
            AND dp.eliminado = FALSE
            AND ped.eliminado = FALSE
          GROUP BY c.id_categoria, c.nombre
          ORDER BY monto DESC
          LIMIT 5)
        EXCEPT
        -- Consulta Desnormalizada (aprovechando caché)
        (SELECT c.id_categoria, c.nombre, SUM(dp.cantidad * dp.precio_unitario) AS monto
           FROM public.detalles_pedido dp
           JOIN public.categorias c ON c.id_categoria = dp.id_categoria_cache
          WHERE dp.fecha_pedido_cache >= '2026-06-25 00:00:00-03'::timestamptz
            AND dp.fecha_pedido_cache <  '2026-06-26 00:00:00-03'::timestamptz
            AND dp.eliminado = FALSE
            AND dp.pedido_eliminado_cache = FALSE
          GROUP BY c.id_categoria, c.nombre
          ORDER BY monto DESC
          LIMIT 5)
    ) t;

    IF v_diff <> 0 THEN
        RAISE EXCEPTION 'Discrepancia en equivalencia relacional entre consulta normalizada y desnormalizada.';
    ELSE
        RAISE NOTICE 'AUDITORÍA EXITOSA: Equivalencia estricta confirmada (0 filas de diferencia).';
    END IF;
END;
$$;

-- ============================================================
-- 9. Mediciones Comparativas (EXPLAIN ANALYZE)
-- ============================================================

\echo '=== A. CONSULTA NORMALIZADA (4 JOINS, sin caché) ==='
EXPLAIN (ANALYZE, BUFFERS)
SELECT
    c.id_categoria,
    c.nombre AS categoria,
    SUM(dp.cantidad * dp.precio_unitario) AS monto_total
FROM public.detalles_pedido dp
JOIN public.pedidos ped ON ped.id_pedido = dp.id_pedido
JOIN public.productos pr ON pr.id_producto = dp.id_producto
JOIN public.categorias c ON c.id_categoria = pr.id_categoria
WHERE ped.fecha_pedido >= '2026-06-25 00:00:00-03'::timestamptz
  AND ped.fecha_pedido <  '2026-06-26 00:00:00-03'::timestamptz
  AND dp.eliminado = FALSE
  AND ped.eliminado = FALSE
GROUP BY c.id_categoria, c.nombre
ORDER BY monto_total DESC
LIMIT 5;

\echo '=== B. CONSULTA DESNORMALIZADA (1 JOIN, usando caché e índice) ==='
EXPLAIN (ANALYZE, BUFFERS)
SELECT
    c.id_categoria,
    c.nombre AS categoria,
    SUM(dp.cantidad * dp.precio_unitario) AS monto_total
FROM public.detalles_pedido dp
JOIN public.categorias c ON c.id_categoria = dp.id_categoria_cache
WHERE dp.fecha_pedido_cache >= '2026-06-25 00:00:00-03'::timestamptz
  AND dp.fecha_pedido_cache <  '2026-06-26 00:00:00-03'::timestamptz
  AND dp.eliminado = FALSE
  AND dp.pedido_eliminado_cache = FALSE
GROUP BY c.id_categoria, c.nombre
ORDER BY monto_total DESC
LIMIT 5;

-- Reversibilidad total
ROLLBACK;

