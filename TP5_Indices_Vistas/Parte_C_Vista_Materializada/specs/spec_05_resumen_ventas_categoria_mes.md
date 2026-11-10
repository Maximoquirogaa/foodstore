# Spec 05 — Vista Materializada para Resumen de Ventas por Categoría y Mes

## 1. Contexto de Negocio
Las consultas que resumen facturación mensual histórica cruzan 4 tablas (`categorias`, `productos`, `detalles_pedido`, `pedidos`) y demandan cientos de milisegundos sobre la base masiva (~500.000 tuplas). Se requiere crear una Vista Materializada para disponer de los datos precalculados de forma inmediata.

## 2. Requerimientos de la Vista Materializada
- Definir `mv_resumen_ventas_categoria_mes` agrupando por `(id_categoria, categoria, mes)` con las siguientes métricas:
  * `cantidad_pedidos`: conteo distintivo de pedidos.
  * `unidades_vendidas`: suma de cantidades.
  * `facturacion_total`: suma de `dp.cantidad * dp.precio_unitario`.
- Crear un índice único sobre `(id_categoria, mes)` para habilitar el comando `REFRESH MATERIALIZED VIEW CONCURRENTLY`.

## 3. Criterio de Verificación de Rendimiento y Concurrencia
- Comparar el tiempo de ejecución de la consulta directa cruzando las 4 tablas frente a la lectura de la vista materializada.
- Comprobar que el refresco concurrente (`REFRESH CONCURRENTLY`) utiliza bloqueos ligeros (`ExclusiveLock`) en vez de bloqueos exclusivos totales (`AccessExclusiveLock`), permitiendo que las consultas de lectura (`SELECT`) continúen ejecutándose sin interrupción.
- Definir la política de refresco periódico recomendada (job nocturno / cron diario).
