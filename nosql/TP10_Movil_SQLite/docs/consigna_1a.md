# Consigna 1.a — Qué datos viajan a la tablet

## Tabla de Atributos: Servidor (PostgreSQL) vs. Tablet (SQLite)

| Atributo / Campo | ¿Viaja a la tablet? | Columna en SQLite | Justificación Técnica |
|---|:---:|---|---|
| `id_producto` | **SÍ** | `producto_cache.id` | Clave primaria requerida para identificar unívocamente el ítem al armar los borradores de compra. |
| `nombre` | **SÍ** | `producto_cache.nombre` | Requerido por la interfaz móvil para que el vendedor visualice qué está agregando a la comanda. |
| `precio_actual` | **SÍ** | `producto_cache.precio_centavos` | Viaja multiplicado por 100 como entero para evitar imprecisiones de punto flotante en SQLite. |
| `stock` | **SÍ** | `producto_cache.stock_visto` | Permite advertir al vendedor en la feria si el producto está próximo a agotarse (validación preliminar local). |
| `activo` | **SÍ** | `producto_cache.disponible` y `eliminado` | `disponible = 1` si está activo; `eliminado = 1` si sufrió baja lógica, impidiendo nuevos pedidos. |
| `fecha_copia` | **SÍ** | `producto_cache.fecha_copia` | Marca de tiempo que registra cuándo se tomó la instantánea del servidor. |
| `id_categoria` | **NO** | — | Innecesario en la tablet de ventas rápidas; reduce el tamaño de transferencia y simplifica el esquema móvil. |
| `usuarios` / `passwords` | **NO** | — | **Principio de Mínimo Privilegio:** Nunca deben viajar credenciales de autenticación ni hashes a dispositivos móviles. |
| `clientes` / `emails` | **NO** | — | **Privacidad:** La tablet en la feria emite tickets al paso sin consultar historiales personales de clientes. |
| `pedidos_anteriores` | **NO** | — | El historial contable reside exclusivamente en PostgreSQL y MongoDB; la tablet solo gestiona borradores de la jornada. |

## Justificación y Fuente de Verdad

En la arquitectura de Food Store, **PostgreSQL es la única e indiscutible fuente de verdad**. 

La tablet que opera en el food truck en la feria sin señal celular funciona bajo el axioma: **«El móvil propone, el servidor dispone»**. La base de datos SQLite almacena exclusivamente una instantánea temporal (*snapshot*) de solo lectura del catálogo comercial para permitir la continuidad operativa fuera de línea. Ni los precios, ni el stock, ni los estados de venta se deciden en el cliente móvil: la tablet únicamente construye borradores de pedidos y proyecta resultados simulados, delegando la confirmación transaccional definitiva al servidor central cuando recupera la conectividad.
