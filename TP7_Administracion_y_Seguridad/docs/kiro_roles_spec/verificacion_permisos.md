# TP7 Parte A.3 — Verificación de Permisos en `foodstore_dev`

**Proyecto:** Food Store — Base de Datos II (UTN FRM)  
**Alumno:** Máximo Juan Cruz Quiroga (`maximoj.quiroga@alumnos.frm.utn.edu.ar`)  
**Docente:** Sergio Neira  
**Motor:** PostgreSQL 17.11 · **Base:** `foodstore_dev` · **Fecha:** 2026-11-09  
**Script aplicado:** [sql/roles.sql](../../sql/roles.sql)  
**Especificación:** [requirements.md](requirements.md) (RF-01 a RF-07) y [design.md](design.md)  

---

## 1. Roles configurados (`\du`)

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

## 2. Permisos a nivel de tabla (`information_schema.role_table_grants`)

Resumen de las 97 filas verificadas en el esquema `public` (ver salida completa en [salida_roles_vigentes_20261109.txt](../evidencias/salida_roles_vigentes_20261109.txt)):

- **`admin_datos`:** `ALL` (`DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE`) sobre las 6 tablas (`categorias`, `clientes`, `productos`, `pedidos`, `detalles_pedido`, `usuarios`) y las 5 vistas regulares (`v_catalogo_productos`, `v_detalle_pedido_producto`, `v_pedido_cliente`, `v_reporte_ventas_cliente`, `v_usuario_publico`).
- **`rol_app_escritura`:** `INSERT, UPDATE` sobre las 5 tablas transaccionales (`categorias`, `clientes`, `detalles_pedido`, `pedidos`, `productos`). **0 permisos de `DELETE` o `TRUNCATE`**, y **0 permisos sobre `usuarios`**.
- **`rol_app_lectura`:** `SELECT` sobre las 5 tablas de negocio (`categorias`, `clientes`, `detalles_pedido`, `pedidos`, `productos`) y las 3 vistas operativas (`v_catalogo_productos`, `v_detalle_pedido_producto`, `v_pedido_cliente`).
- **`rol_reportes`:** `SELECT` exclusivamente sobre `v_reporte_ventas_cliente` y `v_usuario_publico` (más `SELECT` verificado vía `has_table_privilege` sobre `mv_resumen_ventas_categoria_mes`).
- **`rol_soporte`, `rol_auditoria`, `app_web`:** 0 filas directas a nivel de tabla completa (`rol_soporte` opera por columnas; `rol_auditoria` vía `pg_monitor`; `app_web` hereda de lectura y escritura).
- **`PUBLIC`:** **0 filas** en `information_schema.table_privileges` para `table_schema = 'public'`.

---

## 3. Permisos a nivel de columna sobre `usuarios` (`information_schema.role_column_grants`)

Permisos otorgados a `rol_soporte` (RF-03 exacto, **sin `contrasena`**):

```text
   grantee   | table_name |    column_name     | privilege_type
-------------+------------+--------------------+----------------
 rol_soporte | usuarios   | activo             | SELECT
 rol_soporte | usuarios   | activo             | UPDATE
 rol_soporte | usuarios   | apellido           | SELECT
 rol_soporte | usuarios   | correo_electronico | SELECT
 rol_soporte | usuarios   | fecha_creacion     | SELECT
 rol_soporte | usuarios   | id_usuario         | SELECT
 rol_soporte | usuarios   | nombre             | SELECT
 rol_soporte | usuarios   | rol                | SELECT
 rol_soporte | usuarios   | telefono           | SELECT
(9 filas)
```

---

## 4. Funciones (`information_schema.role_routine_grants`)

```text
      grantee      |     routine_name     | privilege_type
-------------------+----------------------+----------------
 admin_datos       | fn_autenticar        | EXECUTE
 admin_datos       | fn_resetear_password | EXECUTE
 postgres          | fn_autenticar        | EXECUTE
 postgres          | fn_resetear_password | EXECUTE
 rol_app_escritura | fn_autenticar        | EXECUTE
 rol_soporte       | fn_resetear_password | EXECUTE
(6 filas)
```

`PUBLIC` en ambas funciones: **0 filas**. Cumple exactamente con la matriz RF-05.

---

## 5. Membresías y Privilegios por Defecto (`pg_auth_members` y `pg_default_acl`)

```text
  login  |    miembro_de
---------+-------------------
 app_web | rol_app_escritura
 app_web | rol_app_lectura
(2 filas)
```

Privilegios por defecto (`pg_default_acl` en esquema `public`):

```text
 para_objetos_de | tipo |                             defaclacl
-----------------+------+-------------------------------------------------------------------
 postgres        | S    | {rol_app_escritura=rU/postgres}
 postgres        | r    | {rol_app_lectura=r/postgres,rol_app_escritura=aw/postgres}
 admin_datos     | S    | {rol_app_escritura=rU/admin_datos}
 admin_datos     | r    | {rol_app_lectura=r/admin_datos,rol_app_escritura=aw/admin_datos}
(4 filas)
```

---

## 6. Pruebas Dinámicas con `SET LOCAL ROLE` (`BEGIN ... ROLLBACK`)

### 6.1 Comprobación bajo `SET LOCAL ROLE rol_soporte`

```text
-- Lectura de columnas permitidas: OK
BEGIN
SET
 id_usuario |    nombre     |     correo_electronico     
------------+---------------+----------------------------
          1 | Administrador | admin@foodstore.utn.edu.ar
(1 fila)
ROLLBACK

-- SELECT * FROM public.usuarios: DENEGADO (42501)
BEGIN
SET
ERROR:  permiso denegado a la tabla usuarios

-- SELECT contrasena FROM public.usuarios: DENEGADO (42501)
BEGIN
SET
ERROR:  permiso denegado a la tabla usuarios

-- Ejecución de fn_resetear_password (usuario inexistente): OK (devuelve false)
BEGIN
SET
 fn_resetear_password 
----------------------
 f
(1 fila)
ROLLBACK
```

### 6.2 Comprobación bajo `SET LOCAL ROLE app_web`, `rol_reportes` y `rol_auditoria`

```text
-- Lectura operativa sobre public.productos bajo app_web: OK
BEGIN
SET
 id_producto |      nombre      
-------------+------------------
           1 | Pizza Muzzarella
           2 | Pizza Napolitana
(2 filas)
ROLLBACK

-- Ejecución de public.fn_autenticar bajo app_web (clave errónea -> NULL): OK
BEGIN
SET
 login_test 
------------
           
(1 fila)
ROLLBACK

-- INSERT sobre public.categorias bajo app_web (hereda lectura + escritura): OK (revertido con ROLLBACK)
BEGIN
SET
 id_categoria |    nombre    
--------------+--------------
            7 | PruebaAppWeb
(1 fila)
INSERT 0 1
ROLLBACK

-- Escalamiento GRANT admin_datos TO app_web: RECHAZADO (42501)
BEGIN
SET
ERROR:  se ha denegado el permiso para otorgar el rol «admin_datos»
DETALLE:  Sólo los roles con la opción ADMIN en el rol «admin_datos» pueden otorgar este rol.

-- DELETE FROM public.categorias bajo app_web: RECHAZADO (42501)
BEGIN
SET
ERROR:  permiso denegado a la tabla categorias

-- DROP TABLE public.categorias bajo app_web: RECHAZADO (42501)
BEGIN
SET
ERROR:  debe ser dueño de la tabla categorias

-- Vistas permitidas bajo rol_reportes: OK
BEGIN
SET
 filas_v_usuario_publico 
-------------------------
                       3
(1 fila)

 filas_mv 
----------
        3
(1 fila)
ROLLBACK

-- Lectura de pg_stat_activity bajo rol_auditoria (pg_monitor): OK
BEGIN
SET
 sesiones_activas 
------------------
                6
(1 fila)
ROLLBACK
```

---

## 7. Contraste contra la Especificación y Veredicto

| Requisito | Esperado | Observado | Estado |
|---|---|---|---|
| **RF-01 Tablas** | Lectura `SELECT`×5; escritura `INSERT, UPDATE`×5 sin `DELETE`; `admin_datos` `ALL`×6 | Idéntico (§2) | Cumplido |
| **RF-02 Vistas** | Lectura 3 operativas; reportes 2 regulares + 1 materializada | Idéntico (§2 + §5) | Cumplido |
| **RF-03 Columnas** | `rol_soporte` 8 `SELECT` + `UPDATE(activo)`, sin `contrasena` | Idéntico (§3); `SELECT contrasena` denegado (§6.1) | Cumplido |
| **RF-04 Secuencias** | Escritura `USAGE, SELECT` en secuencias de negocio (sin `usuarios_id_usuario_seq`) | Idéntico (§5) | Cumplido |
| **RF-05 Funciones** | Escritura → `fn_autenticar`; Soporte → `fn_resetear_password`; Admin → ambas | Idéntico (§4) | Cumplido |
| **RF-06 Auditoría** | `pg_monitor`, sin acceso a tablas de negocio ni `pg_authid` | Miembro de `pg_monitor`, 0 grants de negocio | Cumplido |
| **RF-07 Defaults** | Herencia lectura (`r`) y escritura (`aw`) en tablas y secuencias | 4 filas en `pg_default_acl` (`postgres` + `admin_datos`) | Cumplido |
| **Restricciones §4** | Sin `DELETE`/DDL en `app_web`; sin hash en `rol_soporte`; sin escalamiento | Probado dinámicamente en §6.1 y §6.2 | Cumplido |

**Veredicto final:** Cumplimiento 100% del principio de mínimo privilegio (*"ni más, ni menos"*).
