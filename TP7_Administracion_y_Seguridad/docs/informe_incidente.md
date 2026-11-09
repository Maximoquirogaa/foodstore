# TP7 Parte C — Informe del Incidente (Secuencia Ejecutada, Contraste con IA y Decisión de Contención)

**Proyecto:** Food Store — Base de Datos II (UTN FRM)  
**Alumno:** Máximo Juan Cruz Quiroga (`maximoj.quiroga@alumnos.frm.utn.edu.ar`)  
**Docente:** Sergio Neira  
**Motor:** PostgreSQL 17.11 · **Base:** `foodstore_dev` · **Fecha:** 2026-11-09  
**Evidencias vinculadas:**
- Secuencia SQL: [sql/simulacro_incidente.sql](../sql/simulacro_incidente.sql)
- Registro de ejecución: [docs/evidencias/ejecucion_20261109_1211.md](evidencias/ejecucion_20261109_1211.md)
- Fragmento de log anonimizado (207 líneas, PID 52832): [docs/log_simulacro_anonimizado.utf8.txt](log_simulacro_anonimizado.utf8.txt)
- Reconstrucción analítica del incidente sobre el log anonimizado: [docs/respuesta_ia_incidente.md](respuesta_ia_incidente.md)

---

## 1. Secuencia Ejecutada y Evidencias (Puntos C.1 a C.3)

1. **Inventario de base:** 6 tablas del modelo canónico (`categorias`: 3, `clientes`: 3, `productos`: 5, `pedidos`: 5, `detalles_pedido`: 7, `usuarios`: 3 activos) y los 7 roles del modelo TP7 instalados.
2. **Respaldo previo:** generación de backup en formato custom (`pg_dump -F c`, `45.004` bytes) y verificación de cabecera con `pg_restore --list` (`144` líneas, `exit=0`).
3. **Activación temporal de auditoría:** aplicación de `sql/activar_auditoria_local.sql` (`log_connections = on`, `log_disconnections = on`, `log_statement = all`, `log_line_prefix = '%m [%p] %u@%d %r %a '`).
4. **Ejecución del simulacro (`sql/simulacro_incidente.sql`):**
   - **3 intentos fallidos de autenticación** contra `public.fn_autenticar` sobre la cuenta `ID=1` (devuelven `NULL`).
   - **1 autenticación exitosa confirmada** para usuario `id_usuario = 1`.
   - **Lectura masiva de usuarios activos:** `SELECT count(*) INTO v_cant FROM public.usuarios WHERE activo = TRUE` (`3 registros de usuarios`).
   - **Intento de escalamiento de privilegios** bajo `SET LOCAL ROLE app_web`: ejecución de `GRANT admin_datos TO app_web`, bloqueado por el motor con excepción **`SQLSTATE 42501` (`insufficient_privilege`)**.
   - **Reversión (`ROLLBACK`)** al cierre del script para no alterar datos.
5. **Anonimización del log (Punto C.3):** extracción de las 207 líneas de la sesión PID `52832` (`2026-11-09 12:11:38.855` a `12:11:39.626 -03`) y reemplazo determinista de la IP origen (`127.0.0.1(65390)` → `198.51.100.7(40001)`), el correo (`admin@foodstore.utn.edu.ar` → `usuario_anon_01@anon.invalid`) y las tres contraseñas de prueba (`clave_erronea_anon_01`..`03`), verificando 0 credenciales reales expuestas.
6. **Restauración de parámetros de auditoría:** retorno a los valores por defecto mediante `ALTER SYSTEM RESET` + `SELECT pg_reload_conf()`, y comprobación de que `app_web` no adquirió membresía en `admin_datos` (`app_web_is_admin = false` / 0 filas).

---

## 2. Contraste Crítico de la Reconstrucción de la IA (Punto C.5)

Para el Punto C.4 se realizó un análisis controlado entregando **exclusivamente** el fragmento [log_simulacro_anonimizado.utf8.txt](log_simulacro_anonimizado.utf8.txt) (207 líneas, PID `52832`), sin exponer IPs reales, correos reales ni el estado previo de otras sesiones. El detalle consta en [respuesta_ia_incidente.md](respuesta_ia_incidente.md).

### 2.1 Qué se reconstruye con certeza desde el log
- **Secuencia cronológica exacta:** los 3 intentos fallidos (`resultado=NULL` con `'clave_erronea_anon_01'`, `'02'`, `'03'`), la verificación de login exitoso para `ID=1`, la lectura de conteo sobre `public.usuarios` (`3 registros de usuarios`) y el intento de escalamiento `GRANT admin_datos TO app_web` bajo `SET LOCAL ROLE app_web` rechazado con `SQLSTATE 42501`.
- **Identificación de la sesión:** conexión autenticada con `postgres` vía `scram-sha-256` (`pg_hba.conf:115`), cliente `psql`, uso puntual de `SET LOCAL ROLE app_web` dentro de un bloque `DO`, y cierre con `ROLLBACK` y duración total de `0:00:00.788`.
- **Reconocimiento de límites del log:** los mensajes `SIMULACRO C: ...` provienen de `RAISE LOG` dentro de bloques `DO` PL/pgSQL registrados junto a `CONTEXTO` y `SENTENCIA`, y no de una auditoría automática de filas devueltas por el motor.

### 2.2 Qué no puede inferirse sin contexto externo
- **Origen físico real:** el log entregado contiene la IP documental `198.51.100.7(40001)` (RFC 5737 `TEST-NET-2`); no permite conocer si el cliente real se conectó por loopback local (`127.0.0.1`) o desde otro host de la red.
- **Lógica interna de `fn_autenticar`:** en el log solo figura la invocación `SELECT public.fn_autenticar(...)`; no aparece el cuerpo DDL (`CREATE FUNCTION`) ni el algoritmo hash utilizado internamente.

### 2.3 Evaluación de las medidas de contención
- Bloquear automáticamente una IP perimetral sin verificar origen (`NAT`, proxy inverso o servidor de aplicación `app_web`) puede causar una **denegación de servicio (DoS)** sobre tráfico legítimo. Por eso la decisión humana prioriza el aislamiento a nivel sesión/cuenta de base de datos antes de cualquier regla perimetral.

---

## 3. Decisión Humana de Contención (Punto C.6)

> **Decisión adoptada por el alumno:**  
> 1. **En este entorno de laboratorio:** no se bloquean direcciones IP ni se rotan credenciales adicionales, dado que se comprobó que fue una ejecución controlada y transaccional (`ROLLBACK`), donde el intento de escalamiento fue neutralizado por el motor (`SQLSTATE 42501`) y la consulta posterior sobre `pg_auth_members` confirmó 0 membresías indebidas (`app_web → admin_datos`).  
> 2. **Ante un incidente equivalente en producción:**  
>    - **Primero:** aislar la sesión sospechosa (`pg_terminate_backend`) e identificar si la dirección IP corresponde al servidor de aplicación web legítimo o a un acceso directo no autorizado al puerto 5432.  
>    - **Segundo:** revocar las sesiones activas de la cuenta de aplicación comprometida y forzar el restablecimiento inmediato de su contraseña mediante `public.fn_resetear_password` (o inhabilitar temporalmente la cuenta con `UPDATE public.usuarios SET activo = FALSE`).  
>    - **Tercero:** auditar la ventana temporal completa en los logs del servidor y verificar que las reglas de `pg_hba.conf` y los privilegios de roles permanezcan intactos. El bloqueo perimetral de IP solo se aplicará tras confirmar que no afectará servicios compartidos ni usuarios tras NAT.
