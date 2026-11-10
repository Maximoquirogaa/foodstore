# Trabajo Práctico Nº 4: Reportes Analíticos, Joins y Optimización Medida

**Facultad:** Universidad Tecnológica Nacional — Facultad Regional Mendoza (UTN FRM)  
**Carrera:** Tecnicatura Universitaria en Programación (TUP)  
**Cátedra:** Base de Datos II  
**Profesor:** Sergio Neira  
**Alumno:** Máximo Juan Cruz Quiroga  
**Email:** `maximoj.quiroga@alumnos.frm.utn.edu.ar`  
**Proyecto:** Food Store  
**Motor:** PostgreSQL 17  

---

## 1. Presentación y Contexto

Este módulo constituye la entrega del **Trabajo Práctico Nº 4** en el repositorio institucional de **Food Store**, adaptando y profundizando la práctica de reportes analíticos complejos (joins multinivel, agregaciones, funciones de ventana, subconsultas correlacionadas y competencia de optimización) sobre el modelo de datos canónico y oficial de nuestro proyecto.

### Adaptación al Modelo de Datos Canónico de Food Store
El trabajo adapta las consignas de optimización respetando estrictamente las restricciones y convenciones establecidas en las entregas previas (TP2 a TP5):
- **Nombres de tablas normalizados:** `categorias`, `clientes`, `productos`, `pedidos`, `detalles_pedido`.
- **Claves primarias canónicas:** `id_categoria`, `id_cliente`, `id_producto`, `id_pedido`.
- **Entidad `clientes`:** Atributos separados `nombre` y `apellido` (concatenados limpiamente para reportes), y clave candidata `correo_electronico`.
- **Entidad `productos`:** Atributo monetario `precio_actual` y control de catálogo con `stock` y `activo` (baja lógica).
- **Entidad `pedidos`:** Tipado cerrado mediante enum `forma_pago` (`'EFECTIVO'`, `'TARJETA'`, `'TRANSFERENCIA'`) y marca temporal `fecha_pedido`.
- **Líneas de venta (`detalles_pedido`):** Montos calculados al vuelo mediante `(dp.cantidad * dp.precio_unitario)`, preservando la regla de precio congelado histórico.

---

## 2. Estructura de la Entrega

```text
TP4/
├── README.md                      <-- Este documento guía
├── DUIA.md                        <-- Declaración de Uso de IA consolidada oficial
├── Parte1/                        <-- Consultas Analíticas Lentas y Optimización
│   ├── consultas_parte1.sql       <-- Script reproducible de consultas A y B
│   ├── plan_a_antes.md            <-- Plan real inicial de Consulta A
│   ├── plan_a_despues.md          <-- Plan real optimizado (Index Only Scan)
│   ├── plan_b_antes.md            <-- Plan real inicial de Consulta B
│   ├── plan_b_despues.md          <-- Plan real con propuesta descartada
│   ├── PROMPT_1.md                <-- Prompts iniciales de exploración
│   ├── PROMPT_2.md                <-- Prompts de evaluación comparativa
│   ├── tabla_comparativa.md       <-- Matriz comparativa de métricas y decisiones
│   └── DUIA_Parte1.md             <-- DUIA específica de la Parte 1
├── Parte2/                        <-- Lectura Crítica de Planes de JOIN
│   ├── plan_a_explicacion_ia.md   <-- Análisis nodo por nodo y tabla de 7 afirmaciones
│   └── DUIA_Parte2.md             <-- DUIA específica de la Parte 2
├── Parte3/                        <-- Rankings, Subconsultas y Equivalencia Formal
│   ├── consulta_a_ranking.sql     <-- DENSE_RANK() vs subconsulta (validación EXCEPT)
│   ├── consulta_b_subconsulta.sql <-- Subconsulta correlacionada vs CTE pre-agregada
│   └── DUIA_Parte3.md             <-- DUIA específica de la Parte 3
└── Parte4/                        <-- Competencia de Optimización entre Equipos
    ├── consulta_competencia.sql   <-- Consulta oficial del Top 3 por categoría
    ├── analisis_optimizacion.md   <-- Diagnóstico de Sort disk spill y sesgo de orden
    ├── registro_competencia.md    <-- Tabla oficial de resultados de la competencia
    ├── plan_antes.txt             <-- EXPLAIN ANALYZE antes de la optimización
    ├── plan_despues.txt           <-- EXPLAIN ANALYZE tras work_mem = '8MB'
    └── DUIA_Parte4.md             <-- DUIA específica de la Parte 4
```

---

## 3. Resumen Ejecutivo de las 4 Fases

### Parte 1 — Laboratorio: Consultas Analíticas Lentas
- **Consulta A (Facturación mensual por categoría activa):** Cruce de 4 tablas. El plan base demoraba **699.55 ms** con `Parallel Hash Join` y escaneo en heap. Se probó el índice cubriente `idx_TP4_a_pedidos_fecha ON pedidos (id_pedido) INCLUDE (fecha_pedido)`. El plan conmutó a `Parallel Index Only Scan` con `Heap Fetches: 0`, preservando paralelismo y reduciendo el tiempo a **164.25 ms** (**mejora de ~4.26x, ACEPTADA**).
- **Consulta B (Ranking histórico de clientes por gasto):** La IA propuso un índice cubriente sobre `pedidos(id_pedido) INCLUDE (id_cliente)`. El optimizador lo ignoró completamente y mantuvo `Parallel Seq Scan` (304.75 ms vs 305.60 ms). **Propuesta RECHAZADA**. Se descubrió que el cuello de botella era derrame a disco por agregación, resolviéndose elevando memoria (`work_mem`).

### Parte 2 — Lectura Crítica de Planes de JOIN
- Se auditó la explicación generada por una IA sobre el plan optimizado de la Consulta A.
- Se confeccionó una **matriz de lectura crítica de 7 afirmaciones técnicas**:
  * Se corrigió la falsa creencia de que `Heap Fetches: 0` depende únicamente de que el índice sea cubriente, demostrando el rol insoslayable del **Visibility Map**.
  * Se desmitificó el valor de `cost`, aclarando que es una estimación interna adimensional y no un equivalente a milisegundos.
  * Se explicó cómo el proceso coordinador colabora en el escaneo paralelo (`loops=3`).

### Parte 3 — Especificación Precisa y Verificación Formal (EXCEPT)
- **Consulta A (Ranking con empates):** Se implementó `DENSE_RANK() OVER (ORDER BY gasto DESC)`. Al construir la alternativa con subconsulta correlacionada, la primera propuesta de la IA usó `COUNT(*)`, lo que provocó **19.433 filas de discrepancia en el `EXCEPT`** (emulaba `RANK()` con huecos). Se corrigió a `COUNT(DISTINCT ...) + 1`, alcanzando **0 filas** en el `EXCEPT` bidireccional.
- **Consulta B (Productos sobre el promedio de su categoría):** Se comparó la subconsulta correlacionada en `WHERE` frente a un `JOIN` con pre-agregación grupal. Ambas arrojaron 0 filas en el `EXCEPT`, pero la versión pre-agregada redujo la complejidad de $O(N \cdot M)$ a $O(N)$, resolviendo en apenas milisegundos.

### Parte 4 — Competencia de Optimización
- **Consulta:** Top 3 productos por facturación dentro de cada categoría en los últimos 6 meses.
- **Diagnóstico:** El cuello de botella principal no eran los scans secuenciales (~40-70 ms), sino el operador `Sort` con derrame a disco (`external merge Disk: 3576kB`) por exceder el `work_mem = 4MB` por defecto.
- **Solución Adoptada:** `SET LOCAL work_mem = '8MB'`. El ordenamiento pasó a memoria RAM (`quicksort Memory: 5883kB`), eliminando todo el I/O temporal y reduciendo el tiempo de **621.0 ms a 571.4 ms** de forma limpia y sin tocar índices.
- **Control Metodológico de Sesgo de Caché:** Una propuesta de índice parecía ganar por 48 ms en mediciones agrupadas; al aplicar mediciones intercaladas (A-B-A-B-A-B), los promedios empataron exactamente en 571.4 ms, demostrando que la aparente ganancia era un artefacto del búfer caché. El índice fue consecuentemente **RECHAZADO**.

---

## 4. Guía de Ejecución y Reproducibilidad

Para verificar cualquiera de las consultas y pruebas en una instancia local de PostgreSQL 17:

1. **Asegurar la carga de datos:**
   ```sql
   -- Ejecutar el esquema y la carga masiva oficial desde TP5 o TP3
   \i 'TP5/schema.sql'
   \i 'TP5/data.sql'
   ```
2. **Ejecutar las consultas de la Parte 1:**
   ```sql
   \i 'TP4/Parte1/consultas_parte1.sql'
   ```
3. **Comprobar la equivalencia formal de la Parte 3:**
   ```sql
   \i 'TP4/Parte3/consulta_a_ranking.sql'
   \i 'TP4/Parte3/consulta_b_subconsulta.sql'
   ```
4. **Reproducir la optimización de la competencia de la Parte 4:**
   ```sql
   \i 'TP4/Parte4/consulta_competencia.sql'
   ```

