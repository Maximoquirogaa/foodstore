# Ensayos de Respaldo y Restauración — TP8 (Unidad 6)

**Alumno:** Máximo Juan Cruz Quiroga (`maximoj.quiroga@alumnos.frm.utn.edu.ar`)  
**Materia:** Base de Datos II · UTN FRM  
**Motor:** PostgreSQL 17.11  
**Fecha de ejecución:** 2026-11-09  

---

## 1. Resumen de Ejecución

Se respaldaron ambas bases PostgreSQL 17 mediante `pg_dump` en formato custom (`-Fc`) y se restauraron sucesivamente en `foodstore_restore_test`, creada desde `template0`. Se utilizó `pg_restore --exit-on-error --no-owner --no-privileges`. Los códigos de salida fueron comprobados (`0`). Las bases originales se consultaron en modo de solo lectura y no recibieron modificaciones. El mantenimiento selectivo se ejecutó posteriormente sobre la copia restaurada; sus registros se conservan en `salud_mantenimiento/`.

| Ensayo Evaluado | Tamaño del Respaldo (bytes) | RTO Observado | Antigüedad del Respaldo al Iniciar (Proxy RPO) | Validación |
|---|---:|---:|---:|:---:|
| **`foodstore_dev`** (Desarrollo) | 45.004 | **0,964 s** | 0,735 s | **PASS (100%)** |
| **`foodstore_tp3_carga`** (Volumen Masivo) | 6.021.693 | **4,119 s** | 1,719 s | **PASS (100%)** |

El RTO medido incluye la creación de la base destino, la restauración física y la ejecución de los 9 controles lógicos de integridad. La especificación operativa ([`../SPEC_U6.md`](../SPEC_U6.md)) fija metas de **RPO $\le 24\text{ h}$** y **RTO $\le 15\text{ min}$**, cumpliéndose con amplio margen en ambos escenarios.

---

## 2. Paridad de Conteos y Controles Lógicos

| Tabla | `foodstore_dev`: Antes = Restaurado | `foodstore_tp3_carga`: Antes = Restaurado |
|---|---:|---:|
| `categorias` | 3 | 5 |
| `clientes` | 3 | 20.000 |
| `productos` | 5 | 50.000 |
| `pedidos` | 5 | 200.000 |
| `detalles_pedido` | 7 | 200.000 |
| `usuarios` (verificación adicional) | 3 | 3 |

Ambas restauraciones conservaron las 6 tablas base, 5 vistas regulares, 1 vista materializada, 52 restricciones y los índices del esquema original (`11` en `foodstore_dev` y `13` en `foodstore_tp3_carga`). Se comprobaron **cero** precios negativos o nulos, stocks negativos o nulos, cantidades no positivas, subtotales inconsistentes y referencias huérfanas en los 9 indicadores auditados.

---

## 3. Resguardo de Archivos Binarios (`.dump`)

Por política de seguridad y buenas prácticas de repositorios Git, los archivos `.dump` binarios completos se almacenan fuera del árbol de control de versiones (en `$env:USERPROFILE\TP8_Backups\`). Este directorio conserva la totalidad de los metadatos JSON (`results.json`, `respaldo_maximo_quiroga_foodstore_dev.json`, `result.json`, `source_before.json`, `restored_after.json`), resúmenes CSV (`summary.csv`), hashes criptográficos SHA-256 y bitácoras de ejecución.
