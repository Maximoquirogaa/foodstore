# Parte 2 - Lectura Crítica de Planes de JOIN Interpretados por IA

**Materia:** Base de Datos II  
**Trabajo Práctico:** TP4 — Optimización de Consultas Analíticas, Joins y Subconsultas  
**Proyecto:** Food Store (UTN FRM)  
**Alumno:** Máximo Juan Cruz Quiroga  
**Docente:** Sergio Neira  
**Motor:** PostgreSQL 17  

---

## 1. Objetivo y Selección del Plan
Se seleccionó el plan optimizado de la **Consulta A** (Facturación mensual por categoría activa) debido a su riqueza estructural: combina tres niveles consecutivos de `JOIN`, ejecución paralela con múltiples workers, agregaciones por lotes, ordenamiento incremental y un acceso cubriente mediante `Parallel Index Only Scan`. 

Esta complejidad proporciona el escenario ideal para auditar la precisión conceptual de una IA generativa, contrastando sus afirmaciones contra la evidencia fáctica del motor relacional.

---

## 2. Consulta y Plan Suministrado a la IA

### Consulta SQL Evaluada:
```sql
SELECT
    c.id_categoria,
    c.nombre AS categoria,
    DATE_TRUNC('month', pe.fecha_pedido) AS mes,
    SUM(dp.cantidad * dp.precio_unitario) AS total_facturado
FROM categorias AS c
JOIN productos AS p ON p.id_categoria = c.id_categoria
JOIN detalles_pedido AS dp ON dp.id_producto = p.id_producto
JOIN pedidos AS pe ON pe.id_pedido = dp.id_pedido
WHERE c.activo = TRUE
GROUP BY
    c.id_categoria,
    c.nombre,
    DATE_TRUNC('month', pe.fecha_pedido)
ORDER BY
    mes,
    total_facturado DESC;
```

### Plan Real Obtenido (`EXPLAIN ANALYZE`):
```text
Incremental Sort (cost=15617.57..26686.93 rows=61812 width=166)
  Sort Key: (date_trunc('month'::text, pe.fecha_pedido)), (sum((dp.cantidad * dp.precio_unitario))) DESC
  Presorted Key: (date_trunc('month'::text, pe.fecha_pedido))
  -> Finalize GroupAggregate (cost=15589.45..23621.14 rows=61812 width=166)
       Group Key: c.id_categoria, (date_trunc('month'::text, pe.fecha_pedido))
       -> Gather Merge (cost=15589.45..22178.86 rows=51510 width=166)
            Workers Planned: 2  Workers Launched: 2
            -> Partial GroupAggregate (cost=14589.43..15233.31 rows=25755 width=166)
                 Group Key: c.id_categoria, (date_trunc('month'::text, pe.fecha_pedido))
                 -> Sort (cost=14589.43..14653.82 rows=25755 width=158)
                      Sort Key: (date_trunc('month'::text, pe.fecha_pedido)), c.id_categoria
                      -> Hash Join (cost=3557.05..10851.05 rows=25755 width=158)
                           Hash Cond: (dp.id_producto = p.id_producto)
                           -> Parallel Hash Join (cost=1825.22..8604.12 rows=51509 width=42)
                                Hash Cond: (dp.id_pedido = pe.id_pedido)
                                -> Parallel Seq Scan on detalles_pedido dp
                                   actual rows=166203 loops=3
                                -> Parallel Hash
                                     -> Parallel Index Only Scan using idx_TP4_a_pedidos_fecha on pedidos pe
                                          actual rows=66668 loops=3
                                          Heap Fetches: 0
                           -> Hash
                                -> Hash Join (cost=16.66..1419.31 rows=25002 width=140)
                                     Hash Cond: (p.id_categoria = c.id_categoria)
                                     -> Seq Scan on productos p
                                        actual rows=50003 loops=3
                                     -> Seq Scan on categorias c
                                        Filter: c.activo
                                        actual rows=5 loops=3
```

---

## 3. Explicación Técnica y Desglose Nodo por Nodo

### 3.1 Flujo General de Ejecución
El optimizador procesa las relaciones desde los nodos inferiores hacia la raíz. Primero une en paralelo `detalles_pedido` con `pedidos`. En paralelo, genera una tabla hash uniendo `productos` con las `categorias` activas. Luego une ambos resultados intermedios mediante un `Hash Join`, efectúa una agregación parcial en cada worker, combina los flujos con `Gather Merge`, consolida el `GroupAggregate` y finalmente aplica un `Incremental Sort` aprovechando que los datos ya venían parcialmente ordenados por mes.

### 3.2 Análisis de los Nodos de JOIN (Roles Externo e Interno)
En un algoritmo `Hash Join`, la relación **interna (build side)** es aquella que se escanea primero para construir la tabla hash en memoria; la relación **externa (probe side)** es la que se escanea posteriormente fila por fila para sondear dicha tabla.

1. **JOIN 1: `Parallel Hash Join` (`detalles_pedido` con `pedidos`):**
   - **Entrada Interna (Build Side):** `pedidos pe`. Se escanea mediante `Parallel Index Only Scan` y se carga en memoria compartida a través de `Parallel Hash`.
   - **Entrada Externa (Probe Side):** `detalles_pedido dp`. Se escanea secuencialmente en paralelo (`Parallel Seq Scan`) y sondea la tabla hash de pedidos.
   - **Condición:** `(dp.id_pedido = pe.id_pedido)`.

2. **JOIN 2: `Hash Join` (`productos` con `categorias`):**
   - **Entrada Interna (Build Side):** `categorias c`. Se filtran las categorías activas (`Filter: c.activo`) y se cargan en el hash. Al ser una tabla diminuta (5 filas), el hash cabe perfectamente en memoria mínima (9kB).
   - **Entrada Externa (Probe Side):** `productos p`. Se realiza un barrido secuencial (`Seq Scan`) sondeando la categoría asociada.
   - **Condición:** `(p.id_categoria = c.id_categoria)`.

3. **JOIN 3: `Hash Join` (Resultado de JOIN 1 con Resultado de JOIN 2):**
   - **Entrada Interna (Build Side):** El subárbol de `productos` cruzado con `categorias`.
   - **Entrada Externa (Probe Side):** El flujo masivo resultante de cruzar `detalles_pedido` con `pedidos`.
   - **Condición:** `(dp.id_producto = p.id_producto)`.

### 3.3 Mecanismo del Índice y `Heap Fetches: 0`
El operador `Parallel Index Only Scan using idx_TP4_a_pedidos_fecha` reporta `Heap Fetches: 0`. Esto certifica que:
1. El índice cubriente `(id_pedido) INCLUDE (fecha_pedido)` contiene todos los atributos que la consulta requiere de la tabla `pedidos`.
2. Las páginas de datos correspondientes en la tabla están marcadas como **completamente visibles** en el mapa de visibilidad (`Visibility Map`), producto de un `VACUUM` o `ANALYZE` previo. Si las páginas tuvieran transacciones recientes no congeladas, el motor se vería forzado a acudir al Heap para verificar visibilidad MVCC, resultando en un valor mayor a cero.

### 3.4 Paralelismo y Concurrencia
- `Workers Planned: 2` y `Workers Launched: 2`: Indican que el planificador estimó óptimo usar 2 procesos secundarios y que el sistema operativo/PostgreSQL dispuso de los recursos para crearlos inmediatamente.
- En los nodos paralelos aparece `loops=3` porque participan los 2 workers trabajadores más el proceso líder (coordinador).

### 3.5 Discrepancia entre Costo Estimado y Tiempo Real
- El costo en la raíz es `cost=15617.57..26686.93`. Estos números son unidades arbitrarias de planificación (donde 1.0 suele representar la lectura de una página secuencial en disco, `seq_page_cost`), **no representan milisegundos**.
- El tiempo real de ejecución medido por instrumentación de hardware fue `164.254 ms`. No existe fórmula directa de conversión matemática entre ambas magnitudes.

---

## 4. Tabla de Lectura Crítica de Afirmaciones de la IA

| # | Afirmación generada por la IA | ¿Correcta? | Corrección técnica y evidencia del plan real |
|:---:|:---|:---:|:---|
| **1** | *"En el primer Parallel Hash Join, detalles_pedido es la tabla externa y pedidos es la interna."* | **SÍ** | **Correcto.** El plan indica `Parallel Hash` sobre `pedidos pe` (lado que construye la tabla hash / build side), mientras que `detalles_pedido dp` es la entrada izquierda que sondea (probe side). |
| **2** | *"El plan utiliza un Hash Join para unir productos con categorias antes de combinarlo con los pedidos."* | **SÍ** | **Correcto.** El nodo `Hash Join (cost=16.66..1419.31)` genera el conjunto de productos con sus categorías activas en el subárbol derecho antes de unirse al flujo de ventas. |
| **3** | *"En la unión de productos y categorias, categorias es la relación interna porque tiene filtro activo."* | **SÍ** | **Correcto.** `categorias c` aparece bajo el nodo `Hash`, siendo la relación build side cargada en memoria para validar `c.id_categoria`. |
| **4** | *"El índice idx_TP4_a_pedidos_fecha es utilizado porque su primera columna coincide con la condición de JOIN id_pedido."* | **SÍ** | **Correcto.** El índice fue definido sobre `(id_pedido) INCLUDE (fecha_pedido)`. Al ser `id_pedido` la clave del árbol B, permite la búsqueda y navegación directa en el scan. |
| **5** | *"Heap Fetches: 0 demuestra que el índice es cubriente y por eso ningún Index Only Scan necesita jamás acceder a la tabla."* | **PARCIALMENTE** | **Imprecisión conceptual importante.** Que el índice sea cubriente es condición *necesaria pero no suficiente*. `Heap Fetches: 0` ocurre porque el **Visibility Map** garantiza que todas las tuplas de esas páginas son visibles para todas las transacciones actuales. Si hubiera escrituras concurrentes sin vaciado, habría fetches al heap a pesar de ser cubriente. |
| **6** | *"Workers Launched: 2 confirma que la consulta se ejecutó exclusivamente en dos procesos independientes."* | **NO** | **Incorrecto.** Se lanzaron 2 workers auxiliares, pero el proceso coordinador (líder) también ejecuta trabajo útil en los scans paralelos, evidenciado en la métrica `loops=3` del `Parallel Seq Scan`. |
| **7** | *"El cost final de 26686.93 indica que la consulta demoró aproximadamente 26.6 segundos en su estimación teórica."* | **NO** | **Error grave clásico de la IA.** El `cost` es una métrica interna adimensional de esfuerzo computacional ponderado (I/O de disco + ciclos de CPU). No tiene equivalencia temporal directa. El tiempo real medido fue de solo `164.254 ms`. |

---

## 5. Conclusiones Metodológicas para la Defensa
1. **Predominio del Hash Join:** La consulta no utiliza ni `Nested Loop` (ineficiente para 500.000 registros) ni `Merge Join` (que exigiría ordenar previamente ambas fuentes masivas).
2. **Naturaleza del Salto de Rendimiento:** La aceleración de ~4.26x no derivó de un cambio de algoritmo de JOIN, sino del pasaje de lectura de Heap a lectura exclusiva de páginas de índice (`Index Only Scan`) en la tabla `pedidos`.
3. **Rol del Auditor Humano:** La lectura crítica demuestra que la IA comete errores sutiles (ignorar el mapa de visibilidad en `Heap Fetches`) y errores graves de concepto (interpretar costo como tiempo). La validación rigurosa contra el plan real es indispensable.

