# TP7 Parte D — Verificación de Equivalencia (`usuarios_anon` vs `usuarios`)

**Proyecto:** Food Store — Base de Datos II (UTN FRM)  
**Alumno:** Máximo Juan Cruz Quiroga (`maximoj.quiroga@alumnos.frm.utn.edu.ar`)  
**Docente:** Sergio Neira  
**Motor:** PostgreSQL 17.11 · **Base:** `foodstore_dev` · **Fecha:** 2026-11-09  
**Scripts ejecutados:** [sql/usuario_anon.sql](../sql/usuario_anon.sql) y [sql/usuario_anon_cobertura.sql](../sql/usuario_anon_cobertura.sql)  

> **Estado:** dos ensayos ejecutados sobre `foodstore_dev` el `2026-11-09` (ambos con `PSQL_EXIT=0` y `ROLLBACK` final):
> - **Muestra base** (§§1–4): 3 usuarios reales de desarrollo. Salida íntegra en [salida_psql_usuario_anon_20261109_121409.txt](evidencias/salida_psql_usuario_anon_20261109_121409.txt).
> - **Ensayo ampliado de cobertura** (§6): 9 usuarios (3 base + 6 fixtures sintéticos), abarcando los tres roles (`ADMIN`, `VENDEDOR`, `USUARIO`), cuatro meses de alta y cuentas activas e inactivas (`activo = FALSE`). Salida en [usuario_anon_cobertura_20261109_121410.md](evidencias/usuario_anon_cobertura_20261109_121410.md).

---

## 1. Transformación y Reglas de Anonimización (Punto D.1)

El script [sql/usuario_anon.sql](../sql/usuario_anon.sql) crea `public.usuarios_anon` dentro de una transacción aislada (`REPEATABLE READ`) que finaliza en `ROLLBACK`:

- **Columnas de `usuarios_anon`:** `id_anon` (clave subrogada), `nombre_anon`, `mail_anon`, `rol`, `activo`, `mes_alta DATE` (primer día del mes de alta).
- **Generación sintética determinista:** `'UsuarioAnon-' || id_usuario` y `'anon_' || id_usuario || '@foodstore-anon.invalid'`.
- **Atributos conservados para analítica:** únicamente `rol`, `activo` y `mes_alta = date_trunc('month', fecha_creacion)::date`.
- **Atributos personales y sensibles descartados:** `telefono`, `contrasena` (hash bcrypt omitido por completo, sin columna en la tabla anonimizada), `nombre` y `apellido` reales, `correo_electronico` real y la marca temporal exacta de `fecha_creacion`.

---

## 2. Consultas Analíticas Equivalentes (Punto D.2)

```sql
-- §3a: Consulta analítica sobre la tabla anonimizada (public.usuarios_anon)
SELECT
    rol,
    mes_alta,
    COUNT(*) AS cantidad
FROM public.usuarios_anon
GROUP BY rol, mes_alta
ORDER BY rol, mes_alta;

-- §3b: Consulta analítica equivalente sobre la tabla real (public.usuarios)
SELECT
    rol,
    (date_trunc('month', fecha_creacion)::date) AS mes_alta,
    COUNT(*) AS cantidad
FROM public.usuarios
GROUP BY rol, (date_trunc('month', fecha_creacion)::date)
ORDER BY rol, mes_alta;
```

---

## 3. Comparación Matemática de Resultados (Punto D.3)

### 3.1 Resultado sobre la muestra base (3 usuarios)

```text
   rol    |  mes_alta  | total_anonimizado | total_real 
----------+------------+-------------------+------------
 ADMIN    | 2026-11-01 |                 1 |          1
 VENDEDOR | 2026-11-01 |                 1 |          1
 USUARIO  | 2026-11-01 |                 1 |          1
(3 filas)
```

`NOTICE: EQUIVALENCIA MATEMÁTICA DEMOSTRADA: 3 filas totales analizadas sin discrepancias.` (`EXCEPT ALL` en ambos sentidos = 0 filas; `ROLLBACK`, `PSQL_EXIT=0`).

### 3.2 Resultado sobre el ensayo ampliado de cobertura (9 usuarios: 3 base + 6 fixtures)

El script [sql/usuario_anon_cobertura.sql](../sql/usuario_anon_cobertura.sql) inserta temporalmente 6 fixtures sintéticos (`IDs` `-770701` a `-770706` con `OVERRIDING SYSTEM VALUE` para no alterar la secuencia `usuarios_id_usuario_seq`) que cubren `ADMIN`, `VENDEDOR` y `USUARIO` en enero, febrero y marzo de 2026, incluyendo cuentas dadas de baja lógica (`activo = FALSE`):

```text
   rol    |  mes_alta  | cantidad 
----------+------------+----------
 ADMIN    | 2026-01-01 |        2
 ADMIN    | 2026-11-01 |        1
 VENDEDOR | 2026-02-01 |        2
 VENDEDOR | 2026-11-01 |        1
 USUARIO  | 2026-03-01 |        2
 USUARIO  | 2026-11-01 |        1
(6 filas)
```

`NOTICE: Comparación con fixtures validada con éxito: diferencias 0/0, totales 9/9` (`EXCEPT ALL` bidireccional = 0 diferencias; `ROLLBACK`, `PSQL_EXIT=0`).

---

## 4. Criterios de Protección de Datos ante Asistentes de IA (Punto D.4)

1. **Datos personales identificables (PII):** los atributos de identificación y contacto de `public.usuarios` (`nombre`, `apellido`, `correo_electronico`, `telefono`, `fecha_creacion` exacta) y de `public.clientes` (`nombre`, `email`, `telefono`, `direccion`) **nunca** deben enviarse a un asistente de IA externo sin pasar previamente por un proceso de anonimización o reemplazo sintético.
2. **Secretos y credenciales de autenticación:** las contraseñas y sus hashes criptográficos (`usuarios.contrasena`, tokens de sesión, archivos `.pgpass` o variables de entorno) **no se anonimizan sino que se excluyen por completo** de cualquier exportación, consulta o fragmento de log antes de compartirlo, dado que su exposición habilita ataques de fuerza bruta offline y escalamiento de privilegios.
3. **Preservación de utilidad analítica:** cuando se requiere asistencia de IA para optimizar o auditar consultas estadísticas, basta con conservar las dimensiones de agrupación no identificables (como `rol`, `activo` y el mes truncado `mes_alta`) o trabajar sobre esquemas con datos sintéticos verificados mediante `EXCEPT ALL`.
