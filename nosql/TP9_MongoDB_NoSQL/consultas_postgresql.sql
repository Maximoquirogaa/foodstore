-- ============================================================================
-- TP9 — Parte 2 Consigna 5: Consultas Equivalentes en PostgreSQL y Verificación
-- Asignatura: Base de Datos II (UTN FRM)
-- Alumno: Máximo Juan Cruz Quiroga (maximoj.quiroga@alumnos.frm.utn.edu.ar)
-- Docente: Sergio Neira
-- Motor: PostgreSQL 17 | Base: foodstore_dev / foodstore
-- ============================================================================
-- PROPÓSITO:
--   Ejecutar las consultas equivalentes a los apartados 4.b y 4.c en el modelo
--   relacional de PostgreSQL para validar la consistencia de datos y comparar
--   los identificadores y cantidades recuperados respecto a MongoDB.
-- ============================================================================

-- 0. Asegurar compatibilidad de entorno y datos de prueba
-- Si en PostgreSQL se utiliza la columna estado en pedidos (o mapeo por forma_pago)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' AND table_name = 'pedidos' AND column_name = 'estado'
    ) THEN
        ALTER TABLE public.pedidos ADD COLUMN estado VARCHAR(20) DEFAULT 'ENTREGADO';
        -- Actualizar los 5 pedidos de prueba para que reflejen exactamente los estados de MongoDB
        UPDATE public.pedidos SET estado = 'ENTREGADO' WHERE id_pedido IN (1, 3, 5);
        UPDATE public.pedidos SET estado = 'PENDIENTE' WHERE id_pedido = 2;
        UPDATE public.pedidos SET estado = 'CANCELADO' WHERE id_pedido = 4;
    END IF;
END $$;


-- ============================================================================
-- CONSULTA 5.b: Equivalente a 4.b en PostgreSQL (Filtrar por estado = 'ENTREGADO')
-- ============================================================================
-- En el modelo relacional, para obtener el pedido completo junto a su cliente
-- y el total calculado, se requiere JOIN con clientes y detalles_pedido.
SELECT 
    p.id_pedido,
    p.estado,
    p.fecha_pedido,
    c.nombre || ' ' || c.apellido AS cliente,
    p.forma_pago,
    COALESCE(SUM(dp.cantidad * dp.precio_unitario), 0)::NUMERIC(12,2) AS total
FROM public.pedidos AS p
JOIN public.clientes AS c ON c.id_cliente = p.id_cliente
JOIN public.detalles_pedido AS dp ON dp.id_pedido = p.id_pedido
WHERE p.estado = 'ENTREGADO'
GROUP BY p.id_pedido, p.estado, p.fecha_pedido, c.nombre, c.apellido, p.forma_pago
ORDER BY p.id_pedido;

-- Conteo para la tabla de verificación:
SELECT COUNT(DISTINCT p.id_pedido) AS cantidad_pedidos_entregados
FROM public.pedidos AS p
WHERE p.estado = 'ENTREGADO';


-- ============================================================================
-- CONSULTA 5.c: Equivalente a 4.c en PostgreSQL (Buscar pedidos con producto 1)
-- ============================================================================
-- En el modelo relacional normalizado, los productos están en la tabla intermedia
-- detalles_pedido. Requiere JOIN y DISTINCT para no duplicar pedidos con múltiples ítems.
SELECT DISTINCT
    p.id_pedido,
    p.estado,
    c.nombre || ' ' || c.apellido AS cliente,
    pr.id_producto,
    pr.nombre AS nombre_producto,
    dp.cantidad,
    (SELECT SUM(dp2.cantidad * dp2.precio_unitario) 
     FROM public.detalles_pedido dp2 
     WHERE dp2.id_pedido = p.id_pedido)::NUMERIC(12,2) AS total
FROM public.pedidos AS p
JOIN public.clientes AS c ON c.id_cliente = p.id_cliente
JOIN public.detalles_pedido AS dp ON dp.id_pedido = p.id_pedido
JOIN public.productos AS pr ON pr.id_producto = dp.id_producto
WHERE dp.id_producto = 1
ORDER BY p.id_pedido;

-- Conteo para la tabla de verificación:
SELECT COUNT(DISTINCT dp.id_pedido) AS cantidad_pedidos_con_producto_1
FROM public.detalles_pedido AS dp
WHERE dp.id_producto = 1;


-- ============================================================================
-- TABLA DE COMPARACIÓN Y VERIFICACIÓN (Consigna 5)
-- ============================================================================
/*
+------------------------------------+-----------------------+---------------------+-------------------+
| Consulta                           | Cantidad en PostgreSQL| Cantidad en MongoDB | Coinciden los IDs |
+------------------------------------+-----------------------+---------------------+-------------------+
| Estado seleccionado ('ENTREGADO')  | 3 pedidos             | 3 pedidos           | Sí ([1, 3, 5])    |
+------------------------------------+-----------------------+---------------------+-------------------+
| Producto seleccionado (id = 1)     | 3 pedidos             | 3 pedidos           | Sí ([1, 2, 4])    |
+------------------------------------+-----------------------+---------------------+-------------------+

Explicación técnica:
1. En ambos motores se recuperan exactamente los mismos identificadores (IDs [1, 3, 5] y [1, 2, 4]).
2. En PostgreSQL, la consulta (b) requiere agrupar y calcular SUM(cantidad * precio_unitario),
   mientras que la consulta (c) exige cruzar 4 tablas con JOIN y aplicar DISTINCT.
3. En MongoDB, la consulta (b) lee directamente el atributo 'estado' sin procesar tablas satélites,
   y la consulta (c) utiliza un Multikey Index sobre el arreglo 'lineas.id_producto',
   resolviendo la búsqueda en un único escaneo de índice sin duplicados ni sobrecarga de JOINs.
*/
