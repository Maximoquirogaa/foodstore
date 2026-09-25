# Parte 2 - Laboratorio: Consultas lentas y optimización medida

## Tabla de resultados

| Consulta | Plan antes (nodo, cost, tiempo real) | Cambio aplicado | Plan después (nodo, cost, tiempo real) | Mejora |
| :--- | :--- | :--- | :--- | :--- |
| **Consulta 1** (Filtro por precio y activo) | `Seq Scan`, Cost: 8794.78, Tiempo: **46.671 ms** | Creación de índice parcial: `idx_productos_precio_activo` | `Index Scan`, Cost estimado baja considerablemente, Tiempo: **0.216 ms** | **~216x más rápido** |
| **Consulta 2** (Filtro por fecha 30 días) | `Parallel Seq Scan`, Cost: 16265.01, Tiempo: **156.123 ms** | Creación de índice en fecha: `idx_pedidos_fecha` | `Index Scan`, Cost estimado se desploma, Tiempo: **0.316 ms** | **~494x más rápido** |
| **Consulta 3** (Cruzar pedidos, productos y filtro) | `Sort + Nested Loop`, Cost: 25203.36, Tiempo: **136.808 ms** | Creación de índices: `idx_pedidos_fecha_desc` y `idx_productos_categoria` | Eliminación de Sort en disco, ahora usa B-Tree en reversa, Tiempo: **0.402 ms** | **~340x más rápido** |

---

# Parte 3 - Lectura crítica de planes interpretados por IA

| Afirmación de la IA | ¿Correcta? | Corrección / evidencia del plan real |
| :--- | :--- | :--- |
| *"El cost es 7144.00, lo que significa que el motor tardó exactamente 7,144 milisegundos en encontrar las filas."* | **No** | Confunde la unidad arbitraria de estimación interna `cost` de PostgreSQL con milisegundos reales de tiempo (`actual time`). El tiempo real del Seq Scan fue de `38.176` ms. |
| *"El tiempo perdido de 156ms se debe principalmente a que el Group Key (la agregación) no tiene un índice"* | **No** | Atribuye la mejora/retraso a la causa equivocada. Un `HashAggregate` o agrupamiento no requiere estrictamente un índice para funcionar rápido. El retraso real era el barrido secuencial donde "Rows Removed by Filter: 122383" descartaba la inmensa mayoría de la tabla `pedidos`. |
| *"Hace un Index Scan sobre clientes_pkey buscando por categoría."* | **No** | Falla conceptual grave. La categoría vive en la tabla `productos`. El plan indica `Index Cond: (id_cliente = p.id_cliente)` usando el PK de clientes, no la categoría de productos. |

