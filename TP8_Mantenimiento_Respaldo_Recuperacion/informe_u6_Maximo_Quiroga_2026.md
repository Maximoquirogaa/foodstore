# TP8 — Mantenimiento, Respaldo y Recuperación de Base de Datos

**Institución:** Universidad Tecnológica Nacional – Facultad Regional Mendoza (UTN FRM)  
**Cátedra:** Base de Datos II  
**Docente:** Sergio Neira  
**Alumno:** Máximo Juan Cruz Quiroga (`maximoj.quiroga@alumnos.frm.utn.edu.ar`)  
**Proyecto:** Food Store (PostgreSQL 17 — Windows)  
**Ubicación Curricular:** Unidad 6 — Mantenimiento, Respaldo y Recuperación (Semana 10)  

---

## 1. Objetivo y Entorno Operativo

El objetivo del presente laboratorio es diseñar, validar y auditar un procedimiento integral de continuidad operativa sobre la base de datos Food Store, abarcando:
1. **Generación automatizada de respaldos consistentes** en formato binario custom (`pg_dump -Fc`).
2. **Diagnóstico de salud del motor** (`health_check.sql`) mediante inspección de catálogos de PostgreSQL (`pg_stat_database`, `pg_stat_user_tables`, `pg_stat_activity`).
3. **Mantenimiento justificado del planificador** (`maintenance.sql`) aplicando `ANALYZE` específico sobre relaciones pequeñas con estadísticas ausentes.
4. **Simulacro de recuperación y medición de RTO/RPO** (`restore_test.ps1`) en una base descartable (`foodstore_restore_test`), verificando paridad de conteos y 9 reglas lógicas de integridad referencial y de dominio.

### Entornos Evaluados
- `foodstore_dev`: Esquema canónico de desarrollo de Food Store (`categorias`, `clientes`, `productos`, `pedidos`, `detalles_pedido`, `usuarios`, 5 vistas regulares y 1 vista materializada).
- `foodstore_tp3_carga`: Base con carga masiva (5 categorías, 20.000 clientes, 50.000 productos, 200.000 pedidos, 200.000 detalles de pedido y 3 usuarios) para comprobar el impacto del volumen sobre la ventana de recuperación.
- `foodstore_restore_test`: Destino de restauración transitorio y descartable.

---

## 2. Procedimiento de Respaldo y Restauración

### 2.1 Respaldo Lógico Automatizado (`backup_foodstore.ps1`)
- **Comando:** `pg_dump -w -h localhost -p 5432 -U postgres -d <origen> -Fc -f <ruta_dump>`
- **Seguridad:** Autenticación sin contraseñas interactivas resuelta vía archivo `pgpass.conf`. Se impide almacenar contraseñas en scripts o historial de consola.
- **Trazabilidad:** Cada respaldo genera un subdirectorio fechado con:
  - Archivo binario comprimido `.dump`.
  - Checksum criptográfico SHA-256 (`dump_sha256`).
  - Metadatos en formato JSON (`metadata.json`) con la línea base de conteos de tablas previa al respaldo.
  - Logs completos de la invocación (`logs/pg_dump.log` y `logs/archive_contents.log`).

### 2.2 Reconstrucción en Entorno Descartable (`restore_test.ps1`)
- **Creación de Destino:** `createdb --template=template0 foodstore_restore_test`.
- **Defensa contra Destrucción Accidental:** Si la base `foodstore_restore_test` ya existe, el proceso aborta de inmediato para proteger datos preexistentes. Su eliminación previa requiere confirmación manual del operador (`dropdb -i`).
- **Restauración:** `pg_restore --exit-on-error --no-owner --no-privileges -d foodstore_restore_test <dump_path>`.

---

## 3. Validación de Línea Base y Controles Lógicos

Finalizada la restauración, el script ejecuta una auditoría de consistencia para validar que la copia restaurada sea idéntica a la fuente y cumpla con las reglas del negocio:

### 3.1 Paridad Exacta de Conteos
| Tabla | `foodstore_dev` (Antes) | `foodstore_dev` (Restaurado) | `foodstore_tp3_carga` (Antes) | `foodstore_tp3_carga` (Restaurado) |
|---|---:|---:|---:|---:|
| **categorias** | 3 | 3 | 5 | 5 |
| **clientes** | 3 | 3 | 20.000 | 20.000 |
| **productos** | 5 | 5 | 50.000 | 50.000 |
| **pedidos** | 5 | 5 | 200.000 | 200.000 |
| **detalles_pedido** | 7 | 7 | 200.000 | 200.000 |
| **usuarios** (verificación extra) | 3 | 3 | 3 | 3 |

### 3.2 Los 9 Controles Lógicos de Integridad (Resultado = 0 anomalías)
1. `producto_precio_negativo`: 0 filas con precio negativo o nulo.
2. `producto_stock_negativo`: 0 filas con stock negativo o nulo.
3. `detalle_cantidad_no_positiva`: 0 filas con cantidad menor o igual a 0.
4. `detalle_precio_negativo`: 0 filas con precio unitario negativo.
5. `detalle_subtotal_incorrecto`: 0 desvíos en el cálculo `cantidad * precio_unitario`.
6. `producto_categoria_huerfana`: 0 productos apuntando a categorías inexistentes.
7. `pedido_cliente_huerfano`: 0 pedidos con clientes inexistentes.
8. `detalle_pedido_huerfano`: 0 renglones con cabeceras de pedido inexistentes.
9. `detalle_producto_huerfano`: 0 renglones con productos inexistentes.

---

## 4. Métricas de Continuidad: RTO y RPO

Las metas fijadas en la especificación [SPEC_U6.md](SPEC_U6.md) fueron:
- **RTO (Recovery Time Objective):** $\le 15$ minutos.
- **RPO (Recovery Point Objective):** $\le 24$ horas (frecuencia diaria de respaldo).

### Resultados Observados (Ejecución `2026-11-09`)
| Métrica | Meta de Diseño | Entorno Desarrollo (`foodstore_dev`) | Entorno Carga Masiva (`foodstore_tp3_carga`) |
|---|---|---:|---:|
| **Tamaño del Dump** | — | **45.004 bytes** (~43,9 KB) | **6.021.693 bytes** (~5,74 MB) |
| **RTO Observado** | $\le 15$ min | **0,964 segundos** | **4,119 segundos** |
| **Antigüedad del Respaldo (RPO Proxy)** | $\le 24$ horas | **0,735 segundos** | **1,719 segundos** |
| **Estado de Restauración** | PASS | **PASS (100% verificado)** | **PASS (100% verificado)** |

> **Interpretación:**
> - El **RTO** medido incluye la creación de la base, la descompresión binaria, la recreación de índices y llaves foráneas, y la ejecución de los 9 controles lógicos. En la base de carga volumétrica (470.008 filas totales en tablas base), el RTO fue de apenas **4,119 segundos**, situándose varios órdenes de magnitud por debajo del umbral de 15 minutos.
> - La **antigüedad del respaldo** (`rpo_proxy_seconds`) mide la frescura del dump al momento de la restauración. Dado que durante el ensayo no hubo escrituras en las bases de origen, no existió pérdida de información ($RPO = 0$ datos perdidos).

---

## 5. Mantenimiento Justificado del Motor

A través de [health_check.sql](health_check.sql) se identificó el siguiente comportamiento del planificador de consultas de PostgreSQL:
- **Diagnóstico:** En `foodstore_tp3_carga` todas las tablas registraron **0 tuplas muertas**. Tras la restauración en `foodstore_restore_test`, `detalles_pedido` (200.000 filas) y `mv_resumen_ventas_categoria_mes` (65 filas) ya tenían estadísticas de `autoanalyze`, mientras que las relaciones pequeñas (`categorias`, con 5 filas, y `usuarios`, con 3 filas) permanecían con `last_analyze` y `last_autoanalyze` en `NULL` por hallarse por debajo del umbral automático de `50 + 0,1 * filas`.
- **Acción aplicada en `maintenance.sql`:** Se ejecutó un `ANALYZE VERBOSE` selectivo y focalizado sobre `categorias`, `usuarios` y `mv_resumen_ventas_categoria_mes` en la base de prueba:
  - Columnas con estadísticas en `categorias`: pasaron de **0 a 4**.
  - Columnas con estadísticas en `usuarios`: pasaron de **0 a 9**.
  - Columnas con estadísticas en `mv_resumen_ventas_categoria_mes`: se actualizaron y validaron (**6**).
  - **Validación de seguridad:** Se comprobó mediante `\gset` que los conteos de filas permanecieron estrictamente idénticos antes y después del `ANALYZE` (`5 = 5`, `3 = 3`, `65 = 65`).
- **Exclusión de `VACUUM FULL`:** Se descartó el uso de `VACUUM FULL` en rutinas periódicas porque bloquea la tabla en modo exclusivo (`AccessExclusiveLock`), impidiendo lecturas y escrituras en producción.

---

## 6. Análisis Post-Incidente y Lecciones Aprendidas

1. **Gestión de Credenciales en Automatizaciones:**
   - La prueba con `-w` (sin prompt de contraseña) requiere que `pgpass.conf` tenga el formato exacto sin espacios al inicio y con permisos NTFS restringidos únicamente al usuario interactivo y al servicio de PostgreSQL.
2. **Robustez en la Comparación de Metadatos:**
   - Durante los primeros ensayos de integración, se detectó que comparar objetos JSON como texto plano provocaba falsos positivos si los motores ordenaban las claves de manera distinta. Se resolvió la comparación deserializando a objetos y validando propiedad por propiedad.
3. **Propuesta de Mejora para Producción:**
   - Se recomienda incorporar un `ANALYZE` integral automático al final del script `restore_test.ps1`, de modo que cualquier réplica restaurada para contingencia entre en servicio con estadísticas de ejecución frescas y óptimas para el planificador de PostgreSQL.

---

## 7. Conclusión

El procedimiento de respaldo, restauración, diagnóstico y mantenimiento de Food Store cumple rigurosamente con los estándares de la cátedra de Base de Datos II (UTN FRM), garantizando un RTO inferior a 10 segundos para bases medianas/grandes, integridad lógica validada al 100% y una gestión segura y sin exposición de secretos.
