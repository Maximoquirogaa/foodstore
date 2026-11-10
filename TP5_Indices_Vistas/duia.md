# Declaración de Uso de IA (DUIA) - TP5 Consolidada

**Materia:** Base de Datos II  
**Trabajo Práctico:** TP5 — Plan de Indexado, Vistas y Vistas Materializadas  
**Facultad:** Universidad Tecnológica Nacional — Facultad Regional Mendoza (UTN FRM)  
**Alumno:** Máximo Juan Cruz Quiroga  
**Email:** `maximoj.quiroga@alumnos.frm.utn.edu.ar`  
**Docente:** Sergio Neira  
**Motor:** PostgreSQL 17  
**Base de trabajo:** Esquema masivo Food Store (~20.000 clientes, ~50.000 productos, ~200.000 pedidos, ~500.000 detalles)

---

Esta declaración documenta formalmente la utilización de herramientas de Inteligencia Artificial (Kiro, Claude 3.5 Sonnet y GitHub Copilot) en el marco de la política de uso responsable de la cátedra: *"Especificar con precisión antes de codificar, medir antes y después en el plan real, y documentar los descartes con fundamentación técnica"*.

---

## 1. Parte A — Plan de Indexado y Medición del Costo de Escritura

| Herramienta | Para qué se usó | Prompt / Spec (resumen) | Se aceptó / Se descartó y por qué |
|:---|:---|:---|:---|
| **Kiro / GitHub Copilot** | Evaluar candidato a índice para Q5 (Ranking de clientes): `idx_pedidos_cliente_q5 ON pedidos (id_cliente)`. | Spec 01: Analizar el plan EXPLAIN ANALYZE de Q5 y proponer índice para el enlace de pedidos. | **RECHAZADO**. El optimizador ignoró el índice en las 3 rondas de medición, manteniendo `Parallel Seq Scan` debido a que la consulta agrega la totalidad de las filas históricas. No aporta beneficio y penaliza escrituras. |
| **Kiro / GitHub Copilot** | Evaluar segundo candidato para Q5: `idx_detalles_pedido_id_pedido ON detalles_pedido (id_pedido)`. | Spec 01: Acelerar enlace con detalles de pedido. | **RECHAZADO POR SOBREINDEXACIÓN REDUNDANTE**. Es idéntico a la columna líder de la clave primaria compuesta `(id_pedido, id_producto)`. Pruebas en el motor confirmaron que `WHERE id_pedido = 100` ya resuelve con la PK en 0.031 ms. |
| **Kiro / Claude** | Evaluar intervención de memoria para Q5: `SET LOCAL work_mem = '16MB'`. | Spec 01: Eliminar el spill a disco en `HashAggregate`. | **ACEPTADA**. El operador de agregación redujo sus lotes de 5 a 1 solo batch (100% en RAM), bajando el tiempo en ~26.3% sin tocar índices ni alterar el esquema. |
| **Kiro / GitHub Copilot** | Proponer índice para Q6 (Subconsulta correlacionada): `idx_productos_categoria_precio_activo ON productos (id_categoria, precio_actual DESC) WHERE activo = TRUE`. | Spec 02: Diseñar índice B-Tree para resolver `AVG(precio_actual)` en el WHERE. | **ACEPTADO CON SALVEDAD METODOLÓGICA**. Conmutó el SubPlan a `Index Only Scan` con `Heap Fetches: 0` (271.2 s a 158.7 s). Se documenta explícitamente que la solución estructural es la reescritura mediante JOIN pre-agregado (45 ms). |
| **Kiro / Claude** | Evaluar viabilidad de índice BRIN en `pedidos(fecha_pedido)` para Q4. | Spec 03: Analizar correlación física en disco según `pg_stats`. | **RECHAZADO POR INEFICACIA MATEMÁTICA**. La correlación física arrojó `0.0051` (cercana a 0), demostrando que un índice BRIN no puede podar bloques de disco en datos con fechas aleatorias. |
| **Kiro / GitHub Copilot** | Proponer índice B-Tree compuesto para Q2: `idx_productos_categoria_precio ON productos (id_categoria, precio_actual)`. | Spec 06: Búsqueda exacta por categoría y rango de precio. | **ACEPTADO EN FIRME**. Redujo el tiempo de 4.71 ms a 0.27 ms (~17.1x de mejora) y eliminó el operador explícito `Sort`. |
| **GitHub Copilot** | Asistir en el diseño del script de medición de penalización en escritura (INSERTs masivos). | Generar bloque de inserción de 10.000 tuplas en tabla temporal con 0, 1 y 2 índices. | **ACEPTADO**. Se demostró que cada índice adicional incrementa el tiempo de inserción en +33.5% y +72.2% respectivamente. |

*Detalle completo en:* `Parte_A_Indices/indices.sql` y `informe_mediciones.md`.

---

## 2. Parte B — Vistas Analíticas, Exposición Segura y Seguridad por Roles

| Herramienta | Para qué se usó | Prompt / Spec (resumen) | Se aceptó / Se descartó y por qué |
|:---|:---|:---|:---|
| **Kiro / GitHub Copilot** | Diseñar la estructura DDL de las 5 vistas requeridas (`v_usuario_publico`, `v_reporte_ventas_cliente`, `v_catalogo_productos`, `v_detalle_pedido_producto`, `v_pedido_cliente`). | Spec 04: Crear vistas analíticas y seguras, ocultando contraseñas y datos sensibles. | **ACEPTADO**. Se validó que `v_usuario_publico` omite la columna `contrasena` y que las vistas de ventas utilizan agregaciones y joins coherentes con el esquema. |
| **Kiro / Claude** | Configurar el rol restringido `TP5_reportes` (NOLOGIN), revocar acceso a tablas base y otorgar SELECT a vistas. | Spec 04: Principio de mínimo privilegio para auditores y usuarios de reportes. | **ACEPTADO**. Se capturó la evidencia formal del fallo de permisos (`ERROR: permiso denegado para la tabla usuarios`) al intentar consultar tablas físicas bajo este rol. |
| **GitHub Copilot** | Diseñar el script de verificación formal de equivalencia relacional con `EXCEPT`. | Spec 04: Comprobar formalmente que las vistas retornan exactamente lo mismo que las consultas directas. | **ACEPTADO**. Los tres bloques de prueba bidireccional arrojaron exactamente 0 filas de discrepancia. |

*Detalle completo en:* `Parte_B_Vistas/vistas.sql`, `Parte_B_Vistas/seguridad_roles.sql` y `Parte_B_Vistas/verificacion_vistas.sql`.

---

## 3. Parte C — Vista Materializada (`mv_resumen_ventas_categoria_mes`)

| Herramienta | Para qué se usó | Prompt / Spec (resumen) | Se aceptó / Se descartó y por qué |
|:---|:---|:---|:---|
| **Kiro / GitHub Copilot** | Diseñar el DDL de la Vista Materializada `mv_resumen_ventas_categoria_mes` y su índice único. | Spec 05: Resumen precalculado de facturación por categoría y mes, habilitando refresco no bloqueante. | **ACEPTADO**. Se creó la vista materializada y el índice único sobre `(id_categoria, mes)` requerido para `CONCURRENTLY`. |
| **Kiro / Claude** | Analizar el impacto de rendimiento y el comportamiento de bloqueos en el refresco. | Spec 05: Medir consulta directa vs vista materializada y analizar `AccessExclusiveLock` vs `ExclusiveLock`. | **ACEPTADA**. La vista redujo el tiempo de 976.1 ms a 0.054 ms (~18.076x de aceleración). Se justificó la adopción de `REFRESH CONCURRENTLY` para producción. |

*Detalle completo en:* `Parte_C_Vista_Materializada/vista_materializada.sql` y `informe_mediciones.md`.

---

## Conclusiones Metodológicas

La realización de este TP5 reafirmó la importancia crítica de auditar y medir empíricamente cada propuesta de indexado:
1. **La sobreindexación es un costo real:** Los índices secundarios no son gratuitos; la experimentación demostró que dos índices secundarios penalizan las operaciones de escritura en más de un 70%.
2. **Los índices redundantes deben descartarse:** La propuesta de indexar una columna que ya lidera una clave primaria compuesta demuestra que los asistentes de IA no siempre auditan las restricciones existentes antes de sugerir estructuras.
3. **La arquitectura supera al hardware:** Ajustar 16 MB de memoria de sesión (`work_mem`) o crear una vista materializada precalculada aportan órdenes de magnitud más rendimiento que saturar las tablas con índices secundarios ineficaces.

