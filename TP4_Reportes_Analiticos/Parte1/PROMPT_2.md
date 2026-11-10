# Registro de Prompts - Parte 1: Evaluación y Contraste de Planes

**Materia:** Base de Datos II  
**Proyecto:** Food Store (UTN FRM)  
**Alumno:** Máximo Juan Cruz Quiroga  
**Docente:** Sergio Neira  

---

## Prompt 2: Comparación Crítica de Planes Antes y Después

```text
A continuación te presento los planes de ejecución obtenidos tras probar en transacción (BEGIN ... ROLLBACK) las propuestas para ambas consultas:

Para Consulta A:
Propuesta: CREATE INDEX idx_TP4_a_pedidos_fecha ON pedidos (id_pedido) INCLUDE (fecha_pedido);
- Plan Antes: Execution Time = 699.550 ms, Parallel Hash Join, Parallel Bitmap Heap Scan on pedidos.
- Plan Después: Execution Time = 164.254 ms, Parallel Index Only Scan using idx_TP4_a_pedidos_fecha, Heap Fetches: 0.

Para Consulta B:
Propuesta: CREATE INDEX idx_TP4_b_pedidos_cliente ON pedidos (id_pedido) INCLUDE (id_cliente);
- Plan Antes: Execution Time = 304.753 ms, Parallel Seq Scan on pedidos, HashAggregate Batches: 5, Disk Usage: 720kB.
- Plan Después: Execution Time = 305.604 ms, Parallel Seq Scan on pedidos (el índice NO fue usado), HashAggregate Batches: 5, Disk Usage: 744kB.

Prueba adicional sobre B:
SET LOCAL work_mem = '64MB';
- Resultado: Execution Time = 250.280 ms, Batches: 1, Memory Usage: 12MB, Disk Usage: 0kB.

Solicitud:
Compara ambos planes con evidencia técnica concreta y fundamenta:
1. ¿El índice fue efectivamente aprovechado por el motor en cada caso? ¿Por qué sí o por qué no?
2. ¿Hubo cambios en los algoritmos de JOIN o en el grado de paralelismo?
3. ¿Qué representa 'Heap Fetches: 0' en la Consulta A?
4. ¿Cuál es el diagnóstico final sobre la Consulta B y por qué se descarta el índice propuesto?
```

