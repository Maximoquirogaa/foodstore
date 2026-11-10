-- ============================================================================
-- Parte_A_Indices/indices.sql — Plan de Indexado Detallado y Evaluado
-- Proyecto: Food Store (UTN FRM - Base de Datos II)
-- Alumno: Máximo Juan Cruz Quiroga
-- Docente: Sergio Neira
-- Motor: PostgreSQL 17
-- ============================================================================
-- Este archivo documenta cada consulta analizada, los candidatos a índices
-- evaluados empíricamente, las decisiones de descarte por sobreindexación y
-- los índices aplicados en firme.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- CASO 1 — Q5: Ranking de clientes por gasto acumulado total (DENSE_RANK)
-- Spec: specs/spec_01_pedidos_cliente_join.md
-- ----------------------------------------------------------------------------

-- Candidato A — DESCARTADO POR BAJA SELECTIVIDAD
-- Propuesta generada por IA: Crear índice en pedidos(id_cliente).
--
-- CREATE INDEX idx_pedidos_cliente_q5 ON pedidos (id_cliente);
-- (Dejado comentado a propósito: NO se aplica en firme)
--
-- Motivo del descarte: Para computar el ranking histórico, la consulta debe
-- agregar el gasto de la totalidad de los 200.000 pedidos. Al no existir un
-- filtro altamente selectivo, el optimizador ignora el árbol B y mantiene el
-- Parallel Seq Scan sobre pedidos en todas las rondas de medición.
-- Crear este índice penalizaría las inserciones de pedidos sin brindar beneficio.

-- Candidato B — DESCARTADO POR REDUNDANCIA CON CLAVE PRIMARIA
-- Propuesta generada por IA: Crear índice en detalles_pedido(id_pedido).
--
-- CREATE INDEX idx_detalles_pedido_id_pedido ON detalles_pedido (id_pedido);
-- (Dejado comentado a propósito: NO se aplica en firme)
--
-- Motivo del descarte: Es completamente redundante con la clave primaria
-- compuesta de la tabla: PRIMARY KEY (id_pedido, id_producto).
-- Los árboles B permiten búsquedas exactas utilizando cualquier prefijo a la
-- izquierda de sus columnas indexadas. Al ser id_pedido la primera columna de
-- la PK, ya está 100% indexada y cubierta. Crear un índice secundario sobre
-- esa misma columna es un caso típico de sobreindexación injustificada.

-- Intervención Aceptada — Ajuste de Memoria de Sesión (Sin Índices)
-- El plan base mostraba que el operador HashAggregate superaba los 4MB de RAM
-- por defecto, dividiéndose en 5 batches y volcando datos a disco temporal
-- (Disk Usage: ~1.5 MB). Ajustando la memoria local a 16MB se resuelve en RAM:
--
--   SET LOCAL work_mem = '16MB';
--
-- Resultado: 1 solo batch, 0 kB en disco, y reducción del tiempo en ~26%
-- sin tocar el esquema ni crear índices superfluos.


-- ----------------------------------------------------------------------------
-- CASO 2 — Q6: Productos con precio superior al promedio de su categoría
-- Spec: specs/spec_02_productos_categoria_precio.md
-- ----------------------------------------------------------------------------

-- ACEPTADO (con salvedad metodológica documentada)
CREATE INDEX IF NOT EXISTS idx_productos_categoria_precio_activo
    ON productos (id_categoria, precio_actual DESC)
    WHERE activo = TRUE;

-- Justificación y Resultado:
-- El índice permite resolver el cálculo del AVG(precio_actual) dentro de la
-- subconsulta correlacionada mediante un Index Only Scan (Heap Fetches: 0),
-- reduciendo el tiempo de 271.2 s a 158.7 s (~41% de mejora).
--
-- SALVEDAD METODOLÓGICA OBLIGATORIA:
-- Este índice optimiza cada ejecución individual de la subconsulta, pero NO
-- elimina el problema algorítmico de raíz: la subconsulta se ejecuta 50.000
-- veces (una por cada producto del catálogo). La verdadera solución de
-- arquitectura para esta consulta es REESCRIBIRLA con una tabla derivada
-- pre-agregada (JOIN en vez de subconsulta correlacionada, como se probó en TP6).


-- ----------------------------------------------------------------------------
-- CASO 3 — Q4: Top 3 productos por categoría en los últimos 6 meses
-- Spec: specs/spec_03_pedidos_fecha_brin.md
-- ----------------------------------------------------------------------------

-- Propuesta Candidata — Índice BRIN en fecha_pedido: DESCARTADO
--
-- CREATE INDEX idx_pedidos_fecha_brin ON pedidos USING brin (fecha_pedido);
-- (Dejado comentado a propósito: NO se aplica en firme)
--
-- Motivo del descarte: Un índice BRIN requiere que los datos estén ordenados
-- físicamente en disco (alta correlación). Al consultar pg_stats, la correlación
-- física de fecha_pedido arrojó un valor cercano a cero (~0.005), producto de
-- cargas masivas y actualizaciones aleatorias. Con tan baja correlación, un
-- índice BRIN pierde toda capacidad de descarte de bloques y es ignorado por el motor.


-- ----------------------------------------------------------------------------
-- CASO 4 — Q2: Productos por categoría y rango de precios
-- Spec: specs/spec_06_productos_categoria_precio_sin_activo.md
-- ----------------------------------------------------------------------------

-- ACEPTADO EN FIRME
CREATE INDEX IF NOT EXISTS idx_productos_categoria_precio
    ON productos (id_categoria, precio_actual);

-- Justificación y Resultado:
-- Acelera sustancialmente las búsquedas de productos filtrando por categoría
-- exacta y rango de precios (BETWEEN 1000 AND 3000). Al contener ambas columnas
-- en el orden (igualdad, rango), evita el barrido secuencial de toda la tabla y
-- suprime la necesidad de un operador de ordenamiento (Sort) explícito.
-- El tiempo de respuesta se reduce de 4.92 ms a 0.28 ms (~17.5x más rápido).
