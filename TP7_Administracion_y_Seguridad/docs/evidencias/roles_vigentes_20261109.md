# TP7 — Roles y Permisos Vigentes (`\du` + `role_table_grants`)

**Proyecto:** Food Store — Base de Datos II (UTN FRM)  
**Alumno:** Máximo Juan Cruz Quiroga (`maximoj.quiroga@alumnos.frm.utn.edu.ar`)  
**Docente:** Sergio Neira  
**Base:** `foodstore_dev` (PostgreSQL 17.11)  
**Fecha de verificación:** 2026-11-09  

---

## 1. Salida de `\du` (Roles de Instancia)

```text
                                Lista de roles
   Nombre de rol   |                         Atributos                         
-------------------+-----------------------------------------------------------
 admin_datos       | 5 conexiones
 app_web           | 20 conexiones
 postgres          | Superusuario, Crear rol, Crear BD, Replicación, Ignora RLS
 rol_app_escritura | No puede conectarse
 rol_app_lectura   | No puede conectarse
 rol_auditoria     | No puede conectarse
 rol_reportes      | No puede conectarse
 rol_soporte       | No puede conectarse
```

---

## 2. `information_schema.role_table_grants` (Roles TP7, Esquema `public`)

97 filas verificadas contra la especificación de [requirements.md](../kiro_roles_spec/requirements.md) (salida completa en [salida_roles_vigentes_20261109.txt](salida_roles_vigentes_20261109.txt)):

- **`admin_datos`:** `ALL` (77 filas = 7 privilegios × 11 objetos: 6 tablas base `categorias`, `clientes`, `productos`, `pedidos`, `detalles_pedido`, `usuarios` + 5 vistas regulares).
- **`rol_app_escritura`:** `INSERT, UPDATE` (10 filas) en las 5 tablas de negocio (`categorias`, `clientes`, `detalles_pedido`, `pedidos`, `productos`); sin `DELETE`; sin acceso a `usuarios`.
- **`rol_app_lectura`:** `SELECT` (8 filas) en las 5 tablas de negocio + 3 vistas operativas (`v_catalogo_productos`, `v_detalle_pedido_producto`, `v_pedido_cliente`).
- **`rol_reportes`:** `SELECT` (2 filas en `role_table_grants`) en `v_reporte_ventas_cliente` y `v_usuario_publico` (más `SELECT` sobre `mv_resumen_ventas_categoria_mes`, verificado vía consulta directa en [verificacion_permisos.md](../kiro_roles_spec/verificacion_permisos.md)).
- **`rol_soporte`, `rol_auditoria`:** sin filas a nivel de tabla completa (`rol_soporte` opera por columnas sobre `usuarios`, 9 filas en `role_column_grants`, RF-03).
