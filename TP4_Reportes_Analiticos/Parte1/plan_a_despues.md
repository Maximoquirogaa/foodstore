# QUERY PLAN - FoodStore (UTN FRM) - Consulta A - DESPUÉS

Optimización probada dentro de una transacción (`BEGIN ... ROLLBACK`):
```sql
CREATE INDEX idx_TP4_a_pedidos_fecha ON pedidos (id_pedido) INCLUDE (fecha_pedido);
ANALYZE pedidos;
```

`EXPLAIN (ANALYZE, BUFFERS, VERBOSE)`

```text
Incremental Sort (cost=15617.57..26686.93 rows=61812 width=166)
  Sort Key: (date_trunc('month'::text, pe.fecha_pedido)), (sum((dp.cantidad * dp.precio_unitario))) DESC
  Presorted Key: (date_trunc('month'::text, pe.fecha_pedido))
  -> Finalize GroupAggregate (cost=15589.45..23621.14 rows=61812 width=166)
       Group Key: c.id_categoria, (date_trunc('month'::text, pe.fecha_pedido))
       -> Gather Merge (cost=15589.45..22178.86 rows=51510 width=166)
            Workers Planned: 2  Workers Launched: 2
            -> Partial GroupAggregate (cost=14589.43..15233.31 rows=25755 width=166)
                 Group Key: c.id_categoria, (date_trunc('month'::text, pe.fecha_pedido))
                 -> Sort (cost=14589.43..14653.82 rows=25755 width=158)
                      Sort Key: (date_trunc('month'::text, pe.fecha_pedido)), c.id_categoria
                      -> Hash Join (cost=3557.05..10851.05 rows=25755 width=158)
                           Hash Cond: (dp.id_producto = p.id_producto)
                           -> Parallel Hash Join (cost=1825.22..8604.12 rows=51509 width=42)
                                Hash Cond: (dp.id_pedido = pe.id_pedido)
                                -> Parallel Seq Scan on detalles_pedido dp
                                   (actual rows=166203 loops=3)
                                -> Parallel Hash
                                     -> Parallel Index Only Scan using idx_TP4_a_pedidos_fecha on pedidos pe
                                          actual rows=66668 loops=3
                                          Heap Fetches: 0
                           -> Hash
                                -> Hash Join (cost=16.66..1419.31 rows=25002 width=140)
                                     Hash Cond: (p.id_categoria = c.id_categoria)
                                     -> Seq Scan on productos p
                                        (actual rows=50003 loops=3)
                                     -> Seq Scan on categorias c
                                        Filter: c.activo
                                        (actual rows=5 loops=3)

Planning Time: 5.386 ms
Execution Time: 164.254 ms
Buffers: shared hit=6529 read=247
```

## Evaluación Técnica:
- **Algoritmos de JOIN:** Se mantienen `Hash Join` y `Parallel Hash Join`. No cambiaron los algoritmos, pero el nodo de entrada interno cambió radicalmente.
- **Acceso a `pedidos`:** Pasa de `Parallel Bitmap Heap Scan` a **`Parallel Index Only Scan`**.
- **Heap Fetches:** `0`. Al ser un índice cubriente (`INCLUDE (fecha_pedido)`), PostgreSQL obtuvo todos los datos necesarios directamente de las páginas del árbol B sin acceder al Heap.
- **Tiempo de Ejecución:** Reducción de **699.550 ms a 164.254 ms** (**mejora de ~4.26x**).
- **Decisión:** **ACEPTADA**. Se comprueba empíricamente el impacto del índice cubriente.
- **Estado:** Se ejecuta `ROLLBACK` para no persistir cambios en el entorno de pruebas.

