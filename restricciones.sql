-- Parte 1: Restricciones y Triggers de Integridad

-- Regla 1: No se puede agregar un producto inactivo a un pedido.
-- En la aplicación, esto evita que productos dados de baja lógica se sigan vendiendo.
CREATE OR REPLACE FUNCTION fn_check_producto_activo()
RETURNS TRIGGER AS $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM productos 
        WHERE id_producto = NEW.id_producto AND activo = TRUE
    ) THEN
        RAISE EXCEPTION 'Regla de negocio: No se puede agregar un producto inactivo al pedido (ID: %)', NEW.id_producto;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_check_producto_activo
BEFORE INSERT ON detalles_pedido
FOR EACH ROW
EXECUTE FUNCTION fn_check_producto_activo();

-- Regla 2: Descontar el stock del producto automáticamente al registrar un detalle de pedido.
CREATE OR REPLACE FUNCTION fn_deducir_stock()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE productos
    SET stock = stock - NEW.cantidad
    WHERE id_producto = NEW.id_producto;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_deducir_stock
AFTER INSERT ON detalles_pedido
FOR EACH ROW
EXECUTE FUNCTION fn_deducir_stock();

