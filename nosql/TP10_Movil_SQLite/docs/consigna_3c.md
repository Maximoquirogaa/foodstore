# Consigna 3.c — Revisión Integral de Código con Inteligencia Artificial (Code Review)

**Entorno de Auditoría:** Asistente de IA Antigravity / Gemini en modo análisis estático de solo lectura.  
**Alcance:** Scripts de SQL, JavaScript BSON, Python y PowerShell de la cursada de Base de Datos II (TP2 al TP10).

---

## Tabla de Hallazgos Principales

| ID | Ubicación / Módulo | Hallazgo Identificado por la IA | Decisión | Justificación Técnica |
|:---:|---|---|:---:|---|
| **F01** | TP2 · `restricciones_integridad.sql` | El trigger de control de stock lee existencias sin `FOR UPDATE`, permitiendo que dos sesiones concurrentes vendan más del stock disponible. | **Aceptado** | Riesgo de condición de carrera (*race condition*). Se registra como mejora arquitectónica para entornos de alta concurrencia. |
| **F02** | TP5 · `views.sql` / `indices.sql` | Instrucciones `DROP ... CASCADE` sin verificación previa de existencia ni contexto de base de datos activa. | **Aceptado (Parcial)** | Falta el control de base de datos, aunque la ejecución guiada por scripts asume un esquema pre-configurado. |
| **F03** | TP7 · `fn_resetear_password.sql` | La función permite que un usuario con `rol_soporte` pueda resetear la contraseña de un `ADMINISTRADOR`. | **Aceptado** | Vulnerabilidad de escalamiento de privilegios. Debería existir una cláusula `WHERE rol != 'ADMIN'`. |
| **F04** | TP7 · `fn_autenticar.sql` | Discrepancia en el tratamiento de espacios en blanco (`btrim`) entre autenticación y reseteo. | **Aceptado** | Riesgo de inconsistencia en claves con espacios accidentales al inicio o fin. |
| **F05** | **TP2 · `schema.sql` y `restricciones.sql`** | **Un pedido en estado `ENTREGADO` se puede eliminar físicamente con `DELETE`, borrando sus detalles por `CASCADE`.** | **Aceptado** | **Comprobado en base de datos de laboratorio (Ver desarrollo en detalle).** |
| **F06** | TP9 (Unidad 7) · `prueba_validacion_expr.js` | El validador `$expr` solo controla consistencia aritmética, pero no valida tipos ni rangos sin `$jsonSchema`. | **Aceptado** | Comprobado empíricamente; la validación completa en MongoDB requiere combinar `$jsonSchema` con `$expr`. |
| **F07** | **TP10 (Unidad 8) · `recargar_snapshot.sql`** | **Si se usa `DELETE FROM producto_cache` para recargar el catálogo, la tablet falla o borra ítems de borradores activos.** | **Corregido** | **Comprobado y corregido implementando `ON CONFLICT (id) DO UPDATE SET` (Ver desarrollo).** |
| **F08** | TP10 (Unidad 8) · `importar_snapshot.sql` | Un `CAST` de texto no numérico en SQLite produce 0 de forma silenciosa sin disparar error. | **Aceptado** | Riesgo mitigado ya que los datos se originan en columnas `bigint` fuertemente tipadas en la vista de PostgreSQL. |
| **F09** | **TP10 (Unidad 8) · `recargar_snapshot.sql`** | **La IA afirmó que si un producto se elimina del catálogo, permanecerá disponible en la tablet indefinidamente.** | **Descartado** | **Descartado con fundamento técnico y refutado en laboratorio (Ver desarrollo en detalle).** |
| **F10** | TP8 · `backup_foodstore.ps1` | El conteo de control se mide en una transacción distinta a la del volcado de `pg_dump`. | **Descartado** | En la ventana de mantenimiento nocturno no existen conexiones activas de escritura; no hay discrepancia en reposo. |

---

## Desarrollo en Profundidad de Tres Hallazgos (Al menos uno Descartado con Fundamento)

### 1. Hallazgo F05 (Unidad 2 / TP2) — Un pedido `ENTREGADO` se puede borrar · [ACEPTADO]
* **Observación de la IA:** El trigger `trg_evitar_modificar_pedidos_cerrados` de TP2 únicamente interceptaba operaciones de tipo `UPDATE`. Como la clave foránea entre `detalles_pedido` y `pedidos` tenía la regla `ON DELETE CASCADE`, un comando `DELETE FROM pedidos WHERE id_pedido = 1;` eliminaba exitosamente el pedido y todos sus renglones asociados, violando el principio contable de preservación histórica de ventas.
* **Comprobación en PostgreSQL 17:**  
  Dentro de una transacción con `ROLLBACK`, se ejecutó:
  ```sql
  BEGIN;
  -- Intento de UPDATE: Bloqueado correctamente por el trigger
  UPDATE pedidos SET estado = 'CANCELADO' WHERE id_pedido = 1; -- ERROR: Pedido cerrado
  -- Intento de DELETE: Pasa sin oposición y borra la venta
  DELETE FROM pedidos WHERE id_pedido = 1; -- DELETE 1 (Borrado físico indebido)
  ROLLBACK;
  ```
* **Conclusión:** Hallazgo **Aceptado y comprobado**. La solución definitiva requiere extender el trigger a eventos `BEFORE DELETE OR UPDATE`.

---

### 2. Hallazgo F07 (Unidad 8 / TP10) — La recarga destructiva rompe la tablet · [CORREGIDO]
* **Observación de la IA:** En la primera versión de recarga de catálogo móvil, se planteó ejecutar `DELETE FROM producto_cache;` antes de insertar la nueva instantánea. La IA advirtió que al tener claves foráneas activas (`PRAGMA foreign_keys = ON;`), si el vendedor tenía un pedido borrador abierto en `item_borrador`, el `DELETE` fallaría con `FOREIGN KEY constraint failed`, impidiendo que la tablet actualice sus precios.
* **Comprobación y Corrección:**  
  Se verificó el fallo en SQLite CLI y se rediseñó [`movil/recargar_snapshot.sql`](../movil/recargar_snapshot.sql) utilizando la cláusula **UPSERT**:
  ```sql
  INSERT INTO producto_cache (id, nombre, precio_centavos, stock_visto, disponible, eliminado, fecha_copia)
  SELECT id, nombre, precio_centavos, stock, disponible, eliminado, fecha_copia
  FROM snapshot_servidor
  ON CONFLICT (id) DO UPDATE SET
      nombre = excluded.nombre,
      precio_centavos = excluded.precio_centavos,
      stock_visto = excluded.stock_visto,
      disponible = excluded.disponible,
      eliminado = excluded.eliminado,
      fecha_copia = excluded.fecha_copia;
  ```
* **Conclusión:** Hallazgo **Corregido**. Los productos existentes se actualizan en su lugar sin eliminar filas maestras, preservando la integridad referencial de los borradores en curso.

---

### 3. Hallazgo F09 (Unidad 8 / TP10) — Persistencia indebida de productos dados de baja · [DESCARTADO CON FUNDAMENTO]
* **Observación de la IA:** La IA afirmó textualmente: *"Si un producto sufre baja lógica en PostgreSQL, al sincronizar la tablet mediante UPSERT, el producto no se actualizará y el vendedor continuará vendiéndolo en la feria como si estuviera disponible"*.
* **Refutación Técnica y Comprobación en Laboratorio:**  
  La afirmación de la IA es **técnicamente falsa y desestimada**:
  1. En la vista de PostgreSQL ([`vista_snapshot_movil.sql`](../postgresql/vista_snapshot_movil.sql)), los productos inactivos **sí se incluyen en la instantánea**, viajando con `disponible = 'f'` y `eliminado = 't'`.
  2. En SQLite, la consulta de catálogo del Caso C1 filtra de manera obligatoria:
     ```sql
     SELECT * FROM producto_cache WHERE disponible = 1 AND eliminado = 0 AND stock_visto > 0;
     ```
  3. Tras aplicar la instantánea en el Caso C4, se comprobó que el producto 3 (Papas Fritas) **desaparece instantáneamente del catálogo disponible para el vendedor**, y si existía un borrador previo, el semáforo lo clasifica inmediatamente en **`RECHAZADO` (Rojo)** con el motivo *"Producto no disponible"*.
* **Conclusión:** Hallazgo **Descartado con fundamento**. La IA no comprendió que la baja lógica en Food Store se modela como un cambio de estado booleano y no como la omisión física del registro en el CSV.
