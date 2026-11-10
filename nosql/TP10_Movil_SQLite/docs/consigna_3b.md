# Consigna 3.b — Plan de Mantenimiento Integral (Ampliación al plan de Unidad 6)

El plan de contingencia y resiliencia de la Unidad 6 (RTO $\le$ 15 minutos, RPO $\le$ 24 horas para PostgreSQL) se extiende formalmente para incorporar la persistencia políglota y los dispositivos móviles desconectados.

---

### 1. Políticas de Respaldo y Ensayo de Restauración por Motor

| Motor | Qué se respalda | Periodicidad y Método | Procedimiento de Ensayo |
|---|---|---|---|
| **PostgreSQL 17** | Base relacional completa (`foodstore_dev`) y objetos globales (`pg_dumpall --globals-only`). | Diario a las 02:00 AM con `pg_dump -Fc` comprimido. | Restauración automatizada en base descartable (`restore_test.ps1` en `foodstore_restore_test`), verificando 9 métricas de integridad. |
| **MongoDB** | Colección documental `pedidos` en `foodstore_nosql`. | Semanal con `mongodump --gzip` (o diario diferencial). No es crítico: se reconstruye vía ETL desde Postgres. | Restauración de prueba con `mongorestore` sobre `foodstore_nosql_test`, validando conteo de documentos y consistencia de esquemas. |
| **SQLite (Tablets Móviles)** | Exclusivamente datos volátiles no sincronizados: `pedido_borrador`, `item_borrador` y `cola_sync`. | Al cierre de cada jornada de feria mediante el comando online `.backup` de SQLite CLI. | Verificación de integridad estructural con `PRAGMA integrity_check;` (debe responder `ok`) y conteo de solicitudes pendientes. |

---

### 2. Comportamiento de las Tablets ante la Restauración de un Respaldo Antiguo en PostgreSQL

Si el servidor central de PostgreSQL sufre una contingencia grave y se restaura un backup con 12 o 24 horas de antigüedad, las tablets en la feria pueden contener un catálogo más nuevo que el servidor restaurado. Como la autoridad indiscutible es el servidor, las tablets deben seguir este protocolo:

1. **Invalidación de Caché:** La tablet descarta su catálogo local y descarga una instantánea fresca (`servidor_snapshot.csv`) emitida por el servidor restaurado, actualizando `producto_cache`.
2. **Reevaluación del Semáforo:** La tablet vuelve a ejecutar `semaforo.sql` sobre todas las solicitudes que figuren en estado `PENDIENTE`. Si un precio restaurado volvió a su valor previo, la solicitud pasará a `CONFLICTO` y se renegociará con el cliente (Caso C2).
3. **Reenvío Seguro con Idempotencia:** Las solicitudes que se emitieron con posterioridad a la fecha del backup son reenviadas con su `solicitud_uuid` original. Al no existir en el PostgreSQL restaurado, el servidor las procesa en orden sin duplicarlas, preservando la continuidad del negocio.

---

### 3. Protocolo de Revisión de Solicitudes en `CONFLICTO` o `RECHAZADO`

* **Solicitudes en `CONFLICTO` (Amarillo):** Se resuelven **en tiempo real en el mostrador**. El operador del food truck le comunica la discrepancia de precio al cliente; si este acepta, se actualiza el borrador local y se despacha una nueva solicitud (Caso C2).
* **Solicitudes en `RECHAZADO` (Rojo):** Son analizadas **al final de cada turno/jornada** por el encargado de la feria. Si el rechazo fue por falta de stock, se da aviso para reponer insumos; si fue por producto dado de baja, se cancela definitivamente el borrador.
* **Auditoría Semanal de la Base Central:** El Administrador de Base de Datos (DBA) ejecuta periódicamente la consulta de monitoreo en las tablets y servidores:

```sql
SELECT estado, motivo, COUNT(*) AS total_solicitudes
FROM cola_sync
WHERE estado IN ('CONFLICTO', 'RECHAZADO')
GROUP BY estado, motivo
ORDER BY total_solicitudes DESC;
```

Si la métrica de rechazos por "Stock insuficiente" supera el 15% de las órdenes, indica que las tablets están sincronizando con baja frecuencia y se reduce el intervalo de actualización de instantáneas de 4 horas a 1 hora.
