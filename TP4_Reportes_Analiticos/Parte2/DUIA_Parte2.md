# Declaración de Uso de IA (DUIA) - TP4 Parte 2

**Materia:** Base de Datos II  
**Trabajo Práctico:** TP4 — Optimización de Consultas Analíticas, Joins y Subconsultas  
**Parte:** 2 — Lectura crítica de planes de JOIN interpretados por IA  
**Proyecto:** Food Store (UTN FRM)  
**Alumno:** Máximo Juan Cruz Quiroga  
**Docente:** Sergio Neira  
**Motor:** PostgreSQL 17  

---

## 1. Registro de Usos de Inteligencia Artificial

| Herramienta | Para qué se usó | Prompt o especificación | Decisión y verificación |
|:---|:---|:---|:---|
| **Kiro / Claude 3.5 Sonnet** | Generar una explicación en lenguaje natural nodo por nodo del plan de ejecución optimizado de la Consulta A. | Se pasó el plan textual de `EXPLAIN ANALYZE` sin contexto previo, solicitando identificar tablas externas/internas de cada JOIN, función del índice cubriente, paralelismo, `Heap Fetches` y relación costo-tiempo. | **Utilizada como borrador preliminar**. Ningún párrafo se aceptó sin confrontarlo línea por línea con las etiquetas del plan oficial emitido por PostgreSQL. |
| **GitHub Copilot (VS Code)** | Asistir en la estructuración de la matriz de lectura crítica y evaluación de hipótesis. | Solicitar la confección de una tabla de 7 afirmaciones técnicas para contrastar las explicaciones generadas frente a los conceptos formales de base de datos. | **ACEPTADA con correcciones activas**. Se corrigieron manualmente las afirmaciones sobre `Heap Fetches` (añadiendo el mapa de visibilidad) y se refutó la confusión entre `cost` y milisegundos. |

---

## 2. Criterio de Aceptación y Hallazgos
La IA demostró solvencia para identificar la jerarquía básica de los joins (`Parallel Hash Join` y `Hash Join`), pero falló en aspectos de arquitectura interna del motor:
1. **Omitió el Visibility Map:** Atribuyó erróneamente la ausencia de accesos al heap (`Heap Fetches: 0`) única y exclusivamente a que el índice era cubriente.
2. **Confundió Costo con Tiempo:** Equiparó la unidad adimensional `cost` con tiempo de ejecución en milisegundos.
3. **Desconoció el Rol del Proceso Líder:** Supuso que `Workers Launched: 2` excluía al proceso padre del procesamiento paralelo.

Todas las desviaciones fueron documentadas en la tabla de lectura crítica, cumpliendo rigurosamente con los objetivos formativos de la cátedra.

