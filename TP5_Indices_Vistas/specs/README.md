# Índice de Especificaciones (Specs) - TP5

Este directorio y sus subdirectorios contienen las especificaciones funcionales y de optimización utilizadas para la interacción con los asistentes de Inteligencia Artificial (Kiro / Claude / GitHub Copilot), asegurando el principio de diseño asistido riguroso: *"Especificar con precisión antes de codificar"*.

## Mapa de Especificaciones

| Spec | Ubicación | Caso de Estudio | Objetivo / Técnica |
|:---|:---|:---|:---|
| **Spec 01** | `Parte_A_Indices/specs/spec_01_pedidos_cliente_join.md` | Caso 1 (Q5) | Evaluación de índice en `pedidos` vs ajuste de memoria de sesión `work_mem`. |
| **Spec 02** | `Parte_A_Indices/specs/spec_02_productos_categoria_precio.md` | Caso 2 (Q6) | Índice cubriente para subconsulta correlacionada con salvedad de reescritura. |
| **Spec 03** | `Parte_A_Indices/specs/spec_03_pedidos_fecha_brin.md` | Caso 3 (Q4) | Estudio de viabilidad de índice BRIN según correlación física en `fecha_pedido`. |
| **Spec 04** | `Parte_B_Vistas/specs/spec_04_vistas_reportes.md` | Parte B | Diseño de 5 vistas seguras y analíticas con control de privilegios de roles. |
| **Spec 05** | `Parte_C_Vista_Materializada/specs/spec_05_resumen_ventas_categoria_mes.md` | Parte C | Vista materializada agregada con refresco no bloqueante `CONCURRENTLY`. |
| **Spec 06** | `Parte_A_Indices/specs/spec_06_productos_categoria_precio_sin_activo.md` | Caso 4 (Q2) | Índice B-Tree compuesto sobre `(id_categoria, precio_actual)`. |

