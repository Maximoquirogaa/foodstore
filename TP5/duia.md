# Declaración de Uso de IA (DUIA) - TP5

Obligatoria para toda la práctica, según la política de uso responsable de IA de la cátedra.

| Herramienta | Para qué se usó | Prompt / Spec (resumen) | Se aceptó / se descartó y por qué |
| :--- | :--- | :--- | :--- |
| **Kiro (simulando IA)** | Parte A: Diseñar plan de indexado (Especificaciones). | *Generar specs para búsquedas de productos por nombre, filtros por precio y por forma de pago.* | **Aceptado**. Generaron los archivos base de especificación requeridos en la carpeta `/specs`. |
| **OpenCode (simulando IA)** | Parte A: Generar código SQL de índices. | *A partir de las specs, redacta los CREATE INDEX.* | **Descartado un índice intencionalmente (Sobreindexación)**. Rechacé explícitamente indexar `forma_pago` por su baja cardinalidad, que penaliza el INSERT sin beneficiar la lectura. |
| **OpenCode (simulando IA)** | Parte B: Generar vistas del sistema ocultando columnas sensibles. | *Crea 3 vistas (catálogo, pedidos, detalles). Asegura que la de pedidos excluya el email como medida de seguridad.* | **Aceptado**. El SQL abstrae la complejidad y permite dar privilegios granulados (SELECT) al usuario limitando los datos expuestos. |
| **OpenCode (simulando IA)** | Parte C: Vista Materializada. | *Escribe el DDL de la materialized view con el agregado de categorías y meses, agregando un UNIQUE INDEX.* | **Aceptado**. Los tiempos bajaron de más de 1000 milisegundos a milésimas. El UNIQUE INDEX se aceptó para habilitar la estrategia de REFRESH CONCURRENTLY en horario nocturno. |

