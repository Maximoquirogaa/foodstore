# Informe de Mediciones Técnicas — TP5 (Índices, Costo de Escritura y Vistas Materializadas)

**Materia:** Base de Datos II  
**Trabajo Práctico:** TP5 — Plan de Indexado, Vistas y Vistas Materializadas  
**Facultad:** Universidad Tecnológica Nacional — Facultad Regional Mendoza (UTN FRM)  
**Alumno:** Máximo Juan Cruz Quiroga  
**Email:** `maximoj.quiroga@alumnos.frm.utn.edu.ar`  
**Docente:** Sergio Neira  
**Motor:** PostgreSQL 17  
**Base de trabajo:** Esquema masivo Food Store (~20.000 clientes, ~50.000 productos, ~200.000 pedidos, ~500.000 detalles)

---

## 1. Parte A — Plan de Indexado y Medición de Impacto

### Caso 1 — Q5: Ranking Histórico de Clientes por Gasto Acumulado (`DENSE_RANK`)

**Consulta Evaluada:**
```sql
SELECT
    c.nombre || ' ' || c.apellido AS cliente,
    SUM(dp.cantidad * dp.precio_unitario) AS total_gastado,
    DENSE_RANK() OVER (ORDER BY SUM(dp.cantidad * dp.precio_unitario) DESC) AS puesto
FROM clientes c
JOIN pedidos p ON p.id_cliente = c.id_cliente
JOIN detalles_pedido dp ON dp.id_pedido = p.id_pedido
GROUP BY c.id_cliente, c.nombre, c.apellido
ORDER BY puesto;
```

**Diagnóstico Inicial (Baseline):**
- Tiempo de ejecución base: **527.637 ms**.
- El operador `Finalize HashAggregate` reporta derrame temporal a disco (`Batches: 5, Disk Usage: 1568kB`) debido a que la agregación de todos los clientes excede el límite estándar de memoria (`work_mem = 4MB`).

#### Candidato A — `CREATE INDEX idx_pedidos_cliente_q5 ON pedidos (id_cliente)`
- **Propuesta:** Sugerida por la IA para acelerar el cruce entre `pedidos` y `clientes`.
- **Medición Experimental en 3 Rondas Intercaladas:**
  * Ronda 1: Baseline 795.5 ms | Con Índice 417.2 ms (efecto arranque en frío)
  * Ronda 2: Baseline 433.2 ms | Con Índice 409.9 ms
  * Ronda 3: Baseline 385.9 ms | Con Índice 405.5 ms
  * **Promedio estabilizado:** Baseline **409.6 ms** vs Con Índice **407.7 ms** (diferencia de -0.4%, puro ruido estadístico).
- **Inspección del Plan:** En todas las corridas, el optimizador mantuvo el `Parallel Seq Scan` sobre `pedidos`. El índice no fue seleccionado porque la consulta debe acumular el gasto de los 200.000 pedidos históricos.
- **Decisión:** **DESCARTADO POR SOBREINDEXACIÓN Y BAJA SELECTIVIDAD**.

#### Candidato B — `CREATE INDEX idx_detalles_pedido_id_pedido ON detalles_pedido (id_pedido)`
- **Propuesta:** Sugerida por la IA para acelerar el enlace con los detalles de compra.
- **Evidencia Empírica de Redundancia:**
  * La tabla `detalles_pedido` ya cuenta con la clave primaria compuesta `PRIMARY KEY (id_pedido, id_producto)`.
  * En una búsqueda puntual (`WHERE id_pedido = 100`), PostgreSQL ya utiliza la clave primaria (`detalles_pedido_pkey`) resolviendo en **0.031 ms**.
  * Al medir la consulta Q5 con el índice secundario propuesto dentro de una transacción, el tiempo fue de **615.6 ms** contra **612.2 ms** sin el índice. El optimizador prefirió el escaneo secuencial paralelo y no utilizó el índice.
- **Decisión:** **DESCARTADO POR REDUNDANCIA ESTRUCTURAL CON LA PK**.

#### Intervención Aceptada — Ajuste de Memoria de Sesión (`SET LOCAL work_mem = '16MB'`)
- Al elevar la memoria local de la sesión de 4 MB a 16 MB:
  * El operador `HashAggregate` redujo sus lotes de 5 a **1 solo batch**, eliminando el spill a disco (`Disk Usage: 0kB`).
  * El tiempo promedio se redujo a **302.0 ms** (**mejora neta del ~26.3%**).
- **Decisión:** **ACEPTADA**. Se optimiza la consulta mediante configuración de sesión sin alterar el esquema ni añadir índices innecesarios.

---

### Caso 2 — Q6: Productos con Precio Superior al Promedio de su Categoría

**Consulta Evaluada (Subconsulta Correlacionada en WHERE):**
```sql
SELECT p.nombre, p.precio_actual
FROM productos p
JOIN categorias cat ON cat.id_categoria = p.id_categoria AND cat.activo = TRUE
WHERE p.activo = TRUE
  AND p.precio_actual > (
      SELECT AVG(p2.precio_actual)
      FROM productos p2
      WHERE p2.activo = TRUE AND p2.id_categoria = p.id_categoria
  )
ORDER BY cat.id_categoria, p.precio_actual DESC;
```

**Índice Candidato Probado:**
```sql
CREATE INDEX idx_productos_categoria_precio_activo
    ON productos (id_categoria, precio_actual DESC)
    WHERE activo = TRUE;
```

**Resultados de Medición:**
- **Antes (Baseline):** 271.205 segundos (~4.5 minutos). SubPlan 1 resolvía mediante `Seq Scan` sobre 50.000 tuplas en cada iteración.
- **Después (Con Índice):** 158.728 segundos (~2.6 minutos). SubPlan 1 pasó a resolver mediante `Index Only Scan` con `Heap Fetches: 0`.
- **Mejora Observada:** **~41.5% de reducción de tiempo**.
- **Decisión:** **ACEPTADO**.
- **Salvedad Metodológica Crítica:** El índice acelera el escaneo de cada categoría individual, pero **no resuelve el cuello de botella algorítmico**: la subconsulta se ejecuta 50.003 veces (una por cada producto). La solución definitiva de producción es la reescritura mediante `JOIN` con pre-agregación grupal (probada en TP6), que resuelve en menos de 45 milisegundos.

---

### Caso 3 — Q4: Top 3 Productos por Facturación (Evaluación de Índice BRIN)

**Estudio de Viabilidad de Índice BRIN en `pedidos(fecha_pedido)`:**
- Un índice BRIN (*Block Range Index*) es extremadamente compacto y eficiente cuando existe una correlación física estricta entre el orden físico de las páginas en disco y el orden lógico de los datos.
- **Consulta de Catálogo (`pg_stats`):**
  ```sql
  SELECT correlation FROM pg_stats WHERE tablename = 'pedidos' AND attname = 'fecha_pedido';
  ```
- **Resultado:** `correlation = 0.0051`.
- **Evaluación:** La correlación es prácticamente nula. Al haberse generado los pedidos con fechas aleatorias durante la carga masiva, cada bloque físico contiene pedidos de todas las épocas, impidiendo que el índice BRIN descarte rangos de bloques.
- **Decisión:** **DESCARTADO POR INEFICACIA MATEMÁTICA DEMOSTRADA**.

---

### Caso 4 — Q2: Catálogo de Productos por Categoría y Rango de Precio

**Consulta Evaluada:**
```sql
SELECT id_producto, nombre, precio_actual, stock
FROM productos
WHERE id_categoria = 1 AND precio_actual BETWEEN 1000 AND 3000
ORDER BY precio_actual;
```

**Índice B-Tree Compuesto Aplicado:**
```sql
CREATE INDEX idx_productos_categoria_precio
    ON productos (id_categoria, precio_actual);
```

**Resultados de Medición en 3 Rondas:**
| Ronda | Baseline (Seq Scan + Sort) | Con Índice (Index Scan) | Factor de Mejora |
|:---:|:---:|:---:|:---:|
| 1 | 4.921 ms | 0.281 ms | **17.5x** |
| 2 | 4.654 ms | 0.274 ms | **17.0x** |
| 3 | 4.582 ms | 0.271 ms | **16.9x** |
| **Promedio** | **4.719 ms** | **0.275 ms** | **~17.1x** |

- **Análisis de Búferes:** Las lecturas en memoria se redujeron de 443 bloques compartidos a solo **42 bloques** (reducción del 90.5%).
- **Eliminación del Sort:** Al estar indexado por `(id_categoria, precio_actual)`, el motor obtiene los datos ya pre-ordenados, eliminando por completo el operador `Sort`.
- **Decisión:** **ACEPTADO EN FIRME**.

---

## 2. Medición del Costo de Escritura (Penalización en INSERTs)

Para evaluar el impacto de la sobreindexación en operaciones de escritura (`INSERT`), se midió el tiempo requerido para insertar 10.000 tuplas en `productos` y 20.000 tuplas en `detalles_pedido`:

### Inserción Masiva en `productos` (10.000 tuplas):
1. **Solo con Clave Primaria:** **115.4 ms**.
2. **Con 1 Índice Secundario (`idx_productos_categoria_precio`):** **154.1 ms** (+33.5% de sobrecosto).
3. **Con 2 Índices Secundarios (+ `idx_productos_categoria_precio_activo`):** **198.8 ms** (+72.2% de sobrecosto).

### Inserción Masiva en `detalles_pedido` (20.000 tuplas):
1. **Solo con Clave Primaria Compuesta:** **235.1 ms**.
2. **Con Índice Secundario Redundante en `id_pedido`:** **348.6 ms** (+48.3% de penalización innecesaria).

**Conclusión:** Cada índice añadido degrada sustancialmente el rendimiento de las operaciones DML de escritura. Los índices solo deben crearse si brindan un beneficio de lectura contundente y medido.

---

## 3. Parte C — Vista Materializada (`mv_resumen_ventas_categoria_mes`)

### 1. Comparación de Rendimiento Directo

| Métrica | Consulta Directa (Cruza 4 tablas) | Lectura de Vista Materializada | Impacto / Mejora |
|:---|:---|:---|:---:|
| **Tiempo de Ejecución** | **976.120 ms** | **0.054 ms** (54 µs) | **~18.076x más rápido** |
| **Bloques de Búfer Leídos** | 9.870 páginas (shared hit + read) | **2 bloques** | Reducción del 99.98% |
| **Operadores Involucrados** | Hash Joins, Parallel Scans, Aggregate | Simple `Seq Scan` sobre 60 filas | Mínimo consumo de CPU |

### 2. Análisis de Bloqueos y Refresco Concurrente

- **`REFRESH MATERIALIZED VIEW` (Estándar):** Demora ~1120 ms y adquiere un bloqueo **`AccessExclusiveLock`**, impidiendo que cualquier usuario ejecute consultas `SELECT` sobre la vista hasta que finalice.
- **`REFRESH MATERIALIZED VIEW CONCURRENTLY`:** Demora ~1450 ms y adquiere un bloqueo **`ExclusiveLock`**. **No bloquea las lecturas concurrentes**. Los usuarios pueden seguir consultando reportes analíticos sin interrupción mientras la vista se actualiza en segundo plano. Requiere obligatoriamente un índice único (`idx_mv_resumen_ventas_categoria_mes`).

### 3. Política de Mantenimiento Recomendada
Dado que los reportes de ventas mensuales analizan tendencias históricas y no requieren consistencia transaccional al segundo, la estrategia recomendada es programar la ejecución nocturna de `REFRESH MATERIALIZED VIEW CONCURRENTLY` (por ejemplo, a las 02:00 AM) mediante un cron o demonio de tareas programadas.

