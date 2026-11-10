# TP9 (Unidad 7) — NoSQL y Nuevas Formas de Almacenamiento: Food Store

**Institución:** Universidad Tecnológica Nacional – Facultad Regional Mendoza (UTN FRM)  
**Cátedra:** Base de Datos II  
**Docente:** Sergio Neira  
**Alumno:** Máximo Juan Cruz Quiroga (`maximoj.quiroga@alumnos.frm.utn.edu.ar`)  
**Proyecto:** Food Store (PostgreSQL 17 / MongoDB)  
**Ciclo Lectivo:** 2026  

---

## 📌 Guía de Entregables del Trabajo Práctico

Este directorio contiene la solución completa de la **Unidad 7 (NoSQL y MongoDB)** para el subconjunto transaccional «pedidos y detalle de pedidos» de Food Store:

| Entregable | Archivo | Descripción |
|---|---|---|
| **Informe Oficial en PDF** | [**`Informe_TP_NoSQL_FoodStore.pdf`**](Informe_TP_NoSQL_FoodStore.pdf) | **PDF final de 3 páginas:** Descripción sintética del modelo, datos migrados, evidencias de consultas, tabla comparativa, contraste crítico de IA y conclusión técnica. |
| **Informe Técnico Editable** | [**`informe_u7_Maximo_Quiroga.md`**](informe_u7_Maximo_Quiroga.md) | Versión completa en Markdown con explicaciones de diseño y justificaciones teóricas. |
| **Consultas MongoDB** | [**`consultas_mongodb.js`**](consultas_mongodb.js) | Las 4 consultas obligatorias (todas las órdenes, filtro por estado, búsqueda de producto en arreglo embebido y filtro por total > $10.000). |
| **Consultas PostgreSQL** | [**`consultas_postgresql.sql`**](consultas_postgresql.sql) | Consultas SQL equivalentes a las consultas (b) y (c) para verificación cruzada. |
| **Script de Migración BSON** | [**`migracion_pedidos.js`**](migracion_pedidos.js) | Script de inicialización de colección con `$jsonSchema`, índices y `insertMany()`. |
| **ETL Automatizado** | [**`etl_postgres_a_mongo.py`**](etl_postgres_a_mongo.py) | Script en Python (`pymongo`) para extracción, transformación documental y carga directa. |
| **Dataset Documental JSON** | [**`datos/pedidos.json`**](datos/pedidos.json) | Los 5 pedidos canónicos en formato JSON con líneas embebidas y snapshot de cliente. |
| **Compilador de PDF** | [**`generate_pdf.py`**](generate_pdf.py) | Script de ReportLab para compilar el PDF de entrega oficial. |

---

## 🚀 Instrucciones de Ejecución

### Opción A: Carga mediante MongoDB Compass (Recomendada con Interfaz Gráfica)
1. Abrir **MongoDB Compass** y conectarse a la instancia (`mongodb://localhost:27017` o clúster de Atlas).
2. Crear la base de datos `foodstore_nosql` y la colección `pedidos`.
3. Seleccionar **Add Data** -> **Import JSON or CSV file** y cargar el archivo:
   `nosql/TP9/datos/pedidos.json`
4. En la pestaña **_mongosh** (en la barra inferior de Compass), ejecutar las consultas pegando el contenido de [**`consultas_mongodb.js`**](consultas_mongodb.js).

### Opción B: Ejecución por Terminal (`mongosh`)
```powershell
# 1. Ejecutar la migración inicial e inserción masiva
mongosh "mongodb://localhost:27017" ".\migracion_pedidos.js"

# 2. Ejecutar las 4 consultas de verificación
mongosh "mongodb://localhost:27017" ".\consultas_mongodb.js"
```

### Opción C: Ejecución vía Script ETL en Python
```powershell
python .\etl_postgres_a_mongo.py
```

---

## 📊 Tabla Comparativa de Verificación (Consigna 5)

| Consulta Evaluada | Cantidad en PostgreSQL | Cantidad en MongoDB | ¿Coinciden los IDs? | IDs Recuperados |
|---|:---:|:---:|:---:|:---:|
| **Estado seleccionado (`'ENTREGADO'`)** | **3** | **3** | **SÍ** | `[1, 3, 5]` |
| **Producto seleccionado (`id_producto = 1`)** | **3** | **3** | **SÍ** | `[1, 2, 4]` |

---

## 💡 Conclusión Técnica y Arquitectónica (Consigna 7)

Para el ecosistema de **Food Store**, la arquitectura recomendada es **Persistencia Políglota (*Polyglot Persistence*)**:
1. **PostgreSQL** se mantiene como el **Almacén de Registro Transaccional (*System of Record*)** para el catálogo maestro, categorías, balance de stock, clientes y facturación impositiva (donde las garantías ACID, auditoría de logs y restricciones de clave foránea son mandatorias).
2. **MongoDB** se adopta como el **Repositorio Documental de Órdenes (*Order History & Read Store*)**, donde los pedidos despachados se almacenan desnormalizados con sus ítems embebidos y el snapshot del cliente, optimizando las lecturas a un único ciclo I/O (`find`) sin la sobrecarga de múltiples JOINs relacionales.
