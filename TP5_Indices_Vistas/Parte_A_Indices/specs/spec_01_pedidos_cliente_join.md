# Spec 01 — Índice en Pedidos y Agregación de Clientes (Caso Q5)

## 1. Contexto de Negocio
Se requiere optimizar el reporte de ranking histórico de clientes por gasto acumulado (`Q5`), que combina `clientes`, `pedidos` y `detalles_pedido`, aplicando `DENSE_RANK() OVER (ORDER BY gasto DESC)`.

## 2. Requerimientos para la IA
- Analizar el plan de ejecución `EXPLAIN (ANALYZE, BUFFERS)` de Q5 sobre 200.000 pedidos.
- Proponer un índice candidato para acelerar el enlace entre `pedidos` y `clientes`.
- Evaluar si el cuello de botella radica en el acceso a las tablas o en el operador de agregación `HashAggregate`.

## 3. Criterio de Verificación
- Contrastar el índice propuesto en una transacción `BEGIN ... ROLLBACK`.
- Si el planificador ignora el índice debido al escaneo masivo de filas, documentar el descarte explícito por baja selectividad.
- Evaluar el ajuste alternativo `SET LOCAL work_mem = '16MB'` para comprobar si elimina el derrame temporal a disco (`Disk Usage > 0`).
