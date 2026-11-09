# TP7 — Diseño Técnico: Modelo de Roles PostgreSQL

**Proyecto:** Food Store — Base de Datos II (UTN FRM)  
**Alumno:** Máximo Juan Cruz Quiroga (`maximoj.quiroga@alumnos.frm.utn.edu.ar`)  
**Docente:** Sergio Neira  
**Motor:** PostgreSQL 17  
**Base de destino:** `foodstore_dev`  
**Documento complementario:** [requirements.md](requirements.md)  
**Script implementado:** [sql/roles.sql](../../sql/roles.sql)  

---

## 1. Modelo de Herencia de Roles

Las flechas indican membresías: rol concedido → rol miembro.

```text
rol_app_lectura   ──────┐
                        ├──→ app_web (LOGIN)
rol_app_escritura ──────┘

pg_monitor ────────────────→ rol_auditoria (NOLOGIN)
```

No existe membresía entre `rol_app_lectura` y `rol_app_escritura`. `app_web` recibe ambos roles directamente y hereda la unión de sus permisos. `rol_soporte` y `rol_reportes` son grupos `NOLOGIN`. `admin_datos` es `LOGIN` con permisos directos, sin membresías en los grupos operativos.

---

## 2. Secuencia de Implementación del Script `roles.sql`

El script divide su contenido en 12 secciones ejecutables e idempotentes:

| § | Contenido |
|---|---|
| 0 | Comprobación e información de la base de datos activa (`current_database()`) |
| 1 | `REVOKE` de `PUBLIC` sobre esquema, tablas, secuencias y funciones |
| 2 | Creación idempotente de todos los roles (grupos `NOLOGIN` y cuentas `LOGIN`) con `DO/EXCEPTION` |
| 3 | `GRANT USAGE ON SCHEMA public` a todos los roles del modelo; `GRANT CREATE` solo a `admin_datos` |
| 4 | `GRANT` de tabla a nivel de tabla (RF-01: `categorias`, `clientes`, `productos`, `pedidos`, `detalles_pedido`, `usuarios`) |
| 5 | `GRANT` de columna sobre `usuarios` para `rol_soporte` (RF-03) + `REVOKE ALL` previo |
| 6 | `GRANT` de secuencias de negocio (RF-04, excluyendo `usuarios_id_usuario_seq` para escritura operativa) |
| 7 | `GRANT` de vistas operativas, analíticas y vista materializada (RF-02) |
| 8 | `GRANT EXECUTE` directo de funciones `fn_autenticar` y `fn_resetear_password` (RF-05) |
| 9 | `GRANT pg_monitor TO rol_auditoria` (RF-06) |
| 10 | `ALTER DEFAULT PRIVILEGES` para el ejecutor y `FOR ROLE admin_datos` (RF-07) |
| 11 | `GRANT rol_app_lectura, rol_app_escritura TO app_web` (membresías) |
| 12 | Consultas de verificación recomendadas sobre `information_schema` |

---

## 3. Matrices de Privilegios Completas

### 3.1 Tablas de negocio

| Rol | `categorias` | `clientes` | `productos` | `pedidos` | `detalles_pedido` |
|---|---|---|---|---|---|
| `rol_app_lectura` | S | S | S | S | S |
| `rol_app_escritura` | IU | IU | IU | IU | IU |
| `rol_soporte` | — | — | — | — | — |
| `rol_reportes` | — | — | — | — | — |
| `rol_auditoria` | — | — | — | — | — |
| `admin_datos` | ALL | ALL | ALL | ALL | ALL |
| `app_web` *(efectivo)* | S·IU | S·IU | S·IU | S·IU | S·IU |

*(S = SELECT · I = INSERT · U = UPDATE · D = DELETE nunca otorgado a roles operativos)*

### 3.2 Tabla `usuarios` — nivel de columna

| Rol | `id_usuario` | `nombre` | `apellido` | `correo_electronico` | `telefono` | `rol` | `activo` | `fecha_creacion` | `contrasena` |
|---|---|---|---|---|---|---|---|---|---|
| `rol_soporte` | S | S | S | S | S | S | S · U | S | **✗ denegado** |
| `rol_reportes` | — | — | — | — | — | — | — | — | — |
| `rol_auditoria` | — | — | — | — | — | — | — | — | — |
| `admin_datos` | ALL | ALL | ALL | ALL | ALL | ALL | ALL | ALL | ALL |

`rol_reportes` accede a los datos públicos de cuentas únicamente vía `v_usuario_publico`, que excluye `contrasena` por definición.

### 3.3 Vistas

| Rol | `v_catalogo_productos` | `v_pedido_cliente` | `v_detalle_pedido_producto` | `v_reporte_ventas_cliente` | `v_usuario_publico` | `mv_resumen_ventas_categoria_mes` |
|---|---|---|---|---|---|---|
| `rol_app_lectura` | S | S | S | — | — | — |
| `rol_reportes` | — | — | — | S | S | S |
| `rol_auditoria` | — | — | — | — | — | — |
| `admin_datos` | ALL | ALL | ALL | ALL | ALL | ALL |

### 3.4 Secuencias

| Rol | `categorias_id_categoria_seq` | `clientes_id_cliente_seq` | `productos_id_producto_seq` | `pedidos_id_pedido_seq` | `usuarios_id_usuario_seq` |
|---|---|---|---|---|---|
| `rol_app_escritura` | USAGE, SELECT | USAGE, SELECT | USAGE, SELECT | USAGE, SELECT | — |
| `admin_datos` | ALL | ALL | ALL | ALL | ALL |
| Resto | — | — | — | — | — |

### 3.5 Funciones

| Rol | `fn_autenticar(VARCHAR,VARCHAR)` | `fn_resetear_password(BIGINT,VARCHAR)` |
|---|---|---|
| `rol_app_escritura` | EXECUTE | — |
| `rol_soporte` | — | EXECUTE |
| `admin_datos` | EXECUTE | EXECUTE |
| Resto | — | — |

---

## 4. Decisiones de Diseño (D1–D11)

- **D1 — Sin `DELETE` para `rol_app_escritura`:** La regla de negocio R7 establece baja lógica (`UPDATE activo = FALSE`). Omitir `DELETE` impide que cualquier defecto de aplicación o inyección destruya registros históricos.
- **D2 — Separación lectura / escritura en dos roles de grupo:** Permite conectar en el futuro cuentas de solo lectura (APIs de consulta, réplicas) otorgando únicamente `rol_app_lectura`.
- **D3 — `rol_auditoria` con `pg_monitor`:** Otorga visibilidad sobre vistas de actividad y rendimiento sin exponer tablas de negocio ni hashes de `pg_authid`.
- **D4 — Permisos de columna para `rol_soporte`:** Ejercita el control granular nativo de PostgreSQL (`GRANT SELECT (...) ON TABLE public.usuarios`) garantizando que `SELECT contrasena FROM usuarios` falle con `SQLSTATE 42501`.
- **D5 — Revocación explícita de `PUBLIC` en funciones:** Tanto `fn_autenticar` como `fn_resetear_password` revocan `ALL FROM PUBLIC` inmediatamente tras su creación.
- **D6 — `ALTER DEFAULT PRIVILEGES` dual:** Se registra tanto para el rol ejecutor como `FOR ROLE admin_datos`, asegurando que futuras migraciones DDL hereden exactamente RF-07.
- **D7 — `CONNECTION LIMIT` como defensa en profundidad:** Limita `app_web` a 20 conexiones y `admin_datos` a 5 para evitar agotamiento de `max_connections`.
- **D8 — Sinonimia documental `password_hash` == `contrasena`:** Mantiene intacto el esquema físico de `public.usuarios` sin romper vistas ni funciones existentes.
- **D9 — Cuentas `LOGIN` con `PASSWORD NULL`:** Evita almacenar contraseñas en texto plano dentro del repositorio Git; la asignación de credenciales se realiza fuera de banda.
- **D10 — Funciones `SECURITY DEFINER` con `search_path` cerrado:** Fija `SET search_path = pg_catalog, pg_temp` y califica `public.crypt` y `public.gen_salt` para impedir ataques de secuestro de objetos (*search_path hijacking*).
- **D11 — Contrato transaccional para tablas sensibles futuras:** Cualquier tabla nueva con información sensible debe crearse y despojarse de los privilegios por defecto (`REVOKE ALL ... FROM rol_app_lectura, rol_app_escritura`) dentro de la misma transacción antes del `COMMIT`.
