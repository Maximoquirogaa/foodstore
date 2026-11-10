# Spec 06 — Índice B-Tree Compuesto para Filtro de Categoría y Rango de Precio (Caso Q2)

## 1. Contexto de Negocio
La consulta Q2 consulta el catálogo de productos filtrando por una categoría puntual (`id_categoria = 1`) y un rango cerrado de precios (`precio_actual BETWEEN 1000 AND 3000`), ordenando el resultado por `precio_actual`.

## 2. Requerimientos para la IA
- Proponer un índice B-Tree compuesto que aproveche la igualdad de categoría como primer punto de entrada y el rango de precio para acotar la búsqueda y proveer el ordenamiento requerido.
- Evaluar la definición: `CREATE INDEX idx_productos_categoria_precio ON productos (id_categoria, precio_actual);`

## 3. Criterio de Verificación
- Medir el plan antes (Seq Scan) y después (Index Scan o Bitmap Index Scan).
- Comprobar la eliminación del operador explícito `Sort` en el plan.
- Confirmar la aceleración del tiempo de respuesta mediante un protocolo de 3 rondas controladas.
