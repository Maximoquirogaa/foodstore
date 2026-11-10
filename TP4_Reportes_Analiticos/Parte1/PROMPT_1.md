# Registro de Prompts - Parte 1: Análisis Inicial y Propuestas de Optimización

**Materia:** Base de Datos II  
**Proyecto:** Food Store (UTN FRM)  
**Alumno:** Máximo Juan Cruz Quiroga  
**Docente:** Sergio Neira  
**Motor:** PostgreSQL 17  

---

## Prompt 1: Análisis de Consultas Analíticas y Planes EXPLAIN

```text
Estoy realizando la Parte 1 de la práctica de Base de Datos II (Unidad 2: Optimización de Consultas) sobre el proyecto Food Store en PostgreSQL 17.

Contexto y Restricciones:
- Base de datos poblada masivamente: ~20.000 clientes, ~50.000 productos, ~200.000 pedidos y ~500.000 detalles_pedido.
- Esquema relacional oficial:
  * categorias (id_categoria, nombre, activo, fecha_creacion)
  * clientes (id_cliente, nombre, apellido, correo_electronico, fecha_creacion)
  * productos (id_producto, id_categoria, nombre, precio_actual, stock, activo, fecha_creacion)
  * pedidos (id_pedido, id_cliente, forma_pago, fecha_pedido)
  * detalles_pedido (id_pedido, id_producto, cantidad, precio_unitario)
- No se deben modificar los datos ni el esquema en firme. Toda propuesta debe probarse dentro de una transacción reversible con ROLLBACK.
- Criterio metodológico: "Medir antes, proponer con IA, medir después, decidir con datos".

Objetivo:
Analizar dos consultas analíticas que combinan al menos tres tablas mediante JOIN, filtros, agregación y ordenamiento. Debo comparar los planes EXPLAIN (ANALYZE, BUFFERS, VERBOSE) antes y después de una propuesta de optimización.

Consultas a analizar:

CONSULTA A — Facturación mensual por categoría activa:
SELECT
    c.id_categoria,
    c.nombre AS categoria,
    DATE_TRUNC('month', pe.fecha_pedido) AS mes,
    SUM(dp.cantidad * dp.precio_unitario) AS total_facturado
FROM categorias AS c
JOIN productos AS p ON p.id_categoria = c.id_categoria
JOIN detalles_pedido AS dp ON dp.id_producto = p.id_producto
JOIN pedidos AS pe ON pe.id_pedido = dp.id_pedido
WHERE c.activo = TRUE
GROUP BY c.id_categoria, c.nombre, DATE_TRUNC('month', pe.fecha_pedido)
ORDER BY mes, total_facturado DESC;

CONSULTA B — Top 20 clientes por gasto total histórico:
SELECT
    cl.id_cliente,
    cl.nombre || ' ' || cl.apellido AS cliente,
    SUM(dp.cantidad * dp.precio_unitario) AS total_gastado
FROM clientes AS cl
JOIN pedidos AS pe ON pe.id_cliente = cl.id_cliente
JOIN detalles_pedido AS dp ON dp.id_pedido = pe.id_pedido
GROUP BY cl.id_cliente, cl.nombre, cl.apellido
ORDER BY total_gastado DESC
LIMIT 20;

Adjunto los planes reales de ejecución obtenidos con EXPLAIN (ANALYZE, BUFFERS, VERBOSE). 
Por favor:
1. Identifica qué algoritmos de join eligió el optimizador (Hash Join, Parallel Hash Join, Nested Loop o Merge Join) para cada combinación.
2. Identifica los nodos más costosos en tiempo real y búferes.
3. Propón una estrategia concreta de optimización (reescritura o índice específico) para cada consulta que pueda ser evaluada en transacción reversible.
```
