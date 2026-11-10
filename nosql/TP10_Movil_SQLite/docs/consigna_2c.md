# Consigna 2.c — Simulación y Resolución de Casos del Semáforo

## Resumen de los Casos Evaluados

| Caso | Situación Preparada en el Servidor | Comportamiento del Semáforo en la Tablet | Resultado Esperado | Resultado Observado |
|:---:|---|---|:---:|:---:|
| **C2-a** | El servidor incrementó el precio de la Hamburguesa Clásica de \$4.500 a \$4.800. | Detecta que el precio visto (\$4.500 = 450.000 centavos) no coincide con la nueva instantánea del servidor (\$4.800 = 480.000 centavos). | `CONFLICTO` | **`CONFLICTO`** (*Cambió el precio observado*) |
| **C2-b** | El cliente acepta en el mostrador el nuevo precio informado. Se actualiza el borrador local y se emite nueva solicitud (`c2-solicitud-2`). | El nuevo precio visto (480.000 centavos) coincide con el servidor y hay stock suficiente. | `SIMULADO_APROBADO` | **`SIMULADO_APROBADO`** (*Precio, disponibilidad y stock coinciden*) |
| **C3** | El vendedor arma un pedido por 99 unidades de Hamburguesa Doble Queso. | La cantidad solicitada (99) supera el stock real en el servidor (35 unidades). | `RECHAZADO` | **`RECHAZADO`** (*Stock insuficiente*) |
| **C4** | El servidor dio de baja lógica el producto Papas Fritas (`activo = false`). | Al recargar la instantánea, el producto figura como no disponible / eliminado (`disponible = 0`). | `RECHAZADO` | **`RECHAZADO`** (*Producto no disponible*) |
| **C5** | Pedido creado con precios y catálogo vigentes sin modificaciones. | Precio, stock y disponibilidad concuerdan al 100%. | `SIMULADO_APROBADO` | **`SIMULADO_APROBADO`** (*Precio, disponibilidad y stock coinciden*) |
| **C6** | Intento de reenvío malicioso o por reintento de red de la misma solicitud (`c5-solicitud`). | La clave primaria `solicitud_uuid` en `cola_sync` rechaza el duplicado con error de unicidad. | `ERROR DE PK` (Sin mutación) | **`ERROR DE PK`** (*UNIQUE constraint failed*) |

## Análisis de Integridad y Protección en Sistemas Productivos

1. **Inmutabilidad en el Servidor:**  
   Tras correr los 5 casos de simulación, la ejecución de [`postgresql/verificar_sin_cambios_2c.sql`](../postgresql/verificar_sin_cambios_2c.sql) demostró que **la cantidad de pedidos y los stocks en PostgreSQL no sufrieron ninguna modificación**. El estado `SIMULADO_APROBADO` es una mera pre-autorización local de la tablet y jamás constituye una venta firme hasta que el servidor procesa una transacción formal.
2. **Ubicación de la Protección Idempotente en Producción (Caso C6):**  
   En un sistema distribuido real, la protección de idempotencia debe residir en la **capa de la API transaccional de PostgreSQL**. Al recibir un paquete de sincronización con un `solicitud_uuid` (o token de idempotencia en cabecera HTTP), el servidor debe consultar una tabla de deduplicación dentro de una transacción serializable. Si el UUID ya fue procesado con anterioridad, el servidor retorna inmediatamente la respuesta almacenada sin descontar stock dos veces ni crear pedidos duplicados.
