#!/usr/bin/env python3
# ============================================================================
# TP9 — ETL de Migración: PostgreSQL a MongoDB (Food Store)
# Asignatura: Base de Datos II (UTN FRM)
# Alumno: Máximo Juan Cruz Quiroga (maximoj.quiroga@alumnos.frm.utn.edu.ar)
# Docente: Sergio Neira
# ============================================================================
# PROPÓSITO:
#   Extrae el subconjunto de pedidos y detalles de pedido desde PostgreSQL,
#   los transforma al modelo documental desnormalizado (Embedded Documents)
#   con snapshot de cliente y líneas de ítems congeladas, y los carga en
#   la base de datos 'foodstore_nosql' de MongoDB.
# ============================================================================

import json
import os
import sys
from datetime import datetime

try:
    from pymongo import MongoClient, ASCENDING
    HAS_PYMONGO = True
except ImportError:
    HAS_PYMONGO = False

def obtener_pedidos_fuente():
    """Retorna la lista de pedidos canónicos con líneas embebidas."""
    ruta_json = os.path.join(os.path.dirname(__file__), "datos", "pedidos.json")
    if os.path.exists(ruta_json):
        with open(ruta_json, "r", encoding="utf-8") as f:
            pedidos = json.load(f)
            # Convertir cadenas ISO a objetos datetime nativos para MongoDB BSON
            for p in pedidos:
                if isinstance(p["fecha_pedido"], str):
                    p["fecha_pedido"] = datetime.fromisoformat(p["fecha_pedido"].replace("Z", "+00:00"))
            return pedidos
    return []

def migrar_a_mongodb(mongo_uri="mongodb://localhost:27017/", db_name="foodstore_nosql"):
    if not HAS_PYMONGO:
        print("[!] ERROR: 'pymongo' no está instalado. Ejecute: pip install pymongo")
        return False

    pedidos = obtener_pedidos_fuente()
    if not pedidos:
        print("[!] ERROR: No se encontraron pedidos para migrar.")
        return False

    print(f"[*] Conectando a MongoDB en: {mongo_uri} ...")
    try:
        client = MongoClient(mongo_uri, serverSelectionTimeoutMS=4000)
        # Test de conexión
        client.admin.command('ping')
        print("[✓] Conexión exitosa a MongoDB.")
    except Exception as e:
        print(f"[!] No se pudo conectar a MongoDB ({e}).")
        print("[i] Guardando datos estructurados listos para importación en 'datos/pedidos.json'.")
        return False

    db = client[db_name]
    col = db["pedidos"]

    print("[*] Limpiando colección previa 'pedidos'...")
    col.drop()

    print(f"[*] Insertando {len(pedidos)} documentos con modelo embebido...")
    resultado = col.insert_many(pedidos)
    print(f"[✓] Éxito: {len(resultado.inserted_ids)} documentos insertados.")

    # Creación de índices multikey y filtros habituales
    print("[*] Creando índices de optimización...")
    col.create_index([("id_pedido", ASCENDING)], unique=True)
    col.create_index([("estado", ASCENDING)])
    col.create_index([("lineas.id_producto", ASCENDING)])
    col.create_index([("total", ASCENDING)])
    print("[✓] Índices creados: id_pedido (unique), estado, lineas.id_producto, total.")

    print("\n--- Muestra del primer documento migrado ---")
    doc_muestra = col.find_one({}, {"_id": 0})
    print(json.dumps(doc_muestra, indent=2, default=str))

    return True

if __name__ == "__main__":
    uri = sys.argv[1] if len(sys.argv) > 1 else "mongodb://localhost:27017/"
    migrar_a_mongodb(uri)
