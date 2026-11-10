# Bitácora de Uso de Inteligencia Artificial · TP10 (Unidad 8)

**Estudiante:** Máximo Juan Cruz Quiroga (`maximoj.quiroga@alumnos.frm.utn.edu.ar`)  
**Materia:** Base de Datos II · UTN Facultad Regional Mendoza (UTN FRM)  
**Ciclo Lectivo:** 2026  

---

## Entrada 1 · 04/11/2026 · Asistente IA Antigravity / Claude
* **Qué se pidió:**  
  Generar la especificación en notación EARS y el esquema de SQLite en modo `STRICT`, asegurando que no se permita la mutación indebida de stock desde el cliente móvil.
* **Qué propuso la IA:**  
  Propuso un modelo simplificado donde la tablet descontaba directamente el inventario local en `producto_cache.stock_visto` y emitía una solicitud directamente en estado `APROBADO`.
* **Qué se aceptó:**  
  La estructura de tablas `STRICT`, la representación de precios en centavos enteros (`INTEGER`) y las restricciones de verificación `CHECK`.
* **Qué se descartó:**  
  Se descartó que la tablet descuente stock o emita ventas definitivas.
* **Por qué:**  
  Viola la **Regla de Oro** de la cátedra: *"El móvil propone, el servidor dispone"*. En un sistema desconectado, dos tablets podrían vender las mismas existencias en paralelo si descontaran stock localmente. Solo PostgreSQL tiene autoridad para confirmar transacciones y alterar stock.

---

## Entrada 2 · 05/11/2026 · Asistente IA Antigravity / Gemini
* **Qué se pidió:**  
  Diseñar la consulta del semáforo de sincronización en `semaforo.sql` para clasificar solicitudes en `RECHAZADO`, `CONFLICTO` y `SIMULADO_APROBADO`.
* **Qué propuso la IA:**  
  Propuso evaluar la condición de precio (`precio_visto <> precio_servidor`) antes de chequear la disponibilidad del producto o el stock, asignando `CONFLICTO` prioritario.
* **Qué se aceptó:**  
  La técnica de agregación mediante tabla temporal `evaluacion_semaforo` agrupando por `solicitud_uuid`.
* **Qué se descartó:**  
  Se descartó la precedencia propuesta por la IA.
* **Por qué:**  
  Si un producto está dado de baja o no tiene stock, no tiene sentido advertir sobre un cambio de precio; la orden debe ser estrictamente rechazada en primera instancia (Rojo prioritario sobre Amarillo).

---

## Entrada 3 · 06/11/2026 · Asistente IA Antigravity / Code Review
* **Qué se pidió:**  
  Realizar una auditoría estática de código sobre la totalidad de los scripts desarrollados durante la cursada, buscando inconsistencias de integridad referencial.
* **Qué propuso la IA:**  
  Detectó que en `recargar_snapshot.sql`, vaciar la tabla `producto_cache` con `DELETE` provocaba errores de clave foránea con `item_borrador` (Hallazgo F07). Asimismo, afirmó que un producto con baja lógica quedaría accesible en la tablet (Hallazgo F09).
* **Qué se aceptó:**  
  El hallazgo F07, procediendo a rediseñar la recarga mediante la sentencia atómica `INSERT INTO producto_cache ... ON CONFLICT (id) DO UPDATE SET ...`.
* **Qué se descartó:**  
  El hallazgo F09, el cual fue refutado demostrando que la vista de PostgreSQL exporta los productos inactivos con `disponible = 'f'`, haciendo que la tablet oculte el producto y rechace nuevos pedidos.
* **Por qué:**  
  La consigna penaliza aceptar sugerencias de la IA sin contrastarlas empíricamente en la base de datos de laboratorio.
