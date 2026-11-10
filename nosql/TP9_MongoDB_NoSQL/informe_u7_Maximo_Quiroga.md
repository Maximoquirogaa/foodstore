# Trabajo Práctico · Unidad 7: NoSQL y Nuevas Formas de Almacenamiento

**Institución:** Universidad Tecnológica Nacional – Facultad Regional Mendoza (UTN FRM)  
**Carrera:** Tecnicatura Universitaria en Programación  
**Asignatura:** Base de Datos II  
**Docente:** Sergio Neira  
**Alumno:** Máximo Juan Cruz Quiroga (`maximoj.quiroga@alumnos.frm.utn.edu.ar`)  
**Proyecto:** Food Store (PostgreSQL 17 / MongoDB)  
**Ciclo Lectivo:** 2026  

---

## Introducción y Objetivos

El presente trabajo aborda la transición arquitectónica entre el modelo relacional tradicional (**PostgreSQL 17**) y el modelo no relacional orientado a documentos (**MongoDB**), centrándose en el subconjunto transaccional crítico de **Food Store: «pedidos y detalles de pedido»**.

Se modela, migra y consulta una colección documental completa, preservando los identificadores de origen y validando rigurosamente la coherencia de datos, la equivalencia de resultados entre ambos motores y el análisis crítico de recomendaciones proporcionadas por herramientas de Inteligencia Artificial.

---

## Parte 1 · Modelo Documental y Migración

### Consigna 1: Identificación Relacional y Diseño del Esquema Documental

#### 1.1 Tablas y Claves Intervinientes en PostgreSQL
En la base de datos relacional de Food Store, la información de una orden de compra se encuentra distribuida y normalizada a lo largo de cuatro tablas:

1. **`pedidos`**: Tabla cabecera.
   - **Clave Primaria (PK):** `id_pedido` (`BIGINT GENERATED ALWAYS AS IDENTITY`).
   - **Clave Foránea (FK):** `id_cliente` hacia `clientes(id_cliente)`.
   - **Atributos:** `forma_pago` (`ENUM: EFECTIVO, TARJETA, TRANSFERENCIA`), `fecha_pedido` (`TIMESTAMPTZ`), `estado` (`VARCHAR(20)`).
2. **`detalles_pedido`**: Tabla intermedia de resolución N:M.
   - **Clave Primaria Compuesta (PK):** (`id_pedido`, `id_producto`).
   - **Claves Foráneas (FK):** `id_pedido` hacia `pedidos` (`ON DELETE CASCADE`), `id_producto` hacia `productos` (`ON DELETE RESTRICT`).
   - **Atributos:** `cantidad` (`INTEGER CHECK > 0`), `precio_unitario` (`DECIMAL(12,2)`).
3. **`clientes`**: Entidad externa referenciada.
   - **Clave Primaria (PK):** `id_cliente`. Atributos: `nombre`, `apellido`, `correo_electronico`.
4. **`productos`**: Entidad del catálogo comercial.
   - **Clave Primaria (PK):** `id_producto`. Atributos: `nombre`, `id_categoria`, `precio_actual`.

#### 1.2 Esquema Documental Propuesto en MongoDB (Colección `pedidos`)
Para MongoDB se diseñó un **modelo embebido desnormalizado (*Embedded Document Pattern*)**, donde cada documento representa un pedido integral y autocontenido:

```json
{
  "_id": ObjectId("67324fa1b8c19d45e1234567"),
  "id_pedido": 1,
  "fecha_pedido": ISODate("2026-10-15T12:30:00Z"),
  "forma_pago": "TARJETA",
  "estado": "ENTREGADO",
  "cliente": {
    "id_cliente": 1,
    "nombre": "Juan Pérez",
    "correo_electronico": "juan.perez@email.com"
  },
  "lineas": [
    {
      "id_producto": 1,
      "nombre": "Hamburguesa Clásica",
      "cantidad": 2,
      "precio_unitario": 4500.00,
      "subtotal": 9000.00
    },
    {
      "id_producto": 3,
      "nombre": "Papas Fritas Medianas",
      "cantidad": 1,
      "precio_unitario": 2200.00,
      "subtotal": 2200.00
    },
    {
      "id_producto": 4,
      "nombre": "Gaseosa Cola 500ml",
      "cantidad": 2,
      "precio_unitario": 1500.00,
      "subtotal": 3000.00
    }
  ],
  "total": 14200.00
}
```

* **Campos principales:** `id_pedido`, `fecha_pedido`, `forma_pago`, `estado`, `total`.
* **Objeto embebido (`cliente`):** Subdocumento con los datos esenciales del comprador.
* **Arreglo de objetos (`lineas`):** Arreglo de subdocumentos con cada ítem ordenado, congelando nombre, precio unitario, cantidad y subtotal.
* **Identificadores conservados:** Se mantiene `id_pedido`, `id_cliente` e `id_producto` originales de PostgreSQL como campos numéricos para trazabilidad cruzada.

---

### Consigna 2: Creación de Base, Colección y Migración de Datos

Se creó la base de datos **`foodstore_nosql`** y la colección **`pedidos`**. La migración se implementó mediante el script [**`migracion_pedidos.js`**](migracion_pedidos.js) ejecutando `db.pedidos.insertMany(...)` (y alternativamente mediante el ETL automatizado [**`etl_postgres_a_mongo.py`**](etl_postgres_a_mongo.py)).

Se migraron 5 pedidos representativos con la siguiente composición:

| `id_pedido` | Fecha | Cliente | Estado | Forma Pago | Ítems en el Pedido | Total |
|---|---|---|---|---|---|---:|
| **1** | 2026-10-15 12:30 | Juan Pérez | `ENTREGADO` | `TARJETA` | 2x Hamb. Clásica, 1x Papas Med., 2x Gaseosa | **$14.200,00** |
| **2** | 2026-10-16 13:15 | María Gómez | `PENDIENTE` | `EFECTIVO` | 1x Hamb. Clásica, 1x Gaseosa | **$6.000,00** |
| **3** | 2026-10-16 20:45 | Carlos López | `ENTREGADO` | `TRANSFERENCIA`| 2x Hamb. Doble Queso, 2x Cerveza Art. | **$18.000,00** |
| **4** | 2026-10-17 21:10 | Juan Pérez | `CANCELADO` | `TARJETA` | 1x Hamb. Clásica, 1x Hamb. Doble Queso | **$10.700,00** |
| **5** | 2026-10-18 14:00 | María Gómez | `ENTREGADO` | `TRANSFERENCIA`| 2x Papas Med., 2x Gaseosa | **$7.400,00** |

---

### Consigna 3: Reglas de Integridad y Justificación del Modelo Embebido

#### 3.1 Dos Reglas de Integridad Conservadas Durante la Migración
1. **Regla de Inmutabilidad Histórica y Precios Congelados (R4 y R5 de Food Store):**  
   En un sistema de ventas, el `precio_unitario` y el `subtotal` registrados en un pedido no deben modificarse si en el futuro el producto sube de precio en la tabla `productos`. Al migrar a MongoDB, cada renglón en `lineas` almacena el valor nominal exacto pactado al momento de la compra.
2. **Regla de Integridad de Dominio y No Negatividad (R5 de Food Store):**  
   Toda cantidad debe ser un entero estrictamente positivo ($cantidad \ge 1$) y los precios unitarios deben ser no negativos ($precio \ge 0$). Asimismo, el total general debe ser igual a la suma de los subtotales de las líneas ($\sum subtotal$). En MongoDB, esto se blinda mediante validación de esquema con **`$jsonSchema`** a nivel de colección.

#### 3.2 Justificación Técnica de la Inclusión Embebida (*Embedding*)
Se optó por embeber `lineas` y `cliente` dentro del documento `pedido` por tres razones:
1. **Acceso Atómico en una Sola Lectura (*Single-Document Read*):**  
   El patrón de consulta predominante en Food Store requiere leer el pedido completo con todos sus detalles (para facturación, despacho o detalle en pantalla). Embeber los renglones permite resolver la consulta con un único `db.pedidos.find({ id_pedido: X })` en un solo ciclo I/O de disco y red, sin incurrir en la penalización de rendimiento de múltiples `$lookup` (JOINs relacionales).
2. **Atomicidad Transaccional Nativa:**  
   MongoDB garantiza atomicidad completa para escrituras dentro de un único documento (*single-document atomicity*). Al estar las líneas dentro del pedido, la creación o actualización de la orden nunca puede quedar en un estado inconsistente de "cabecera creada sin renglones".
3. **Snapshot Desnormalizado del Cliente:**  
   Embeber el nombre y correo del cliente al momento de la compra asegura que el comprobante comercial no cambie si el cliente posteriormente modifica sus datos de perfil en la aplicación.

#### 3.3 Experimento de Laboratorio: Validación de Esquema (`$jsonSchema`) vs. Expresiones Cruzadas (`$expr`)
Un desafío recurrente al migrar desde bases relacionales es cómo garantizar que los valores calculados no se corrompan (por ejemplo, que `subtotal == cantidad * precio_unitario` y `total == SUM(subtotales)`).
Para responder a esto, se diseñó y ejecutó el script de laboratorio [`prueba_validacion_expr.js`](prueba_validacion_expr.js), evaluando dos niveles de validación en MongoDB:

1. **Validación Estructural con `$jsonSchema` (Colección Principal `pedidos`):**
   Garantiza tipos de datos BSON, presencia de campos obligatorios, cantidades mínimas ($\ge 1$), precios no negativos y enumeraciones de estado permitidas (`ENTREGADO`, `PENDIENTE`, etc.).
2. **Validación Cruzada Avanzada con `$expr` (Colección de Ensayo `pedidos_validacion_expr`):**
   Mediante el operador `$expr`, MongoDB permite evaluar expresiones de agregación durante inserciones y actualizaciones. Se programó una regla que compara en tiempo real `$total` con `{ $sum: "$lineas.subtotal" }`, y valida que cada subtotal coincida con el producto `{ $multiply: ["$$l.cantidad", "$$l.precio_unitario"] }`.
3. **Resultados Observados en el Laboratorio:**
   * **Caso A (Matemática consistente):** Aceptado correctamente por el motor.
   * **Caso B (Total alterado arbitrariamente):** Rechazado por MongoDB con error de validación `Document failed validation` (Código de error 121).
   * **Caso C (Subtotal inconsistente con cantidad y precio):** Rechazado inmediatamente con Código 121.

**Conclusión del Experimento:** Si bien MongoDB *sí* es capaz de rechazar incoherencias matemáticas internas mediante `$expr`, en PostgreSQL esta garantía es nativa y declarativa (vía columnas generadas `GENERATED ALWAYS AS (cantidad * precio_unitario) STORED` y constraints `CHECK`), sin sobrecosto de CPU en la evaluación de expresiones complejas. Por ello, la validación `$expr` debe reservarse como salvaguarda secundaria en MongoDB, complementando la lógica de la aplicación.

---

## Parte 2 · Consultas y Verificación

### Consigna 4: Consultas Ejecutadas en MongoDB ([`consultas_mongodb.js`](consultas_mongodb.js))

#### a) Mostrar todos los pedidos, incluyendo su identificador y estado
```javascript
db.pedidos.find(
  {},
  { id_pedido: 1, estado: 1, fecha_pedido: 1, total: 1, _id: 0 }
).sort({ id_pedido: 1 });
```
* **Resultado:** Devuelve los 5 pedidos registrados (IDs 1, 2, 3, 4, 5) con sus respectivos estados (`ENTREGADO`, `PENDIENTE`, `CANCELADO`).

#### b) Filtrar pedidos por un estado existente (`"ENTREGADO"`)
```javascript
db.pedidos.find(
  { estado: "ENTREGADO" },
  { id_pedido: 1, estado: 1, "cliente.nombre": 1, total: 1, _id: 0 }
).sort({ id_pedido: 1 });
```
* **Resultado:** Recupera exactamente **3 pedidos**:
  - Pedido ID 1: Juan Pérez ($14.200,00)
  - Pedido ID 3: Carlos López ($18.000,00)
  - Pedido ID 5: María Gómez ($7.400,00)

#### c) Buscar pedidos que contengan un producto determinado (`id_producto = 1`, Hamburguesa Clásica)
```javascript
db.pedidos.find(
  { "lineas.id_producto": 1 },
  { id_pedido: 1, estado: 1, "cliente.nombre": 1, "lineas.nombre": 1, total: 1, _id: 0 }
).sort({ id_pedido: 1 });
```
* **Resultado:** Utiliza el *Multikey Index* sobre el arreglo `lineas` y recupera **3 pedidos**:
  - Pedido ID 1 (contiene 2x Hamburguesa Clásica)
  - Pedido ID 2 (contiene 1x Hamburguesa Clásica)
  - Pedido ID 4 (contiene 1x Hamburguesa Clásica)

#### d) Buscar pedidos cuyo total sea superior a un importe elegido (`total > $10.000,00`)
* **Umbral elegido:** **$10.000,00 ARS**.
* **Justificación técnica:** Segmenta las compras de ticket alto (pedidos múltiples o grupales) frente al consumo individual promedio ($6.000 - $8.000).
```javascript
db.pedidos.find(
  { total: { $gt: 10000.00 } },
  { id_pedido: 1, estado: 1, "cliente.nombre": 1, total: 1, _id: 0 }
).sort({ total: -1 });
```
* **Resultado:** Recupera **3 pedidos**: Pedido 3 ($18.000,00), Pedido 1 ($14.200,00) y Pedido 4 ($10.700,00).

---

### Consigna 5: Consultas Equivalentes en PostgreSQL y Verificación Cruzada

Las consultas equivalentes fueron programadas en [**`consultas_postgresql.sql`**](consultas_postgresql.sql):

```sql
-- Equivalente a 4.b: Pedidos con estado 'ENTREGADO'
SELECT p.id_pedido, p.estado, c.nombre || ' ' || c.apellido AS cliente, 
       SUM(dp.cantidad * dp.precio_unitario) AS total
FROM pedidos p
JOIN clientes c ON c.id_cliente = p.id_cliente
JOIN detalles_pedido dp ON dp.id_pedido = p.id_pedido
WHERE p.estado = 'ENTREGADO'
GROUP BY p.id_pedido, p.estado, c.nombre, c.apellido
ORDER BY p.id_pedido;

-- Equivalente a 4.c: Pedidos con id_producto = 1
SELECT DISTINCT p.id_pedido, p.estado, c.nombre || ' ' || c.apellido AS cliente
FROM pedidos p
JOIN clientes c ON c.id_cliente = p.id_cliente
JOIN detalles_pedido dp ON dp.id_pedido = p.id_pedido
WHERE dp.id_producto = 1
ORDER BY p.id_pedido;
```

#### Tabla Comparativa de Verificación

| Consulta Ejecutada | Cantidad en PostgreSQL | Cantidad en MongoDB | ¿Coinciden los IDs? |
|---|:---:|:---:|:---:|
| **Estado seleccionado (`'ENTREGADO'`)** | **3** | **3** | **Sí** (`[1, 3, 5]`) |
| **Producto seleccionado (`id_producto = 1`)** | **3** | **3** | **Sí** (`[1, 2, 4]`) |

#### Explicación Técnica de las Diferencias
1. **Coincidencia Absoluta:** Ambos motores recuperaron exactamente las mismas cardinalidades y los mismos identificadores.
2. **Mecánica Relacional (PostgreSQL):** La consulta requiere combinar 3 tablas (`pedidos`, `detalles_pedido`, `clientes`) mediante operaciones de `Nested Loop` o `Hash Join`. En la búsqueda por producto, es obligatorio aplicar `DISTINCT` o `GROUP BY` para evitar la multiplicación de filas.
3. **Mecánica Documental (MongoDB):** La consulta por estado es un escaneo directo de campo indexado sobre la colección `pedidos`. La consulta por producto utiliza un índice *Multikey*, donde MongoDB indexa cada elemento del arreglo de manera individual, resolviendo la búsqueda sin operaciones de combinación ni desduplicación.

---

## Parte 3 · Evaluación de la Tecnología e IA

### Consigna 6: Consulta Realizada a la Inteligencia Artificial

Se formuló a la IA la siguiente consulta estructurada de arquitectura:

> **Prompt enviado a la IA:**  
> *"Actuá como Arquitecto de Bases de Datos senior. En nuestro sistema Food Store (PostgreSQL 17), los pedidos se modelan en tablas relacionales normalizadas (`pedidos`, `detalles_pedido`, `clientes`). El 95% de las consultas leen pedidos completos para emisión de comprobantes y detalle de compra. Además, una regla crítica del negocio es congelar el precio unitario y cantidad al momento de la compra para que futuros cambios en el catálogo no alteren el historial. Evaluá técnica y comparativamente si conviene mantener PostgreSQL o migrar este subconjunto a una colección documental en MongoDB usando un modelo embebido. Contrastá rendimiento de lectura, consistencia transaccional y complejidad operativa."*

#### Resumen de la Respuesta Recibida de la IA:
*La IA destacó las ventajas del modelo embebido en MongoDB para lecturas rápidas sin JOINs y sugirió que "MongoDB es ideal para e-commerce porque PostgreSQL sufre una penalización severa al reconstruir pedidos con JOINs". Afirmó textualmente que (1) "MongoDB no ofrece garantías ACID relacionales, por lo que no es apto para transacciones financieras complejas", y que (2) "migrar a MongoDB reducirá a la mitad la latencia de consulta en cualquier circunstancia debido a la ausencia de esquemas rígidos". Concluyó recomendando migrar toda la capa transaccional a MongoDB.*

---

### Consigna 7: Contraste Crítico de Afirmaciones y Conclusión Técnica

#### Contraste 1: *"MongoDB no ofrece garantías ACID y es riesgoso para transacciones"*
* **Contraste con la Documentación Oficial de MongoDB:**  
  La afirmación de la IA es **desactualizada e inexacta**.  
  1. Según el manual oficial (*Data Modeling & Atomicity*), las escrituras sobre un único documento son **completamente atómicas y aisladas**. Al embeber los renglones dentro de `pedidos`, la creación de la orden es 100% atómica por diseño.  
  2. Asimismo, desde la versión 4.0 (y perfeccionado en 4.2+ para clústeres shardeados), MongoDB soporta **Transacciones Multi-Documento ACID** con niveles de aislamiento estrictos (`Read Committed`, `Snapshot`). Por lo tanto, MongoDB sí puede garantizar consistencia transaccional cuando se requiere.

#### Contraste 2: *"Migrar a MongoDB reducirá la latencia a la mitad en cualquier circunstancia"*
* **Contraste con Resultados de Laboratorio y Documentación de PostgreSQL:**  
  La afirmación es **falsa como generalización absoluta**.  
  En nuestro laboratorio con PostgreSQL 17, cuando las tablas cuentan con índices adecuados (`idx_pedidos_cliente`, PK compuesta en `detalles_pedido`) y las páginas residen en el *Buffer Cache*, una consulta por clave primaria resuelve en **menos de 1 milisegundo**. Además, PostgreSQL ofrece soporte nativo para **`JSONB`**, permitiendo generar estructuras jerárquicas embebidas directamente en el motor mediante `json_build_object()` y `json_agg()`, alcanzando un rendimiento prácticamente indistinguible de MongoDB sin abandonar las garantías del motor relacional.

#### Contraste 3: *"MongoDB no puede validar dependencias matemáticas entre campos y debe delegarse a la aplicación"*
* **Contraste con Evidencia de Laboratorio y Documentación Oficial de MongoDB:**  
  La afirmación comúnmente formulada por asistentes de IA (que sugiere que MongoDB es incapaz de forzar `total = SUM(subtotales)` o `subtotal = cantidad * precio`) es **técnicamente imprecisa**.  
  Tal como demostró nuestro experimento con [`prueba_validacion_expr.js`](prueba_validacion_expr.js) y la documentación oficial (*Specify Validation With Query Operators*), MongoDB soporta el operador **`$expr`** dentro de las reglas de validación de la colección. Esto permite definir expresiones dinámicas con `$sum` y `$multiply` que rechazan cualquier documento matemáticamente incoherente con código 121 (`Document failed validation`).  
  Sin embargo, existe una diferencia de costo arquitectónico: en PostgreSQL las columnas generadas (`GENERATED ALWAYS AS`) y constraints relacionales son declarativos y de costo prácticamente nulo, mientras que en MongoDB la evaluación de pipelines de expresión en cada inserción/actualización introduce sobrecarga de procesamiento en el motor. Por ello, el modelo relacional sigue siendo superior para reglas contables estrictas.

---

### Conclusión Técnica Final (189 palabras)

Para el sistema Food Store, la decisión arquitectónica óptima es adoptar **Persistencia Políglota (*Polyglot Persistence*)**, combinando ambos motores según el patrón de acceso:

1. **PostgreSQL como Almacén de Registro Transaccional (*System of Record*):**  
   Debe conservarse para el catálogo maestro de productos, categorías, gestión de clientes, control de inventario y facturación fiscal. Estas áreas exigen restricciones de clave foránea estrictas (`ON DELETE RESTRICT`), auditoría nativa, roles de seguridad granulares y consistencia ACID inmediata ante escrituras concurrentes.
2. **MongoDB como Repositorio Documental de Órdenes (*Order History & Read Store*):**  
   El subconjunto de pedidos cerrados y despachados se beneficia enormemente del modelo embebido en MongoDB. Almacenar el pedido desnormalizado con sus líneas y el snapshot del cliente permite que la aplicación web móvil y el servicio de atención consulten órdenes completas en un único ciclo de lectura (`find`), sin costo de JOINs y con escalabilidad horizontal natural.

Migrar la totalidad de Food Store a NoSQL introduciría complejidad innecesaria al replicar la integridad referencial en la capa de aplicación; en cambio, una arquitectura híbrida capitaliza lo mejor de ambos paradigmas.
