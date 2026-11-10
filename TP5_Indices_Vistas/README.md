# Trabajo Práctico Nº 5: Índices, Vistas, Seguridad por Roles y Vistas Materializadas

**Facultad:** Universidad Tecnológica Nacional — Facultad Regional Mendoza (UTN FRM)  
**Carrera:** Tecnicatura Universitaria en Programación (TUP)  
**Cátedra:** Base de Datos II  
**Profesor:** Sergio Neira  
**Alumno:** Máximo Juan Cruz Quiroga  
**Email:** `maximoj.quiroga@alumnos.frm.utn.edu.ar`  
**Proyecto:** Food Store  
**Motor:** PostgreSQL 17  
**Base de trabajo:** Esquema masivo Food Store (~20k clientes, ~50k productos, ~200k pedidos, ~500k detalles)

---

## 1. Presentación y Estado de la Entrega

Este módulo consolida la entrega del **Trabajo Práctico Nº 5** dentro del repositorio oficial de Food Store, adaptando de forma integral la práctica de indexación estratégica, vistas de seguridad y vistas materializadas al esquema canónico del proyecto.

### Estado de los Componentes
- ✅ **Parte A (Plan de Indexado y Costo de Escritura):**
  * 4 casos de estudio analizados (`Q5`, `Q6`, `Q4`, `Q2`).
  * 2 índices aplicados en firme: `idx_productos_categoria_precio` (Q2, ~17.1x de mejora) y `idx_productos_categoria_precio_activo` (Q6, Index Only Scan con Heap Fetches: 0).
  * 2 casos de descarte explícito por sobreindexación: descarte por baja selectividad en `pedidos` (Q5) y descarte por redundancia estructural con la clave primaria en `detalles_pedido`.
  * Descarte de índice BRIN en `fecha_pedido` por correlación física nula (`0.0051`).
  * Medición empírica de la penalización en escritura: hasta +72.2% de lentitud en inserciones por sobreindexación.
- ✅ **Parte B (Vistas y Seguridad por Roles):**
  * Tabla `usuarios` con contraseñas en hash criptográfico y enum de roles (`ADMIN`, `VENDEDOR`, `USUARIO`).
  * 5 vistas analíticas y de exposición controlada (`v_usuario_publico`, `v_reporte_ventas_cliente`, `v_catalogo_productos`, `v_detalle_pedido_producto`, `v_pedido_cliente`).
  * Rol restringido `TP5_reportes` (NOLOGIN) con acceso concedido exclusivamente a las vistas y revocado de todas las tablas base (con evidencia capturada de error de acceso denegado).
  * Verificación formal de equivalencia relacional de cada vista contra su consulta manual mediante `EXCEPT` (0 filas de diferencia).
- ✅ **Parte C (Vista Materializada y Concurrencia):**
  * Vista materializada precalculada `mv_resumen_ventas_categoria_mes` con índice único sobre `(id_categoria, mes)`.
  * Reducción de tiempo de **976.12 ms a 0.054 ms** (**~18.076x de aceleración** con 99.98% menos lecturas de disco).
  * Refresco no bloqueante en producción mediante `REFRESH MATERIALIZED VIEW CONCURRENTLY` (adquiere `ExclusiveLock` en lugar de `AccessExclusiveLock`, permitiendo lecturas concurrentes ininterrumpidas).

---

## 2. Estructura de Directorios

```text
TP5/
├── README.md                                  <-- Guía integral de la entrega
├── DUIA.md                                    <-- Bitácora consolidada oficial de IA
├── informe_mediciones.md                      <-- Informe técnico detallado de mediciones
├── queries.sql                                <-- Consultas reales de negocio (Q1 a Q6)
├── indices.sql                                <-- Punto de entrada a la Parte A
├── views.sql                                  <-- Punto de entrada a las Partes B y C
├── specs/                                     <-- Índice de especificaciones para diseño asistido
│   └── README.md
├── Parte_A_Indices/                           <-- Plan de Indexado y Medición de Escritura
│   ├── indices.sql                            <-- DDL detallado con justificaciones
│   ├── correlacion_fecha_pedido.sql           <-- Medición de pg_stats para BRIN
│   ├── correlacion_fecha_pedido_salida.txt    <-- Salida: correlación nula (0.0051)
│   ├── medir_q2_rondas.sql                    <-- 3 rondas controladas para Q2
│   ├── plan_q2_antes.txt                      <-- Plan base Q2 (Seq Scan + Sort)
│   ├── plan_q2_despues.txt                    <-- Plan con índice (Index Scan, 0.28 ms)
│   ├── plan_q2_rondas_salida.txt              <-- Registro de tiempos de Q2
│   ├── medir_q5_rondas.sql                    <-- 3 rondas intercaladas para Q5
│   ├── plan_q5_antes.txt                      <-- Plan base Q5 (HashAggregate disk spill)
│   ├── plan_q5_despues_workmem.txt            <-- Plan Q5 con work_mem = '16MB' (en RAM)
│   ├── plan_q5_despues_indice_descartado.txt  <-- Plan Q5 con índice ignorado
│   ├── medir_indice_redundante_q5.sql         <-- Prueba de redundancia con PK
│   ├── plan_q5_indice_redundante.txt          <-- Evidencia de descarte de candidato B
│   ├── plan_q5_rondas_salida.txt              <-- Registro de tiempos de Q5
│   ├── medir_q6_rondas.sql                    <-- Medición de subconsulta correlacionada
│   ├── plan_q6_antes.txt                      <-- Plan base Q6 (271.2 s)
│   ├── plan_q6_despues.txt                    <-- Plan con índice cubriente (158.7 s)
│   ├── medir_escritura_productos.sql          <-- Medición de INSERTs masivos en productos
│   ├── medicion_escritura_productos_salida.txt<-- Sobrecosto medido (+33% y +72%)
│   ├── medir_escritura_detalles.sql           <-- Medición de INSERTs en detalles
│   ├── medicion_escritura_detalles_salida.txt <-- Sobrecosto del índice redundante (+48%)
│   └── specs/                                 <-- Specs de diseño asistido de la Parte A
├── Parte_B_Vistas/                            <-- Vistas y Seguridad por Roles
│   ├── usuarios.sql                           <-- Tabla usuarios y enum rol_usuario
│   ├── usuarios_datos.sql                     <-- Datos semilla con contraseñas hasheadas
│   ├── vistas.sql                             <-- Creación de las 5 vistas seguras
│   ├── seguridad_roles.sql                    <-- Rol TP5_reportes y asignación de privilegios
│   ├── verificacion_vistas.sql                <-- Validaciones de seguridad y EXCEPT
│   ├── verificacion_vistas_salida.txt         <-- Salida de verificación formal
│   ├── evidencia_permiso_denegado.txt         <-- Captura del ERROR de permiso denegado
│   └── specs/                                 <-- Specs de diseño asistido de la Parte B
└── Parte_C_Vista_Materializada/               <-- Vista Materializada y Concurrencia
    ├── vista_materializada.sql                <-- DDL de la MV e índice único
    ├── medir_refresh_parte_c.sql              <-- Comparación directa vs MV y medición de locks
    ├── medir_refresh_parte_c_salida.txt       <-- Salida: 976 ms vs 0.054 ms (~18.000x)
    └── specs/                                 <-- Specs de diseño asistido de la Parte C
```

---

## 3. Instrucciones de Ejecución y Reproducibilidad

Para reproducir o verificar cualquiera de los componentes en una instancia local de PostgreSQL 17:

### 1. Despliegue de Índices de la Parte A
```bash
psql -U postgres -d foodstore_tp3_carga -f "TP5/indices.sql"
```

### 2. Despliegue de Vistas, Usuarios y Seguridad (Partes B y C)
```bash
psql -U postgres -d foodstore_tp3_carga -f "TP5/views.sql"
```

### 3. Ejecución de Pruebas de Verificación y Permisos
```bash
psql -U postgres -d foodstore_tp3_carga -f "TP5/Parte_B_Vistas/verificacion_vistas.sql"
psql -U postgres -d foodstore_tp3_carga -f "TP5/Parte_C_Vista_Materializada/medir_refresh_parte_c.sql"
```

