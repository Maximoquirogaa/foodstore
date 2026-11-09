# Trabajo Práctico Nº 6: FNBC y Desnormalización Controlada

**Facultad:** Universidad Tecnológica Nacional — Facultad Regional Mendoza (UTN FRM)  
**Carrera:** Tecnicatura Universitaria en Programación (TUP)  
**Cátedra:** Base de Datos II  
**Profesor:** Sergio Neira  
**Alumno:** Máximo Juan Cruz Quiroga  
**Email:** `maximoj.quiroga@alumnos.frm.utn.edu.ar`  
**Proyecto:** Food Store  
**Motor:** PostgreSQL 17.11  
**Base de trabajo:** `foodstore_copia_trabajo` (esquema masivo Food Store: 200.000 pedidos, 200.000 detalles, 50.000 productos, 20.000 clientes, 5 categorías)

---

## 1. Presentación y Contexto

Este módulo constituye la entrega del **Trabajo Práctico Nº 6** en el repositorio institucional de Food Store, integrando de manera rigurosa:
1. **Parte 1 — FNBC en Control de Lotes:** Análisis matemático formal de dependencias funcionales, demostración de cumplimiento de 3FN y transgresión de FNBC, descomposición sin pérdida de información y evaluación de la preservación de dependencias.
2. **Parte 2 — Desnormalización Controlada en Top Diario de Categorías:** Optimización de una consulta analítica de alta frecuencia en tiempo real, pasando de **109.758 ms a 1.867 ms en promedio sobre 3 rondas intercaladas** (**~58.79x más rápida**, con línea base previa medida en **148.939 ms**) mediante columnas caché precalculadas, índices B-Tree específicos y disparadores transaccionales de sincronización.

---

## 2. Estructura de Directorios

```text
TP6_FNBC_Desnormalizacion/
├── README.md                                        <-- Guía integral de la entrega y comandos
├── DUIA.md                                          <-- Bitácora consolidada oficial de Uso de IA
├── informe_final_tp6.md                             <-- Informe técnico consolidado completo
├── Parte1_FNBC/                                     <-- Normalización formal en FNBC
│   ├── tp_fnbc_control_lote.sql                     <-- Script DDL, migración y validación EXCEPT
│   ├── informe_parte1_fnbc.md                       <-- Desarrollo analítico de DFs y anomalías
│   └── evidencias/
│       └── evidencia_fnbc_20261109_121045.txt       <-- Log de ejecución y prueba sin pérdida
└── Parte2_Desnormalizacion/                         <-- Desnormalización orientada a rendimiento
    ├── medir_top_categorias_antes.sql               <-- Medición inicial de consulta normalizada
    ├── tp_desnormalizacion_top_categorias.sql       <-- Script de columnas caché, triggers y pruebas
    ├── informe_parte2_desnormalizacion.md           <-- Análisis comparativo de planes y trade-offs
    └── evidencias/                                  <-- Registros textuales de salidas y tiempos
        ├── evidencia_top_antes_20261109_121047.txt
        └── evidencia_top_desnormalizacion_20261109_121048.txt
```

---

## 3. Síntesis Técnica

### Parte 1 — Normalización en FNBC
- **Relación:** `control_lote_almacen(id_lote, id_deposito, id_responsable_control)`.
- **Dependencias Funcionales:** $LD \to C$ y $C \to D$.
- **Claves Candidatas:** $LD$ y $LC$ (todos los atributos son primos).
- **Veredicto Teórico:** Cumple 3FN (porque $D$ es primo), pero **viola FNBC** porque $C$ no es superclave.
- **Descomposición:** Se descompone en `responsable_deposito(id_responsable_control, id_deposito)` y `control_lote(id_lote, id_responsable_control)`.
- **Propiedades:** Se demuestra reunión sin pérdida mediante `EXCEPT` bidireccional (0 filas). Se constata que la dependencia $LD \to C$ no se preserva localmente por las PKs/FKs de las tablas resultantes.

### Parte 2 — Desnormalización Controlada
- **Consulta:** Top 5 diario de categorías por facturación con filtro de borrado lógico (`eliminado = FALSE`).
- **Problema en Normalizado:** Demoraba **148.939 ms** en medición inicial aislada (**5.306** búferes: `shared hit=4791 read=515`) y **109.758 ms** promedio en las 3 rondas intercaladas (**5.854** búferes `shared hit` promedio) debido a escaneos paralelos/anidados en pedidos, detalles y productos.
- **Estrategia Aplicada:** Incorporación a `detalles_pedido` de las columnas `fecha_pedido_cache`, `id_categoria_cache` y `pedido_eliminado_cache`, con un índice B-Tree sobre la fecha copiada (`idx_tp6_detalle_fecha_cache`) y 3 triggers automáticos de sincronización transaccional.
- **Resultado:** Reducción a **1.867 ms** promedio (**mejora de ~58.79x**, `-98.30%` tiempo) y reducción del **91.48%** en búferes leídos (a **499** bloques `shared hit` constantes), garantizando actualización en tiempo real con **0 filas de discrepancia** en la prueba formal de equivalencia.

---

## 4. Instrucciones de Ejecución

Para reproducir las pruebas en PostgreSQL 17 (ambos scripts se ejecutan dentro de bloques con `ROLLBACK` final para no alterar la base de datos):

```bash
# 1. Ejecución y validación de la Parte 1 (FNBC)
psql -U postgres -d foodstore_copia_trabajo -f "TP6_FNBC_Desnormalizacion/Parte1_FNBC/tp_fnbc_control_lote.sql"

# 2. Medición inicial normalizada de la Parte 2
psql -U postgres -d foodstore_copia_trabajo -f "TP6_FNBC_Desnormalizacion/Parte2_Desnormalizacion/medir_top_categorias_antes.sql"

# 3. Despliegue de desnormalización, triggers y comparación de la Parte 2
psql -U postgres -d foodstore_copia_trabajo -f "TP6_FNBC_Desnormalizacion/Parte2_Desnormalizacion/tp_desnormalizacion_top_categorias.sql"
```

