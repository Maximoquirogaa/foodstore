# TP6 — Parte 2: Desnormalización Controlada del Top Diario de Categorías

**Materia:** Base de Datos II  
**Trabajo Práctico:** TP6 — FNBC y Desnormalización Controlada  
**Proyecto:** Food Store (UTN FRM)  
**Alumno:** Máximo Juan Cruz Quiroga  
**Docente:** Sergio Neira  
**Motor:** PostgreSQL 17.11  
**Base de trabajo:** `foodstore_copia_trabajo` (200.000 pedidos, 200.000 detalles, 50.000 productos, 5 categorías)

---

## 1. Problema de Negocio y Diagnóstico Inicial

La aplicación de comercio electrónico Food Store requiere visualizar en el panel de administración el **Top diario de categorías por facturación** con actualización en tiempo real.

### La Consulta Normalizada Original:
Cruza 4 tablas: `detalles_pedido`, `pedidos`, `productos` y `categorias`, aplicando el filtro diario sobre `pedidos.fecha_pedido` y contemplando el borrado lógico (`eliminado = FALSE` en pedidos y detalles).

### Diagnóstico del Plan Normalizado:
- **Medición aislada previa (`medir_top_categorias_antes.sql`):** `Planning Time: 6.386 ms`, `Execution Time: 148.939 ms`, `Buffers: shared hit=4791 read=515` (5.306 bloques totales).
- **Rondas intercaladas A1–A3 (`tp_desnormalizacion_top_categorias.sql`):** **109.758 ms** promedio (**R1:** `183.256 ms`, **R2:** `77.299 ms`, **R3:** `68.720 ms`; promedio en caliente R2–R3: `73.010 ms`).
- **Buffers promedio (en caché):** `shared hit = 5854` bloques (R1: `5853`, R2: `5853`, R3: `5856`).
- **Cuello de Botella:** Sin las columnas desnormalizadas en `detalles_pedido`, el motor debe unir `pedidos` del día con `detalles_pedido` y `productos` para resolver la categoría y el estado de eliminación del pedido padre.

---

## 2. Estrategia de Desnormalización Controlada

Para cumplir con la exigencia de **actualización inmediata en tiempo real sin desfase**, una vista materializada con refresco periódico no es admisible (presentaría retraso hasta el próximo refresco). 

Se optó por el patrón de **Columnas Redundantes Precalculadas con Disparadores (Triggers)**:
1. Se incorporan tres columnas caché en `detalles_pedido`:
   - `fecha_pedido_cache` (`TIMESTAMPTZ`): Copia de `pedidos.fecha_pedido`.
   - `id_categoria_cache` (`BIGINT`): Copia de `productos.id_categoria`.
   - `pedido_eliminado_cache` (`BOOLEAN`): Copia de `pedidos.eliminado`.
2. Se crea un índice B-Tree sobre la fecha copiada: `idx_TP6_detalle_fecha_cache ON detalles_pedido (fecha_pedido_cache)`.
3. Se implementan tres triggers PL/pgSQL transaccionales:
   - `trg_sincronizar_cache_detalle`: En INSERT/UPDATE de detalles_pedido, autocompleta el caché desde pedidos y productos.
   - `trg_propagar_cambios_pedido`: En UPDATE de pedidos, propaga cambios de fecha o estado eliminado a sus detalles hijos.
   - `trg_propagar_categoria_producto`: En UPDATE de productos, actualiza la categoría asociada en los detalles.

---

## 3. La Consulta Desnormalizada

Gracias a las columnas desnormalizadas, la consulta se simplifica radicalmente:
- Se eliminan por completo los JOINs con `pedidos` y `productos`.
- Se realiza un único `INNER JOIN` con `categorias` para obtener el nombre descriptivo vigente.
- El filtro de fecha y estado se evalúa directamente sobre `detalles_pedido` utilizando el índice B-Tree:

```sql
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
```

---

## 4. Resultados Comparativos y Métricas

| Métrica | Antes (Consulta Normalizada) | Después (Consulta Desnormalizada) | Impacto / Mejora |
|:---|---:|---:|:---:|
| **Tiempo de Ejecución Promedio (3 rondas intercaladas)** | **109.758 ms** | **1.867 ms** | **~58.79x más rápido** (reducción del 98.30%) |
| **Detalle por ronda (R1 / R2 / R3)** | 183.256 / 77.299 / 68.720 ms | 2.515 / 1.303 / 1.783 ms | En caliente (R2–R3): 73.010 → 1.543 ms (**~47.32x**) |
| **Búferes leídos en caché (`shared hit`)** | **5.854 bloques** | **499 bloques** | **Reducción del 91.48%** en lecturas lógicas |
| **Estrategia de Planificación** | Escaneo + joins sobre `pedidos`, `detalles_pedido` y `productos` | `Bitmap Index Scan` en `idx_tp6_detalle_fecha_cache` + `Memoize` sobre `categorias` | Supresión total de accesos a `pedidos` y `productos` |

---

## 5. Auditoría de Sincronización y Equivalencia Formal

- **Pruebas de Sincronización:** Se ejecutaron pruebas secuenciales en savepoint modificando fechas y estados en pedidos y verificando la propagación inmediata e íntegra hacia `detalles_pedido`.
- **Equivalencia Relacional Formal:** Se contrastaron ambas consultas mediante el operador `EXCEPT`, confirmando **0 filas de discrepancia**. La desnormalización no alteró en lo absoluto la veracidad ni la semántica del resultado de negocio.

---

## 6. Análisis de Costo-Beneficio (Trade-off de Desnormalización)

1. **Ventajas Obtenidas:**
   - La consulta analítica más crítica del panel directivo pasó de **109.758 ms** (y **148.939 ms** en la medición previa aislada) a **1.867 ms**.
   - Se redujo drásticamente la contención de memoria en el buffer pool (de **5.854** a **499** bloques).
2. **Costos y Penalizaciones Asumidas:**
   - **Sobrecosto de almacenamiento:** 3 nuevas columnas en las **200.000** filas de `detalles_pedido` + 1 índice B-Tree (`idx_tp6_detalle_fecha_cache`).
   - **Sobrecosto de escritura (DML):** Cada `INSERT` o `UPDATE` en `detalles_pedido`, `pedidos` o `productos` debe ejecutar las funciones de los triggers para mantener la coherencia transaccional.
   - **Mantenibilidad:** Requiere supervisión activa de los disparadores para evitar inconsistencias lógicas si se ejecutan procesos masivos por fuera del motor.

