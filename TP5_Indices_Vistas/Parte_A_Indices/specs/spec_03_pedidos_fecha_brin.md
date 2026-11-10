# Spec 03 — Evaluación de Viabilidad de Índice BRIN en Pedidos (Caso Q4)

## 1. Contexto de Negocio
La consulta Q4 filtra pedidos correspondientes a los últimos 6 meses (`fecha_pedido >= now() - interval '6 months'`). Al tratarse de una tabla voluminosa (200.000 tuplas), se plantea evaluar un índice BRIN (*Block Range Index*) para ahorrar espacio en disco frente a un B-Tree tradicional.

## 2. Requerimientos para la IA
- Explicar las condiciones matemáticas y físicas necesarias para que un índice BRIN sea efectivo (alta correlación física entre el orden de almacenamiento en disco y los valores lógicos de la columna).
- Suministrar la consulta para medir el coeficiente de correlación física mediante el catálogo del sistema (`pg_stats`).

## 3. Criterio de Verificación
- Medir la correlación real de `fecha_pedido` en `pg_stats`.
- Si el valor absoluto de la correlación es cercano a 0 (por ejemplo, ~0.005 producto de inserciones simuladas no ordenadas estrictamente en disco), **descartar categóricamente el índice BRIN** por ineficacia demostrada y documentar la evidencia.
