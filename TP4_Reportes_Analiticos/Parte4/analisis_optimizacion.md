# TP4 — Parte 4: Competencia de Optimización - Análisis Técnico

**Materia:** Base de Datos II  
**Trabajo Práctico:** TP4 — Optimización de Consultas Analíticas, Joins y Subconsultas  
**Proyecto:** Food Store (UTN FRM)  
**Alumno:** Máximo Juan Cruz Quiroga  
**Docente:** Sergio Neira  
**Motor:** PostgreSQL 17  
**Base de trabajo:** Esquema masivo Food Store  
**Tiempo base de referencia:** **660.865 ms** (promedio baseline: 621.0 ms)

---

## 1. Diagnóstico del Cuello de Botella Real

Un análisis superficial sugeriría atacar de inmediato los barridos secuenciales (`Seq Scan`) en `pedidos` o `detalles_pedido`. Sin embargo, al inspeccionar el desglose de tiempos reales (`actual time`) y el consumo de búferes temporales, se detecta que el nodo dominante es el **`Sort` con derrame a disco (`external merge Disk`)** dentro de los workers paralelos:

```text
Sort  (actual time=323.171..336.597 rows=60470 loops=3)
  Sort Key: cat.id_categoria, p.id_producto
  Sort Method: external merge  Disk: 3576kB
  Worker 0:  Sort Method: external merge  Disk: 3576kB
  Worker 1:  Sort Method: external merge  Disk: 3776kB
```

### Por qué ocurre:
- Este nodo acumula aproximadamente **323 ms** del tiempo total de ejecución (~49%).
- Los operadores posteriores (`GroupAggregate`, `Gather Merge`, `WindowAgg` e `Incremental Sort`) están completamente bloqueados esperando que este ordenamiento finalice para poder consumir filas.
- Los barridos secuenciales, en contraste, son extremadamente eficientes gracias a la lectura secuencial en paralelo:
  * `pedidos ped`: ~41 ms (filtra rango de 6 meses).
  * `detalles_pedido dp`: ~71 ms (lectura de ~500.000 tuplas repartidas en 3 procesos).
  * `productos p`: ~19 ms.
  * `categorias cat`: ~0.5 ms.

---

## 2. Alternativa sin Índices: `SET LOCAL work_mem = '8MB'`

### Causa Raíz
El valor por defecto de `work_mem` en PostgreSQL es de 4 MB por operación y por proceso. Al ejecutar en paralelo con 2 workers + el proceso líder, el ordenamiento de los grupos de productos requería mantener alrededor de 5.8 MB en memoria. Al superar los 4 MB permitidos, PostgreSQL recurre obligatoriamente al mecanismo `external merge Disk`, escribiendo bloques temporales en disco y volviéndolos a leer.

### Protocolo de Prueba Reversible
```sql
BEGIN;
SET LOCAL work_mem = '8MB';
-- Ejecución de la consulta oficial de competencia
ROLLBACK;
```

### Resultado Real Obtenido
```text
Sort Method: quicksort  Memory: 5883kB   <-- ¡Spill a disco eliminado!
Worker 0:  Sort Method: quicksort  Memory: 5762kB
Worker 1:  Sort Method: quicksort  Memory: 5708kB
Execution Time: 556.884 ms (corrida única de prueba)
Buffers: temp read=0 written=0
```

### ¿Conviene aumentar a 16MB?
Se probó de forma exploratoria `SET LOCAL work_mem = '16MB'`:
- Tiempo resultante: **641.026 ms** (peor que con 8MB).
- **Justificación:** Con 16 MB el sort ya entra completamente en RAM, pero el costo de asignación, inicialización y gestión de fragmentación de bloques de memoria por parte del kernel penaliza la latencia global sin aportar ninguna reducción de I/O adicional. **8MB es el punto de equilibrio óptimo.**

---

## 3. Propuesta de Índice Evaluada y Descartada: `idx_pedidos_fecha_reciente`

La IA sugirió crear un índice parcial sobre `pedidos` para acelerar el filtrado de fecha:
```sql
CREATE INDEX idx_pedidos_fecha_reciente
    ON pedidos (fecha_pedido DESC)
    WHERE fecha_pedido >= (now() - interval '6 months');
```

### La Trampa del Sesgo de Orden de Ejecución (Cache Warming)
En una primera medición ejecutada en bloques continuos (AAA vs BBB):
- Sin índice (3 corridas seguidas): promedio = **621.0 ms**.
- Con índice (3 corridas seguidas): promedio = **573.0 ms**.
- Parecía indicar una ventaja de ~48 ms a favor del índice.

### Control Científico Metodológico (Mediciones Intercaladas A-B-A-B-A-B)
Para descartar que la supuesta ventaja fuera un artefacto de páginas precargadas en la memoria caché del sistema operativo y del motor, se aplicó un protocolo de mediciones intercaladas alternando una corrida de A y una de B:

| Corrida | Estrategia | Tiempo (ms) | Notas |
|:---:|:---|---:|:---|
| 1 | Baseline (A) | 600.7 ms | Primera corrida intercalada |
| 2 | Con Índice (B) | 598.2 ms | Prácticamente idéntico |
| 3 | Baseline (A) | 557.1 ms | Beneficiado por caché caliente |
| 4 | Con Índice (B) | 556.8 ms | Idéntico |
| 5 | Baseline (A) | 556.2 ms | Estabilizado en RAM |
| 6 | Con Índice (B) | 559.1 ms | Ligera variación por CPU |

- **Promedio intercalado Baseline (solo work_mem = 8MB):** **571.4 ms**
- **Promedio intercalado Con Índice + work_mem = 8MB:** **571.4 ms**

### Conclusión del Descarte
La ventaja de 48 ms observada inicialmente era **100% atribuible al calentamiento progresivo del búfer caché** (`shared buffers` y page cache del SO) y no al índice. Dado que el filtro de 6 meses abarca la mitad de los pedidos históricos (~100.000 tuplas), el planificador considera más económico hacer un barrido secuencial paralelo contiguo en disco que saltar aleatoriamente por los punteros de un índice. Se descarta la creación del índice para evitar overhead de mantenimiento en transacciones de inserción.

