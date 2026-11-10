# QUERY PLAN - FoodStore (UTN FRM) - Consulta B - ANTES
`EXPLAIN (ANALYZE, BUFFERS, VERBOSE)`

```text
Limit (cost=19053.81..19053.86 rows=20 width=65)
  -> Sort (cost=19053.81..19103.81 rows=20003 width=65)
       Sort Key: (sum((dp.cantidad * dp.precio_unitario))) DESC
       -> Finalize HashAggregate (cost=18271.50..18521.53 rows=20003 width=65)
            Group Key: cl.id_cliente
            Batches: 5  Memory Usage: 10289kB  Disk Usage: 720kB
            -> Gather (cost=13720.81..17971.45 rows=40006 width=40)
                 Workers Planned: 2  Workers Launched: 2
                 -> Partial HashAggregate (cost=12720.81..12970.85 rows=20003 width=40)
                      Batches: 5  Memory Usage: 8241kB  Disk Usage: 216kB
                      -> Hash Join (cost=4757.33..11944.09 rows=155344 width=24)
                           Hash Cond: (pe.id_cliente = cl.id_cliente)
                           -> Parallel Hash Join (cost=4041.26..10820.16 rows=155344 width=16)
                                Hash Cond: (dp.id_pedido = pe.id_pedido)
                                -> Parallel Seq Scan on detalles_pedido dp
                                   (actual rows=166203 loops=3)
                                -> Parallel Seq Scan on pedidos pe
                                   (actual rows=66667 loops=3)
                           -> Hash
                                -> Seq Scan on clientes cl
                                   (actual rows=20000 loops=3)

Planning Time: 14.287 ms
Execution Time: 304.753 ms
Buffers: shared hit=6434, temp read=101 written=237
```

## Observaciones del Plan Inicial:
- **Algoritmos de JOIN:** `Parallel Hash Join` (detalles_pedido con pedidos) y `Hash Join` (con clientes).
- **Paralelismo:** 2 workers planificados y lanzados.
- **Derrame a disco:** El operador de agregación `HashAggregate` supera el límite de memoria asignado por defecto (`work_mem = 4MB`), requiriendo 5 lotes (`Batches: 5`) y volcando datos temporales a disco (`Disk Usage: 720kB` en el proceso líder y `216kB` en los workers).
- **Tiempo de Ejecución Base:** **304.753 ms**.
