# Food Store — Trabajo Práctico N.º 10 (Unidad 8)

**Base de Datos II — Tecnicatura Universitaria en Programación**  
**Universidad Tecnológica Nacional · Facultad Regional Mendoza (UTN FRM)**  
**Docente:** Sergio Neira  
**Alumno:** Máximo Juan Cruz Quiroga (`maximoj.quiroga@alumnos.frm.utn.edu.ar`)  
**Ciclo Lectivo:** 2026  

---

## 1. Descripción del Proyecto

Este trabajo práctico implementa la base de datos de una tablet para el food truck de **Food Store en una feria gastronómica sin conexión a Internet**. La solución utiliza **SQLite 3 (en modo STRICT)** para consultar de forma desconectada una instantánea (*snapshot*) del catálogo comercial y armar borradores de pedidos. 

La sincronización y validación diferida se resuelve simulando el algoritmo del **semáforo**:
* **Rojo (`RECHAZADO`):** Algún producto no existe, no está disponible, fue dado de baja lógica o no alcanza el stock del servidor.
* **Amarillo (`CONFLICTO`):** No hay condición de rechazo, pero el precio visto en la tablet difiere del precio vigente en el servidor.
* **Verde (`SIMULADO_APROBADO`):** Todos los precios, existencias y estados coinciden plenamente.

### Regla de Oro
> **«El móvil propone, el servidor dispone»**  
> La tablet solo consulta y arma borradores. Precios, stock, ventas firmes y facturación los decide exclusivamente **PostgreSQL**.

---

## 2. Estructura de Archivos del Trabajo Práctico

La estructura de entrega respeta de manera exacta los requisitos solicitados por la cátedra:

```text
TP10/ (o nosql/TP10/)
├── README.md                          <- Guía de navegación, ejecución y ensayo de defensa
├── movil/
│   ├── schema_sqlite.sql              <- Consigna 1.b: Esquema SQLite STRICT con PRAGMA foreign_keys
│   ├── pruebas_sqlite.sql             <- Consigna 1.c: Transacciones COMMIT, ROLLBACK, Caso C1 y C7
│   ├── importar_snapshot.sql          <- Consigna 2.a: Importación del CSV del servidor a la caché
│   ├── recargar_snapshot.sql          <- Consigna 2.c: Recarga atómica con UPSERT ON CONFLICT DO UPDATE
│   ├── semaforo.sql                   <- Consigna 2.b: Lógica SQL del semáforo de sincronización
│   ├── casos_2c.sql                   <- Consigna 2.c: Script reproducible de los casos C2 a C6
│   ├── servidor_snapshot.csv          <- Consigna 2.a: Instantánea inicial exportada desde PostgreSQL
│   ├── servidor_snapshot_2c.csv       <- Consigna 2.c: Instantánea modificada con cambio de precio y baja
│   ├── simulador.py                   <- Runner automatizado en Python con SQLite 3 nativo
│   └── foodstore_movil.db             <- Base de datos generada y verificada
├── postgresql/
│   ├── vista_snapshot_movil.sql       <- Consigna 2.a: Vista v_snapshot_movil en PostgreSQL
│   ├── preparar_casos_2c.sql          <- Consigna 2.c: Modificaciones de prueba en servidor (suba de precio y baja)
│   └── verificar_sin_cambios_2c.sql   <- Consigna 2.c: Consulta que prueba que stock y pedidos no cambiaron
└── docs/
    ├── informe.pdf                    <- Consignas 1.a, 2.c, 3.a, 3.b y 3.c (6 páginas exactas ReportLab)
    ├── generate_pdf.py                <- Compilador del informe oficial
    ├── consigna_1a.md                 <- Análisis detallado de qué datos viajan y fuente de verdad
    ├── consigna_2c.md                 <- Documentación técnica de los casos C2 a C6 del semáforo
    ├── consigna_3a.md                 <- Mapa tri-motor (PostgreSQL + MongoDB + SQLite)
    ├── consigna_3b.md                 <- Plan de mantenimiento y contingencia integral
    ├── consigna_3c.md                 <- Code review con IA de los 75 scripts de la cursada
    ├── bitacora_ia.md                 <- Consigna 4.b: Registro de interacción con IA (prompts y descartes)
    ├── DUIA.md                        <- Consigna 4.b: Declaración oficial de uso de Inteligencia Artificial
    └── kiro/                          <- Consigna 4.a: Especificación formal
        ├── requirements.md            <- 4 Requisitos en notación EARS (REQ-01 a REQ-04 ligados a casos)
        ├── design.md                  <- Diagrama de estados del semáforo y diseño
        └── tasks.md                   <- Checklist de tareas de implementación
```

---

## 3. Guía de Ejecución Paso a Paso desde Cero

### Opción A: Ejecución Automatizada en un Solo Paso (Recomendada)
Para crear la base SQLite desde cero, importar los snapshots, ejecutar las pruebas unitarias y resolver los casos C2 a C6 del semáforo:

```bash
python nosql/TP10/movil/simulador.py
```
*Salida esperada:*
- Verificación de esquema `STRICT` y activación de claves foráneas.
- Carga de instantáneas desde CSV.
- `COMMIT` y `ROLLBACK` exitosos.
- Caso C1 (catálogo offline) y Caso C7 (rechazo de cantidad 0 y FK inexistente).
- Evaluación del semáforo: `c2-solicitud-1` (CONFLICTO), `c2-solicitud-2` (SIMULADO_APROBADO), `c3` (RECHAZADO), `c4` (RECHAZADO), `c5` (SIMULADO_APROBADO), `c6` (Error de clave primaria).

---

### Opción B: Ejecución Manual con SQLite CLI (`sqlite3`)

1. **Crear la base de la tablet y cargar el esquema:**
   ```bash
   sqlite3 foodstore_movil.db < nosql/TP10/movil/schema_sqlite.sql
   ```
2. **Ejecutar pruebas unitarias de transacciones y restricciones:**
   ```bash
   sqlite3 foodstore_movil.db < nosql/TP10/movil/pruebas_sqlite.sql
   ```
3. **Importar la instantánea inicial del servidor:**
   ```bash
   sqlite3 foodstore_movil.db
   .mode csv
   .import --skip 1 nosql/TP10/movil/servidor_snapshot.csv snapshot_servidor_import
   .read nosql/TP10/movil/importar_snapshot.sql
   ```
4. **Evaluar los casos C2 a C6:**
   ```bash
   .read nosql/TP10/movil/casos_2c.sql
   ```

---

## 4. Ensayo de Defensa en Clase (Guía de 10 Minutos)

Para la defensa presencial/individual estipulada en la Consigna 4.c, la presentación se estructura en tres bloques de 3 minutos con demostración en vivo:

### Bloque 1: El Mapa de la Capa de Datos (Minutos 0 a 3)
* **Demostración:** Explicar el mapa tri-motor de la Consigna 3.a.
* **Argumento Central:**  
  *"Food Store utiliza tres motores por especialización de patrones de acceso: PostgreSQL es el System of Record relacional que manda sobre stock y facturación; MongoDB aloja el histórico de órdenes cerradas para lectura ultrarrápida sin JOINs; y SQLite reside en la tablet para garantizar que el food truck continúe vendiendo en la feria sin señal."*
* **Regla de Oro:** Enfatizar que el móvil propone y el servidor dispone; `SIMULADO_APROBADO` nunca descuenta existencias en PostgreSQL.

### Bloque 2: Demostración en Vivo de un Caso del Semáforo (Minutos 3 a 7)
* **Demostración:** Correr `simulador.py` o ejecutar en SQLite CLI el **Caso C2**:
  1. Mostrar que el borrador con precio visto de \$4.500 pasa a **`CONFLICTO` (Amarillo)** porque el servidor actualizó el precio a \$4.800.
  2. Mostrar cómo el operador renegocia en el mostrador: el cliente acepta, se actualiza el borrador a \$4.800 y una nueva solicitud con distinto UUID pasa a **`SIMULADO_APROBADO` (Verde)**.
  3. Ejecutar la consulta en PostgreSQL: demostrar que la cantidad de pedidos y el stock permanecen inalterados.

### Bloque 3: Un Hallazgo Crítico de la Revisión con IA (Minutos 7 a 10)
* **Demostración:** Presentar el **Hallazgo F07** (Corregido) o el **Hallazgo F09** (Descartado con fundamento).
* **F07 (Corregido):** Explicar que la IA descubrió que hacer `DELETE FROM producto_cache` rompía la clave foránea con los borradores abiertos de la tablet, lo que motivó el rediseño con `UPSERT (ON CONFLICT DO UPDATE)`.
* **F09 (Descartado):** Explicar por qué se refutó la afirmación de la IA sobre los productos dados de baja: en Food Store la baja es lógica, viaja en el CSV con `disponible = 'f'`, y la tablet la excluye del catálogo disponible y la rechaza en el semáforo con código Rojo.
