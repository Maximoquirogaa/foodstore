# Tabla Comparativa y Evaluación - TP4 Parte 1

**Materia:** Base de Datos II  
**Proyecto:** Food Store (UTN FRM)  
**Alumno:** Máximo Juan Cruz Quiroga  
**Docente:** Sergio Neira  
**Motor:** PostgreSQL 17  
**Entorno de prueba:** Carga masiva (20.000 clientes, 50.000 productos, 200.000 pedidos, 500.000 detalles).  
**Método:** `EXPLAIN (ANALYZE, BUFFERS, VERBOSE)` evaluado dentro de transacciones reversibles (`BEGIN ... ROLLBACK`).

---

## 1. Tabla de Resultados Comparativos

| Consulta | JOIN antes | Cambio probado | JOIN después | Tiempo antes | Tiempo después | Mejora | Decisión |
|:---|:---|:---|:---|---:|---:|:---:|:---:|
| **Consulta A**<br>(Facturación por categoría y mes) | `Parallel Hash Join` (`dp`-`pe`),<br>`Hash Join` (`dp`-`p`),<br>`Hash Join` (`p`-`c`),<br>con 2 workers | `CREATE INDEX idx_TP4_a_pedidos_fecha ON pedidos (id_pedido) INCLUDE (fecha_pedido)` | Se mantuvieron los mismos algoritmos de JOIN y los 2 workers. Acceso a `pedidos` pasó a `Parallel Index Only Scan` con `Heap Fetches: 0` | 699.550 ms | 164.254 ms | **~4.26x** | **ACEPTADA** |
| **Consulta B**<br>(Ranking clientes por gasto) | `Parallel Hash Join` (`dp`-`pe`) y `Hash Join` (resultado-`cl`), con 2 workers | `CREATE INDEX idx_TP4_b_pedidos_cliente ON pedidos (id_pedido) INCLUDE (id_cliente)` | Sin cambios de JOIN ni de paralelismo. PostgreSQL ignoró el índice y mantuvo `Parallel Seq Scan` sobre `pedidos` | 304.753 ms | 305.604 ms | **Nula (0%)** | **RECHAZADA** |

---

## 2. Evidencia y Análisis Técnico

### Consulta A: Aceptación con Fundamentación Empírica
1. **Conservación de Algoritmos:** No hubo alteración en la tipología de los JOINs; el motor mantuvo la estrategia de `Hash Join` y `Parallel Hash Join` debido a la volumetría de filas a cruzar.
2. **Impacto de la Optimización:** La ganancia de tiempo proviene íntegramente del operador de acceso a la tabla `pedidos`. En el plan base, `pedidos` requería un Bitmap Heap Scan con lectura directa de páginas en heap. Con el índice cubriente `idx_TP4_a_pedidos_fecha (id_pedido) INCLUDE (fecha_pedido)`, el planificador conmutó a `Parallel Index Only Scan`.
3. **Ausencia de Accesos al Heap (`Heap Fetches: 0`):** Al contener el índice tanto la clave de enlace (`id_pedido`) como la fecha agregada (`fecha_pedido`), y al estar las páginas marcadas como visibles en el mapa de visibilidad (`Visibility Map`), PostgreSQL satisfizo la consulta directamente desde el árbol B.
4. **Resultado:** El tiempo de ejecución se redujo de **699.550 ms a 164.254 ms**.

### Consulta B: Descarte Fundamentado y Hallazgo de Memoria
1. **Ignorancia del Índice:** El índice cubriente propuesto por la IA no fue seleccionado por el optimizador de costos. Dado que la consulta calcula el gasto total acumulado de toda la base histórica sin ningún filtro selectivo sobre los pedidos, el motor debe leer la totalidad de los 200.000 pedidos. Un `Parallel Seq Scan` que lee bloques secuenciales contiguos es sustancialmente más rápido que descender por un B-Tree.
2. **Cuello de Botella Real (Spill a Disco):** El análisis detallado de búferes reveló que el operador `HashAggregate` realizaba 5 batches y volcaba aproximadamente `720 kB` de datos a disco temporal (`Disk Usage: 720kB`) por superar el límite por defecto de `work_mem = 4MB`.
3. **Verificación Alternativa:** Se probó elevar la memoria local de sesión a `64MB` (`SET LOCAL work_mem = '64MB'`). Esto eliminó por completo el derrame a disco (`Batches: 1`, `Disk Usage: 0kB`), bajando el tiempo de ejecución a **250.280 ms** sin requerir ningún índice. Se descarta la creación del índice para no sobrecargar el mantenimiento de escrituras (INSERT/UPDATE).

---

## 3. Protocolo de Reversibilidad
Todas las mediciones se realizaron dentro de bloques transaccionales que culminaron con `ROLLBACK`, preservando la integridad estricta del entorno de base de datos masiva del proyecto Food Store.

