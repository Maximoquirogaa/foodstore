-- ============================================================================
-- TRABAJO PRÁCTICO N.º 10 (UNIDAD 8): Food Store en la Feria (Móvil & SQLite)
-- Base de Datos II - Tecnicatura Universitaria en Programación (UTN FRM)
-- Alumno: Máximo Juan Cruz Quiroga (maximoj.quiroga@alumnos.frm.utn.edu.ar)
-- Consigna 1.b: Esquema de base de datos de la tablet en SQLite (STRICT)
-- ============================================================================

-- Activación obligatoria de claves foráneas en SQLite
PRAGMA foreign_keys = ON;

-- Limpieza preventiva para recreación idempotente
DROP TABLE IF EXISTS cola_sync;
DROP TABLE IF EXISTS item_borrador;
DROP TABLE IF EXISTS pedido_borrador;
DROP TABLE IF EXISTS snapshot_servidor_import;
DROP TABLE IF EXISTS snapshot_servidor;
DROP TABLE IF EXISTS producto_cache;

-- 1. Tabla de caché local del catálogo en la tablet
CREATE TABLE producto_cache (
    id INTEGER PRIMARY KEY,
    nombre TEXT NOT NULL CHECK (length(trim(nombre)) > 0),
    precio_centavos INTEGER NOT NULL CHECK (precio_centavos >= 0),
    stock_visto INTEGER NOT NULL CHECK (stock_visto >= 0),
    disponible INTEGER NOT NULL CHECK (disponible IN (0, 1)),
    eliminado INTEGER NOT NULL CHECK (eliminado IN (0, 1)),
    fecha_copia TEXT NOT NULL CHECK (length(trim(fecha_copia)) > 0)
) STRICT;

-- 2. Tabla destino de la instantánea recibida del servidor (PostgreSQL)
CREATE TABLE snapshot_servidor (
    id INTEGER PRIMARY KEY,
    nombre TEXT NOT NULL CHECK (length(trim(nombre)) > 0),
    precio_centavos INTEGER NOT NULL CHECK (precio_centavos >= 0),
    stock INTEGER NOT NULL CHECK (stock >= 0),
    disponible INTEGER NOT NULL CHECK (disponible IN (0, 1)),
    eliminado INTEGER NOT NULL CHECK (eliminado IN (0, 1)),
    fecha_copia TEXT NOT NULL CHECK (length(trim(fecha_copia)) > 0)
) STRICT;

-- 3. Tabla auxiliar de importación de texto para el CSV de PostgreSQL
CREATE TABLE snapshot_servidor_import (
    id TEXT NOT NULL,
    nombre TEXT NOT NULL,
    precio_centavos TEXT NOT NULL,
    stock TEXT NOT NULL,
    disponible TEXT NOT NULL CHECK (disponible IN ('t', 'f', '1', '0', 'true', 'false')),
    eliminado TEXT NOT NULL CHECK (eliminado IN ('t', 'f', '1', '0', 'true', 'false')),
    fecha_copia TEXT NOT NULL
) STRICT;

-- 4. Cabecera del borrador de pedido creado en la tablet
CREATE TABLE pedido_borrador (
    id_local TEXT PRIMARY KEY,
    usuario TEXT NOT NULL CHECK (length(trim(usuario)) > 0),
    forma_pago TEXT NOT NULL CHECK (
        forma_pago IN ('EFECTIVO', 'TARJETA', 'TRANSFERENCIA')
    ),
    fecha TEXT NOT NULL CHECK (length(trim(fecha)) > 0)
) STRICT;

-- 5. Renglones/ítems asociados a cada borrador de pedido
CREATE TABLE item_borrador (
    id_local TEXT NOT NULL,
    producto_id INTEGER NOT NULL,
    cantidad INTEGER NOT NULL CHECK (cantidad > 0),
    precio_centavos_visto INTEGER NOT NULL CHECK (precio_centavos_visto >= 0),
    PRIMARY KEY (id_local, producto_id),
    FOREIGN KEY (id_local) REFERENCES pedido_borrador (id_local) ON DELETE CASCADE,
    FOREIGN KEY (producto_id) REFERENCES producto_cache (id)
) STRICT;

-- 6. Cola de sincronización que simula la evaluación del semáforo con el servidor
CREATE TABLE cola_sync (
    solicitud_uuid TEXT PRIMARY KEY,
    id_local TEXT NOT NULL,
    estado TEXT NOT NULL CHECK (
        estado IN ('PENDIENTE', 'CONFLICTO', 'RECHAZADO', 'SIMULADO_APROBADO')
    ),
    motivo TEXT,
    FOREIGN KEY (id_local) REFERENCES pedido_borrador (id_local) ON DELETE CASCADE
) STRICT;
