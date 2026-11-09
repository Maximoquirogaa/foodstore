# TP7 Parte D — Evidencia del Ensayo Adicional de Cobertura (`usuario_anon_cobertura.sql`)

**Proyecto:** Food Store — Base de Datos II (UTN FRM)  
**Alumno:** Máximo Juan Cruz Quiroga (`maximoj.quiroga@alumnos.frm.utn.edu.ar`)  
**Docente:** Sergio Neira  
**Base:** `foodstore_dev` (PostgreSQL 17.11)  
**Fecha de ejecución:** 2026-11-09 12:14:10 -03  

---

## 1. Alcance y Respaldo Previo

- Ejecución en una única pasada transaccional (`BEGIN ISOLATION LEVEL REPEATABLE READ ... ROLLBACK`) del script [sql/usuario_anon_cobertura.sql](../../sql/usuario_anon_cobertura.sql).
- Respaldo previo generado fuera del repositorio: `respaldo_foodstore_dev_20261109_121409_antes_tp7_d.dump` (formato custom, `45.004` bytes, SHA-256 `2cf91163ac986fa4fc41e867ed0581ce12504fae1a05a8e150129a9d4e147bd8`, `pg_dump` exit `0`, `pg_restore --list` exit `0`, `144` líneas de cabecera verificadas).

## 2. Salida de Ejecución (`psql`)

Salida completa registrada en [salida_psql_usuario_anon_cobertura_20261109_121410.txt](salida_psql_usuario_anon_cobertura_20261109_121410.txt):

```text
BEGIN
SET
SET
DO
LOCK TABLE
CREATE TABLE
INSERT 0 6
INSERT 0 6
CREATE TABLE AS
INSERT 0 9
   rol    |  mes_alta  | cantidad 
----------+------------+----------
 ADMIN    | 2026-01-01 |        2
 ADMIN    | 2026-11-01 |        1
 VENDEDOR | 2026-02-01 |        2
 VENDEDOR | 2026-11-01 |        1
 USUARIO  | 2026-03-01 |        2
 USUARIO  | 2026-11-01 |        1
(6 filas)

   rol    |  mes_alta  | cantidad 
----------+------------+----------
 ADMIN    | 2026-01-01 |        2
 ADMIN    | 2026-11-01 |        1
 VENDEDOR | 2026-02-01 |        2
 VENDEDOR | 2026-11-01 |        1
 USUARIO  | 2026-03-01 |        2
 USUARIO  | 2026-11-01 |        1
(6 filas)

psql:TP7_Administracion_y_Seguridad/sql/usuario_anon_cobertura.sql:98: NOTICE:  Comparación con fixtures validada con éxito: diferencias 0/0, totales 9/9
DO
ROLLBACK

PSQL_EXIT=0
```

## 3. Controles Posteriores

| Control | Resultado |
|---|---|
| `post_read_only` | `true` |
| `usuario_anon_absent` | `true` |
| Conteos inalterados | `true` |
| Secuencias inalteradas | `true` |
| `app_web_is_admin` | `false` |

- **Conteos antes y después:** `{"categorias": 3, "clientes": 3, "pedidos": 5, "productos": 5, "detalles_pedido": 7, "usuarios": 3}`.
- **Secuencias antes y después (`last_value` / `is_called`):** intactas (`categorias`: 4, `clientes`: 3, `pedidos`: 5, `productos`: 5, `usuarios`: 3).
