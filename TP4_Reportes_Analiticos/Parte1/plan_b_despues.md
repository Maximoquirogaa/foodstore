# QUERY PLAN - FoodStore (UTN FRM) - Consulta B - DESPUÉS

Optimización probada dentro de una transacción (`BEGIN ... ROLLBACK`):
```sql
CREATE INDEX idx_TP4_b_pedidos_cliente ON pedidos (id_pedido) INCLUDE (id_cliente);
ANALYZE pedidos;
```

`EXPLAIN (ANALYZE, BUFFERS, VERBOSE)`

```text
Limit (cost=19055.73..19055.78 rows=20 width=65)
  -> Sort (cost=19055.73..19105.74 rows=20003 width=65)
       Sort Key: (sum((dp.cantidad * dp.precio_unitario))) DESC
       -> Finalize HashAggregate (cost=18273.42..18523.46 rows=20003 width=65)
            Group Key: cl.id_cliente
            Batches: 5  Memory Usage: 9521kB  Disk Usage: 744kB
            -> Gather (cost=13722.74..17973.37 rows=40006 width=40)
                 Workers Planned: 2  Workers Launched: 2
                 -> Partial HashAggregate (cost=12722.74..12972.78 rows=20003 width=40)
                      Batches: 5
                      -> Hash Join (cost=4758.26..11945.36 rows=155475 width=24)
                           Hash Cond: (pe.id_cliente = cl.id_cliente)
                           -> Parallel Hash Join (cost=4042.19..10821.08 rows=155475 width=16)
                                Hash Cond: (dp.id_pedido = pe.id_pedido)
                                -> Parallel Seq Scan on detalles_pedido dp
                                   actual rows=166203 loops=3
                                -> Parallel Seq Scan on pedidos pe
                                   actual rows=66667 loops=3
                           -> Hash
                                -> Seq Scan on clientes cl
                                   actual rows=20000 loops=3

Planning Time: 3.684 ms
Execution Time: 305.604 ms
Buffers: shared hit=6434, temp read=151 written=314
```

## Evaluación Técnica:
- **Uso del Índice:** **EL ÍNDICE NO FUE UTILIZADO**. PostgreSQL prefirió mantener el `Parallel Seq Scan` sobre `pedidos`.
- **Razón del Planificador:** Dado que la consulta debe calcular el gasto acumulado de todos los clientes procesando la totalidad de los pedidos, un escaneo secuencial paralelo en bloques contiguos de disco resulta mucho más eficiente que recorrer las páginas de un árbol B.
- **Derrame de Memoria:** Persiste el derrame en el `HashAggregate` (`Disk Usage: 744kB`).
- **Tiempo de Ejecución:** **305.604 ms** (vs. 304.753 ms base). Variación estadística despreciable.
- **Decisión:** **RECHAZADA**. La propuesta de la IA fue descartada tras contrastar la evidencia empírica. El índice solo aportaría penalización en escrituras (INSERTs) sin beneficio alguno en lectura.
- **Nota Metodológica:** Una prueba complementaria incrementando `work_mem` a `64MB` (`SET LOCAL work_mem = '64MB'`) eliminó completamente el spill a disco del HashAggregate, reduciendo el tiempo a **250.280 ms**. Esto demuestra que el cuello de botella era de memoria para la agregación y no de acceso a tablas.
- **Estado:** Se ejecuta `ROLLBACK`.

