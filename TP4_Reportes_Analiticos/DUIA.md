# Declaración de Uso de IA (DUIA) - TP4 Consolidada

**Materia:** Base de Datos II  
**Trabajo Práctico:** TP4 — Optimización de Consultas Analíticas, Joins, Agregaciones y Subconsultas  
**Proyecto:** Food Store  
**Facultad:** Universidad Tecnológica Nacional — Facultad Regional Mendoza (UTN FRM)  
**Alumno:** Máximo Juan Cruz Quiroga  
**Email:** `maximoj.quiroga@alumnos.frm.utn.edu.ar`  
**Docente:** Sergio Neira  
**Motor:** PostgreSQL 17  
**Base de trabajo:** Esquema masivo Food Store (~20.000 clientes, ~50.000 productos, ~200.000 pedidos, ~500.000 detalles)

---

Esta declaración consolida formalmente el uso de herramientas de Inteligencia Artificial a lo largo de las cuatro partes del **TP4**, siguiendo estrictamente la política institucional de uso responsable de IA de la cátedra de Base de Datos II: *"Medir antes, proponer con IA, medir después y decidir con datos"*.

---

## Parte 1 — Laboratorio: Consultas Analíticas Lentas y Optimización Medida

| Herramienta | Para qué se usó | Prompt / Spec (resumen) | Se aceptó / Se descartó y por qué |
|:---|:---|:---|:---|
| **Kiro / GitHub Copilot** | Analizar los planes de ejecución iniciales de las Consultas A (Facturación mensual por categoría) y B (Ranking de clientes por gasto) e identificar algoritmos de JOIN y cuellos de botella. | Se suministraron los planes reales con `EXPLAIN (ANALYZE, BUFFERS, VERBOSE)` sobre la base masiva, pidiendo desglosar `Parallel Hash Join`, `Hash Join`, `cost`, `actual rows` y buffers. | **Propuestas consideradas solo como hipótesis**. Se conservaron para testing empírico bajo transacciones reversibles. |
| **Kiro / GitHub Copilot** | Evaluar la propuesta de índice para Consulta A: `CREATE INDEX idx_TP4_a_pedidos_fecha ON pedidos (id_pedido) INCLUDE (fecha_pedido)`. | Bloque reversible `BEGIN ... ROLLBACK` con `CREATE INDEX` y `EXPLAIN ANALYZE`. | **ACEPTADA**. El motor adoptó un `Parallel Index Only Scan` con `Heap Fetches: 0`, manteniendo los 2 workers y reduciendo el tiempo de 699.55 ms a 164.25 ms (~4.26x de mejora). |
| **Kiro / GitHub Copilot** | Evaluar la propuesta de índice para Consulta B: `CREATE INDEX idx_TP4_b_pedidos_cliente ON pedidos (id_pedido) INCLUDE (id_cliente)`. | Mismo protocolo de transacción reversible. | **RECHAZADA**. El optimizador ignoró el índice y mantuvo `Parallel Seq Scan` sobre pedidos (304.75 ms vs 305.60 ms). La agregación histórica requiere escanear casi toda la tabla; el cuello de botella era de memoria (`work_mem`). |

*Detalle completo en:* `Parte1/DUIA_Parte1.md` y `Parte1/tabla_comparativa.md`.

---

## Parte 2 — Lectura Crítica de Planes de JOIN Interpretados por IA

| Herramienta | Para qué se usó | Prompt / Spec (resumen) | Se aceptó / Se descartó y por qué |
|:---|:---|:---|:---|
| **Kiro / Claude 3.5 Sonnet** | Generar una explicación conceptual nodo por nodo del plan optimizado de la Consulta A, detallando entradas externas/internas, índices, paralelismo y costo vs tiempo. | Se proporcionó el plan real sin contexto adicional, solicitando identificar las relaciones de build side y probe side en cada `Hash Join`. | **Aceptada como borrador, sujeta a revisión crítica**. Cada afirmación se auditó minuciosamente contra el texto del plan del motor. |
| **GitHub Copilot (VS Code)** | Estructurar la matriz de lectura crítica de 7 afirmaciones evaluadas. | Confrontar hipótesis generadas contra conceptos de arquitectura de PostgreSQL. | **ACEPTADA CON CORRECCIONES**. Se validaron 4 afirmaciones correctas, se corrigió 1 imprecisión sobre `Heap Fetches: 0` (omisión del mapa de visibilidad / `Visibility Map`), se corrigió 1 sobre paralelismo (loops=3 incluye al proceso líder), y se refutó 1 falsedad (costo estimado de 26686 no equivale a milisegundos). |

*Detalle completo en:* `Parte2/DUIA_Parte2.md` y `Parte2/plan_a_explicacion_ia.md`.

---

## Parte 3 — Consultas Resumen, Rankings y Subconsultas con Verificación Formal

| Herramienta | Para qué se usó | Prompt / Spec (resumen) | Se aceptó / Se descartó y por qué |
|:---|:---|:---|:---|
| **Kiro / GitHub Copilot** | Generar la Consulta A: Ranking de clientes por gasto acumulado en dos versiones (V1 con ventana `DENSE_RANK()`, V2 alternativa con subconsulta correlacionada) y verificar con `EXCEPT`. | Especificación formal precisa: ranking por `SUM(dp.cantidad * dp.precio_unitario)`, empates comparten puesto sin saltos en los números posteriores. Sin SELECT *. | **Primera propuesta V2 RECHAZADA**. La IA propuso `COUNT(*) + 1`, resultando en 19.433 filas de discrepancia en el `EXCEPT` bidireccional (emulaba `RANK()` con saltos). Tras corregir a `COUNT(DISTINCT ...) + 1`, el `EXCEPT` confirmó 0 filas en ambos sentidos (**ACEPTADA**). |
| **Kiro / GitHub Copilot** | Generar la Consulta B: Productos activos con precio mayor al promedio de su categoría en dos versiones (V1 subconsulta correlacionada en WHERE, V2 con pre-agregación grupal). | Especificación formal: filtrar `activo = TRUE` en productos y categorías, calcular `AVG(precio_actual)`. Validar equivalencia con `EXCEPT`. | **ACEPTADA DE ENTRADA**. Ambas versiones produjeron 0 filas de discrepancia en el `EXCEPT`. La versión pre-agregada demostró ser órdenes de magnitud más eficiente ($O(N)$ vs $O(N \cdot M)$). |

*Detalle completo en:* `Parte3/DUIA_Parte3.md`, `Parte3/consulta_a_ranking.sql` y `Parte3/consulta_b_subconsulta.sql`.

---

## Parte 4 — Competencia de Optimización entre Equipos

| Herramienta | Para qué se usó | Prompt / Spec (resumen) | Se aceptó / Se descartó y por qué |
|:---|:---|:---|:---|
| **Kiro / GitHub Copilot** | Diagnosticar el cuello de botella del plan en la consulta de competencia: Top 3 productos por facturación dentro de cada categoría (últimos 6 meses). | Plan completo de `EXPLAIN (ANALYZE, BUFFERS, VERBOSE)` pegado, solicitando aislar el operador dominante por tiempo real e I/O. | **ACEPTADA**. Identificó que el factor crítico era el operador `Sort` con spill a disco (`external merge Disk: 3576kB`) en los 2 workers, no los escaneos secuenciales. |
| **Kiro / GitHub Copilot** | Evaluar la alternativa no invasiva `SET LOCAL work_mem = '8MB'` dentro de una transacción. | Ejecutar la consulta con ajuste de memoria local. | **ACEPTADA**. El Sort pasó a ejecutarse en RAM (`quicksort Memory: 5883kB`), bajando el tiempo promedio de 621.0 ms a 571.4 ms sin alterar índices ni el esquema. |
| **Kiro / GitHub Copilot** | Probar la creación de un índice parcial sobre la fecha de pedidos: `idx_pedidos_fecha_reciente (fecha_pedido DESC)`. | Probar el índice en transacción combinado con work_mem y medir el impacto. | **RECHAZADA TRAS CONTROL DE SESGO DE ORDEN**. Una primera medición en bloque (AAA-BBB) sugería 48 ms de ventaja; al aplicar el protocolo científico de mediciones intercaladas A-B-A-B-A-B, ambos promedios empataron exactamente en 571.4 ms. La supuesta ventaja era un falso positivo por caché caliente. |

*Detalle completo en:* `Parte4/DUIA_Parte4.md`, `Parte4/analisis_optimizacion.md` y `Parte4/registro_competencia.md`.

---

## Reflexión Metodológica Global

El trabajo realizado en este TP4 pone de manifiesto una lección clave para el ejercicio profesional de la ingeniería de datos: **la IA generativa es una poderosa asistente para la exploración de hipótesis y la escritura de sintaxis, pero un pésimo evaluador de rendimiento en ausencia de supervisión humana**.

1. **En la Parte 2**, la IA confundió conceptos fundamentales como el mapa de visibilidad en los escaneos de solo índice y la escala adimensional de costos.
2. **En la Parte 3**, la IA generó una subconsulta correlacionada que parecía impecable a simple vista pero violaba la especificación matemática de `DENSE_RANK()`, error que solo el operador `EXCEPT` pudo desenmascarar.
3. **En la Parte 4**, una propuesta de índice pareció exitosa hasta que un diseño experimental riguroso con control de sesgo de orden (mediciones intercaladas) demostró que el beneficio era un espejismo producido por la memoria caché.

En conclusión, la metodología de la cátedra —medir empíricamente, justificar en el plan real y documentar los descartes con el mismo celo que los aciertos— se consolidó como la única vía fiable para optimizar sistemas de bases de datos.

