# Especificación de Requisitos del Sistema Móvil (Kiro Spec)

**Proyecto:** Food Store Móvil (Tablet en la Feria)  
**Asignatura:** Base de Datos II (UTN FRM)  
**Alumno:** Máximo Juan Cruz Quiroga  
**Notación:** EARS (*Easy Approach to Requirements Syntax*)

---

## Requisitos del Semáforo de Sincronización

### REQ-01 · Conflicto por Alteración de Precio en Servidor
* **Sintaxis EARS:**  
  *WHEN el precio actual en la instantánea del servidor (`snapshot_servidor.precio_centavos`) difiere del precio observado en el borrador de la tablet (`item_borrador.precio_centavos_visto`), AND no se presentan condiciones de rechazo por disponibilidad o inventario,*  
  **THE SYSTEM SHALL** marcar la solicitud en `cola_sync` con el estado `'CONFLICTO'`, registrar el motivo `'Cambió el precio observado'` y solicitar renegociación con el cliente.
* **Caso de Prueba Asociado:** **Caso C2**

---

### REQ-02 · Rechazo por Insuficiencia de Existencias (Stock)
* **Sintaxis EARS:**  
  *WHEN la cantidad requerida en una línea de pedido (`item_borrador.cantidad`) es estrictamente superior al inventario reportado por el servidor (`snapshot_servidor.stock`),*  
  **THE SYSTEM SHALL** clasificar la solicitud en `cola_sync` con el estado `'RECHAZADO'` y registrar el motivo `'Stock insuficiente'`.
* **Caso de Prueba Asociado:** **Caso C3**

---

### REQ-03 · Rechazo por Baja Lógica o No Disponibilidad de Producto
* **Sintaxis EARS:**  
  *WHEN un producto incluido en un borrador figura en la instantánea con disponibilidad inactiva (`disponible = 0`) o con baja lógica confirmada (`eliminado = 1`),*  
  **THE SYSTEM SHALL** clasificar la solicitud en `cola_sync` con el estado `'RECHAZADO'`, registrar el motivo `'Producto no disponible'` e impedir la confirmación de la venta.
* **Caso de Prueba Asociado:** **Caso C4**

---

### REQ-04 · Idempotencia y Protección ante Reenvíos con Mismo Identificador
* **Sintaxis EARS:**  
  *WHEN se intenta registrar o reenviar una solicitud cuyo identificador universal (`solicitud_uuid`) ya existe en la base de datos local o en el servidor central,*  
  **THE SYSTEM SHALL** rechazar la inserción por violación de clave primaria unívoca (`PRIMARY KEY`), garantizando que ninguna orden se procese de forma duplicada ni altere inventarios múltiples veces.
* **Caso de Prueba Asociado:** **Caso C6**
