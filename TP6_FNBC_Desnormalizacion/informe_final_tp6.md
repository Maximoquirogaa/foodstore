# Informe Consolidado Final — TP6 (FNBC y Desnormalización Controlada)

**Materia:** Base de Datos II  
**Trabajo Práctico:** TP6 — Normalización en FNBC y Estrategias de Desnormalización  
**Facultad:** Universidad Tecnológica Nacional — Facultad Regional Mendoza (UTN FRM)  
**Alumno:** Máximo Juan Cruz Quiroga  
**Email:** `maximoj.quiroga@alumnos.frm.utn.edu.ar`  
**Docente:** Sergio Neira  
**Motor:** PostgreSQL 17.11  
**Base de trabajo:** `foodstore_copia_trabajo` (200.000 pedidos, 200.000 detalles, 50.000 productos, 20.000 clientes, 5 categorías)

---

## 1. Resumen Ejecutivo

El presente trabajo aborda los dos extremos complementarios del diseño relacional avanzado en sistemas de bases de datos masivas:
1. **Parte 1 (Diseño Lógico Puro):** Identificación rigurosa de dependencias funcionales, claves candidatas y transgresiones de la Forma Normal de Boyce-Codd (FNBC) en la relación de control de lotes y almacenes, ejecutando la descomposición formal sin pérdida de información y evaluando los límites de preservación de dependencias.
2. **Parte 2 (Diseño Físico y Rendimiento):** Aplicación de una desnormalización controlada orientada a optimizar el reporte crítico de facturación diaria (*Top categorías del día*), implementando columnas precalculadas y disparadores transaccionales para reducir el tiempo de respuesta promedio (3 rondas intercaladas) en un **98.30%** (**de 109.758 ms a 1.867 ms**, partiendo de **148.939 ms** en la medición previa).

---

## 2. Parte 1 — Normalización del Control de Lotes en FNBC

### Diagnóstico de la Relación Original $R(L, D, C)$:
- **Atributos:** $L$ (`id_lote`), $D$ (`id_deposito`), $C$ (`id_responsable_control`).
- **Dependencias Funcionales:** $LD \to C$ y $C \to D$.
- **Claves Candidatas:** $LD$ y $LC$ (todos los atributos son primos).
- **Forma Normal:** Cumple **3FN** (en $C \to D$, el consecuente $D$ es primo), pero **viola FNBC** porque el determinante $C$ no es superclave.
- **Anomalías Operativas:** La repetición de la tupla responsable-depósito por cada lote genera redundancia, anomalías de actualización y la imposibilidad de dar de alta un responsable sin asignarle inmediatamente un lote.

### Descomposición Aplicada:
- **`responsable_deposito(id_responsable_control, id_deposito)`**: PK `id_responsable_control`.
- **`control_lote(id_lote, id_responsable_control)`**: PK `(id_lote, id_responsable_control)`.

### Propiedades Matemáticas Verificadas:
- **Reunión sin pérdida (Lossless Join):** **PRESERVADA**. Comprobada mediante `v_control_lote_almacen` con `EXCEPT` bidireccional arrojando **0 filas** de diferencia.
- **Preservación de Dependencias:** **NO PRESERVADA LOCALMENTE**. La dependencia $LD \to C$ no queda garantizada por las PKs/FKs locales de las tablas descompuestas, requiriendo aserciones o triggers en caso de necesitar control estricto entre tablas.

---

## 3. Parte 2 — Desnormalización del Top Diario de Categorías

### Problema de Rendimiento:
El cálculo del Top 5 diario normalizado requería recorrer los pedidos del entorno masivo (200.000 pedidos / 200.000 detalles) y ejecutar uniones sucesivas con productos y detalles, consumiendo **5.306 búferes** en la medición previa (`shared hit=4791 read=515`, **148.939 ms**) y **5.854 búferes `shared hit`** promedio en rondas intercaladas (**109.758 ms** promedio).

### Solución con Columnas Precalculadas y Triggers:
1. Se incorporaron a `detalles_pedido` las columnas: `fecha_pedido_cache`, `id_categoria_cache` y `pedido_eliminado_cache`, junto a un índice B-Tree sobre la fecha copiada (`idx_tp6_detalle_fecha_cache`).
2. Se implementaron tres disparadores PL/pgSQL que garantizan la sincronización inmediata en INSERT/UPDATE sobre `detalles_pedido`, `pedidos` y `productos`.
3. Se integró el modelo de **borrado lógico** con atributos propios e independientes (`eliminado = FALSE`).

### Resultados Comparativos de Rendimiento:

| Métrica de Ejecución | Consulta Normalizada (4 tablas) | Consulta Desnormalizada (1 tabla + 1 JOIN) | Factor de Impacto |
|:---|---:|---:|:---:|
| **Tiempo de Respuesta (Promedio 3 rondas)** | **109.758 ms** | **1.867 ms** | **~58.79x más rápido** (-98.30%) |
| **Rondas individuales (R1 / R2 / R3)** | 183.256 / 77.299 / 68.720 ms | 2.515 / 1.303 / 1.783 ms | ~47.32x en rondas en caliente (R2–R3) |
| **Búferes Leídos (`shared hit`)** | **5.854 páginas** | **499 páginas** | **-91.48%** de carga en memoria |
| **Operador Dominante** | Hash/Parallel Scan + Joins | Bitmap Index Scan (`idx_tp6_detalle_fecha_cache`) + Memoize | Supresión de accesos a pedidos y productos |

---

## 4. Conclusiones y Criterio de Ingeniería

1. **Normalización vs Rendimiento:** La normalización formal hasta 3FN/FNBC es el estándar mandatorio para el diseño conceptual, eliminando anomalías de actualización y redundancia. Sin embargo, para consultas analíticas de alta concurrencia que exigen latencia en tiempo real, la desnormalización controlada constituye una herramienta de ingeniería legítima.
2. **Costo de la Desnormalización:** La ganancia de ~58.8x en lectura no es gratuita: traslada el esfuerzo computacional a los disparadores de inserción y actualización, además de demandar espacio adicional en disco. Se justifica plenamente en sistemas con alta tasa de lectura frente a escritura.
3. **Consistencia Transaccional:** El uso de triggers dentro del motor garantiza que la desnormalización mantenga consistencia ACID estricta en cada transacción, a diferencia de soluciones asíncronas o vistas materializadas que toleran datos desactualizados.

