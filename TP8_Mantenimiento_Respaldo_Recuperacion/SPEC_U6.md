# SPEC_U6 — Operación, Respaldo, Mantenimiento y Recuperación

**Proyecto:** Food Store — Base de Datos II (UTN FRM)  
**Institución:** Universidad Tecnológica Nacional – Facultad Regional Mendoza  
**Docente:** Sergio Neira  
**Alumno:** Máximo Juan Cruz Quiroga (`maximoj.quiroga@alumnos.frm.utn.edu.ar`)  
**Ciclo Lectivo:** 2026  
**Ubicación Curricular:** Unidad 6 — Mantenimiento, Respaldo y Recuperación (Semana 10)  

---

## 1. Alcance y Frecuencia de Operación

El procedimiento de continuidad operativa cubre dos entornos de referencia:
- `foodstore_dev`: esquema de desarrollo adaptado a partir del modelo relacional canónico de Food Store (`categorias`, `clientes`, `productos`, `pedidos`, `detalles_pedido`, `usuarios`, vistas y vista materializada).
- `foodstore_tp3_carga`: entorno con carga volumétrica masiva (20.000 clientes, 50.000 productos, 200.000 pedidos, 200.000 detalles) para contrastar tiempos de recuperación bajo estrés y crecimiento de datos.
- **Destino de prueba:** `foodstore_restore_test` (base descartable creada desde `template0` para pruebas no destructivas de restauración). Las bases de origen nunca se modifican durante los ensayos.

| Frecuencia | Acción | Criterio de Éxito / Evidencia |
|---|---|---|
| **Diaria** | Respaldo lógico (`pg_dump -Fc`) | Archivo `.dump` no vacío, checksum SHA-256 verificado, código de salida 0 y registro en `metadata.json`. |
| **Diaria** | Chequeo de salud (`health_check.sql`) | Diagnóstico en solo lectura: tamaño de base, conexiones, tuplas vivas/muertas, deadlocks y estado de autovacuum. |
| **Semanal** | Mantenimiento justificado (`maintenance.sql`) | Detección de relaciones pequeñas bajo el umbral de autovacuum, ejecución de `ANALYZE` puntual y validación de conteos preservados. |
| **Semanal** | Simulacro de restauración (`restore_test.ps1`) | Reconstrucción en `foodstore_restore_test`, validación de 9 controles de integridad lógica y cálculo de RTO y RPO proxy. |

---

## 2. Protocolo de Seguridad Operativa

1. **Gestión de Credenciales:**
   - Queda estrictamente prohibido incluir contraseñas en scripts, comandos o evidencias del repositorio.
   - La autenticación local se resuelve mediante el archivo `pgpass.conf` de PostgreSQL (`localhost:5432:*:postgres:contrasena`) con permisos de lectura restringidos (`0600`).
2. **Defensa contra Destrucción Accidental:**
   - Si la base de destino `foodstore_restore_test` ya existe, el script aborta inmediatamente sin borrarla automáticamente. Cualquier eliminación previa exige decisión explícita y confirmación del operador (`dropdb -i`).
3. **Almacenamiento de Respaldos:**
   - Los archivos `.dump` pesados se almacenan fuera del repositorio Git (`$env:USERPROFILE\TP8_Backups`), versionando en Git únicamente los metadatos JSON, hashes SHA-256 y logs de ejecución.
4. **Política de Mantenimiento:**
   - Se prohíbe el uso periódico indiscriminado de `VACUUM FULL` en ambientes de producción (por bloqueo exclusivo `AccessExclusiveLock`).
   - Se aplica `ANALYZE` específico sobre relaciones con estadísticas obsoletas, validando que los conteos de filas no sufran ninguna alteración.

---

## 3. Metas de Continuidad del Negocio (RTO y RPO)

Las metas de recuperación fijadas para el laboratorio de Food Store son:
- **RPO (Recovery Point Objective) ≤ 24 horas:** Garantizado mediante la ejecución periódica diaria de respaldos automatizados. En el laboratorio, se mide la *antigüedad del respaldo* (`rpo_proxy_seconds`) al iniciar la restauración.
- **RTO (Recovery Time Objective) ≤ 15 minutos:** Tiempo transcurrido desde el inicio de la creación de la base de destino (`createdb`), pasando por la restauración con `pg_restore`, hasta la conclusión exitosa de las validaciones de integridad lógica.

---

## 4. Criterios de Validación Lógica (Línea Base)

Para certificar que la base restaurada es consistente y no presenta anomalías, se auditan:
1. **Paridad de conteos:** `categorias`, `clientes`, `productos`, `pedidos`, `detalles_pedido` deben coincidir exactamente con la línea base previa al respaldo.
2. **9 Controles de Integridad Lógica (deben dar 0 desvíos):**
   - Productos con precio negativo o nulo.
   - Productos con stock negativo o nulo.
   - Detalles de pedido con cantidad menor o igual a cero.
   - Detalles de pedido con precio unitario negativo.
   - Detalles de pedido con subtotal discrepante (`cantidad * precio_unitario`).
   - Productos con categoría inexistente (huérfanos FK).
   - Pedidos con cliente inexistente (huérfanos FK).
   - Detalles con pedido inexistente (huérfanos FK).
   - Detalles con producto inexistente (huérfanos FK).
