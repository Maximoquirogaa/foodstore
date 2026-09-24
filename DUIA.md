# Declaraciones de Uso de IA (DUIA) - TP2

## Parte 1: Integridad versionada

| Campo | Completar |
| :--- | :--- |
| **Herramienta** | OpenCode (simulado / Gemini 3.1 Pro) |
| **Spec o prompt utilizado** | "Generar para mi schema.sql: 1) Un trigger que evite insertar en detalles_pedido si el producto tiene activo=FALSE. 2) Un trigger para descontar stock automáticamente después del insert." |
| **Qué generó** | Archivo `restricciones.sql` con las funciones `fn_check_producto_activo` y `fn_deducir_stock`, además de sus respectivos triggers. |
| **Qué se aceptó** | Todo el código lógico propuesto. |
| **Qué se modificó o descartó, y por qué** | Se ajustó el texto del `RAISE EXCEPTION` para hacerlo más descriptivo hacia el usuario final. |
| **Verificación realizada** | Inserción simulada en transacción comprobando que un producto inactivo hace fallar la inserción. |

---

## Parte 2 y 3: Concurrencia y Lectura Crítica

| Campo | Completar |
| :--- | :--- |
| **Herramienta** | Kiro / ChatGPT / Gemini |
| **Spec o prompt utilizado** | "1. Explicar escenarios de lectura no repetible, lock wait y deadlocks. 2. Identificar el efecto real de dos scripts peligrosos (baja de cartelera sin WHERE y borrado de categoría con NULL en NOT IN)." |
| **Qué generó** | Explicación teórica del MVCC, niveles de aislamiento, exclusión forzada (FOR UPDATE) y la resolución corregida de los scripts destructivos SQL. |
| **Qué se aceptó** | Los análisis completos de ambas partes. |
| **Qué se modificó o descartó, y por qué** | Se organizó la salida para ajustarse estrictamente a la plantilla markdown de la cátedra. |
| **Verificación realizada** | Se cotejó en el motor el efecto de los niveles de aislamiento y los scripts peligrosos se evaluaron estáticamente. |

