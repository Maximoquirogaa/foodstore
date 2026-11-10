# Spec 02 — Índice para Subconsulta de Precios y Categorías (Caso Q6)

## 1. Contexto de Negocio
La consulta Q6 busca todos los productos activos cuyo `precio_actual` sea mayor al promedio de los productos activos de su misma categoría, utilizando una subconsulta correlacionada en la cláusula `WHERE`.

## 2. Requerimientos para la IA
- Diseñar un índice B-Tree sobre `productos` que permita resolver el cálculo del `AVG(precio_actual)` mediante `Index Only Scan` sin acudir al Heap.
- Considerar el predicado de filtro `WHERE activo = TRUE`.
- Determinar el orden óptimo de las columnas: `(id_categoria, precio_actual DESC)`.

## 3. Criterio de Verificación
- Medir la reducción de tiempo y comprobar la ausencia de accesos al heap (`Heap Fetches: 0`).
- Documentar la salvedad metodológica: ningún índice elimina la complejidad intrínseca de ejecutar la subconsulta 50.000 veces ($O(N \cdot M)$). La solución estructural de fondo es la reescritura mediante JOIN pre-agregado.
