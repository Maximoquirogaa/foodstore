# TP7 — Requisitos de Seguridad: Modelo de Roles PostgreSQL

**Proyecto:** Food Store — Base de Datos II (UTN FRM)  
**Alumno:** Máximo Juan Cruz Quiroga (`maximoj.quiroga@alumnos.frm.utn.edu.ar`)  
**Docente:** Sergio Neira  
**Motor:** PostgreSQL 17  
**Base de destino:** `foodstore_dev`  
**Script de implementación:** `sql/roles.sql`  

---

## 1. Esquema Real de `foodstore_dev`

Este documento se basa en el esquema canónico instalado en `foodstore_dev` al cierre del punto de partida (Clases 1 y 2 del TP7). Todo lo que aquí se especifica refiere a nombres de objetos reales del modelo de Food Store.

### 1.1 Tablas y columnas relevantes para la política de roles

- **`categorias`** — `id_categoria, nombre, descripcion, activo, fecha_creacion`
- **`clientes`** — `id_cliente, nombre, email, telefono, direccion, activo, fecha_registro`
- **`productos`** — `id_producto, id_categoria, nombre, descripcion, precio_actual, stock, activo, fecha_creacion`
- **`pedidos`** — `id_pedido, id_cliente, fecha_pedido, medio_pago, estado, observaciones, total_calculado`
- **`detalles_pedido`** — `id_detalle, id_pedido, id_producto, cantidad, precio_unitario, subtotal`
- **`usuarios`** — `id_usuario, nombre, apellido, correo_electronico, telefono, contrasena, rol, activo, fecha_creacion`

> **Nota sobre `password_hash` vs `contrasena`:** el enunciado del TP usa el nombre genérico `password_hash`. La columna física real en el modelo canónico de Food Store es `usuarios.contrasena VARCHAR(255)`, que almacena un hash bcrypt generado con `pgcrypto`. Esta decisión fue validada por el alumno y registrada en `BITACORA.md` (fila 1): renombrarla a `password_hash` rompería `vistas.sql`, `roles.sql §5` y RF-03. En toda la especificación, `password_hash` y `contrasena` nombran la misma columna física.

### 1.2 Vistas instaladas

| Vista | Tipo | Propósito |
|---|---|---|
| `v_catalogo_productos` | Regular | Productos y categorías activas (`activo = TRUE`) |
| `v_pedido_cliente` | Regular | Cabecera de pedido con datos del cliente |
| `v_detalle_pedido_producto` | Regular | Detalle de pedido con nombre del producto |
| `v_reporte_ventas_cliente` | Regular | Ventas agregadas por cliente (excluye `CANCELADO`) |
| `v_usuario_publico` | Regular | Usuarios activos; **excluye `contrasena` por construcción** |
| `mv_resumen_ventas_categoria_mes` | Materializada | Facturación por categoría y mes; soporta `REFRESH MATERIALIZED VIEW CONCURRENTLY` |

### 1.3 Funciones instaladas

| Función | Firma | Retorno | Propósito |
|---|---|---|---|
| `fn_autenticar` | `(p_email VARCHAR, p_password VARCHAR)` | `BIGINT` | Verifica credenciales contra `usuarios.contrasena` (bcrypt). Devuelve `id_usuario` si autentica o `NULL` si falla. No revela si el usuario existe. Respeta baja lógica (`activo = TRUE`). |
| `fn_resetear_password` | `(p_id_usuario BIGINT, p_nueva_password VARCHAR)` | `BOOLEAN` | Actualiza `usuarios.contrasena` con un nuevo hash bcrypt. Requiere `≥ 8 caracteres`. Solo opera sobre usuarios con `activo = TRUE`. Devuelve `TRUE` si actualizó exactamente 1 fila. |

Ambas funciones se definen con `SECURITY DEFINER`, `SET search_path = pg_catalog, pg_temp`, llamadas calificadas explícitamente (`public.crypt`, `public.gen_salt`) y `REVOKE ALL FROM PUBLIC` desde su creación (`sql/fn_autenticar.sql`, `sql/fn_resetear_password.sql`). El acceso se otorga exclusivamente vía `sql/roles.sql §8`.

### 1.4 Secuencias implícitas (`GENERATED ALWAYS AS IDENTITY`)

`categorias_id_categoria_seq`, `clientes_id_cliente_seq`, `productos_id_producto_seq`, `pedidos_id_pedido_seq`, `detalles_pedido_id_detalle_seq`, `usuarios_id_usuario_seq`.

### 1.5 Superficie de ataque que la política cierra

| Objeto sensible | Riesgo sin control |
|---|---|
| `usuarios.contrasena` | Hash bcrypt expuesto a cualquier rol con `SELECT` genérico sobre la tabla |
| `fn_autenticar` | Invocable por cualquier rol sin restricción; abusable para enumeración de cuentas |
| `fn_resetear_password` | Modifica credenciales; acceso no controlado habilita cambio masivo de contraseñas |
| Secuencias `*_seq` | `USAGE` sin control sobre `usuarios_id_usuario_seq` permite reservar o adelantar IDs de cuentas |
| Tablas base vs. vistas | Acceso directo a tablas expone columnas no publicadas en vistas; las vistas son la interfaz segura para reportes |

---

## 2. Roles Requeridos

### 2.1 Roles de grupo (`NOLOGIN`)

| Rol | Justificación — qué operación habilita y por qué solo esa |
|---|---|
| `rol_app_lectura` | Habilita `SELECT` sobre las cinco tablas de negocio (`categorias`, `clientes`, `productos`, `pedidos`, `detalles_pedido`) y las vistas operativas porque la capa de consulta de la aplicación necesita leer el catálogo y el historial de pedidos, y no necesita escribir ni acceder a datos de `usuarios`. |
| `rol_app_escritura` | Habilita `INSERT` y `UPDATE` sobre las tablas transaccionales (`clientes`, `pedidos`, `detalles_pedido`, `categorias`, `productos`), `USAGE, SELECT` sobre sus secuencias y `EXECUTE` sobre `fn_autenticar`, porque la capa de negocio debe crear pedidos y mantener el catálogo sin poder borrar registros históricos (baja lógica, R7) ni tocar credenciales directamente. |
| `rol_soporte` | Habilita `SELECT` sobre las columnas de identificación y estado de `usuarios` (`id_usuario`, `nombre`, `apellido`, `correo_electronico`, `telefono`, `rol`, `activo`, `fecha_creacion`), `UPDATE (activo)` para gestionar altas y bajas lógicas de cuentas, y `EXECUTE` sobre `fn_resetear_password` para restablecer contraseñas, porque soporte gestiona cuentas sin necesitar jamás leer ni escribir `contrasena`. |
| `rol_reportes` | Habilita `SELECT` sobre las vistas de agregación (`v_reporte_ventas_cliente`, `v_usuario_publico`, `mv_resumen_ventas_categoria_mes`) porque los analistas necesitan reportes de facturación y de usuarios activos sin acceder a tablas base ni credenciales. |
| `rol_auditoria` | Habilita lectura de las estadísticas operativas del motor vía el rol predefinido `pg_monitor`, sin acceso directo a tablas de negocio ni a `pg_authid.rolpassword`. |

### 2.2 Roles de login (`LOGIN`)

| Rol | Hereda de | Justificación |
|---|---|---|
| `app_web` | `rol_app_lectura`, `rol_app_escritura` | Es el usuario de conexión de la aplicación web; hereda lectura para el catálogo y escritura para las operaciones transaccionales sin privilegios DDL ni acceso directo a `usuarios`. Se crea con `PASSWORD NULL` (gestión de secretos fuera de banda) y `CONNECTION LIMIT 20`. |
| `admin_datos` | *(sin herencia de roles de grupo)* | Es el usuario de administración controlada; recibe permisos directos de DDL sobre el esquema `public` y acceso completo a todas las tablas —incluyendo `usuarios.contrasena`— para operaciones de mantenimiento, pero sin atributo `SUPERUSER`. Se crea con `PASSWORD NULL` y `CONNECTION LIMIT 5`. |

---

## 3. Requisitos Funcionales

### RF-01 — Permisos de tabla (nivel de tabla)

| Rol | `categorias` | `clientes` | `productos` | `pedidos` | `detalles_pedido` | `usuarios` |
|---|---|---|---|---|---|---|
| `rol_app_lectura` | SELECT | SELECT | SELECT | SELECT | SELECT | — |
| `rol_app_escritura` | INSERT, UPDATE | INSERT, UPDATE | INSERT, UPDATE | INSERT, UPDATE | INSERT, UPDATE | — |
| `rol_soporte` | — | — | — | — | — | *ver RF-03* |
| `rol_reportes` | — | — | — | — | — | — |
| `rol_auditoria` | — | — | — | — | — | — |
| `admin_datos` | ALL | ALL | ALL | ALL | ALL | ALL |

`rol_reportes` y `rol_auditoria` no reciben permisos directos sobre tablas; operan exclusivamente a través de vistas (RF-02) o monitoreo del sistema (RF-06).

### RF-02 — Permisos de vista

| Rol | `v_catalogo_productos` | `v_pedido_cliente` | `v_detalle_pedido_producto` | `v_reporte_ventas_cliente` | `v_usuario_publico` | `mv_resumen_ventas_categoria_mes` |
|---|---|---|---|---|---|---|
| `rol_app_lectura` | SELECT | SELECT | SELECT | — | — | — |
| `rol_reportes` | — | — | — | SELECT | SELECT | SELECT |
| `rol_auditoria` | — | — | — | — | — | — |
| `admin_datos` | ALL | ALL | ALL | ALL | ALL | ALL |

`v_usuario_publico` excluye `contrasena` por construcción; otorgar `SELECT` sobre ella a `rol_reportes` no expone el hash.

### RF-03 — Permisos a nivel de columna sobre `usuarios` (mínimo privilegio estricto)

`rol_soporte` no recibe `GRANT SELECT ON TABLE usuarios` ni `GRANT UPDATE ON TABLE usuarios`. Recibe exclusivamente permisos de columna:

```sql
GRANT SELECT (id_usuario, nombre, apellido, correo_electronico, telefono, rol, activo, fecha_creacion)
    ON TABLE public.usuarios TO rol_soporte;

GRANT UPDATE (activo)
    ON TABLE public.usuarios TO rol_soporte;
```

La columna `contrasena` queda **excluida de todos los permisos de `rol_soporte`**. Un `SELECT contrasena FROM usuarios` bajo ese rol se deniega por privilegios insuficientes (`SQLSTATE 42501`).

### RF-04 — Permisos de secuencia

| Secuencia | `rol_app_escritura` | `admin_datos` | Resto |
|---|---|---|---|
| `clientes_id_cliente_seq` | USAGE, SELECT | ALL | — |
| `pedidos_id_pedido_seq` | USAGE, SELECT | ALL | — |
| `detalles_pedido_id_detalle_seq` | USAGE, SELECT | ALL | — |
| `categorias_id_categoria_seq` | USAGE, SELECT | ALL | — |
| `productos_id_producto_seq` | USAGE, SELECT | ALL | — |
| `usuarios_id_usuario_seq` | — | ALL | — |

`usuarios_id_usuario_seq` queda exclusivamente bajo `admin_datos` porque ningún rol operativo puede registrar usuarios directamente.

### RF-05 — Permisos de ejecución de funciones

| Función | Firma real | `rol_app_escritura` | `rol_soporte` | `admin_datos` | Resto |
|---|---|---|---|---|---|
| `fn_autenticar` | `(VARCHAR, VARCHAR) → BIGINT` | EXECUTE | — | EXECUTE | — |
| `fn_resetear_password` | `(BIGINT, VARCHAR) → BOOLEAN` | — | EXECUTE | EXECUTE | — |

### RF-06 — Permisos de monitoreo para `rol_auditoria`

```sql
GRANT pg_monitor TO rol_auditoria;
```

`pg_monitor` permite observar estadísticas e información operativa mediante `pg_stat_activity`, `pg_locks`, `pg_stat_user_tables` y `pg_stat_user_indexes`, sin conceder `SELECT` sobre tablas de negocio ni sobre `pg_authid`.

### RF-07 — Política de `ALTER DEFAULT PRIVILEGES`

Las tablas y secuencias creadas en el futuro en el esquema `public` heredan la misma política sin intervención manual:

```sql
ALTER DEFAULT PRIVILEGES IN SCHEMA public
    GRANT SELECT ON TABLES TO rol_app_lectura;

ALTER DEFAULT PRIVILEGES IN SCHEMA public
    GRANT INSERT, UPDATE ON TABLES TO rol_app_escritura;

ALTER DEFAULT PRIVILEGES IN SCHEMA public
    GRANT USAGE, SELECT ON SEQUENCES TO rol_app_escritura;
```

`rol_soporte`, `rol_reportes` y `rol_auditoria` no reciben privilegios heredados sobre tablas nuevas. Si en el futuro se añade una tabla con datos sensibles, su `CREATE` y el `REVOKE` correspondiente deben ejecutarse en la misma transacción antes del `COMMIT` (contrato D11).

---

## 4. Restricciones Explícitas (lo que cada rol NO puede hacer)

| Rol | Restricción crítica |
|---|---|
| `rol_app_lectura` | Sin `INSERT`, `UPDATE` ni `DELETE` sobre ningún objeto |
| `rol_app_escritura` | Sin `DELETE` ni `TRUNCATE` sobre ninguna tabla (baja lógica con `activo = FALSE`, regla R7) |
| `rol_soporte` | Sin leer ni escribir `usuarios.contrasena` bajo ninguna circunstancia; sin acceso a tablas de negocio |
| `rol_reportes` | Sin acceso directo a tablas base; sin acceso a `usuarios.contrasena` |
| `rol_auditoria` | Sin `SELECT` sobre tablas de negocio ni `pg_authid` |
| `app_web` | Sin privilegios DDL; no puede crear, alterar ni borrar objetos del esquema |
| `admin_datos` | Sin atributo `SUPERUSER`; sus privilegios se limitan al esquema `public` de `foodstore_dev` |
