-- ==========================================
-- TP3 - Parte 2: Índices propuestos para Optimización
-- Ejecuta estos CREATE INDEX y luego vuelve a correr consultas_lentas.sql
-- ==========================================

-- Optimización Consulta 1: Evitar el Seq Scan en la tabla productos
-- Creamos un índice parcial (solo en los activos) sobre el precio, y añadimos el stock.
CREATE INDEX idx_productos_precio_activo 
ON productos (precio_actual) 
WHERE activo = TRUE;

-- Optimización Consulta 2: Evitar barrer 200.000 pedidos secuencialmente
-- Un índice sobre la fecha de pedido bajará los "Rows Removed by Filter" a cero.
CREATE INDEX idx_pedidos_fecha 
ON pedidos (fecha_pedido);

-- Optimización Consulta 3: Evitar el Merge Sort externo de 500k filas y el Seq Scan de productos
-- Ordenamos la lectura de pedidos en reversa para no usar memoria/disco en ordenamiento,
-- e indexamos la categoría de los productos.
CREATE INDEX idx_pedidos_fecha_desc 
ON pedidos (fecha_pedido DESC);

CREATE INDEX idx_productos_categoria 
ON productos (id_categoria);

