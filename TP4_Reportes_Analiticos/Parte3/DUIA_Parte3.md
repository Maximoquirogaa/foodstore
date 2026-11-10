# Declaración de Uso de IA (DUIA) - TP4 Parte 3

**Materia:** Base de Datos II  
**Trabajo Práctico:** TP4 — Optimización de Consultas Analíticas, Joins y Subconsultas  
**Parte:** 3 — Consultas resumen, rankings y subconsultas bajo especificación precisa  
**Proyecto:** Food Store (UTN FRM)  
**Alumno:** Máximo Juan Cruz Quiroga  
**Docente:** Sergio Neira  
**Motor:** PostgreSQL 17  

---

## 1. Registro de Usos de Inteligencia Artificial

| Herramienta | Para qué se usó | Prompt o especificación | Decisión y verificación |
|:---|:---|:---|:---|
| **Kiro / GitHub Copilot** | Generar la Consulta A (Ranking con función de ventana `DENSE_RANK`) y una versión alternativa equivalente sin ventana (subconsulta correlacionada). | Especificación formal: ranking de clientes por total gastado (`dp.cantidad * dp.precio_unitario`), empates comparten puesto sin dejar huecos posteriores. No usar SELECT *. | **Primera propuesta RECHAZADA**. La IA utilizó `COUNT(*) + 1`, generando 19.433 filas de discrepancia en la prueba formal `EXCEPT`. Se detectó que `COUNT(*)` replica `RANK()` y no `DENSE_RANK()`. Tras corregir a `COUNT(DISTINCT ...) + 1`, la prueba arrojó 0 filas en ambas direcciones (**ACEPTADA**). |
| **Kiro / GitHub Copilot** | Generar la Consulta B (Productos activos con precio mayor al promedio de su categoría) en dos modalidades: subconsulta correlacionada en WHERE y pre-agregación grupal. | Especificación formal: filtrar categorías y productos con `activo = TRUE`, calcular promedio por categoría y contrastar con `p.precio_actual`. Probar equivalencia formal. | **ACEPTADA DE ENTRADA**. Ambas consultas superaron la prueba `EXCEPT` bidireccional arrojando 0 filas. Se constató una sustancial ventaja de rendimiento en la versión pre-agregada ($O(N)$ vs $O(N \cdot M)$). |

---

## 2. Criterio de Aceptación y Hallazgo Metodológico
Ninguna consulta se dio por válida únicamente porque "compilaba y retornaba datos". El protocolo de la cátedra exige **comprobación formal de equivalencia relacional**.

El hallazgo más valioso de esta sección fue descubrir que la subconsulta correlacionada generada por IA para emular funciones de ventana calculaba erróneamente un `RANK()` tradicional (saltando posiciones tras empates) cuando la especificación pedía `DENSE_RANK()`. Este error hubiera pasado completamente inadvertido en una inspección visual superficial, y solo fue descubierto gracias al rigor del operador `EXCEPT`.

