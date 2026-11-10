-- ============================================================================
-- TRABAJO PRÁCTICO N.º 10 (UNIDAD 8): Food Store en la Feria (Móvil & SQLite)
-- Base de Datos II - Tecnicatura Universitaria en Programación (UTN FRM)
-- Alumno: Máximo Juan Cruz Quiroga (maximoj.quiroga@alumnos.frm.utn.edu.ar)
-- Consigna 2.c: Verificación de Integridad en el Servidor (Sin Cambios)
-- ============================================================================

-- Regla de Oro: "El móvil propone, el servidor dispone"
-- La tablet nunca cambia el stock ni los pedidos del servidor: SIMULADO_APROBADO
-- no es una venta en PostgreSQL.

-- 1. Verificar que la cantidad de pedidos y detalles de pedido permanezca idéntica
SELECT 
    'pedidos' AS tabla, COUNT(*) AS total_registros FROM public.pedidos
UNION ALL
SELECT 
    'detalles_pedido' AS tabla, COUNT(*) AS total_registros FROM public.detalles_pedido;

-- 2. Verificar que las existencias de stock de los productos no se descontaron
SELECT 
    id_producto,
    nombre,
    stock,
    precio_actual,
    activo
FROM public.productos
WHERE id_producto IN (1, 2, 3, 4)
ORDER BY id_producto;
