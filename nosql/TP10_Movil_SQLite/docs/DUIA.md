# Declaración de Uso de Inteligencia Artificial (DUIA)

**Cátedra:** Base de Datos II  
**Institución:** Universidad Tecnológica Nacional – Facultad Regional Mendoza (UTN FRM)  
**Docente:** Sergio Neira  
**Alumno:** Máximo Juan Cruz Quiroga (`maximoj.quiroga@alumnos.frm.utn.edu.ar`)  
**Fecha de Presentación:** Noviembre 2026  
**Trabajo Práctico:** TP10 (Unidad 8) — Food Store en la Feria: La base de la tablet y el cierre de la capa de datos  

---

## 1. Herramientas de Inteligencia Artificial Empleadas
* **Antigravity (Google DeepMind):** Empleado como orquestador de análisis, planificación y revisión de código estático.
* **Gemini 3.8 Flash / Claude Sonnet:** Modelos de lenguaje consultados para la formulación de requisitos EARS, validación de esquemas SQLite en modo STRICT y contraste de hipótesis de consistencia en bases distribuidas.

---

## 2. Declaración por Secciones del Trabajo Práctico

| Sección / Consigna | Asistencia de la IA | Aceptado / Incorporado | Descartado / Modificado con Fundamento |
|---|---|---|---|
| **Consigna 1 (Base SQLite)** | Asistencia en la formulación de restricciones `CHECK` y sintaxis `STRICT` en SQLite 3. | Estructura de 4 tablas maestras y tipado fuerte. | Se descartó sugerencia de almacenar precios en punto flotante (`REAL`), adoptando centavos enteros (`INTEGER`). |
| **Consigna 2 (Semáforo y Casos)** | Generación de la consulta de agregación para el semáforo y simulación de casos C2 a C6. | Agrupación por solicitud en tabla temporal y actualización atómica en `cola_sync`. | Se corrigió la precedencia de evaluación: los rechazos por stock o baja (Rojo) tienen prioridad estricta sobre discrepancias de precio (Amarillo). |
| **Consigna 3 (Integración y Review)** | Code review asistido sobre los 75 scripts de la cursada de Food Store. | 20 hallazgos válidos documentados; corrección de F07 (UPSERT en recarga de snapshot). | Se descartó con fundamento el hallazgo F09 tras comprobar que la baja lógica en PostgreSQL se propaga correctamente a SQLite. |
| **Consigna 4 (Kiro y Defensa)** | Asistencia en la estructuración de requisitos en formato EARS (`requirements.md`). | Estructura EARS para REQ-01 a REQ-04 mapeados 1:1 a los casos C2, C3, C4 y C6. | Se rechazó la redacción simplificada de REQ-04, especificando que la protección de unicidad reside en la `PRIMARY KEY` de `cola_sync`. |

---

## 3. Declaración de Responsabilidad y Privacidad
El alumno declara bajo fe de juramento que:
1. **Comprensión Absoluta:** Todos los scripts, esquemas, consultas y reportes generados han sido leídos, ejecutados, comprobados en motores reales (PostgreSQL 17 y SQLite 3.50) y comprendidos a cabalidad, estando en condiciones de defenderlos y responder preguntas individuales en clase.
2. **Protección de Datos:** Ningún dato confidencial, contraseña en texto claro ni información sensible de personas reales ha sido provisto a los motores de Inteligencia Artificial. Todos los ensayos emplean datos ficticios y copias descartables de laboratorio.
