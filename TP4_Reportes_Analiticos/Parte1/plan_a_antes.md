# QUERY PLAN - FoodStore (UTN FRM) - Consulta A - ANTES
`EXPLAIN (ANALYZE, BUFFERS, VERBOSE)`

```text
Incremental Sort (cost=16550.74..27625.76 rows=61837 width=166)
  Sort Key: (date_trunc('month'::text, pe.fecha_pedido)), (sum((dp.cantidad * dp.precio_unitario))) DESC
  Presorted Key: (date_trunc('month'::text, pe.fecha_pedido))
  -> Finalize GroupAggregate (cost=16522.54..24557.36 rows=61837 width=166)
      Group Key: c.id_categoria, (date_trunc('month'::text, pe.fecha_pedido))
      -> Gather Merge (cost=16522.54..23114.50 rows=51530 width=166)
          Workers Planned: 2  Workers Launched: 2
          -> Partial GroupAggregate (cost=15522.51..16166.64 rows=25765 width=166)
              Group Key: c.id_categoria, (date_trunc('month'::text, pe.fecha_pedido))
              -> Sort (cost=15522.51..15586.92 rows=25765 width=158)
                  Sort Key: (date_trunc('month'::text, pe.fecha_pedido)), c.id_categoria
                  -> Hash Join (cost=4489.12..11783.32 rows=25765 width=158)
                      Hash Cond: (dp.id_producto = p.id_producto)
                      -> Parallel Hash Join (cost=2757.28..9536.18 rows=51530 width=42)
                          Hash Cond: (dp.id_pedido = pe.id_pedido)
                          -> Parallel Seq Scan on detalles_pedido dp
                              (actual rows=166203 loops=3)
                          -> Parallel Bitmap Heap Scan on pedidos pe
                              Recheck Cond: (pe.fecha_pedido IS NOT NULL)
                              -> Bitmap Index Scan on idx_pedidos_cliente
                                 (actual rows=66668 loops=3)
                      -> Hash
                          -> Hash Join (cost=16.66..1419.31 rows=25002 width=140)
                              Hash Cond: (p.id_categoria = c.id_categoria)
                              -> Seq Scan on productos p
                                  (actual rows=50003 loops=3)
                              -> Seq Scan on categorias c
                                  Filter: c.activo
                                  (actual rows=5 loops=3)

Planning Time: 54.428 ms
Execution Time: 699.550 ms
Buffers: shared hit=8044
```

## Observaciones del Plan Inicial:
- **Algoritmos de JOIN:** Utiliza una combinación de `Hash Join` y `Parallel Hash Join`. No se utilizan `Nested Loop` ni `Merge Join`.
- **Paralelismo:** Se planificaron 2 workers (`Workers Planned: 2`) y ambos fueron lanzados exitosamente (`Workers Launched: 2`). El proceso líder colabora en el escaneo (loops = 3).
- **Acceso a `pedidos`:** Aunque se escanean los pedidos mediante Bitmap Heap Scan, el acceso a las páginas de datos en el Heap introduce una latencia considerable.
- **Tiempo de Ejecución Base:** **699.550 ms**.
