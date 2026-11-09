# TP7 Parte B — Informe de Auditoría (`foodstore_dev`, PostgreSQL 17)

**Proyecto:** Food Store — Base de Datos II (UTN FRM)  
**Alumno:** Máximo Juan Cruz Quiroga (`maximoj.quiroga@alumnos.frm.utn.edu.ar`)  
**Docente:** Sergio Neira  
**Evidencia:** [log_auditoria_prueba.utf8.txt](log_auditoria_prueba.utf8.txt)  
**Secuencia ejecutada:** [sql/auditoria_test.sql](../sql/auditoria_test.sql)  

---

## 1. Configuración Aplicada (Punto B.1)

La auditoría nativa se activó en caliente mediante `ALTER SYSTEM SET` + `SELECT pg_reload_conf()` (parámetros de contexto `SIGHUP`, sin reinicio del servicio; `logging_collector` ya se encontraba en `on`, por lo que `pg_current_logfile()` devolvió la ruta activa del archivo de registro).

| Parámetro | Valor previo | Valor nuevo | Qué aporta |
|---|---|---|---|
| `log_connections` | `off` | `on` | Registra cada intento de conexión (`conexión recibida`, autenticada y autorizada) y los intentos fallidos con `FATAL` + regla `pg_hba.conf` aplicada |
| `log_disconnections` | `off` | `on` | Registra el cierre de sesión con duración, usuario, base y dirección de origen (cierra la traza quién/cuándo) |
| `log_statement` | `none` | `all` | Registra el texto de cada sentencia SQL (DDL, DML y `SELECT`); ver nota técnica `mod` vs `all` abajo |
| `log_line_prefix` | `%t ` (solo hora) | `%m [%p] %u@%d %r %a ` | `%m` timestamp con ms, `%p` PID, `%u` usuario, `%d` base, `%r` host/IP origen, `%a` aplicación: identifica el quién/cuándo/dónde de cada línea |
| `logging_collector` | `on` | `on` (sin cambio) | Sin colector no se escribe a archivo (requeriría reinicio si estuviera en `off`: contexto `postmaster`) |
| `log_destination` | `stderr` | `stderr` (sin cambio) | Destino de salida capturado por el colector de archivos |
| `log_directory` / `log_filename` | `log` / `postgresql-%Y-%m-%d_%H%M%S.log` | sin cambio | Archivo activo: `log/postgresql-2026-11-09_000000.log` |

**Nota técnica sobre `mod` vs `all`:** el nivel mínimo sugerido inicialmente por el asistente era `mod` (solo DDL + `INSERT/UPDATE/DELETE`), pero el Punto B.2 exige verificar una lectura de prueba (`SELECT`) visible en el log y con `mod` los `SELECT` no se auditan. Por ello se fijó deliberadamente `all` para este laboratorio en desarrollo. Como contrapartida, `all` genera alto volumen de escritura y vuelca parámetros sensibles al disco; en un entorno productivo se preferiría `mod` combinado con la extensión `pgaudit` filtrada por objeto.

---

## 2. Análisis del Fragmento Capturado (Punto B.3)

Trazabilidad de **quién / qué / cuándo / desde dónde** verificada sobre las 24 líneas de [log_auditoria_prueba.utf8.txt](log_auditoria_prueba.utf8.txt) (`2026-11-09`):

- **Intento fallido de conexión al motor:**
  - `2026-11-09 12:11:38.086 -03 [21356] [desconocido]@[desconocido] 127.0.0.1(65388) [desconocido] LOG: conexión recibida: host=127.0.0.1 port=65388` → intento desde `127.0.0.1` puerto `65388`.
  - `2026-11-09 12:11:38.104 -03 [21356] postgres@foodstore_dev 127.0.0.1(65388) [desconocido] FATAL: la autentificación password falló para el usuario «postgres»` → **qué**: fallo de autenticación; **quién**: `postgres`; **cuándo**: `2026-11-09 12:11:38.104 -03`; **desde dónde**: `127.0.0.1(65388)`; el `DETALLE` cita la regla evaluada (`pg_hba.conf línea 115: host all all 127.0.0.1/32 scram-sha-256`).
- **Conexión legítima (PID `39876`, puerto `65389`):**
  - `conexión autenticada: identidad=«postgres» método=scram-sha-256 (C:/Program Files/PostgreSQL/17/data/pg_hba.conf:115)` + `conexión autorizada: usuario=postgres base_de_datos=foodstore_dev nombre_de_aplicación=psql` → identifica usuario, método criptográfico, base de destino y aplicación cliente (`%a = psql`).
- **Sentencias auditadas:**
  - Lectura sobre `public.usuarios` (`SELECT id_usuario, nombre, apellido, correo_electronico, rol FROM public.usuarios WHERE activo = TRUE ORDER BY id_usuario LIMIT 3;`).
  - Transacción de prueba (`BEGIN`, `INSERT INTO public.categorias`, `UPDATE public.categorias` sobre `'AuditoriaTestB2'` / `'AuditoriaTestB2_Modificada'` y su reversión con `ROLLBACK`).
  - Llamada de autenticación fallida a nivel aplicación: `SELECT public.fn_autenticar('admin@foodstore.utn.edu.ar', 'clave_erronea_test') AS login_fallido;` (nótese que el parámetro de contraseña errónea queda expuesto en **texto plano** en el log, ver §3).
  - Marcas delimitadoras `AUDITORIA_TEST_INICIO_B2` y `AUDITORIA_TEST_FIN_B2`.
- **Cierre de sesión:**
  - `2026-11-09 12:11:38.466 -03 [39876] postgres@foodstore_dev 127.0.0.1(65389) psql LOG: desconexión: duración de sesión: 0:00:00.305 usuario=postgres base=foodstore_dev host=127.0.0.1 port=65389` (efecto directo de `log_disconnections = on`).

### Límites del mecanismo nativo frente a `pgaudit` y triggers

- Con `log_statement = 'mod'` no se auditan los `SELECT` (una exfiltración masiva de `public.usuarios` o `public.clientes` pasaría inadvertida).
- Con `'all'` se registra absolutamente todo sin distinguir tablas críticas (`usuarios`) de tablas de catálogo (`categorias`), degradando el rendimiento y exponiendo parámetros en disco.
- El log nativo registra el texto de la sentencia SQL ejecutada, pero **no registra cuántas filas se devolvieron ni cuáles eran los valores previos y nuevos (`OLD` / `NEW`)** de cada fila afectada.
- Tampoco desglosa las sentencias ejecutadas internamente dentro de funciones `SECURITY DEFINER` (solo se observa la invocación exterior a `fn_autenticar`).
- La extensión **`pgaudit`** resuelve la granularidad de filtrado por rol y por objeto (permitiendo auditar `SELECT` únicamente sobre `public.usuarios`), mientras que para registrar los valores antes/después fila por fila (`OLD`/`NEW`) se requieren **triggers de auditoría** hacia una tabla dedicada.

---

## 3. El Archivo de Log como Activo Sensible (Punto B.4)

El propio archivo de log constituye un activo altamente crítico porque almacena en texto plano el cuerpo de las consultas ejecutadas: direcciones de correo electrónico, argumentos literales pasados a funciones (como `'clave_erronea_test'` en `fn_autenticar`), nombres de tablas y patrones de uso del sistema.

Por lo tanto, su protección exige controles en dos capas:
1. **A nivel de Sistema Operativo:** el directorio `log/` y sus archivos solo deben ser legibles por la cuenta de servicio del motor PostgreSQL y los administradores de infraestructura: permisos `0600` o `0640` (`postgres:adm`) en sistemas Linux/POSIX, o listas de control de acceso (ACL NTFS) en Windows restringidas exclusivamente a `NT AUTHORITY\NetworkService` (o la cuenta del servicio `postgresql-x64-17`), `SYSTEM` y `BUILTIN\Administradores`, removiendo cualquier permiso heredado de usuarios locales interactivos.
2. **A nivel del Motor de Base de Datos:** la lectura de archivos del servidor debe restringirse estrictamente al superusuario o a miembros explícitamente autorizados de `pg_read_server_files`, sin otorgar jamás ese rol a `app_web`, `rol_soporte`, `rol_reportes`, `rol_auditoria` ni `PUBLIC`.
