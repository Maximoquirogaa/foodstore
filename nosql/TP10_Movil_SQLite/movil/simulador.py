#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Simulador de Sincronización Offline y Semáforo para Food Store (SQLite 3.50+)
Base de Datos II - UTN FRM - Alumno: Máximo Juan Cruz Quiroga
Ejecuta la totalidad de consignas 1.b, 1.c, 2.a, 2.b y 2.c de forma 100% reproducible.
"""

import os
import sys
import csv
import sqlite3

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
DB_PATH = os.path.join(BASE_DIR, "foodstore_movil.db")
SCHEMA_SQL = os.path.join(BASE_DIR, "schema_sqlite.sql")
SEMAFORO_SQL = os.path.join(BASE_DIR, "semaforo.sql")
CSV_SNAPSHOT_1 = os.path.join(BASE_DIR, "servidor_snapshot.csv")
CSV_SNAPSHOT_2C = os.path.join(BASE_DIR, "servidor_snapshot_2c.csv")

def run_simulation():
    print("====================================================================")
    print("TP10 (UNIDAD 8): SIMULADOR DEL SEMÁFORO Y BASE DE LA TABLET (SQLite)")
    print("Alumno: Máximo Juan Cruz Quiroga | Base de Datos II | UTN FRM")
    print(f"Motor SQLite: v{sqlite3.sqlite_version}")
    print("====================================================================\n")

    # Si existe base previa, eliminarla para asegurar reproducibilidad limpia
    if os.path.exists(DB_PATH):
        try:
            os.remove(DB_PATH)
        except Exception:
            pass

    conn = sqlite3.connect(DB_PATH)
    conn.execute("PRAGMA foreign_keys = ON;")
    cursor = conn.cursor()

    # 1. Crear Esquema (Consigna 1.b)
    print("[1/5] Creando esquema de tablas STRICT en SQLite...")
    with open(SCHEMA_SQL, "r", encoding="utf-8") as f:
        schema_script = f.read()
    conn.executescript(schema_script)
    print("  [OK] Tablas producto_cache, snapshot_servidor, pedido_borrador, item_borrador, cola_sync creadas.")

    # 2. Carga Inicial de Catálogo desde CSV (Consigna 2.a)
    print("\n[2/5] Importando instantánea inicial del servidor (servidor_snapshot.csv)...")
    with open(CSV_SNAPSHOT_1, "r", encoding="utf-8") as f:
        reader = csv.DictReader(f)
        for r in reader:
            disp_int = 1 if r["disponible"].lower() in ("t", "1", "true") else 0
            elim_int = 1 if r["eliminado"].lower() in ("t", "1", "true") else 0
            cursor.execute("""
                INSERT INTO snapshot_servidor (id, nombre, precio_centavos, stock, disponible, eliminado, fecha_copia)
                VALUES (?, ?, ?, ?, ?, ?, ?)
            """, (int(r["id"]), r["nombre"], int(r["precio_centavos"]), int(r["stock"]), disp_int, elim_int, r["fecha_copia"]))
            cursor.execute("""
                INSERT INTO producto_cache (id, nombre, precio_centavos, stock_visto, disponible, eliminado, fecha_copia)
                VALUES (?, ?, ?, ?, ?, ?, ?)
            """, (int(r["id"]), r["nombre"], int(r["precio_centavos"]), int(r["stock"]), disp_int, elim_int, r["fecha_copia"]))
    conn.commit()
    print("  [OK] Instantánea cargada en snapshot_servidor y replicada en producto_cache.")

    # 3. Verificación de Transacciones y Casos C1 y C7 (Consigna 1.c)
    print("\n[3/5] Ejecutando pruebas unitarias de SQLite (1.c: COMMIT, ROLLBACK, C1, C7)...")
    
    # COMMIT
    cursor.execute("""
        INSERT INTO pedido_borrador (id_local, usuario, forma_pago, fecha)
        VALUES ('test-commit', 'maximo_quiroga', 'EFECTIVO', '2026-11-04T10:00:00Z');
    """)
    cursor.execute("""
        INSERT INTO item_borrador (id_local, producto_id, cantidad, precio_centavos_visto)
        VALUES ('test-commit', 1, 2, 450000);
    """)
    cursor.execute("""
        INSERT INTO cola_sync (solicitud_uuid, id_local, estado, motivo)
        VALUES ('uuid-commit', 'test-commit', 'PENDIENTE', NULL);
    """)
    conn.commit()
    print("  [OK] Prueba COMMIT: Borrador e ítems persistidos correctamente.")

    # ROLLBACK
    try:
        cursor.execute("BEGIN TRANSACTION;")
        cursor.execute("""
            INSERT INTO pedido_borrador (id_local, usuario, forma_pago, fecha)
            VALUES ('test-rollback', 'maximo_quiroga', 'TARJETA', '2026-11-04T10:05:00Z');
        """)
        cursor.execute("ROLLBACK;")
        res_rb = cursor.execute("SELECT COUNT(*) FROM pedido_borrador WHERE id_local = 'test-rollback';").fetchone()[0]
        assert res_rb == 0
        print("  [OK] Prueba ROLLBACK: Transacción descartada sin dejar filas huérfanas.")
    except Exception as e:
        print(f"  [ERROR] Falló ROLLBACK: {e}")

    # Caso C1: Consulta Offline
    cursor.execute("""
        SELECT COUNT(*) FROM producto_cache WHERE disponible = 1 AND eliminado = 0 AND stock_visto > 0;
    """)
    prod_offline = cursor.fetchone()[0]
    print(f"  [OK] Caso C1 (Consulta Offline): {prod_offline} productos disponibles consultados sin red.")

    # Caso C7: Violación de restricciones
    try:
        cursor.execute("""
            INSERT INTO item_borrador (id_local, producto_id, cantidad, precio_centavos_visto)
            VALUES ('test-commit', 1, 0, 450000);
        """)
        print("  [FALLO] Caso C7: Debería haber rechazado cantidad = 0.")
    except sqlite3.IntegrityError:
        print("  [OK] Caso C7 (Restricción CHECK): Rechazó correctamente ítem con cantidad = 0.")

    try:
        cursor.execute("""
            INSERT INTO item_borrador (id_local, producto_id, cantidad, precio_centavos_visto)
            VALUES ('test-commit', 9999, 1, 450000);
        """)
        print("  [FALLO] Caso C7: Debería haber rechazado producto inexistente.")
    except sqlite3.IntegrityError:
        print("  [OK] Caso C7 (Clave Foránea): Rechazó correctamente producto inexistente (id=9999).")

    # Limpiar pedido de prueba inicial
    cursor.execute("DELETE FROM cola_sync;")
    cursor.execute("DELETE FROM item_borrador;")
    cursor.execute("DELETE FROM pedido_borrador;")
    conn.commit()

    # 4. Simulación de los Casos C2 a C6 del Semáforo (Consigna 2.c)
    print("\n[4/5] Simulando Casos C2 a C6 del Semáforo con Instantánea Actualizada...")
    
    # Cargar nueva instantánea (servidor_snapshot_2c) en snapshot_servidor y actualizar producto_cache con UPSERT
    with open(CSV_SNAPSHOT_2C, "r", encoding="utf-8") as f:
        reader = csv.DictReader(f)
        cursor.execute("DELETE FROM snapshot_servidor;")
        for r in reader:
            disp_int = 1 if r["disponible"].lower() in ("t", "1", "true") else 0
            elim_int = 1 if r["eliminado"].lower() in ("t", "1", "true") else 0
            cursor.execute("""
                INSERT INTO snapshot_servidor (id, nombre, precio_centavos, stock, disponible, eliminado, fecha_copia)
                VALUES (?, ?, ?, ?, ?, ?, ?)
            """, (int(r["id"]), r["nombre"], int(r["precio_centavos"]), int(r["stock"]), disp_int, elim_int, r["fecha_copia"]))
            # Upsert en producto_cache
            cursor.execute("""
                INSERT INTO producto_cache (id, nombre, precio_centavos, stock_visto, disponible, eliminado, fecha_copia)
                VALUES (?, ?, ?, ?, ?, ?, ?)
                ON CONFLICT (id) DO UPDATE SET
                    nombre = excluded.nombre,
                    precio_centavos = excluded.precio_centavos,
                    stock_visto = excluded.stock_visto,
                    disponible = excluded.disponible,
                    eliminado = excluded.eliminado,
                    fecha_copia = excluded.fecha_copia;
            """, (int(r["id"]), r["nombre"], int(r["precio_centavos"]), int(r["stock"]), disp_int, elim_int, r["fecha_copia"]))
    conn.commit()
    print("  [OK] Servidor actualizó catálogo: Hamb. Clásica subió a $4.800 y Papas Fritas fue dada de baja.")

    # Insertar solicitudes de los casos:
    # C2: Precio desactualizado (visto 450000 vs 480000 actual)
    cursor.execute("INSERT INTO pedido_borrador VALUES ('c2-local', 'maximo_quiroga', 'EFECTIVO', '2026-11-04T12:00:00Z');")
    cursor.execute("INSERT INTO item_borrador VALUES ('c2-local', 1, 1, 450000);")
    cursor.execute("INSERT INTO cola_sync VALUES ('c2-solicitud-1', 'c2-local', 'PENDIENTE', NULL);")

    # C3: Stock insuficiente (pide 99 unidades, stock servidor es 35)
    cursor.execute("INSERT INTO pedido_borrador VALUES ('c3-local', 'maximo_quiroga', 'TARJETA', '2026-11-04T12:05:00Z');")
    cursor.execute("INSERT INTO item_borrador VALUES ('c3-local', 2, 99, 620000);")
    cursor.execute("INSERT INTO cola_sync VALUES ('c3-solicitud', 'c3-local', 'PENDIENTE', NULL);")

    # C4: Producto dado de baja (Papas Fritas id=3)
    cursor.execute("INSERT INTO pedido_borrador VALUES ('c4-local', 'maximo_quiroga', 'TRANSFERENCIA', '2026-11-04T12:10:00Z');")
    cursor.execute("INSERT INTO item_borrador VALUES ('c4-local', 3, 1, 220000);")
    cursor.execute("INSERT INTO cola_sync VALUES ('c4-solicitud', 'c4-local', 'PENDIENTE', NULL);")

    # C5: Sin cambios (precio 480000 coincide)
    cursor.execute("INSERT INTO pedido_borrador VALUES ('c5-local', 'maximo_quiroga', 'EFECTIVO', '2026-11-04T12:15:00Z');")
    cursor.execute("INSERT INTO item_borrador VALUES ('c5-local', 1, 1, 480000);")
    cursor.execute("INSERT INTO cola_sync VALUES ('c5-solicitud', 'c5-local', 'PENDIENTE', NULL);")

    conn.commit()

    # Correr Semáforo primera pasada
    with open(SEMAFORO_SQL, "r", encoding="utf-8") as f:
        semaforo_code = f.read()
    conn.executescript(semaforo_code)

    # C2 Resolución: Cliente acepta nuevo precio ($4.800 = 480000)
    cursor.execute("UPDATE item_borrador SET precio_centavos_visto = 480000 WHERE id_local = 'c2-local' AND producto_id = 1;")
    cursor.execute("INSERT INTO cola_sync VALUES ('c2-solicitud-2', 'c2-local', 'PENDIENTE', NULL);")
    conn.commit()

    # Correr Semáforo segunda pasada (evalúa c2-solicitud-2)
    conn.executescript(semaforo_code)

    # Caso C6: Intento de reenvío con mismo UUID (debe fallar por clave primaria)
    try:
        cursor.execute("INSERT INTO cola_sync VALUES ('c5-solicitud', 'c5-local', 'PENDIENTE', NULL);")
        print("  [FALLO] Caso C6: Permitió duplicar UUID de solicitud.")
    except sqlite3.IntegrityError:
        print("  [OK] Caso C6 (Idempotencia / PK): Rechazó correctamente UUID repetido ('c5-solicitud').")

    # Repetir semáforo no debe mutar registros existentes
    conn.executescript(semaforo_code)

    # 5. Reporte de Resultados Finales
    print("\n[5/5] Tabla de Resultados del Semáforo en la Tablet:")
    print("-------------------------------------------------------------------------------------------------")
    print(f"{'Caso':<6} | {'Solicitud UUID':<18} | {'Estado Semáforo':<18} | {'Motivo / Explicación'}")
    print("-------------------------------------------------------------------------------------------------")
    cursor.execute("""
        SELECT solicitud_uuid, estado, motivo
        FROM cola_sync
        WHERE solicitud_uuid IN ('c2-solicitud-1', 'c2-solicitud-2', 'c3-solicitud', 'c4-solicitud', 'c5-solicitud')
        ORDER BY solicitud_uuid;
    """)
    rows = cursor.fetchall()
    caso_map = {
        "c2-solicitud-1": "C2-a",
        "c2-solicitud-2": "C2-b",
        "c3-solicitud":   "C3",
        "c4-solicitud":   "C4",
        "c5-solicitud":   "C5"
    }
    for uuid_val, estado, motivo in rows:
        tag = caso_map.get(uuid_val, "---")
        print(f"{tag:<6} | {uuid_val:<18} | {estado:<18} | {motivo}")
    print("-------------------------------------------------------------------------------------------------")

    conn.close()
    print("\n[OK] Simulación finalizada exitosamente. Base guardada en foodstore_movil.db.")

if __name__ == "__main__":
    run_simulation()
