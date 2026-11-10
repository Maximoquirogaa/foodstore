# Declaración de Uso de IA (DUIA) - TP4 Parte 4

**Materia:** Base de Datos II  
**Trabajo Práctico:** TP4 — Optimización de Consultas Analíticas, Joins y Subconsultas  
**Parte:** 4 — Competencia de optimización entre equipos  
**Proyecto:** Food Store (UTN FRM)  
**Alumno:** Máximo Juan Cruz Quiroga  
**Docente:** Sergio Neira  
**Motor:** PostgreSQL 17  

---

## 1. Registro de Usos de Inteligencia Artificial

| Herramienta | Para qué se usó | Prompt o especificación | Decisión y verificación |
|:---|:---|:---|:---|
| **Kiro / GitHub Copilot** | Diagnóstico del nodo más costoso del plan real en la consulta de competencia (Top 3 productos por facturación por categoría en los últimos 6 meses). | Plan completo de `EXPLAIN (ANALYZE, BUFFERS, VERBOSE)` pegado, solicitando aislar el cuello de botella por tiempo real y consumo de búferes. | **ACEPTADA**. Identificó correctamente que el cuello de botella era un `Sort` con spill a disco (`external merge Disk: 3576kB`) en los workers, y no los scans secuenciales. |
| **Kiro / GitHub Copilot** | Evaluar la alternativa no invasiva `SET LOCAL work_mem = '8MB'` dentro de `BEGIN ... ROLLBACK`. | Consulta de competencia ejecutada bajo transacción con ajuste de memoria. | **ACEPTADA**. El sort pasó a `quicksort Memory: 5883kB`, reduciendo el tiempo de 621.0 ms a 571.4 ms sin tocar índices ni alterar el esquema. |
| **Kiro / GitHub Copilot** | Evaluar la propuesta de un índice parcial sobre la fecha de pedidos: `CREATE INDEX idx_pedidos_fecha_reciente ON pedidos (fecha_pedido DESC)`. | Probar el índice en transacción combinado con work_mem y medir el impacto. | **RECHAZADA TRAS CONTROL DE SESGO DE ORDEN**. La ventaja preliminar de 48 ms en mediciones en bloque se evaporó por completo al intercalar corridas (A-B-A-B-A-B), empatando ambos promedios en 571.4 ms. Se descartó por ser un falso positivo inducido por la memoria caché. |

---

## 2. Criterio de Aceptación y Aprendizaje Metodológico
El protocolo de la cátedra se cumplió de forma rigurosa: documentar no solo la alternativa exitosa, sino también toda propuesta descartada. La detección del sesgo de orden en las mediciones de rendimiento refuerza que las herramientas de IA son excelentes formuladoras de hipótesis, pero la confirmación empírica y el diseño experimental controlado siguen siendo responsabilidad ineludible del analista.

