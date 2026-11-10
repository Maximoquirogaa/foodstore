# Declaración de Uso de IA (DUIA) - TP3

Obligatoria para toda la práctica, según la política de uso responsable de IA de la cátedra.

| Herramienta | Para qué se usó | Prompt / spec (resumen) | Se aceptó / se descartó — por qué |
| :--- | :--- | :--- | :--- |
| **Gemini / IA Asistente** | **Parte 1**: Script de carga masiva de datos (50.000 productos, 200.000 pedidos) sin usar PL/pgSQL. | *"Generá un script SQL con generate_series para insertar masivamente en las tablas respetando las restricciones, sin tirar la base."* | **Aceptado (con ajustes)**. Se aplicó un bloque `ON CONFLICT DO NOTHING` que no estaba previsto inicialmente para lidiar con ejecuciones parciales. |
| **Gemini / IA Asistente** | **Parte 2**: Análisis de EXPLAIN ANALYZE y creación de índices. | *"Analiza estos 3 planes de ejecución lentos, explica la causa del problema y dame el DDL de los índices para optimizar."* | **Aceptado**. Se validó y midió empíricamente que los índices propuestos (`idx_productos_precio_activo`, `idx_pedidos_fecha`) bajaron el tiempo en un 99%. |
| **Gemini / IA Asistente** | **Parte 3**: Lectura Crítica de los planes interpretados. | *"Actúa como una IA estándar y dame la explicación de los nodos de ejecución de las 3 consultas."* | **Descartado / Corregido**. La IA cometió errores conceptuales (confundir el valor `cost` con milisegundos, y atribuir mejoras al nodo erróneo). Se documentó en la tabla de Lectura Crítica. |
| **Gemini / IA Asistente** | **Parte 4**: Redacción de subconsultas a partir de especificaciones estrictas. | *"Dada esta especificación de agregación y subconsulta, escribe el SQL principal y una alternativa que arroje el mismo resultado, validado con EXCEPT."* | **Aceptado**. Se verificó formalmente la equivalencia ejecutando las consultas combinadas y confirmando el retorno de 0 filas discordantes. |

