# TP4 — Parte 4: Registro Oficial de Competencia de Optimización

**Materia:** Base de Datos II  
**Trabajo Práctico:** TP4 — Optimización de Consultas Analíticas, Joins y Subconsultas  
**Proyecto:** Food Store (UTN FRM)  
**Alumno:** Máximo Juan Cruz Quiroga  
**Docente:** Sergio Neira  
**Motor:** PostgreSQL 17  
**Consulta Evaluada:** Top 3 productos por facturación dentro de cada categoría (últimos 6 meses).  

---

## 1. Tabla Oficial de Resultados

| Equipo / Alumno | Estrategia aplicada | Tiempo antes (ms) | Tiempo después (ms) | Mejora (×) | Decisión |
|:---|:---|---:|---:|:---:|:---:|
| **Máximo Quiroga**<br>(Food Store FRM) | `SET LOCAL work_mem = '8MB'` aplicado en transacción (eliminación de spill a disco en Sort sin tocar índices ni alterar esquema) | 621.0 ms | 571.4 ms | **1.09×**<br>(~50 ms netos de I/O) | **ACEPTADA** |

> **Nota sobre la Conducción de Mediciones:**
> - Los tiempos reportados no corresponden a corridas aisladas con ruido del sistema, sino a promedios rigurosos bajo protocolo de control.
> - **Tiempo Antes (621.0 ms):** Promedio de 3 corridas baseline (657.1 / 557.5 / 648.5 ms).
> - **Tiempo Después (571.4 ms):** Promedio del control intercalado A-B-A-B-A-B (600.7 / 557.1 / 556.2 ms), eliminando el sesgo de calentamiento de caché.
> - **Corrida Única Oficial del Plan:** Registrada en `plan_despues.txt` con `601.629 ms`.

---

## 2. Resumen del Diagnóstico Técnico

1. **Cuello de Botella Dominante:**
   El operador `Sort` dentro de los dos workers paralelos derramaba a disco (`external merge Disk: 3576kB`), consumiendo casi el 50% de la latencia total de la consulta.
2. **Impacto de la Optimización:**
   Al elevar `work_mem` a 8MB mediante `SET LOCAL`, el ordenamiento se realizó íntegramente en memoria RAM mediante `quicksort Memory: 5883kB`, reduciendo el I/O temporal (`temp read/written = 0`).
3. **Propuesta de Índice Descartada:**
   Se probó crear un índice parcial sobre `pedidos(fecha_pedido DESC)`. El análisis metodológico con mediciones intercaladas demostró que no aportaba ninguna ganancia real (empate exacto en 571.4 ms) debido a que la baja selectividad del filtro temporal forzaba al motor a preferir el barrido secuencial paralelo. Se rechazó para no penalizar operaciones de escritura.

