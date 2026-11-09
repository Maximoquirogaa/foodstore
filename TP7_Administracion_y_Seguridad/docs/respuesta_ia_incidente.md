# TP7 Parte C.4 — Reconstrucción Analítica a Partir del Log Anonimizado

- **Entrada entregada:** exclusivamente `docs/log_simulacro_anonimizado.utf8.txt` (207 líneas, sesión ejecutada el `2026-11-09`), en análisis limpio sin explicar el escenario previo ni entregar los scripts SQL.
- **Revisión y contraste humano:** documentados en [docs/informe_incidente.md](informe_incidente.md).

---

## C.4 — Reconstrucción a partir del log anonimizado (única evidencia)

Análisis basado estrictamente en las 207 líneas de [log_simulacro_anonimizado.utf8.txt](log_simulacro_anonimizado.utf8.txt).

### 1. Hechos observados (con líneas exactas)

- **Una sola sesión, un solo origen, 0,788 s:** todo ocurre bajo PID `52832`, usuario `postgres`, base `foodstore_dev`, aplicación `psql`, origen `198.51.100.7(40001)`. Conexión recibida, autenticada (`scram-sha-256`, `pg_hba.conf:115`) y autorizada (lín. 1–3, `2026-11-09 12:11:38.855` a `38.872 -03`), `BEGIN;` (lín. 4), `SET LOCAL search_path TO public, pg_temp;` (lín. 5), `ROLLBACK;` (lín. 206) y desconexión con duración `0:00:00.788` (lín. 207, `12:11:39.626 -03`).
- **Chequeo de prerrequisitos previo:** bloque `DO` (lín. 6–21) que verifica la existencia de `public.fn_autenticar(varchar,varchar)`, tabla `public.usuarios` y roles `app_web` y `admin_datos`. Sin errores; continúa hacia la marca `SIMULACRO_INCIDENTE_INICIO_C` (lín. 22).
- **Tres intentos fallidos consecutivos:** bloque `DO` (lín. 23–42) con tres llamadas `SELECT public.fn_autenticar('usuario_anon_01@anon.invalid', 'clave_erronea_anon_01'..'03')` validando retorno `NULL` y emitiendo `RAISE LOG` para intentos 1, 2 y 3 (lín. 43, 65 y 87).
- **Confirmación de login para usuario `ID=1`:** bloque `DO` (lín. 109–125) que consulta `id_usuario, correo_electronico` en `public.usuarios WHERE activo = TRUE ORDER BY id_usuario LIMIT 1` y registra `LOG: SIMULACRO C: Autenticación exitosa confirmada para usuario ID=1 (usuario_anon_01@anon.invalid)` (lín. 126).
- **Lectura masiva de usuarios activos:** bloque `DO` (lín. 145–156) con `SELECT count(*) INTO v_cant FROM public.usuarios WHERE activo = TRUE;` y registro `LOG: SIMULACRO C: Lectura masiva realizada sobre 3 registros de usuarios` (lín. 157).
- **Intento de escalamiento denegado (`SQLSTATE 42501`):** bloque `DO` (lín. 171–186) que ejecuta `SET LOCAL ROLE app_web; GRANT admin_datos TO app_web;` capturando `WHEN insufficient_privilege` (`RESET ROLE`) y emitiendo `LOG: SIMULACRO C: Escalamiento RECHAZADO satisfactoriamente (SQLSTATE 42501: privilegios insuficientes)` (lín. 187). Cierre con `SIMULACRO_INCIDENTE_FIN_C` (lín. 205), `ROLLBACK;` (lín. 206) y desconexión (lín. 207).
- **Sin fallos de autenticación del motor:** no aparecen líneas `FATAL` ni rechazos `pg_hba.conf`; la sesión se autentica correctamente como `postgres`.

### 2. Hipótesis de lo ocurrido (secuencia)

Un cliente `psql` ejecutó una secuencia controlada de prueba en una sola transacción revertida con `ROLLBACK`: validó objetos y roles previos, ejecutó tres autenticaciones inválidas seguidas contra `fn_autenticar`, verificó una cuenta activa (`ID=1`), contó usuarios activos (`3`) e intentó escalar privilegios con `SET LOCAL ROLE app_web; GRANT admin_datos TO app_web`, siendo bloqueado por PostgreSQL (`SQLSTATE 42501`).

### 3. Hipótesis de contención (propuesta, no ejecutada)

Si correspondiera a un incidente real: (a) verificar si la IP de origen corresponde a un cliente autorizado o proxy compartido antes de aplicar bloqueo perimetral; (b) terminar sesiones sospechosas (`pg_terminate_backend`) y rotar credenciales/tokens de la cuenta `ID=1`; (c) confirmar ausencia de membresías indebidas en `pg_auth_members`; (d) preservar el log íntegro protegido por permisos de OS y motor.

### 4. Lo que el registro NO permite determinar (lectura crítica)

- **Atribución de red real:** `198.51.100.7` es una IP documental RFC 5737 anonimizada; el fragmento por sí solo no revela el host físico real.
- **Lógica interna de `fn_autenticar`:** el log solo muestra la llamada a la función y la captura de retorno `NULL` en PL/pgSQL, no el código fuente ni el hash almacenado.
- **Autenticidad automática vs. instrumentación:** los mensajes `SIMULACRO C: ...` son emitidos por sentencias `RAISE LOG` dentro del script PL/pgSQL (visible en `CONTEXTO` y `SENTENCIA`), no por triggers internos del catálogo.
- **Datos personales concretos:** excepto el identificador `ID=1` y el correo ya anonimizado `usuario_anon_01@anon.invalid`, la consulta de lectura ejecuta un `COUNT(*)` (`3 registros`) y no expone nombres, contraseñas ni filas individuales.
