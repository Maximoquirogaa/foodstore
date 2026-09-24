# Ejercicio de Lectura Crítica - Parte 3

## Script 1

**Script original:**
```sql
-- Generado para: dar de baja las funciones de películas retiradas de cartel
UPDATE funcion
SET activa = FALSE;
```

**Efecto real:**
Al no tener una cláusula `WHERE`, este script no solo daría de baja las películas retiradas, sino que actualizaría **TODAS** las filas de la tabla `funcion`, estableciendo `activa = FALSE` masivamente. Esto "apagaría" el sistema completo porque daría de baja todas las funciones vigentes.

**Versión corregida:**
```sql
UPDATE funcion
SET activa = FALSE
WHERE pelicula_id IN (SELECT id FROM pelicula WHERE en_cartelera = FALSE);
```

---

## Script 2

**Script original:**
```sql
-- Generado para: limpiar las categorías sin productos asociados
DELETE FROM categoria
WHERE id NOT IN (SELECT categoria_id FROM producto);
```

**Efecto real:**
Si existe al menos un registro en la tabla `producto` cuyo `categoria_id` sea `NULL`, la subconsulta devolverá una lista que contiene `NULL`. En SQL, la condición `id NOT IN (..., NULL)` resulta en `UNKNOWN` (que se evalúa como falso en un `WHERE`). Por lo tanto, el script fallará silenciosamente y **no se eliminará ninguna categoría**, incluso las que realmente no tienen productos asociados.

**Versión corregida (manejo correcto de NULL):**
```sql
DELETE FROM categoria
WHERE id NOT IN (SELECT categoria_id FROM producto WHERE categoria_id IS NOT NULL);
```
*(Alternativamente, se puede usar `NOT EXISTS`, que ignora problemas de nulos en subconsultas y suele ser más eficiente).*
```sql
DELETE FROM categoria c
WHERE NOT EXISTS (SELECT 1 FROM producto p WHERE p.categoria_id = c.id);
```

