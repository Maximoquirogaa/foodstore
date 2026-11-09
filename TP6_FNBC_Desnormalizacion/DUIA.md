# Declaración de Uso de IA (DUIA) - TP6 Consolidada

**Materia:** Base de Datos II  
**Trabajo Práctico:** TP6 — Normalización en FNBC y Desnormalización Controlada  
**Facultad:** Universidad Tecnológica Nacional — Facultad Regional Mendoza (UTN FRM)  
**Alumno:** Máximo Juan Cruz Quiroga  
**Email:** `maximoj.quiroga@alumnos.frm.utn.edu.ar`  
**Docente:** Sergio Neira  
**Motor:** PostgreSQL 17.11  
**Base de trabajo:** `foodstore_copia_trabajo` (200.000 pedidos, 200.000 detalles)

---

Esta declaración documenta formalmente la utilización de herramientas de Inteligencia Artificial a lo largo de las dos partes del **TP6**, siguiendo la política de uso responsable de la cátedra de Base de Datos II: *"Especificación matemática formal, verificación empírica contra el plan del motor y justificación de decisiones"*.

---

## 1. Registro de Usos de Inteligencia Artificial

| Herramienta | Para qué se usó | Prompt o especificación | Decisión y verificación |
|:---|:---|:---|:---|
| **Claude 3.5 Sonnet / Kiro** | Analizar el conjunto de dependencias funcionales $LD \to C$ y $C \to D$ para $R(L,D,C)$, determinar claves candidatas y clasificar en 3FN y FNBC. | Suministrar el enunciado de control de lotes y depósitos, solicitando la clausura de atributos y verificación formal de definiciones de 3FN y FNBC. | **ACEPTADA**. Se confirmó que cumple 3FN porque $D$ es primo, pero viola FNBC porque $C$ no es superclave. |
| **Claude 3.5 Sonnet** | Diseñar el script de descomposición en FNBC y evaluar las propiedades de reunión sin pérdida y preservación de dependencias. | Especificar la creación de `responsable_deposito` y `control_lote`, migración por proyección y prueba formal con `EXCEPT`. | **ACEPTADA**. Se comprobó la reunión sin pérdida (0 filas de diferencia con `EXCEPT`). Se documentó formalmente que $LD \to C$ no se preserva localmente por las PKs/FKs. |
| **GitHub Copilot / Claude** | Diseñar la arquitectura de desnormalización transaccional mediante columnas precalculadas y disparadores en `detalles_pedido`. | Diseñar triggers en PL/pgSQL que sincronicen `fecha_pedido_cache`, `id_categoria_cache` y `pedido_eliminado_cache` ante operaciones en `pedidos`, `productos` y `detalles_pedido`. | **ACEPTADO**. Se validaron las tres funciones trigger y se verificó que la propagación es inmediata e íntegra. |
| **GitHub Copilot** | Confeccionar los scripts de medición comparativa antes y después con `EXPLAIN (ANALYZE, BUFFERS)` y comprobación de equivalencia con `EXCEPT`. | Comparar la consulta normalizada frente a la desnormalizada bajo protocolo de borrado lógico independiente en rondas intercaladas A/B. | **ACEPTADO**. Se confirmó la equivalencia estricta (0 filas) y una aceleración promedio de 109.758 ms a 1.867 ms (~58.79x de mejora; línea base aislada 148.939 ms). |

---

## 2. Reflexión Metodológica

El desarrollo de este TP6 permitió contrastar de manera práctica dos principios esenciales del diseño de bases de datos:
1. **El rigor formal de la teoría de la normalización:** Entender la distinción sutil entre 3FN y FNBC (cuando intervienen múltiples claves candidatas solapadas) y verificar que alcanzar FNBC puede forzar a sacrificar la preservación de dependencias locales.
2. **La ingeniería pragmática de la desnormalización:** Constatar que cuando los requisitos de rendimiento exigen respuestas en milisegundos en tiempo real, desnormalizar selectivamente con triggers y aislamiento transaccional es una técnica válida y potente, siempre que se administren conscientemente sus costos de almacenamiento y escritura.

