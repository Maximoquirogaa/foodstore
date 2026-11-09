# Diagnóstico de Salud y Mantenimiento — Unidad 6

**Alumno:** Máximo Juan Cruz Quiroga (`maximoj.quiroga@alumnos.frm.utn.edu.ar`)  
**Motor:** PostgreSQL 17.11 (x86_64-windows)  
**Fecha de ejecución:** 2026-11-09  
**Estado de Ejecución:** Código de salida `0` en los 3 entornos evaluados.

---

## 1. Métricas de Salud del Motor (`health_check.sql`)

El script utiliza `current_database()`, transacción `READ ONLY`, `psql -X -w` y `ON_ERROR_STOP=1`. No expone contraseñas ni registra texto SQL de otras sesiones.

| Base Evaluada | Tamaño Físico Observado | Conexiones Registradas | Cache Hit Ratio | Deadlocks Acumulados |
|---|---:|---:|---:|---:|
| **`foodstore_dev`** | 8.713.907 bytes (`8510 kB`) | 1 (`active`) | 98,82% | 0 |
| **`foodstore_tp3_carga`** | 58.537.651 bytes (`56 MB`) | 1 (`active`) | 99,87% | 0 |
| **`foodstore_restore_test`** (pre-mantenimiento) | 58.857.139 bytes (`56 MB`) | 2 (`active`) | 99,18% | 0 |

### Análisis de Autovacuum y Estadísticas
- `autovacuum` (`on`) y `track_counts` (`on`) están activos con valores por defecto (`scale_factor = 0.1` para `autoanalyze` y `0.2` para `autovacuum`, `threshold = 50`).
- En `foodstore_tp3_carga` todas las tablas presentan **0 tuplas muertas** (`n_dead_tup = 0`). Tras restaurar `foodstore_restore_test`, `detalles_pedido` (200.000 filas) y `mv_resumen_ventas_categoria_mes` (65 filas) ya habían recibido `autoanalyze`, mientras que `categorias` (5 tuplas vivas estimadas) y `usuarios` (3 tuplas vivas estimadas) mostraban `last_analyze = NULL` y `last_autoanalyze = NULL` por hallarse debajo del umbral automático, mientras `pedidos`, `productos` y `clientes` estaban aún en cola de los workers de autovacuum recién iniciados. No se justifica ejecutar `VACUUM FULL` ni `REINDEX`.

---

## 2. Mantenimiento Justificado Ejecutado (`maintenance.sql`)

Conforme a la documentación oficial de PostgreSQL 17 (`pg_dump` no exporta estadísticas del optimizador y recomienda ejecutar `ANALYZE` tras restaurar), se aplicó `ANALYZE VERBOSE` focalizado sobre las tres relaciones pequeñas en `foodstore_restore_test` (`categorias`, `usuarios` y `mv_resumen_ventas_categoria_mes`):

| Relación Analizada | Columnas con Estadísticas (Antes) | Columnas con Estadísticas (Después) | Conteo de Filas Preservado |
|---|---:|---:|---:|
| **`categorias`** | 0 | **4** | 5 = 5 |
| **`usuarios`** | 0 | **9** | 3 = 3 |
| **`mv_resumen_ventas_categoria_mes`** | 6 | **6** | 65 = 65 |

`maintenance.sql` incorpora guardia de nombre de base (`foodstore_restore_test`), `lock_timeout = '5s'` y `statement_timeout = '60s'`. Tras el mantenimiento (`foodstore_restore_test_after_maintenance.log`), la base reporta `58.906.291` bytes (`56 MB`), cache hit ratio `99,21%`, `0` deadlocks y `last_analyze` actualizado en las tres relaciones tratadas. Los archivos `maintenance_execution.json`, `health_after_execution.json` y `foodstore_restore_test_after_maintenance.log` documentan la ejecución exitosa sin alteración de datos.
