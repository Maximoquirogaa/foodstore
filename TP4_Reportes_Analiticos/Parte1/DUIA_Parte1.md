# Declaración de Uso de IA (DUIA) - TP4 Parte 1

**Materia:** Base de Datos II  
**Trabajo Práctico:** TP4 — Optimización de Consultas Analíticas, Joins y Subconsultas  
**Parte:** 1 — Laboratorio: Consultas analíticas lentas y optimización medida  
**Proyecto:** Food Store (UTN FRM)  
**Alumno:** Máximo Juan Cruz Quiroga  
**Docente:** Sergio Neira  
**Motor:** PostgreSQL 17  

---

## 1. Registro de Usos de Inteligencia Artificial

| Herramienta | Para qué se usó | Prompt o especificación | Decisión y verificación |
|:---|:---|:---|:---|
| **Kiro / GitHub Copilot** | Analizar los planes de ejecución iniciales de las Consultas A y B, categorizar algoritmos de JOIN y proponer candidatos a índices. | Se suministraron los planes reales con `EXPLAIN (ANALYZE, BUFFERS, VERBOSE)` solicitando desglosar `Hash Join`, `Parallel Hash Join`, `Nested Loop` y tiempos por nodo. | **Propuestas consideradas solo como hipótesis**. Se exigió prueba en entorno transaccional aislado antes de validar cualquier afirmación. |
| **Kiro / GitHub Copilot** | Evaluar la propuesta de índice para la Consulta A: `idx_TP4_a_pedidos_fecha ON pedidos (id_pedido) INCLUDE (fecha_pedido)`. | Bloque de prueba en transacción reversible (`BEGIN; CREATE INDEX... EXPLAIN ANALYZE... ROLLBACK;`). | **ACEPTADA**. El planificador adoptó un `Parallel Index Only Scan` con `Heap Fetches: 0`, preservando paralelismo y reduciendo el tiempo de 699.55 ms a 164.25 ms (~4.26x). |
| **Kiro / GitHub Copilot** | Evaluar la propuesta de índice para la Consulta B: `idx_TP4_b_pedidos_cliente ON pedidos (id_pedido) INCLUDE (id_cliente)`. | Mismo protocolo transaccional reversible. | **RECHAZADA**. El optimizador ignoró el índice y mantuvo `Parallel Seq Scan`. El tiempo no mejoró (304.75 ms vs 305.60 ms). Se identificó que el problema radicaba en memoria (`work_mem`) y no en acceso. |
| **Kiro / GitHub Copilot** | Asistencia en la redacción y tabulación de métricas comparativas. | Estructurar tabla comparativa con columnas: JOIN antes, Cambio probado, JOIN después, Tiempos, Mejora y Decisión. | **ACEPTADO**. Formato estandarizado según la impronta del proyecto y las pautas de la cátedra. |

---

## 2. Criterio de Aceptación Profesional
Ninguna recomendación de la IA se incorporó a ciegas ni basándose únicamente en reducciones del costo estimado (`cost`). Se exigió contraste empírico mediante `EXPLAIN (ANALYZE, BUFFERS)` sobre la base masiva real de Food Store. Las propuestas que demostraron beneficio medible en tiempo real e I/O fueron aprobadas; las que no mostraron impacto o fueron ignoradas por el motor fueron descartadas con fundamentación técnica explícita.

