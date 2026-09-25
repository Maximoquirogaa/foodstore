-- ==========================================
-- TP5 - Parte A: Índices propuestos y aceptados
-- Ejecuta este archivo para crear los índices, y luego vuelve a medir.
-- ==========================================

-- 1. Índice para búsqueda de producto por nombre
-- Aceptado: La búsqueda por nombre exacto es altísima en la aplicación, 
-- y al ser una columna de alta cardinalidad, el índice B-Tree filtrará casi toda la tabla inmediatamente.
CREATE INDEX idx_productos_nombre ON productos (nombre);

-- 2. Índice para filtrar detalles por precio unitario
-- Aceptado: Permite reportes sobre valores monetarios altos evitando escanear los 200.000 detalles.
CREATE INDEX idx_detalles_precio ON detalles_pedido (precio_unitario);

-- ==========================================
-- ÍNDICES DESCARTADOS POR SOBREINDEXACIÓN:
-- ==========================================
-- Propuesta: CREATE INDEX idx_pedidos_forma_pago ON pedidos(forma_pago);
-- Razón del rechazo explícito: El campo forma_pago tiene bajísima cardinalidad 
-- (solo EFECTIVO, TARJETA, TRANSFERENCIA). Cualquier búsqueda retornará alrededor del 33% 
-- de la tabla. El optimizador de PostgreSQL probablemente prefiera hacer un Seq Scan de todas formas.
-- Crearlo solo aumentaría el tamaño de la base y haría los INSERTs más lentos sin brindar una mejora real de lectura.

