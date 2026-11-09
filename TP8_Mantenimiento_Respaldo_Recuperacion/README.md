# TP8 — Mantenimiento, Respaldo y Recuperación de Base de Datos

**Institución:** Universidad Tecnológica Nacional – Facultad Regional Mendoza (UTN FRM)  
**Cátedra:** Base de Datos II  
**Docente:** Sergio Neira  
**Alumno:** Máximo Juan Cruz Quiroga (`maximoj.quiroga@alumnos.frm.utn.edu.ar`)  
**Proyecto:** Food Store (PostgreSQL 17 — Windows)  
**Ubicación Curricular:** Unidad 6 — Mantenimiento, Respaldo y Recuperación (Semana 10)  

---

## 1. Guía de Navegación de la Entrega

Este directorio consolida el trabajo práctico de la **Unidad 6** sobre continuidad operativa, procedimientos automatizados de respaldo, restauración no destructiva y mantenimiento justificado:

| Archivo o Directorio | Descripción y Propósito |
|---|---|
| [**`informe_u6_Maximo_Quiroga_2026.md`**](informe_u6_Maximo_Quiroga_2026.md) | **Informe técnico completo (Markdown):** Metodología, resultados cuantitativos de RTO y RPO, paridad de conteos, los 9 controles lógicos de integridad, análisis de mantenimiento y lecciones aprendidas. |
| [**`informe_u6_Maximo_Quiroga_2026.pdf`**](informe_u6_Maximo_Quiroga_2026.pdf) | **Informe oficial en PDF:** Versión ejecutiva compilada lista para entrega. |
| [**`SPEC_U6.md`**](SPEC_U6.md) | **Especificación operativa:** Frecuencias de respaldo y mantenimiento, metas de RPO/RTO y protocolos de seguridad sin exposición de contraseñas. |
| [**`backup_foodstore.ps1`**](backup_foodstore.ps1) | **Script de respaldo automatizado:** Generación de dumps binarios (`pg_dump -Fc`), cálculo de SHA-256 y exportación de metadatos en JSON. |
| [**`restore_test.ps1`**](restore_test.ps1) | **Script de restauración y auditoría:** Reconstrucción en `foodstore_restore_test`, validación de 9 reglas lógicas de integridad y medición de tiempos RTO/RPO. |
| [**`pg_common.ps1`**](pg_common.ps1) | **Módulo auxiliar PowerShell:** Funciones compartidas para invocación de utilitarios de PostgreSQL, captura de métricas y validaciones lógicas. |
| [**`health_check.sql`**](health_check.sql) | **Diagnóstico de salud del motor:** Consultas de solo lectura sobre tamaños de base, transacciones, aciertos de caché, conexiones y autovacuum. |
| [**`maintenance.sql`**](maintenance.sql) | **Mantenimiento justificado:** `ANALYZE` selectivo sobre relaciones pequeñas con estadísticas ausentes, validando que los conteos de filas permanezcan intactos. |
| [**`pruebas/test_delivery.ps1`**](pruebas/test_delivery.ps1) | **Suite de validación automatizada:** 14 pruebas con herramientas simuladas que verifican guardas de seguridad, hashes SHA-256 y detección de anomalías. |
| [**`evidencias/`**](evidencias/) | Registros fechados, archivos JSON de metadatos de respaldo y resultados de ejecución. |
| [**`MANIFEST_SHA256.txt`**](MANIFEST_SHA256.txt) | Manifiesto criptográfico SHA-256 de todos los artefactos entregados. |
| [**`TPUnidad_6_Mantenimiento_FoodStore (1).pdf`**](TPUnidad_6_Mantenimiento_FoodStore%20(1).pdf) | Consigna oficial emitida por la cátedra. |

---

## 2. Resumen de Resultados Principales (`2026-11-09`)

- **RTO Observado:**
  - Base de desarrollo (`foodstore_dev`, 45.004 bytes): **0,964 s** (Meta: $\le 15$ min).
  - Base con carga volumétrica (`foodstore_tp3_carga`, 6.021.693 bytes, 470.008 filas base): **4,119 s** (Meta: $\le 15$ min).
- **RPO Proxy Observado:** **0,735 s** (`foodstore_dev`) y **1,719 s** (`foodstore_tp3_carga`), cumpliendo ampliamente la meta de diseño ($\le 24$ horas).
- **Integridad de Datos:** **100% de paridad** en las 5 tablas canónicas (`categorias`, `clientes`, `productos`, `pedidos`, `detalles_pedido`) más `usuarios`, y **0 anomalías** en los 9 controles lógicos.
- **Mantenimiento:** Cobertura estadística expandida en relaciones pequeñas mediante `ANALYZE VERBOSE` selectivo (`categorias`: `0 → 4`, `usuarios`: `0 → 9`, `mv_resumen_ventas_categoria_mes`: `6 → 6`), preservando la totalidad de los datos.

---

## 3. Instrucciones de Ejecución Paso a Paso

### Requisitos Previos
- Herramientas cliente de PostgreSQL 17 en `C:\Program Files\PostgreSQL\17\bin` (o indicadas vía `-PgBin`).
- Autenticación segura configurada en `%APPDATA%\postgresql\pgpass.conf` (los scripts usan `-w` para no exponer credenciales).

### Paso 1: Ejecutar la suite de pruebas simuladas (Sin requerir conexión a PostgreSQL)
```powershell
powershell.exe -NoProfile -ExecutionPolicy RemoteSigned -File .\pruebas\test_delivery.ps1
```
*Resultado esperado:* `PASS 14 checks`.

### Paso 2: Generar respaldo automatizado
```powershell
powershell.exe -NoProfile -ExecutionPolicy RemoteSigned -File .\backup_foodstore.ps1 -SourceDatabase foodstore_dev
powershell.exe -NoProfile -ExecutionPolicy RemoteSigned -File .\backup_foodstore.ps1 -SourceDatabase foodstore_tp3_carga
```

### Paso 3: Simulación de restauración y verificación lógica
```powershell
powershell.exe -NoProfile -ExecutionPolicy RemoteSigned -File .\restore_test.ps1 -MetadataPath "$env:USERPROFILE\TP8_Backups\<carpeta_respaldo>\metadata.json" -OutputDirectory ".\restore_results"
```

### Paso 4: Diagnóstico de salud y mantenimiento justificado
```powershell
psql -X -w -h localhost -p 5432 -U postgres -d foodstore_dev -v ON_ERROR_STOP=1 -f .\health_check.sql
psql -X -w -h localhost -p 5432 -U postgres -d foodstore_restore_test -v ON_ERROR_STOP=1 -f .\maintenance.sql
```
